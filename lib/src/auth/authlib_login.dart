import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../core/logger.dart';
import '../core/network_client.dart';
import '../core/error_codes.dart';
import '../config/config_manager.dart';
import '../config/config_keys.dart';
import '../di/service_locator.dart';

/// 外置登录认证服务器信息
class AuthlibInjectorServer {
  final String name;
  final String url;
  final String? apiRoot;

  const AuthlibInjectorServer({
    required this.name,
    required this.url,
    this.apiRoot,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'apiRoot': apiRoot,
      };

  factory AuthlibInjectorServer.fromJson(Map<String, dynamic> json) {
    return AuthlibInjectorServer(
      name: json['name'] as String,
      url: json['url'] as String,
      apiRoot: json['apiRoot'] as String?,
    );
  }
}

/// 外置登录账户信息
class AuthlibAccount {
  final String id;
  final String username;
  final String uuid;
  final String accessToken;
  final String serverName;
  final String serverUrl;
  final DateTime createdAt;
  final DateTime lastUsedAt;

  const AuthlibAccount({
    required this.id,
    required this.username,
    required this.uuid,
    required this.accessToken,
    required this.serverName,
    required this.serverUrl,
    required this.createdAt,
    required this.lastUsedAt,
  });

  String get avatarUrl => 'https://mc-heads.net/avatar/$uuid/32';

  String get fullAvatarUrl => 'https://mc-heads.net/avatar/$uuid';

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'uuid': uuid,
        'accessToken': accessToken,
        'serverName': serverName,
        'serverUrl': serverUrl,
        'createdAt': createdAt.toIso8601String(),
        'lastUsedAt': lastUsedAt.toIso8601String(),
      };

