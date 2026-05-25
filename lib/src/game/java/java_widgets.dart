import 'package:flutter/material.dart';
import 'models.dart';
import 'java_manager.dart';

/// Java版本卡片组件
/// 用于显示Java安装信息
class JavaCard extends StatelessWidget {
  /// Java安装信息
  final JavaInstallation installation;

  /// 是否为选中状态
  final bool isSelected;

  /// 点击回调
  final VoidCallback? onTap;

  const JavaCard({
    super.key,
    required this.installation,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final compatibility = JavaVersion.getCompatibilityDescription(
      installation.majorVersion,
    );
    final isCompatible = JavaVersion.isCompatible(installation.majorVersion);

    return Card(
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.code,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Java ${installation.majorVersion}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          installation.version,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChip(
                    context,
                    installation.is64Bit ? '64位' : '32位',
                    Colors.blue,
                  ),
                  _buildChip(
                    context,
                    compatibility,
                    isCompatible ? Colors.green : Colors.orange,
                  ),
                  if (installation.vendor != null)
                    _buildChip(context, installation.vendor!, Colors.purple),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                installation.path,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Java选择对话框组件
/// 用于选择Java版本
class JavaSelectionDialog extends StatefulWidget {
  const JavaSelectionDialog({super.key});

  @override
  State<JavaSelectionDialog> createState() => _JavaSelectionDialogState();
}

class _JavaSelectionDialogState extends State<JavaSelectionDialog> {
  final JavaManager _javaManager = JavaManager();
  List<JavaInstallation> _installations = [];
  String? _selectedPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJavaInstallations();
  }

  Future<void> _loadJavaInstallations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final installations = await _javaManager.findJavaInstallations();
      final selected = await _javaManager.getSelectedJava();

      setState(() {
        _installations = installations;
        _selectedPath = selected?.path;
      });
    } catch (e) {
      // 忽略错误
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectJava(String path) async {
    try {
      await _javaManager.selectJava(path);
      if (mounted) {
        setState(() {
          _selectedPath = path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('选择Java失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择Java版本'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _installations.isEmpty
            ? const Center(child: Text('未找到Java安装'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _installations.length,
                itemBuilder: (context, index) {
                  final installation = _installations[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: JavaCard(
                      installation: installation,
                      isSelected: _selectedPath == installation.path,
                      onTap: () => _selectJava(installation.path),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        TextButton(onPressed: _loadJavaInstallations, child: const Text('刷新')),
      ],
    );
  }
}

/// 显示Java选择对话框
Future<void> showJavaSelectionDialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (context) => const JavaSelectionDialog(),
  );
}
