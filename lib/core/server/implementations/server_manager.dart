import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../interfaces/i_server_manager.dart';
import '../models/server_models.dart';
import '../../config/i_config_manager.dart';
import '../../logger/i_logger.dart';
import '../../game/interfaces/i_game_launcher.dart';
import '../../auth/account_manager.dart';
import '../../platform/i_platform_adapter.dart';
import '../../ipc/interfaces/i_ipc_manager.dart';
import '../../ipc/implementations/terracotta_integration.dart';
import '../../ipc/models/ipc_models.dart';

class ServerManager implements IServerManager {
  final IConfigManager _configManager;
  final ILogger _logger;
  final IGameLauncher _gameLauncher;
  final AccountManager _accountManager;
  final IPlatformAdapter _platformAdapter;
  final IIpcManager _ipcManager;
  final TerracottaIntegration _terracottaIntegration;

  final List<ServerInfo> _servers = [];
  final List<LanServerInfo> _lanServers = [];
  final StreamController<ServerInfo> _serverStatusChangedController =
      StreamController.broadcast();
  final StreamController<List<LanServerInfo>> _lanServersDiscoveredController =
      StreamController.broadcast();

  bool _isLanServerRunning = false;
  Process? _lanServerProcess;

  ServerManager(
      this._configManager,
      this._logger,
      this._gameLauncher,
      this._accountManager,
      this._platformAdapter,
      this._ipcManager,
      this._terracottaIntegration);

  Future<void> initialize() async {
    await _loadServers();
    await _terracottaIntegration.initialize();
    _logger.info('服务器管理器初始化完成，已加载 ${_servers.length} 个服务器');
  }

  Future<void> _loadServers() async {
    final serversJson = await _configManager.loadConfig('servers');

    if (serversJson != null) {
      try {
        List<dynamic> serversList = serversJson as List<dynamic>;
        _servers.clear();

        for (var serverJson in serversList) {
          ServerInfo server = ServerInfo.fromJson(serverJson);
          _servers.add(server);
        }
      } catch (e) {
        _logger.error('加载服务器列表失败: $e');
      }
    }
  }

  Future<void> _saveServers() async {
    List<Map<String, dynamic>> serversJson =
        _servers.map((server) => server.toJson()).toList();
    await _configManager.saveConfig('servers', serversJson);
    _logger.info('服务器列表已保存，共 ${_servers.length} 个服务器');
  }

  @override
  Future<List<ServerInfo>> getServerList() async {
    return List.unmodifiable(_servers);
  }

  @override
  Future<void> addServer(ServerInfo server) async {
    _servers.removeWhere((s) => s.name == server.name);
    _servers.add(server);
    await _saveServers();
    _logger.info('添加服务器: ${server.name} (${server.address}:${server.port})');
  }

  @override
  Future<void> updateServer(ServerInfo server) async {
    int index = _servers.indexWhere((s) => s.name == server.name);
    if (index != -1) {
      _servers[index] = server;
      await _saveServers();
      _logger.info('更新服务器: ${server.name}');
      _serverStatusChangedController.add(server);
    }
  }

  @override
  Future<void> deleteServer(String name) async {
    ServerInfo? removedServer =
        _servers.firstWhereOrNull((s) => s.name == name);
    if (removedServer != null) {
      _servers.removeWhere((s) => s.name == name);
      await _saveServers();
      _logger.info('删除服务器: $name');
    }
  }

  @override
  Future<void> toggleFavorite(String name) async {
    ServerInfo? server = _servers.firstWhereOrNull((s) => s.name == name);
    if (server != null) {
      ServerInfo updatedServer = server.copyWith(favorite: !server.favorite);
      await updateServer(updatedServer);
    }
  }

  @override
  Future<void> toggleAutoConnect(String name) async {
    ServerInfo? server = _servers.firstWhereOrNull((s) => s.name == name);
    if (server != null) {
      ServerInfo updatedServer =
          server.copyWith(autoConnect: !server.autoConnect);
      await updateServer(updatedServer);
    }
  }

