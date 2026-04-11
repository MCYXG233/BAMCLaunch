import 'package:flutter/material.dart';
import '../../../core/server/server.dart';
import '../../components/layout/breadcrumb_navigation.dart';
import '../../components/buttons/bamc_button.dart';
import '../../components/lists/bamc_list.dart';
import '../../components/inputs/bamc_input.dart';
import '../../components/dialogs/copyright_dialog.dart';

class ServerPage extends StatefulWidget {
  final IServerManager serverManager;

  const ServerPage({super.key, required this.serverManager});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  List<ServerInfo> _servers = [];
  List<LanServerInfo> _lanServers = [];
  bool _isLoading = false;
  bool _isDiscovering = false;
  bool _isTerracottaEnabled = false;
  bool _isIpcConnected = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadServers();
    _loadTerracottaStatus();
    _setupListeners();
  }

  void _setupListeners() {
    widget.serverManager.onServerStatusChanged.listen((server) {
      _loadServers();
    });

    widget.serverManager.onLanServersDiscovered.listen((servers) {
      setState(() {
        _lanServers = servers;
        _isDiscovering = false;
      });
    });
  }

  Future<void> _loadTerracottaStatus() async {
    try {
      bool enabled =
          await widget.serverManager.isTerracottaIntegrationEnabled();
      bool connected = await widget.serverManager.isIpcConnected();
      setState(() {
        _isTerracottaEnabled = enabled;
        _isIpcConnected = connected;
      });
    } catch (e) {
      _showErrorDialog('加载Terracotta状态失败: $e');
    }
  }

  Future<void> _toggleTerracottaIntegration() async {
    try {
      await widget.serverManager
          .enableTerracottaIntegration(!_isTerracottaEnabled);
      await _loadTerracottaStatus();
      _showInfoDialog(
        'Terracotta集成',
        _isTerracottaEnabled ? 'Terracotta集成已启用' : 'Terracotta集成已禁用',
      );
    } catch (e) {
      _showErrorDialog('切换Terracotta集成状态失败: $e');
    }
  }

  Future<void> _showCopyrightInfo() async {
    await showDialog(
      context: context,
      builder: (context) => const CopyrightDialog(),
    );
  }

  Future<void> _loadServers() async {
    setState(() => _isLoading = true);
    try {
      List<ServerInfo> servers = await widget.serverManager.getServerList();
      if (_searchQuery.isNotEmpty) {
        servers = await widget.serverManager.searchServers(_searchQuery);
      }
      setState(() => _servers = servers);
    } catch (e) {
      _showErrorDialog('加载服务器列表失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _discoverLanServers() async {
    setState(() => _isDiscovering = true);
    try {
      List<LanServerInfo> servers =
          await widget.serverManager.discoverLanServers();
      setState(() => _lanServers = servers);
    } catch (e) {
      _showErrorDialog('发现局域网服务器失败: $e');
    } finally {
      setState(() => _isDiscovering = false);
    }
  }

  Future<void> _addServer() async {
    TextEditingController nameController = TextEditingController();
    TextEditingController addressController = TextEditingController();
    TextEditingController portController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加服务器'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BamcInput(
              controller: nameController,
              labelText: '服务器名称',
              hintText: '输入服务器名称',
            ),
            const SizedBox(height: 16),
            BamcInput(
              controller: addressController,
              labelText: '服务器地址',
              hintText: '输入服务器IP或域名',
            ),
            const SizedBox(height: 16),
            BamcInput(
              controller: portController,
              labelText: '端口',
              hintText: '默认25565',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          BamcButton(
            onPressed: () async {
              String name = nameController.text.trim();
              String address = addressController.text.trim();
              int port = int.tryParse(portController.text.trim()) ?? 25565;

              if (name.isEmpty || address.isEmpty) {
                _showErrorDialog('请输入服务器名称和地址');
                return;
              }

              ServerInfo server = ServerInfo(
                name: name,
                address: address,
                port: port,
                type: ServerType.vanilla,
              );

              try {
                await widget.serverManager.addServer(server);
                _loadServers();
                Navigator.pop(context);
              } catch (e) {
                _showErrorDialog('添加服务器失败: $e');
              }
            },
            text: '添加',
          ),
        ],
      ),
    );
  }

  Future<void> _connectToServer(ServerInfo server) async {
    try {
      await widget.serverManager.connectToServer(server.name);
    } catch (e) {
      _showErrorDialog('连接服务器失败: $e');
    }
  }

  Future<void> _pingServer(ServerInfo server) async {
    try {
      ServerResponse? response =
          await widget.serverManager.pingServer(server.address, server.port);
      if (response != null) {
        _showInfoDialog(
          '服务器信息',
          '''
版本: ${response.versionName}
在线人数: ${response.onlinePlayers}/${response.maxPlayers}
描述: ${response.description}
安全聊天: ${response.secureChat ? '开启' : '关闭'}
          ''',
        );
      } else {
        _showErrorDialog('服务器离线或无法连接');
      }
    } catch (e) {
      _showErrorDialog('Ping服务器失败: $e');
    }
  }

  Future<void> _toggleFavorite(ServerInfo server) async {
    try {
      await widget.serverManager.toggleFavorite(server.name);
      _loadServers();
    } catch (e) {
      _showErrorDialog('操作失败: $e');
    }
  }

  Future<void> _editServer(ServerInfo server) async {
    TextEditingController nameController =
        TextEditingController(text: server.name);
    TextEditingController addressController =
        TextEditingController(text: server.address);
    TextEditingController portController =
        TextEditingController(text: server.port.toString());
    TextEditingController descriptionController =
        TextEditingController(text: server.description ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑服务器'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BamcInput(
              controller: nameController,
              labelText: '服务器名称',
              hintText: '输入服务器名称',
            ),
            const SizedBox(height: 16),
            BamcInput(
              controller: addressController,
              labelText: '服务器地址',
              hintText: '输入服务器IP或域名',
            ),
            const SizedBox(height: 16),
            BamcInput(
              controller: portController,
              labelText: '端口',
              hintText: '默认25565',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            BamcInput(
              controller: descriptionController,
              labelText: '描述',
              hintText: '输入服务器描述（可选）',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          BamcButton(
            onPressed: () async {
              String name = nameController.text.trim();
              String address = addressController.text.trim();
              int port = int.tryParse(portController.text.trim()) ?? 25565;
              String? description = descriptionController.text.trim().isEmpty
                  ? null
                  : descriptionController.text.trim();

              if (name.isEmpty || address.isEmpty) {
                _showErrorDialog('请输入服务器名称和地址');
                return;
              }

              ServerInfo updatedServer = server.copyWith(
                name: name,
                address: address,
                port: port,
                description: description,
              );

              try {
                await widget.serverManager.updateServer(updatedServer);
                _loadServers();
                Navigator.pop(context);
              } catch (e) {
                _showErrorDialog('编辑服务器失败: $e');
              }
            },
            text: '保存',
          ),
        ],
      ),
    );
  }

  Future<void> _deleteServer(ServerInfo server) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除服务器'),
        content: Text('确定要删除服务器 "${server.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          BamcButton(
            onPressed: () async {
              try {
                await widget.serverManager.deleteServer(server.name);
                _loadServers();
                Navigator.pop(context);
              } catch (e) {
                _showErrorDialog('删除服务器失败: $e');
              }
            },
            text: '删除',
            type: BamcButtonType.warning,
            size: BamcButtonSize.medium,
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildServerItem(ServerInfo server) {
    return BamcListItem(
      title: Text(server.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${server.address}:${server.port}'),
          if (server.description != null)
            Text(
              server.description!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      leading: Icon(
        server.favorite ? Icons.star : Icons.star_border,
        color: server.favorite ? Colors.yellow : null,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _pingServer(server),
            tooltip: 'Ping服务器',
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => _connectToServer(server),
            tooltip: '连接服务器',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editServer(server),
            tooltip: '编辑服务器',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteServer(server),
            tooltip: '删除服务器',
            color: Colors.red,
          ),
          IconButton(
            icon: Icon(server.favorite ? Icons.star : Icons.star_border),
            onPressed: () => _toggleFavorite(server),
            color: server.favorite ? Colors.yellow : null,
            tooltip: server.favorite ? '取消收藏' : '收藏',
          ),
        ],
      ),
    );
  }

  Widget _buildLanServerItem(LanServerInfo server) {
    return BamcListItem(
      title: Text(server.name),
      subtitle: Text('${server.address}:${server.port}'),
      leading: const Icon(Icons.lan),
      trailing: IconButton(
        icon: const Icon(Icons.play_arrow),
        onPressed: () {
          ServerInfo lanServer = ServerInfo(
            name: server.name,
            address: server.address,
            port: server.port,
            type: ServerType.vanilla,
          );
          _connectToServer(lanServer);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BreadcrumbNavigation(
          items: [
            BreadcrumbItem(title: '主页', isActive: false),
            BreadcrumbItem(title: '服务器', isActive: true),
          ],
        ),
        const SizedBox(height: 24),
        if (_isTerracottaEnabled)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isIpcConnected ? Colors.green[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isIpcConnected ? Colors.green : Colors.orange,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isIpcConnected ? Icons.check_circle : Icons.warning,
                  color: _isIpcConnected ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isIpcConnected
                        ? 'Terracotta集成已启用并连接'
                        : 'Terracotta集成已启用但未连接',
                    style: TextStyle(
                      color: _isIpcConnected ? Colors.green : Colors.orange,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _showCopyrightInfo,
                  child: const Text('查看版权信息'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: BamcInput(
                controller: _searchController,
                labelText: '搜索服务器',
                hintText: '输入服务器名称或地址',
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _loadServers();
                },
              ),
            ),
            const SizedBox(width: 16),
            BamcButton(
              onPressed: _addServer,
              text: '添加服务器',
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '服务器列表',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                BamcButton(
                  onPressed: _discoverLanServers,
                  text: _isDiscovering ? '搜索中...' : '搜索局域网',
                  disabled: _isDiscovering,
                ),
                const SizedBox(width: 16),
                BamcButton(
                  onPressed: _toggleTerracottaIntegration,
                  text: _isTerracottaEnabled ? '禁用Terracotta' : '启用Terracotta',
                  type: _isTerracottaEnabled ? BamcButtonType.warning : BamcButtonType.success,
                  size: BamcButtonSize.medium,
                ),
                const SizedBox(width: 16),
                BamcButton(
                  onPressed: _showCopyrightInfo,
                  text: '版权信息',
                  type: BamcButtonType.outline,
                  size: BamcButtonSize.medium,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Expanded(
            child: ListView(
              children: [
                if (_servers.isEmpty && _searchQuery.isEmpty)
                  const Center(
                    child: Text('暂无服务器，点击"添加服务器"添加'),
                  ),
                if (_servers.isEmpty && _searchQuery.isNotEmpty)
                  const Center(
                    child: Text('没有找到匹配的服务器'),
                  ),
                ..._servers.map(_buildServerItem),
                if (_lanServers.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      const Text(
                        '局域网服务器',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ..._lanServers.map(_buildLanServerItem),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
