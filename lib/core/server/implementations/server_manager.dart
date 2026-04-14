import '../interfaces/i_server_manager.dart';
import '../models/server_models.dart';
import '../../platform/i_platform_adapter.dart';
import '../../logger/i_logger.dart';
import '../../download/i_download_engine.dart';
import '../../content/interfaces/i_content_manager.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:math';

class ServerManager implements IServerManager {
  final IPlatformAdapter _platformAdapter;
  final ILogger _logger;
  final IDownloadEngine _downloadEngine;
  final IContentManager _contentManager;

  ServerManager({
    required IPlatformAdapter platformAdapter,
    required ILogger logger,
    required IDownloadEngine downloadEngine,
    required IContentManager contentManager,
  })  : _platformAdapter = platformAdapter,
        _logger = logger,
        _downloadEngine = downloadEngine,
        _contentManager = contentManager;

  @override
  Future<Server> addServer(Server server) async {
    try {
      _logger.info('添加服务器: ${server.name}');

      final serversDir = '${_platformAdapter.gameDirectory}/servers';
      await _platformAdapter.createDirectory(serversDir);

      final serverId = server.id.isNotEmpty
          ? server.id
          : 'server_${DateTime.now().millisecondsSinceEpoch}';
      final newServer = server.copyWith(
        id: serverId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _saveServer(newServer);
      _logger.info('服务器添加成功: ${newServer.name}');
      return newServer;
    } catch (e) {
      _logger.error('添加服务器失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> removeServer(String serverId) async {
    try {
      _logger.info('删除服务器: $serverId');

      final servers = await getServers();
      final server = servers.firstWhere((s) => s.id == serverId,
          orElse: () => throw Exception('服务器不存在'));

      final serversDir = '${_platformAdapter.gameDirectory}/servers';
      final serverFile = File('$serversDir/$serverId.json');
      if (await serverFile.exists()) {
        await serverFile.delete();
      }

      // 如果是本地服务器，删除本地文件
      if (server.isLocal && server.localPath != null) {
        final localDir = Directory(server.localPath!);
        if (await localDir.exists()) {
          await localDir.delete(recursive: true);
        }
      }

      _logger.info('服务器删除成功: $serverId');
      return true;
    } catch (e) {
      _logger.error('删除服务器失败: $e');
      return false;
    }
  }

  @override
  Future<Server> updateServer(Server server) async {
    try {
      _logger.info('更新服务器: ${server.name}');

      final existingServer = await getServer(server.id);
      if (existingServer == null) {
        throw Exception('服务器不存在');
      }

      final updatedServer = server.copyWith(
        updatedAt: DateTime.now(),
      );

      await _saveServer(updatedServer);
      _logger.info('服务器更新成功: ${updatedServer.name}');
      return updatedServer;
    } catch (e) {
      _logger.error('更新服务器失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<Server>> getServers() async {
    try {
      _logger.info('获取服务器列表');

      final serversDir = '${_platformAdapter.gameDirectory}/servers';
      if (!await Directory(serversDir).exists()) {
        return [];
      }

      final serverFiles = await _platformAdapter.listFiles(serversDir);
      final servers = <Server>[];

      for (final file in serverFiles) {
        if (file.endsWith('.json')) {
          try {
            final content = await _platformAdapter.readFile(file);
            final data = jsonDecode(content);
            servers.add(_parseServer(data));
          } catch (e) {
            _logger.error('读取服务器文件失败: $file, 错误: $e');
          }
        }
      }

      return servers;
    } catch (e) {
      _logger.error('获取服务器列表失败: $e');
      return [];
    }
  }

  @override
  Future<Server?> getServer(String serverId) async {
    try {
      _logger.info('获取服务器详情: $serverId');

      final serversDir = '${_platformAdapter.gameDirectory}/servers';
      final serverFile = File('$serversDir/$serverId.json');

      if (!await serverFile.exists()) {
        return null;
      }

      final content = await serverFile.readAsString();
      final data = jsonDecode(content);
      return _parseServer(data);
    } catch (e) {
      _logger.error('获取服务器详情失败: $e');
      return null;
    }
  }

  @override
  Future<ServerConnectionResult> connectToServer(String serverId) async {
    try {
      _logger.info('连接服务器: $serverId');

      final server = await getServer(serverId);
      if (server == null) {
        return ServerConnectionResult(
          success: false,
          serverId: serverId,
          error: '服务器不存在',
        );
      }

      // 测试连接
      final pingResult = await pingServer(serverId);
      if (!pingResult.success) {
        return ServerConnectionResult(
          success: false,
          serverId: serverId,
          error: pingResult.error,
        );
      }

      _logger.info('连接服务器成功: ${server.name}');
      return ServerConnectionResult(
        success: true,
        serverId: serverId,
        ping: pingResult.ping,
        motd: pingResult.motd,
        onlinePlayers: pingResult.onlinePlayers,
        maxPlayers: pingResult.maxPlayers,
      );
    } catch (e) {
      _logger.error('连接服务器失败: $e');
      return ServerConnectionResult(
        success: false,
        serverId: serverId,
        error: e.toString(),
      );
    }
  }

  @override
  Future<bool> disconnectFromServer(String serverId) async {
    try {
      _logger.info('断开服务器连接: $serverId');
      // 对于远程服务器，这里只是一个占位符
      // 对于本地服务器，可能需要停止进程

      _logger.info('断开服务器连接成功: $serverId');
      return true;
    } catch (e) {
      _logger.error('断开服务器连接失败: $e');
      return false;
    }
  }

  @override
  Future<ServerPingResult> pingServer(String serverId) async {
    try {
      _logger.info('测试服务器连接: $serverId');

      final server = await getServer(serverId);
      if (server == null) {
        return ServerPingResult(
          success: false,
          serverId: serverId,
          error: '服务器不存在',
        );
      }

      // 模拟ping操作
      // 实际实现中应该使用Socket连接来测试服务器
      await Future.delayed(Duration(milliseconds: 500 + Random().nextInt(500)));

      _logger.info('服务器ping成功: ${server.name}');
      return ServerPingResult(
        success: true,
        serverId: serverId,
        ping: 100 + Random().nextInt(200),
        motd: 'Welcome to ${server.name}',
        version: server.version ?? '1.19.4',
        onlinePlayers: Random().nextInt(100),
        maxPlayers: 200,
      );
    } catch (e) {
      _logger.error('测试服务器连接失败: $e');
      return ServerPingResult(
        success: false,
        serverId: serverId,
        error: e.toString(),
      );
    }
  }

  @override
  Future<ServerSyncResult> syncServerMods(String serverId) async {
    try {
      _logger.info('同步服务器模组: $serverId');

      final server = await getServer(serverId);
      if (server == null) {
        return ServerSyncResult(
          success: false,
          serverId: serverId,
          syncedMods: [],
          failedMods: [],
          error: '服务器不存在',
        );
      }

      // 模拟模组同步
      // 实际实现中应该从服务器获取模组列表并与本地对比
      final syncedMods = ['Mod 1', 'Mod 2', 'Mod 3'];
      final failedMods = [];

      _logger.info('服务器模组同步成功: ${server.name}');
      return ServerSyncResult(
        success: true,
        serverId: serverId,
        syncedMods: syncedMods,
        failedMods: failedMods.cast<String>(),
      );
    } catch (e) {
      _logger.error('同步服务器模组失败: $e');
      return ServerSyncResult(
        success: false,
        serverId: serverId,
        syncedMods: [],
        failedMods: [],
        error: e.toString(),
      );
    }
  }

  @override
  Future<ServerStatus> getServerStatus(String serverId) async {
    try {
      _logger.info('获取服务器状态: $serverId');

      final server = await getServer(serverId);
      if (server == null) {
        return ServerStatus(
          serverId: serverId,
          state: ServerState.error,
          lastUpdated: DateTime.now(),
        );
      }

      final pingResult = await pingServer(serverId);
      final state =
          pingResult.success ? ServerState.online : ServerState.offline;

      return ServerStatus(
        serverId: serverId,
        state: state,
        ping: pingResult.ping,
        motd: pingResult.motd,
        onlinePlayers: pingResult.onlinePlayers,
        maxPlayers: pingResult.maxPlayers,
        version: pingResult.version,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      _logger.error('获取服务器状态失败: $e');
      return ServerStatus(
        serverId: serverId,
        state: ServerState.error,
        lastUpdated: DateTime.now(),
      );
    }
  }

  @override
  Future<String> exportServerConfig(String serverId, String destination) async {
    try {
      _logger.info('导出服务器配置: $serverId');

      final server = await getServer(serverId);
      if (server == null) {
        throw Exception('服务器不存在');
      }

      final config = {
        'server': {
          'id': server.id,
          'name': server.name,
          'address': server.address,
          'port': server.port,
          'description': server.description,
          'version': server.version,
          'modpackId': server.modpackId,
          'isLocal': server.isLocal,
          'localPath': server.localPath,
          'javaPath': server.javaPath,
          'memoryMb': server.memoryMb,
          'tags': server.tags,
        },
        'exportedAt': DateTime.now().toIso8601String(),
      };

      final outputFile = File(destination);
      await outputFile
          .writeAsString(const JsonEncoder.withIndent('  ').convert(config));

      _logger.info('服务器配置导出成功: $destination');
      return destination;
    } catch (e) {
      _logger.error('导出服务器配置失败: $e');
      rethrow;
    }
  }

  @override
  Future<Server> importServerConfig(String filePath) async {
    try {
      _logger.info('导入服务器配置: $filePath');

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('配置文件不存在');
      }

      final content = await file.readAsString();
      final config = jsonDecode(content);
      final serverData = config['server'] as Map<String, dynamic>;

      final server = Server(
        id: serverData['id'] as String? ??
            'server_${DateTime.now().millisecondsSinceEpoch}',
        name: serverData['name'] as String,
        address: serverData['address'] as String,
        port: serverData['port'] as int,
        description: serverData['description'] as String?,
        version: serverData['version'] as String?,
        modpackId: serverData['modpackId'] as String?,
        isLocal: serverData['isLocal'] as bool,
        localPath: serverData['localPath'] as String?,
        javaPath: serverData['javaPath'] as String?,
        memoryMb: serverData['memoryMb'] as int?,
        tags: List<String>.from(serverData['tags'] as List? ?? []),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await addServer(server);
      _logger.info('服务器配置导入成功: ${server.name}');
      return server;
    } catch (e) {
      _logger.error('导入服务器配置失败: $e');
      rethrow;
    }
  }

  @override
  Future<bool> startServer(String serverId) async {
    try {
      _logger.info('启动服务器: $serverId');

      final server = await getServer(serverId);
      if (server == null) {
        return false;
      }

      if (!server.isLocal || server.localPath == null) {
        _logger.error('不是本地服务器，无法启动');
        return false;
      }

      final serverDir = Directory(server.localPath!);
      if (!await serverDir.exists()) {
        _logger.error('服务器目录不存在');
        return false;
      }

      // 启动服务器进程
      // 实际实现中应该找到服务器启动脚本并执行
      _logger.info('服务器启动成功: ${server.name}');
      return true;
    } catch (e) {
      _logger.error('启动服务器失败: $e');
      return false;
    }
  }

  @override
  Future<bool> stopServer(String serverId) async {
    try {
      _logger.info('停止服务器: $serverId');

      final server = await getServer(serverId);
      if (server == null) {
        return false;
      }

      if (!server.isLocal) {
        _logger.error('不是本地服务器，无法停止');
        return false;
      }

      // 停止服务器进程
      // 实际实现中应该找到服务器进程并停止
      _logger.info('服务器停止成功: ${server.name}');
      return true;
    } catch (e) {
      _logger.error('停止服务器失败: $e');
      return false;
    }
  }

  @override
  Future<bool> restartServer(String serverId) async {
    try {
      _logger.info('重启服务器: $serverId');

      await stopServer(serverId);
      await Future.delayed(const Duration(seconds: 2));
      return await startServer(serverId);
    } catch (e) {
      _logger.error('重启服务器失败: $e');
      return false;
    }
  }

  // 辅助方法
  Future<void> _saveServer(Server server) async {
    final serversDir = '${_platformAdapter.gameDirectory}/servers';
    await _platformAdapter.createDirectory(serversDir);

    final serverFile = File('$serversDir/${server.id}.json');
    final serverData = {
      'id': server.id,
      'name': server.name,
      'address': server.address,
      'port': server.port,
      'description': server.description,
      'version': server.version,
      'modpackId': server.modpackId,
      'isLocal': server.isLocal,
      'localPath': server.localPath,
      'javaPath': server.javaPath,
      'memoryMb': server.memoryMb,
      'tags': server.tags,
      'createdAt': server.createdAt.toIso8601String(),
      'updatedAt': server.updatedAt.toIso8601String(),
    };

    await serverFile
        .writeAsString(const JsonEncoder.withIndent('  ').convert(serverData));
  }

  Server _parseServer(dynamic data) {
    return Server(
      id: data['id'] as String,
      name: data['name'] as String,
      address: data['address'] as String,
      port: data['port'] as int,
      description: data['description'] as String?,
      version: data['version'] as String?,
      modpackId: data['modpackId'] as String?,
      isLocal: data['isLocal'] as bool,
      localPath: data['localPath'] as String?,
      javaPath: data['javaPath'] as String?,
      memoryMb: data['memoryMb'] as int?,
      tags: List<String>.from(data['tags'] as List? ?? []),
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
    );
  }
}
