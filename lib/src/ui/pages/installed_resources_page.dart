import 'package:flutter/material.dart';
import '../../resource_center/models.dart';
import '../../resource_center/resource_manager.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../components/index.dart';

/// 已安装资源管理页面
class InstalledResourcesPage extends StatefulWidget {
  const InstalledResourcesPage({super.key});

  @override
  State<InstalledResourcesPage> createState() => _InstalledResourcesPageState();
}

class _InstalledResourcesPageState extends State<InstalledResourcesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ResourceManager _resourceManager = ResourceManager();

  List<InstalledResource> _installedResources = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInstalledResources();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInstalledResources() async {
    setState(() {
      _isLoading = true;
    });

    await _resourceManager.initialize();
    if (mounted) {
      setState(() {
        _installedResources = _resourceManager.installedResources;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleResource(InstalledResource resource) async {
    try {
      await _resourceManager.toggleResource(
        resource.localId,
        !resource.enabled,
      );
      await _loadInstalledResources();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resource.enabled ? '资源已禁用' : '资源已启用',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  Future<void> _deleteResource(InstalledResource resource) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${resource.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: BAColors.danger,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _resourceManager.removeInstalledResource(resource.localId);
        await _loadInstalledResources();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('资源已删除')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = BAColors.backgroundOf(context);
    final textPrimary = BAColors.textPrimaryOf(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: BAColors.surfaceOf(context),
        elevation: 0,
        title: Text(
          '已安装资源',
          style: BATypography.headlineMedium.copyWith(color: textPrimary),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '全部'),
            Tab(text: '模组'),
            Tab(text: '资源包'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildResourceList(context, null),
                _buildResourceList(context, ResourceType.mod),
                _buildResourceList(context, ResourceType.resourcePack),
              ],
            ),
    );
  }

  Widget _buildResourceList(BuildContext context, ResourceType? filterType) {
    final resources = filterType == null
        ? _installedResources
        : _installedResources
            .where((r) => r.type == filterType)
            .toList();

    if (resources.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: BAColors.textSecondaryOf(context),
            ),
            const SizedBox(height: 16),
            Text(
              '没有已安装的资源',
              style: TextStyle(color: BAColors.textSecondaryOf(context)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: resources.length,
      itemBuilder: (context, index) {
        final resource = resources[index];
        return InstalledResourceCard(
          resource: resource,
          onToggle: () => _toggleResource(resource),
          onDelete: () => _deleteResource(resource),
        );
      },
    );
  }
}
