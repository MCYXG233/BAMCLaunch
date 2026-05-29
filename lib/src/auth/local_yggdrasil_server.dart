import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../core/logger.dart';
import '../account/account.dart';

class LocalYggdrasilServer {
  static LocalYggdrasilServer? _instance;

  factory LocalYggdrasilServer() {
    return _instance ??= LocalYggdrasilServer._internal();
  }

  LocalYggdrasilServer._internal();

  static LocalYggdrasilServer get instance =>
      _instance ??= LocalYggdrasilServer._internal();

  final Logger _logger = Logger('LocalYggdrasilServer');

  HttpServer? _server;
  String _rootUrl = 'http://127.0.0.1:25566';
  bool _isRunning = false;

  final Map<String, String> _tokens = {};
  final Map<String, Account> _players = {};

  bool get isRunning => _isRunning;
  String get rootUrl => _rootUrl;

  Future<void> start({String host = '127.0.0.1', int port = 25566}) async {
    if (_isRunning) {
      _logger.warn('Local Yggdrasil server is already running');
      return;
    }

    _rootUrl = 'http://$host:$port';

    try {
      _server = await HttpServer.bind(host, port);
      _server!.listen(_handleRequest);
      _isRunning = true;
      _logger.info('Local Yggdrasil server started at $_rootUrl');
    } catch (e, stackTrace) {
      _logger.error('Failed to start local Yggdrasil server', e, stackTrace);
      rethrow;
    }
  }

  Future<void> stop() async {
    if (!_isRunning || _server == null) {
      return;
    }

    await _server!.close(force: true);
    _server = null;
    _isRunning = false;
    _logger.info('Local Yggdrasil server stopped');
  }

  void applyPlayer(Account account) {
    _players[account.id] = account;
    _logger.debug('Applied player: ${account.username}');
  }

  String getMetadata() {
    return jsonEncode({
      'meta': {
        'serverName': 'BAMC Launcher Local Server',
        'implementationName': 'BAMCLaunch',
        'implementationVersion': '1.0.0',
      },
      'skinDomains': ['*'],
      'signaturePublickey': '',
    });
  }

  void _handleRequest(HttpRequest request) async {
    try {
      final path = request.uri.path;
      final method = request.method;

      _logger.debug('Request: $method $path');

      switch (path) {
        case '/authserver/authenticate':
          await _handleAuthenticate(request);
          break;
        case '/authserver/refresh':
          await _handleRefresh(request);
          break;
        case '/authserver/validate':
          await _handleValidate(request);
          break;
        case '/authserver/invalidate':
          await _handleInvalidate(request);
          break;
        case '/authserver/signout':
          await _handleSignout(request);
          break;
        case '/api/profiles/minecraft':
          await _handleProfiles(request);
          break;
        case '/sessionserver/session/minecraft/join':
          await _handleJoin(request);
          break;
        case '/sessionserver/session/minecraft/hasJoined':
          await _handleHasJoined(request);
          break;
        case '/.well-known/minecraft/services':
          await _handleWellKnown(request);
          break;
        default:
          _sendError(request, 404, 'Not found');
      }
    } catch (e, stackTrace) {
      _logger.error('Request handling error', e, stackTrace);
      _sendError(request, 500, 'Internal server error');
    }
  }

  Future<void> _handleAuthenticate(HttpRequest request) async {
    final body = await _readRequestBody(request);
    final json = jsonDecode(body) as Map<String, dynamic>;

    final username = json['username'] as String? ?? '';
    final password = json['password'] as String? ?? '';

    if (password.isNotEmpty) {
      _sendError(request, 401, 'Password authentication not supported');
      return;
    }

    final account = _players.values.firstWhere(
      (p) => p.username == username,
      orElse: () => _createOfflineAccount(username),
    );

    final accessToken = _generateToken();
    final clientToken = _generateToken();

    _tokens[accessToken] = account.id;

    final response = jsonEncode({
      'accessToken': accessToken,
      'clientToken': clientToken,
      'selectedProfile': {
        'id': account.uuid ?? _generateUuid(username),
        'name': account.username,
      },
      'availableProfiles': [
        {
          'id': account.uuid ?? _generateUuid(username),
          'name': account.username,
        },
      ],
    });

    _sendResponse(request, 200, response);
  }

  Future<void> _handleRefresh(HttpRequest request) async {
    final body = await _readRequestBody(request);
    final json = jsonDecode(body) as Map<String, dynamic>;

    final accessToken = json['accessToken'] as String? ?? '';
    final clientToken = json['clientToken'] as String? ?? '';

    if (!_tokens.containsKey(accessToken)) {
      _sendError(request, 401, 'Invalid token');
      return;
    }

    final accountId = _tokens[accessToken]!;
    final account = _players[accountId];

    if (account == null) {
      _sendError(request, 401, 'Account not found');
      return;
    }

    final newAccessToken = _generateToken();
    _tokens[newAccessToken] = accountId;
    _tokens.remove(accessToken);

    final response = jsonEncode({
      'accessToken': newAccessToken,
      'clientToken': clientToken,
      'selectedProfile': {
        'id': account.uuid ?? _generateUuid(account.username),
        'name': account.username,
      },
    });

    _sendResponse(request, 200, response);
  }

