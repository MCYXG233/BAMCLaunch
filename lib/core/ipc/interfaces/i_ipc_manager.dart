import '../models/ipc_models.dart';

abstract class IIpcManager {
  Future<void> initialize();
  
  Future<void> connect(String endpoint);
  
  Future<void> disconnect();
  
  Future<IpcResponse> sendRequest(IpcRequest request);
  
  Stream<IpcEvent> get onEventReceived;
  
  Future<bool> isConnected();
  
  Future<void> registerHandler(String action, IpcRequestHandler handler);
  
  Future<void> unregisterHandler(String action);
  
  Future<List<String>> getAvailableActions();
}