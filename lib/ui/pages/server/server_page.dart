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
  List<Server> _servers = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadServers();
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
      List<Server> servers = await widget.serverManager.getServers();
      setState(() => _servers = servers);
    } catch (e) {
      _showErrorDialog('加载服务器列表失败: $e');
    } finally {
      setState(() => _isLoading = false);
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

              Server server = Server(
                id: DateTime.now().toString(),
                name: name,
                address: address,
                port: port,
                isLocal: false,
                tags: [],
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
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

  Future<void> _connectToServer(Server server) async {
    try {
      await widget.serverManager.connectToServer(server.id);
    } catch (e) {
      _showErrorDialog('连接服务器失败: $e');
    }
  }

  Future<void> _pingServer(Server server) async {
    try {
      ServerPingResult response = await widget.serverManager.pingServer(server.id);
      if (response.success) {
        _showInfoDialog(
          '服务器信息',
          '''
版本: ${response.version ?? '未知'}
在线人数: ${response.onlinePlayers ?? 0}/${response.maxPlayers ?? 0}
描述: ${response.motd ?? '无'}
延迟: ${response.ping ?? 0}ms
          ''',
        );
      } else {
        _showErrorDialog('服务器离线或无法连接: ${response.error ?? '未知错误'}');
      }
    } catch (e) {
      _showErrorDialog('Ping服务器失败: $e');
    }
  }

  Future<void> _editServer(Server server) async {
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

              Server updatedServer = server.copyWith(
                name: name,
                address: address,
                port: port,
                description: description,
                updatedAt: DateTime.now(),
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

  Future<void> _deleteServer(Server server) async {
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
                await widget.serverManager.removeServer(server.id);
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

  Widget _buildServerItem(Server server) {
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
      leading: const Icon(Icons.computer),
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
        ],
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
        Row(
          children: [
            Expanded(
              child: BamcInput(
                controller: _searchController,
                labelText: '搜索服务器',
                hintText: '输入服务器名称或地址',
                onChanged: (value) {
                  setState(() => _searchQuery = value);
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
                if (_servers.isEmpty)
                  const Center(
                    child: Text('暂无服务器，点击"添加服务器"添加'),
                  ),
                ..._servers.map(_buildServerItem),
              ],
            ),
          ),
      ],
    );
  }
}