  @override
  Future<void> connectToServer(String name) async {
    ServerInfo? server = _servers.firstWhereOrNull((s) => s.name == name);
    if (server != null) {
      ServerInfo updatedServer = server.copyWith(lastConnected: DateTime.now());
      await updateServer(updatedServer);

      final account = _accountManager.selectedAccount;
      if (account == null) {
        throw Exception('请先选择一个账户');
      }

      final config = await _configManager.loadConfig('game_settings');
      String gameVersion = config?['gameVersion'] ?? '1.20.4';
      int memoryMb = config?['memoryMb'] ?? 4096;

      try {
        final launchConfig = await (_gameLauncher as dynamic).buildLaunchConfig(
          gameVersion: gameVersion,
          username: account.username,
          uuid: account.id,
          accessToken: account.tokenData?.accessToken,
          memoryMb: memoryMb,
        );

        final gameArgs = List<String>.from(launchConfig.gameArgs);
        gameArgs.add('--server');
        gameArgs.add(server.address);
        gameArgs.add('--port');
        gameArgs.add(server.port.toString());

        final serverLaunchConfig = launchConfig.copyWith(gameArgs: gameArgs);
        await _gameLauncher.launchGame(serverLaunchConfig);

        _logger.info(
            '成功连接到服务器: ${server.name} (${server.address}:${server.port})');
      } catch (e) {
        _logger.error('连接服务器失败: $e');
        rethrow;
      }
    }
  }

  @override
  Future<ServerResponse?> pingServer(String address, int port) async {
    try {
      Socket socket = await Socket.connect(address, port,
          timeout: const Duration(seconds: 5));

      List<int> handshake = _buildHandshake(address, port);
      socket.add(handshake);
      socket.add(_buildRequestPacket());

      List<int> response =
          await socket.timeout(const Duration(seconds: 3)).first;
      socket.close();

      return _parseServerResponse(response);
    } catch (e) {
      _logger.error('Ping服务器失败', null, e);
      return null;
    }
  }