  factory AuthlibAccount.fromJson(Map<String, dynamic> json) {
    return AuthlibAccount(
      id: json['id'] as String,
      username: json['username'] as String,
      uuid: json['uuid'] as String,
      accessToken: json['accessToken'] as String,
      serverName: json['serverName'] as String,
      serverUrl: json['serverUrl'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: DateTime.parse(json['lastUsedAt'] as String),
    );
  }

  AuthlibAccount copyWith({
    String? id,
    String? username,
    String? uuid,
    String? accessToken,
    String? serverName,
    String? serverUrl,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return AuthlibAccount(
      id: id ?? this.id,
      username: username ?? this.username,
      uuid: uuid ?? this.uuid,
      accessToken: accessToken ?? this.accessToken,
      serverName: serverName ?? this.serverName,
      serverUrl: serverUrl ?? this.serverUrl,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}

/// authlib-injector 下载状态
enum AuthlibDownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  failed,
}

/// authlib-injector 状态
class AuthlibInjectorStatus {
  final AuthlibDownloadStatus downloadStatus;
  final double downloadProgress;
  final String? errorMessage;
  final String? localPath;

  const AuthlibInjectorStatus({
    this.downloadStatus = AuthlibDownloadStatus.notDownloaded,
    this.downloadProgress = 0.0,
    this.errorMessage,
    this.localPath,
  });

  bool get isReady => downloadStatus == AuthlibDownloadStatus.downloaded && localPath != null;
}

/// 外置登录管理器
class AuthlibLoginManager {
  static AuthlibLoginManager? _instance;

  factory AuthlibLoginManager() {
    return _instance ??= AuthlibLoginManager._internal();
  }

  AuthlibLoginManager._internal();

  static AuthlibLoginManager get instance =>
      ServiceLocator.instance.tryGet<AuthlibLoginManager>() ??
      (_instance ??= AuthlibLoginManager._internal());

  static void reset() {
    _instance = null;
  }

  final Logger _logger = Logger('AuthlibLoginManager');
  final IConfigManager _configManager = ConfigManager();
  final NetworkClient _networkClient = NetworkClient();

  AuthlibInjectorStatus _status = const AuthlibInjectorStatus();
  final StreamController<AuthlibInjectorStatus> _statusController =
      StreamController<AuthlibInjectorStatus>.broadcast();

  Stream<AuthlibInjectorStatus> get statusStream => _statusController.stream;

  List<AuthlibInjectorServer> _servers = [];
  final StreamController<List<AuthlibInjectorServer>> _serversController =
      StreamController<List<AuthlibInjectorServer>>.broadcast();

  Stream<List<AuthlibInjectorServer>> get serversStream => _serversController.stream;

  List<AuthlibInjectorServer> get servers => _servers;

  AuthlibInjectorServer? _selectedServer;

  AuthlibInjectorServer? get selectedServer => _selectedServer;

  String? get authlibPath => _status.localPath;

  bool get isAuthlibReady => _status.isReady;

  Future<void> initialize() async {
    await _loadServers();
    await _checkAuthlibStatus();
  }

  Future<void> _loadServers() async {
    final serversJson = _configManager.getString(ConfigKeys.authlibServers);
    if (serversJson != null) {
      try {
        final List<dynamic> serversList = jsonDecode(serversJson);
        _servers = serversList
            .map((json) => AuthlibInjectorServer.fromJson(json as Map<String, dynamic>))
            .toList();
        _serversController.add(_servers);
      } catch (e) {
        _logger.error('Failed to load authlib servers', e);
      }
    }

    if (_servers.isEmpty) {
      _servers = _getDefaultServers();
      await _saveServers();
    }
  }

  List<AuthlibInjectorServer> _getDefaultServers() {
    return const [
      AuthlibInjectorServer(
        name: 'Minecraft(我的世界)',
        url: 'https://littleservice.cn/authlib',
        apiRoot: 'https://littleservice.cn/api',
      ),
      AuthlibInjectorServer(
        name: 'TiaoWu',
        url: 'https://tiaowu.jfrog.io/artifactory/mirrors/authlib-injector/authlib-injector-1.1.47.jar',
        apiRoot: 'https://mc.tiaowu.cn/api',
      ),
      AuthlibInjectorServer(
        name: 'LittleSkin',
        url: 'https://littlesk.in/authlib-injector-1.1.47.jar',
        apiRoot: 'https://littlesk.in/api',
      ),
    ];
  }

  Future<void> _saveServers() async {
    final serversJson = jsonEncode(_servers.map((s) => s.toJson()).toList());
    await _configManager.setString(ConfigKeys.authlibServers, serversJson);
    _serversController.add(_servers);
  }

  Future<void> addServer(AuthlibInjectorServer server) async {
    _servers.add(server);
    await _saveServers();
    _logger.info('Added authlib server: ${server.name}');
  }

  Future<void> removeServer(String name) async {
    _servers.removeWhere((s) => s.name == name);
    await _saveServers();
    if (_selectedServer?.name == name) {
      _selectedServer = null;
    }
    _logger.info('Removed authlib server: $name');
  }

  Future<void> selectServer(AuthlibInjectorServer server) async {
    _selectedServer = server;
    await _configManager.setString(
      ConfigKeys.authlibSelectedServer,
      jsonEncode(server.toJson()),
    );
    _logger.info('Selected authlib server: ${server.name}');
  }

  Future<void> _loadSelectedServer() async {
    final serverJson = _configManager.getString(ConfigKeys.authlibSelectedServer);
    if (serverJson != null) {
      try {
        _selectedServer = AuthlibInjectorServer.fromJson(jsonDecode(serverJson));
      } catch (e) {
        _logger.error('Failed to load selected server', e);
      }
    }
  }

  Future<void> _checkAuthlibStatus() async {
    final authlibPath = _configManager.getString(ConfigKeys.authlibPath);
    if (authlibPath != null && await File(authlibPath).exists()) {
      _status = AuthlibInjectorStatus(
        downloadStatus: AuthlibDownloadStatus.downloaded,
        localPath: authlibPath,
      );
    } else {
      _status = const AuthlibInjectorStatus();
    }
    _statusController.add(_status);
  }

  Future<String?> downloadAuthlib() async {
    if (_selectedServer == null) {
      throw AppException.fromCode(
        ErrorCodes.authMissingParameter,
        detail: '请先选择一个外置登录服务器',
      );
    }

    final jarUrl = _selectedServer!.url;
    final supportDir = await _getSupportDirectory();
    final jarPath = path.join(supportDir, 'authlib-injector.jar');

    _status = AuthlibInjectorStatus(
      downloadStatus: AuthlibDownloadStatus.downloading,
      downloadProgress: 0.0,
    );
    _statusController.add(_status);

    try {
      _logger.info('Downloading authlib-injector from: $jarUrl');

      await _networkClient.downloadFile(
        jarUrl,
        jarPath,
        onProgress: (downloadedBytes, contentLength) {
          if (contentLength > 0) {
            final progress = downloadedBytes / contentLength;
            _status = AuthlibInjectorStatus(
              downloadStatus: AuthlibDownloadStatus.downloading,
              downloadProgress: progress,
            );
            _statusController.add(_status);
          }
        },
      );

      await _configManager.setString(ConfigKeys.authlibPath, jarPath);

      _status = AuthlibInjectorStatus(
        downloadStatus: AuthlibDownloadStatus.downloaded,
        downloadProgress: 1.0,
        localPath: jarPath,
      );
      _statusController.add(_status);

      _logger.info('Authlib-injector downloaded successfully: $jarPath');
      return jarPath;
    } catch (e, stackTrace) {
      _status = AuthlibInjectorStatus(
        downloadStatus: AuthlibDownloadStatus.failed,
        errorMessage: e.toString(),
      );
      _statusController.add(_status);
      _logger.error('Failed to download authlib-injector', e, stackTrace);
      rethrow;
    }
  }

  Future<AuthlibAccount?> login(String username, String password) async {
    if (_selectedServer == null || !isAuthlibReady) {
      throw AppException.fromCode(
        ErrorCodes.authAuthlibFailed,
        detail: '请先配置并下载 authlib-injector',
      );
    }

    final apiRoot = _selectedServer!.apiRoot ?? '${Uri.parse(_selectedServer!.url).origin}/api';

    try {
      _logger.info('Authlib login to: $apiRoot');

      final response = await _networkClient.postJson(
        '$apiRoot/auth/login',
        {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final account = AuthlibAccount(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          username: data['selectedProfile']['name'] as String,
          uuid: data['selectedProfile']['id'] as String,
          accessToken: data['accessToken'] as String,
          serverName: _selectedServer!.name,
          serverUrl: _selectedServer!.url,
          createdAt: DateTime.now(),
          lastUsedAt: DateTime.now(),
        );

        await _saveAccount(account);
        _logger.info('Authlib login successful: ${account.username}');
        return account;
      } else {
        final error = jsonDecode(response.body);
        throw AppException.fromCode(
          ErrorCodes.authAuthlibFailed,
          detail: error['errorMessage'] ?? '登录失败',
        );
      }
    } catch (e, stackTrace) {
      _logger.error('Authlib login failed', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _saveAccount(AuthlibAccount account) async {
    final accountsJson = _configManager.getString(ConfigKeys.authlibAccounts);
    List<AuthlibAccount> accounts = [];

    if (accountsJson != null) {
      try {
        final List<dynamic> accountsList = jsonDecode(accountsJson);
        accounts = accountsList
            .map((json) => AuthlibAccount.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        _logger.error('Failed to load authlib accounts', e);
      }
    }

    final existingIndex = accounts.indexWhere((a) => a.uuid == account.uuid);
    if (existingIndex >= 0) {
      accounts[existingIndex] = account;
    } else {
      accounts.add(account);
    }

    final newAccountsJson = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await _configManager.setString(ConfigKeys.authlibAccounts, newAccountsJson);
  }

  Future<List<AuthlibAccount>> getAccounts() async {
    final accountsJson = _configManager.getString(ConfigKeys.authlibAccounts);
    if (accountsJson == null) return [];

    try {
      final List<dynamic> accountsList = jsonDecode(accountsJson);
      return accountsList
          .map((json) => AuthlibAccount.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.error('Failed to load authlib accounts', e);
      return [];
    }
  }

  Future<void> removeAccount(String id) async {
    final accounts = await getAccounts();
    accounts.removeWhere((a) => a.id == id);
    final accountsJson = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await _configManager.setString(ConfigKeys.authlibAccounts, accountsJson);
  }

  Future<void> refreshAccount(AuthlibAccount account) async {
    if (_selectedServer == null) return;

    final apiRoot = _selectedServer!.apiRoot ?? '${Uri.parse(_selectedServer!.url).origin}/api';

    try {
      final response = await _networkClient.postJson(
        '$apiRoot/auth/refresh',
        {
          'accessToken': account.accessToken,
          'clientToken': account.id,
        },
        headers: {
          'Authorization': 'Bearer ${account.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final refreshedAccount = account.copyWith(
          accessToken: data['accessToken'] as String,
          lastUsedAt: DateTime.now(),
        );
        await _saveAccount(refreshedAccount);
        _logger.info('Account refreshed: ${refreshedAccount.username}');
      }
    } catch (e) {
      _logger.error('Failed to refresh account', e);
    }
  }

  Future<String> _getSupportDirectory() async {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    final supportDir = path.join(homeDir, '.bamclaunch');
    final authlibDir = path.join(supportDir, 'authlib');

    final dir = Directory(authlibDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return authlibDir;
  }

  void dispose() {
    _statusController.close();
    _serversController.close();
  }
}
