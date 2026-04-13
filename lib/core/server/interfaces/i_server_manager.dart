import '../models/server_models.dart';

abstract class IServerManager {
  // 添加服务器
  Future<Server> addServer(Server server);

  // 删除服务器
  Future<bool> removeServer(String serverId);

  // 更新服务器
  Future<Server> updateServer(Server server);

  // 获取服务器列表
  Future<List<Server>> getServers();

  // 获取服务器详情
  Future<Server?> getServer(String serverId);

  // 连接服务器
  Future<ServerConnectionResult> connectToServer(String serverId);

  // 断开服务器连接
  Future<bool> disconnectFromServer(String serverId);

  // 测试服务器连接
  Future<ServerPingResult> pingServer(String serverId);

  // 自动同步服务器模组
  Future<ServerSyncResult> syncServerMods(String serverId);

  // 获取服务器状态
  Future<ServerStatus> getServerStatus(String serverId);

  // 导出服务器配置
  Future<String> exportServerConfig(String serverId, String destination);

  // 导入服务器配置
  Future<Server> importServerConfig(String filePath);

  // 启动服务器（本地服务器）
  Future<bool> startServer(String serverId);

  // 停止服务器（本地服务器）
  Future<bool> stopServer(String serverId);

  // 重启服务器（本地服务器）
  Future<bool> restartServer(String serverId);
}