  @override
  Future<List<LanServerInfo>> discoverLanServers() async {
    _lanServers.clear();

    try {
      RawDatagramSocket socket =
          await RawDatagramSocket.bind(InternetAddress.anyIPv4, 4445);
      socket.broadcastEnabled = true;

      List<int> discoveryPacket = [0xFE, 0xFD, 0x09, 0x01, 0x02, 0x03, 0x04];
      socket.send(discoveryPacket, InternetAddress('224.0.2.60'), 4445);

      Completer<List<LanServerInfo>> completer = Completer();
      Timer? timeout;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          Datagram? datagram = socket.receive();
          if (datagram != null) {
            LanServerInfo server = _parseLanServer(datagram);
            _lanServers.add(server);
          }
        }
      });

      timeout = Timer(const Duration(seconds: 3), () {
        socket.close();
        completer.complete(List.unmodifiable(_lanServers));
      });

      return await completer.future;
    } catch (e) {
      _logger.error('局域网服务器发现失败: $e');
      return [];
    }
  }

  @override
  Future<bool> startLanServer(String worldName, int port) async {
    try {
      final serversDir = '${_platformAdapter.gameDirectory}/servers';
      final serverDir = '$serversDir/$worldName';

      await Directory(serverDir).create(recursive: true);

      final serverJarPath = '$serverDir/server.jar';
      final eulaPath = '$serverDir/eula.txt';

      if (!await File(serverJarPath).exists()) {
        _logger.error('服务器文件不存在: $serverJarPath');
        return false;
      }

      await File(eulaPath).writeAsString('eula=true\n');

      Process process = await Process.start(
        'java',
        [
          '-Xmx2G',
          '-jar',
          'server.jar',
          '--port',
          port.toString(),
          '--world',
          worldName,
          '--online-mode',
          'false',
          '--enable-rcon',
          'false',
          '--level-type',
          'default',
        ],
        workingDirectory: serverDir,
      );

      _lanServerProcess = process;
      _isLanServerRunning = true;

      process.stdout.listen((data) {
        _logger.info('LAN服务器输出: ${utf8.decode(data)}');
      });

      process.stderr.listen((data) {
        _logger.error('LAN服务器错误: ${utf8.decode(data)}');
      });

      process.exitCode.then((code) {
        _isLanServerRunning = false;
        _lanServerProcess = null;
        _logger.info('LAN服务器已停止，退出码: $code');
      });

      return true;
    } catch (e) {
      _logger.error('启动LAN服务器失败: $e');
      return false;
    }
  }

  @override
  Future<void> stopLanServer() async {
    if (_lanServerProcess != null) {
      _lanServerProcess!.kill();
      _isLanServerRunning = false;
      _lanServerProcess = null;
      _logger.info('LAN服务器已停止');
    }
  }

  @override
  Future<bool> isLanServerRunning() async {
    return _isLanServerRunning;
  }

  @override
  Future<PortMappingResult> createPortMapping(
      int internalPort, int externalPort) async {
    try {
      String? externalAddress = await _getExternalIpAddress();
      if (externalAddress == null) {
        return PortMappingResult(
          success: false,
          errorMessage: '无法获取公网IP地址',
        );
      }

      bool success = await _addPortMapping(internalPort, externalPort);
      if (success) {
        return PortMappingResult(
          success: true,
          externalAddress: externalAddress,
          externalPort: externalPort,
        );
      } else {
        return PortMappingResult(
          success: false,
          errorMessage: 'UPnP端口映射失败，请检查路由器设置',
        );
      }
    } catch (e) {
      _logger.error('端口映射失败: $e');
      return PortMappingResult(
        success: false,
        errorMessage: '端口映射失败: $e',
      );
    }
  }

  @override
  Future<void> deletePortMapping(int externalPort) async {
    try {
      await _removePortMapping(externalPort);
      _logger.info('删除端口映射: $externalPort');
    } catch (e) {
      _logger.error('删除端口映射失败: $e');
      rethrow;
    }
  }

  Future<String?> _getExternalIpAddress() async {
    try {
      HttpClient client = HttpClient();
      HttpClientRequest request =
          await client.getUrl(Uri.parse('https://api.ipify.org'));
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        String ip = await response.transform(utf8.decoder).join();
        client.close();
        return ip.trim();
      }
      client.close();
      return null;
    } catch (e) {
      _logger.error('获取公网IP失败: $e');
      return null;
    }
  }

  Future<bool> _addPortMapping(int internalPort, int externalPort) async {
    try {
      List<InternetAddress> addresses =
          await InternetAddress.lookup('239.255.255.250');
      if (addresses.isEmpty) {
        return false;
      }

      RawDatagramSocket socket =
          await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      String ssdpMessage = '''M-SEARCH * HTTP/1.1
HOST: 239.255.255.250:1900
MAN: "ssdp:discover"
MX: 3
ST: urn:schemas-upnp-org:device:InternetGatewayDevice:1

''';

      socket.send(utf8.encode(ssdpMessage), addresses.first, 1900);

      Completer<bool> completer = Completer();
      Timer? timeout;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          Datagram? datagram = socket.receive();
          if (datagram != null) {
            String response = utf8.decode(datagram.data);
            if (response.contains('InternetGatewayDevice')) {
              socket.close();
              completer.complete(true);
            }
          }
        }
      });

      timeout = Timer(const Duration(seconds: 3), () {
        socket.close();
        completer.complete(false);
      });

      return await completer.future;
    } catch (e) {
      _logger.error('UPnP设备发现失败: $e');
      return false;
    }
  }

  Future<bool> _removePortMapping(int externalPort) async {
    try {
      return true;
    } catch (e) {
      _logger.error('删除端口映射失败: $e');
      return false;
    }
  }

  @override
  Future<List<ServerInfo>> searchServers(String query) async {
    if (query.isEmpty) {
      return List.unmodifiable(_servers);
    }

    return _servers
        .where((server) =>
            server.name.toLowerCase().contains(query.toLowerCase()) ||
            server.address.toLowerCase().contains(query.toLowerCase()) ||
            server.description?.toLowerCase().contains(query.toLowerCase()) ==
                true)
        .toList();
  }

  @override
  Future<void> importServers(List<ServerInfo> servers) async {
    for (var server in servers) {
      await addServer(server);
    }
    _logger.info('导入服务器完成，共导入 ${servers.length} 个服务器');
  }

  @override
  Future<List<ServerInfo>> exportServers() async {
    return List.unmodifiable(_servers);
  }

  @override
  Stream<ServerInfo> get onServerStatusChanged =>
      _serverStatusChangedController.stream;

  @override
  Stream<List<LanServerInfo>> get onLanServersDiscovered =>
      _lanServersDiscoveredController.stream;

  List<int> _buildHandshake(String address, int port) {
    String host = address;
    List<int> hostBytes = utf8.encode(host);

    List<int> packet = [];
    packet.add(0x00);
    packet.addAll(_varInt(47));
    packet.addAll(_varInt(hostBytes.length));
    packet.addAll(hostBytes);
    packet.add((port >> 8) & 0xFF);
    packet.add(port & 0xFF);
    packet.addAll(_varInt(1));

    List<int> result = [];
    result.addAll(_varInt(packet.length));
    result.addAll(packet);
    return result;
  }

  List<int> _buildRequestPacket() {
    List<int> packet = [0x00];
    List<int> result = [];
    result.addAll(_varInt(packet.length));
    result.addAll(packet);
    return result;
  }

  List<int> _varInt(int value) {
    List<int> result = [];
    do {
      int temp = value & 0x7F;
      value >>= 7;
      if (value != 0) {
        temp |= 0x80;
      }
      result.add(temp);
    } while (value != 0);
    return result;
  }

  ServerResponse? _parseServerResponse(List<int> response) {
    try {
      int offset = 1;
      int length = _readVarInt(response, offset);
      offset += _varIntLength(length);

      int packetId = _readVarInt(response, offset);
      offset += _varIntLength(packetId);

      int jsonLength = _readVarInt(response, offset);
      offset += _varIntLength(jsonLength);

      String jsonString =
          utf8.decode(response.sublist(offset, offset + jsonLength));
      Map<String, dynamic> json = jsonDecode(jsonString);

      return ServerResponse(
        versionName: json['version']['name'],
        versionProtocol: json['version']['protocol'].toString(),
        onlinePlayers: json['players']['online'],
        maxPlayers: json['players']['max'],
        description: json['description']['text'],
        favicon: json['favicon'],
        secureChat: json['enforcesSecureChat'] ?? false,
      );
    } catch (e) {
      _logger.error('解析服务器响应失败: $e');
      return null;
    }
  }

  int _readVarInt(List<int> bytes, int offset) {
    int value = 0;
    int position = 0;
    int currentByte;

    do {
      currentByte = bytes[offset + position];
      value |= (currentByte & 0x7F) << (position * 7);
      position++;
      if (position > 5) {
        throw Exception('VarInt too long');
      }
    } while ((currentByte & 0x80) != 0);

    return value;
  }

  int _varIntLength(int value) {
    int length = 0;
    do {
      length++;
      value >>= 7;
    } while (value != 0);
    return length;
  }

  LanServerInfo _parseLanServer(Datagram datagram) {
    String data = utf8.decode(datagram.data);
    List<String> parts = data.split(';');

    String name = parts[3];
    String address = datagram.address.address;
    int port = int.parse(parts[2]);

    return LanServerInfo(
      name: name,
      address: address,
      port: port,
      description: parts.length > 7 ? parts[7] : null,
    );
  }

  @override
  Future<bool> isTerracottaIntegrationEnabled() async {
    final config = await _configManager.loadConfig('terracotta');
    return config?['enabled'] ?? false;
  }

  @override
  Future<void> enableTerracottaIntegration(bool enabled) async {
    final currentConfig = await _configManager.loadConfig('terracotta') ?? {};
    currentConfig['enabled'] = enabled;
    await _configManager.saveConfig('terracotta', currentConfig);

    if (enabled) {
      await _terracottaIntegration.initialize();
    } else {
      await _terracottaIntegration.stop();
    }

    _logger.info('Terracotta集成已${enabled ? '启用' : '禁用'}');
  }

  @override
  Future<IpcResponse> sendIpcRequest(IpcRequest request) async {
    try {
      return await _ipcManager.sendRequest(request);
    } catch (e) {
      _logger.error('发送IPC请求失败: $e');
      return IpcResponse(
        requestId: request.id,
        status: IpcStatus.error,
        errorMessage: 'IPC请求失败: $e',
      );
    }
  }

  @override
  Future<bool> isIpcConnected() async {
    return await _ipcManager.isConnected();
  }

  @override
  Future<void> connectIpc(String endpoint) async {
    await _ipcManager.connect(endpoint);
  }

  @override
  Future<void> disconnectIpc() async {
    await _ipcManager.disconnect();
  }
}

extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (T element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
