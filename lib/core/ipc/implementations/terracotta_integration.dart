import 'dart:io';
import 'dart:async';
import 'dart:convert';
import '../interfaces/i_ipc_manager.dart';
import '../models/ipc_models.dart';
import '../../logger/i_logger.dart';
import '../../config/i_config_manager.dart';
import '../../platform/i_platform_adapter.dart';

class TerracottaIntegration {
  final IIpcManager _ipcManager;
  final ILogger _logger;
  final IConfigManager _configManager;
  final IPlatformAdapter _platformAdapter;
  
  Process? _terracottaProcess;
  TerracottaIntegrationConfig? _config;
  bool _isInitialized = false;

  TerracottaIntegration(
    this._ipcManager,
    this._logger,
    this._configManager,
    this._platformAdapter,
  );

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _logger.info('初始化Terracotta集成');
    
    try {
      await _loadConfig();
      
      if (_config?.enabled == true) {
        await _startTerracotta();
        await _setupIpcHandlers();
      }
      
      _isInitialized = true;
    } catch (e) {
      _logger.error('Terracotta集成初始化失败: $e');
    }
  }

  Future<void> _loadConfig() async {
    final configData = await _configManager.loadConfig('terracotta');
    if (configData != null) {
      _config = TerracottaIntegrationConfig.fromJson(configData);
    } else {
      _config = TerracottaIntegrationConfig(
        enabled: false,
        terracottaPath: '',
        apiEndpoint: 'http://localhost:8080',
        autoStart: false,
        customConfig: {},
      );
    }
  }

  Future<void> _startTerracotta() async {
    if (_config == null || !_config!.enabled) {
      _logger.warn('Terracotta未启用');
      return;
    }
    
    try {
      String terracottaPath = _config!.terracottaPath;
      if (terracottaPath.isEmpty) {
        throw Exception('Terracotta路径未配置');
      }
      
      if (!await File(terracottaPath).exists()) {
        throw Exception('Terracotta可执行文件不存在: $terracottaPath');
      }
      
      List<String> arguments = [
        '--port', '8080',
        '--config', 'terracotta.json',
      ];
      
      if (_config!.customConfig.containsKey('arguments')) {
        arguments.addAll(_config!.customConfig['arguments']);
      }
      
      _terracottaProcess = await Process.start(
        terracottaPath,
        arguments,
        workingDirectory: Directory(terracottaPath).parent.path,
      );
      
      _terracottaProcess!.stdout.listen((data) {
        _logger.info('Terracotta输出: ${utf8.decode(data)}');
      });
      
      _terracottaProcess!.stderr.listen((data) {
        _logger.error('Terracotta错误: ${utf8.decode(data)}');
      });
      
      _terracottaProcess!.exitCode.then((code) {
        _logger.info('Terracotta进程退出，退出码: $code');
        _terracottaProcess = null;
      });
      
      _logger.info('Terracotta进程已启动');
      
      await Future.delayed(const Duration(seconds: 2));
      
      await _ipcManager.connect('localhost:8080');
    } catch (e) {
      _logger.error('启动Terracotta失败: $e');
      rethrow;
    }
  }

  Future<void> _setupIpcHandlers() async {
    await _ipcManager.registerHandler('getServerInfo', _handleGetServerInfo);
    await _ipcManager.registerHandler('connectToServer', _handleConnectToServer);
    await _ipcManager.registerHandler('startLanServer', _handleStartLanServer);
    await _ipcManager.registerHandler('stopLanServer', _handleStopLanServer);
    await _ipcManager.registerHandler('pingServer', _handlePingServer);
    
    _logger.info('Terracotta IPC处理器注册完成');
  }

  Future<IpcResponse> _handleGetServerInfo(IpcRequest request) async {
    try {
      String serverName = request.data['serverName'];
      
      final response = await _ipcManager.sendRequest(IpcRequest(
        id: request.id,
        action: 'getServerInfo',
        data: {'serverName': serverName},
      ));
      
      return response;
    } catch (e) {
      return IpcResponse(
        requestId: request.id,
        status: IpcStatus.error,
        errorMessage: '获取服务器信息失败: $e',
      );
    }
  }

  Future<IpcResponse> _handleConnectToServer(IpcRequest request) async {
    try {
      String serverName = request.data['serverName'];
      String gameVersion = request.data['gameVersion'];
      
      final response = await _ipcManager.sendRequest(IpcRequest(
        id: request.id,
        action: 'connectToServer',
        data: {
          'serverName': serverName,
          'gameVersion': gameVersion,
        },
      ));
      
      return response;
    } catch (e) {
      return IpcResponse(
        requestId: request.id,
        status: IpcStatus.error,
        errorMessage: '连接服务器失败: $e',
      );
    }
  }

  Future<IpcResponse> _handleStartLanServer(IpcRequest request) async {
    try {
      String worldName = request.data['worldName'];
      int port = request.data['port'] ?? 25565;
      
      final response = await _ipcManager.sendRequest(IpcRequest(
        id: request.id,
        action: 'startLanServer',
        data: {
          'worldName': worldName,
          'port': port,
        },
      ));
      
      return response;
    } catch (e) {
      return IpcResponse(
        requestId: request.id,
        status: IpcStatus.error,
        errorMessage: '启动局域网服务器失败: $e',
      );
    }
  }

  Future<IpcResponse> _handleStopLanServer(IpcRequest request) async {
    try {
      final response = await _ipcManager.sendRequest(IpcRequest(
        id: request.id,
        action: 'stopLanServer',
        data: {},
      ));
      
      return response;
    } catch (e) {
      return IpcResponse(
        requestId: request.id,
        status: IpcStatus.error,
        errorMessage: '停止局域网服务器失败: $e',
      );
    }
  }

  Future<IpcResponse> _handlePingServer(IpcRequest request) async {
    try {
      String address = request.data['address'];
      int port = request.data['port'] ?? 25565;
      
      final response = await _ipcManager.sendRequest(IpcRequest(
        id: request.id,
        action: 'pingServer',
        data: {
          'address': address,
          'port': port,
        },
      ));
      
      return response;
    } catch (e) {
      return IpcResponse(
        requestId: request.id,
        status: IpcStatus.error,
        errorMessage: 'Ping服务器失败: $e',
      );
    }
  }

  Future<void> stop() async {
    if (_terracottaProcess != null) {
      _terracottaProcess!.kill();
      _terracottaProcess = null;
      _logger.info('Terracotta进程已停止');
    }
    
    await _ipcManager.disconnect();
  }

  Future<bool> isRunning() async {
    return _terracottaProcess != null && _terracottaProcess!.exitCode == null;
  }

  Future<void> updateConfig(TerracottaIntegrationConfig config) async {
    _config = config;
    await _configManager.saveConfig('terracotta', config.toJson());
    
    if (config.enabled && !await isRunning()) {
      await _startTerracotta();
    } else if (!config.enabled && await isRunning()) {
      await stop();
    }
  }
}