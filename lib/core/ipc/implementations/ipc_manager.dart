import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../interfaces/i_ipc_manager.dart';
import '../models/ipc_models.dart';
import '../../logger/i_logger.dart';
import '../../config/i_config_manager.dart';

class IpcManager implements IIpcManager {
  final ILogger _logger;
  final IConfigManager _configManager;

  Socket? _socket;
  final Map<String, Completer<IpcResponse>> _pendingRequests = {};
  final Map<String, IpcRequestHandler> _handlers = {};
  final StreamController<IpcEvent> _eventController =
      StreamController.broadcast();

  bool _isConnected = false;
  String? _currentEndpoint;

  IpcManager(this._logger, this._configManager);

  @override
  Future<void> initialize() async {
    _logger.info('IPC管理器初始化');

    try {
      final config = await _configManager.loadConfig('terracotta');
      if (config != null && config['enabled'] == true) {
        String endpoint = config['apiEndpoint'] ?? 'localhost:8080';
        await connect(endpoint);
      }
    } catch (e) {
      _logger.error('IPC初始化失败: $e');
    }
  }

  @override
  Future<void> connect(String endpoint) async {
    try {
      if (_isConnected) {
        await disconnect();
      }

      _currentEndpoint = endpoint;
      List<String> parts = endpoint.split(':');
      String host = parts[0];
      int port = parts.length > 1 ? int.parse(parts[1]) : 8080;

      _socket =
          await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      _isConnected = true;

      _socket!.listen(
        _handleData,
        onError: (error) {
          _logger.error('IPC连接错误: $error');
          _isConnected = false;
        },
        onDone: () {
          _logger.info('IPC连接已关闭');
          _isConnected = false;
        },
      );

      _logger.info('成功连接到IPC端点: $endpoint');
    } catch (e) {
      _logger.error('IPC连接失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    if (_socket != null) {
      await _socket!.close();
      _socket = null;
      _isConnected = false;
      _currentEndpoint = null;
      _logger.info('IPC连接已断开');
    }
  }

  @override
  Future<IpcResponse> sendRequest(IpcRequest request) async {
    if (!_isConnected || _socket == null) {
      throw Exception('IPC未连接');
    }

    Completer<IpcResponse> completer = Completer();
    _pendingRequests[request.id] = completer;

    try {
      String json = jsonEncode(request.toJson());
      _socket!.write('$json\n');
      _logger.debug('发送IPC请求: ${request.action}');
      return await completer.future;
    } catch (e) {
      _pendingRequests.remove(request.id);
      _logger.error('发送IPC请求失败: $e');
      rethrow;
    }
  }

  @override
  Stream<IpcEvent> get onEventReceived => _eventController.stream;

  @override
  Future<bool> isConnected() async {
    return _isConnected;
  }

  @override
  Future<void> registerHandler(String action, IpcRequestHandler handler) async {
    _handlers[action] = handler;
    _logger.info('注册IPC处理器: $action');
  }

  @override
  Future<void> unregisterHandler(String action) async {
    _handlers.remove(action);
    _logger.info('注销IPC处理器: $action');
  }

  @override
  Future<List<String>> getAvailableActions() async {
    return _handlers.keys.toList();
  }

  void _handleData(List<int> data) {
    try {
      String message = utf8.decode(data).trim();
      Map<String, dynamic> json = jsonDecode(message);

      if (json.containsKey('requestId')) {
        _handleResponse(json);
      } else if (json.containsKey('name')) {
        _handleEvent(json);
      } else if (json.containsKey('action')) {
        _handleRequest(json);
      }
    } catch (e) {
      _logger.error('处理IPC数据失败: $e');
    }
  }

  void _handleResponse(Map<String, dynamic> json) {
    IpcResponse response = IpcResponse.fromJson(json);
    Completer<IpcResponse>? completer =
        _pendingRequests.remove(response.requestId);

    if (completer != null) {
      completer.complete(response);
    } else {
      _logger.warn('收到未预期的IPC响应: ${response.requestId}');
    }
  }

  void _handleEvent(Map<String, dynamic> json) {
    IpcEvent event = IpcEvent.fromJson(json);
    _eventController.add(event);
    _logger.debug('收到IPC事件: ${event.name}');
  }

  void _handleRequest(Map<String, dynamic> json) async {
    try {
      IpcRequest request = IpcRequest.fromJson(json);
      IpcRequestHandler? handler = _handlers[request.action];

      if (handler != null) {
        IpcResponse response = await handler(request);
        _socket?.write('${jsonEncode(response.toJson())}\n');
      } else {
        IpcResponse errorResponse = IpcResponse(
          requestId: request.id,
          status: IpcStatus.error,
          errorMessage: 'Unknown action: ${request.action}',
        );
        _socket?.write('${jsonEncode(errorResponse.toJson())}\n');
      }
    } catch (e) {
      _logger.error('处理IPC请求失败: $e');
    }
  }
}