  Future<void> _handleValidate(HttpRequest request) async {
    final body = await _readRequestBody(request);
    final json = jsonDecode(body) as Map<String, dynamic>;

    final accessToken = json['accessToken'] as String? ?? '';

    if (_tokens.containsKey(accessToken)) {
      _sendResponse(request, 204, '');
    } else {
      _sendError(request, 401, 'Invalid token');
    }
  }

  Future<void> _handleInvalidate(HttpRequest request) async {
    final body = await _readRequestBody(request);
    final json = jsonDecode(body) as Map<String, dynamic>;

    final accessToken = json['accessToken'] as String? ?? '';

    _tokens.remove(accessToken);
    _sendResponse(request, 204, '');
  }

  Future<void> _handleSignout(HttpRequest request) async {
    final body = await _readRequestBody(request);
    final json = jsonDecode(body) as Map<String, dynamic>;

    final username = json['username'] as String? ?? '';
    final password = json['password'] as String? ?? '';

    if (password.isNotEmpty) {
      _sendError(request, 401, 'Password authentication not supported');
      return;
    }

    final account = _players.values.firstWhere(
      (p) => p.username == username,
      orElse: () => _createOfflineAccount(username),
    );

    _tokens.removeWhere((_, accountId) => accountId == account.id);
    _sendResponse(request, 204, '');
  }

  Future<void> _handleProfiles(HttpRequest request) async {
    final body = await _readRequestBody(request);
    final json = jsonDecode(body) as List<dynamic>;

    final profiles = json.map((name) {
      final account = _players.values.firstWhere(
        (p) => p.username == name,
        orElse: () => _createOfflineAccount(name as String),
      );
      return {
        'id': account.uuid ?? _generateUuid(account.username),
        'name': account.username,
      };
    }).toList();

    _sendResponse(request, 200, jsonEncode(profiles));
  }

  Future<void> _handleJoin(HttpRequest request) async {
    final body = await _readRequestBody(request);
    final json = jsonDecode(body) as Map<String, dynamic>;

    final accessToken = json['accessToken'] as String? ?? '';
    final selectedProfile = json['selectedProfile'] as Map<String, dynamic>?;
    final serverId = json['serverId'] as String? ?? '';

    if (!_tokens.containsKey(accessToken)) {
      _sendError(request, 401, 'Invalid token');
      return;
    }

    _sendResponse(request, 204, '');
  }

  Future<void> _handleHasJoined(HttpRequest request) async {
    final username = request.uri.queryParameters['username'];
    final serverId = request.uri.queryParameters['serverId'];

    if (username == null) {
      _sendError(request, 400, 'Missing username');
      return;
    }

    final account = _players.values.firstWhere(
      (p) => p.username == username,
      orElse: () => _createOfflineAccount(username),
    );

    final response = jsonEncode({
      'id': account.uuid ?? _generateUuid(account.username),
      'name': account.username,
    });

    _sendResponse(request, 200, response);
  }

  Future<void> _handleWellKnown(HttpRequest request) async {
    final response = jsonEncode({
      'authorization': '$_rootUrl/authserver',
      'accounts': '$_rootUrl/api/profiles/minecraft',
      'session': '$_rootUrl/sessionserver/session/minecraft',
    });

    _sendResponse(request, 200, response);
  }

  void _sendResponse(HttpRequest request, int statusCode, String body) {
    request.response
      ..statusCode = statusCode
      ..headers.set('Content-Type', 'application/json')
      ..write(body);
    request.response.close();
  }

  void _sendError(HttpRequest request, int statusCode, String error) {
    final response = jsonEncode({
      'error': 'ForbiddenOperationException',
      'errorMessage': error,
    });
    _sendResponse(request, statusCode, response);
  }

  Account _createOfflineAccount(String username) {
    final now = DateTime.now();
    return Account(
      id: _generateToken(),
      username: username,
      uuid: _generateUuid(username),
      type: AccountType.offline,
      createdAt: now,
      lastUsedAt: now,
    );
  }

  String _generateToken() {
    return 'token_${DateTime.now().millisecondsSinceEpoch}_${_randomString(16)}';
  }

  String _generateUuid(String name) {
    final bytes = utf8.encode('OfflinePlayer:$name');
    final uuidBytes = List<int>.filled(16, 0);

    for (int i = 0; i < bytes.length && i < 16; i++) {
      uuidBytes[i] = bytes[i];
    }

    uuidBytes[6] = (uuidBytes[6] & 0x0F) | 0x30;
    uuidBytes[8] = (uuidBytes[8] & 0x3F) | 0x80;

    return _bytesToUuid(uuidBytes);
  }

  Future<String> _readRequestBody(HttpRequest request) async {
    final bytes = await request.fold<List<int>>(
      [],
      (prev, elem) => prev..addAll(elem),
    );
    return utf8.decode(bytes);
  }

  String _bytesToUuid(List<int> bytes) {
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  String _randomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      List.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }
}
