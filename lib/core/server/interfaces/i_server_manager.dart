import '../models/server_models.dart';
import '../../ipc/models/ipc_models.dart';

abstract class IServerManager {
  Future<List<ServerInfo>> getServerList();

  Future<void> addServer(ServerInfo server);

  Future<void> updateServer(ServerInfo server);

  Future<void> deleteServer(String name);

  Future<void> toggleFavorite(String name);

  Future<void> toggleAutoConnect(String name);

  Future<void> connectToServer(String name);

  Future<ServerResponse?> pingServer(String address, int port);

  Future<List<LanServerInfo>> discoverLanServers();

  Future<bool> startLanServer(String worldName, int port);

  Future<void> stopLanServer();

  Future<bool> isLanServerRunning();

  Future<PortMappingResult> createPortMapping(int internalPort, int externalPort);

  Future<void> deletePortMapping(int externalPort);

  Future<List<ServerInfo>> searchServers(String query);

  Future<void> importServers(List<ServerInfo> servers);

  Future<List<ServerInfo>> exportServers();

  Stream<ServerInfo> get onServerStatusChanged;

  Stream<List<LanServerInfo>> get onLanServersDiscovered;

  Future<bool> isTerracottaIntegrationEnabled();

  Future<void> enableTerracottaIntegration(bool enabled);

  Future<IpcResponse> sendIpcRequest(IpcRequest request);

  Future<bool> isIpcConnected();

  Future<void> connectIpc(String endpoint);

  Future<void> disconnectIpc();
}