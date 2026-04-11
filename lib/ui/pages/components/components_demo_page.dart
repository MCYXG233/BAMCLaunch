import 'package:flutter/material.dart';
import '../../../ui/components/buttons/bamc_button.dart';
import '../../../ui/components/inputs/bamc_input.dart';
import '../../../ui/components/lists/bamc_list.dart';
import '../../../ui/components/progress/bamc_progress_bar.dart';
import '../../../ui/components/menus/bamc_context_menu.dart';
import '../../../ui/theme/colors.dart';

class ComponentsDemoPage extends StatefulWidget {
  const ComponentsDemoPage({super.key});

  @override
  State<ComponentsDemoPage> createState() => _ComponentsDemoPageState();
}

class _ComponentsDemoPageState extends State<ComponentsDemoPage> {
  String? _selectedItem;
  final double _progressValue = 65.0;

  final List<String> _listItems = [
    'Minecraft 1.20.1',
    'Minecraft 1.19.4',
    'Minecraft 1.18.2',
    'Forge 1.20.1-47.0.1',
    'Fabric 1.20.1-0.14.22',
    'Quilt 1.20.1-0.18.1',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('组件库演示'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 按钮组件演示
            _buildSection('按钮组件'),
            Row(
              children: [
                BamcButton(
                  text: '主要按钮',
                  type: BamcButtonType.primary,
                  onPressed: () => _showMessage('主要按钮被点击'),
                ),
                const SizedBox(width: 8),
                BamcButton(
                  text: '次要按钮',
                  type: BamcButtonType.secondary,
                  onPressed: () => _showMessage('次要按钮被点击'),
                ),
                const SizedBox(width: 8),
                BamcButton(
                  text: '警告按钮',
                  type: BamcButtonType.warning,
                  onPressed: () => _showMessage('警告按钮被点击'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                BamcButton(
                  text: '成功按钮',
                  type: BamcButtonType.success,
                  onPressed: () => _showMessage('成功按钮被点击'),
                ),
                const SizedBox(width: 8),
                BamcButton(
                  text: '轮廓按钮',
                  type: BamcButtonType.outline,
                  onPressed: () => _showMessage('轮廓按钮被点击'),
                ),
                const SizedBox(width: 8),
                BamcButton(
                  text: '文字按钮',
                  type: BamcButtonType.text,
                  onPressed: () => _showMessage('文字按钮被点击'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                BamcButton(
                  text: '带图标',
                  icon: Icons.play_arrow,
                  onPressed: () => _showMessage('带图标按钮被点击'),
                ),
                const SizedBox(width: 8),
                BamcButton(
                  text: '加载中',
                  isLoading: true,
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                BamcButton(
                  text: '禁用',
                  disabled: true,
                  onPressed: () {},
                ),
              ],
            ),

            // 输入框组件演示
            const SizedBox(height: 32),
            _buildSection('输入框组件'),
            BamcInput(
              labelText: '用户名',
              hintText: '请输入用户名',
              prefixIcon: Icons.person,
              onChanged: (value) => print('用户名: $value'),
            ),
            const SizedBox(height: 16),
            BamcInput(
              labelText: '密码',
              hintText: '请输入密码',
              prefixIcon: Icons.lock,
              suffixIcon: Icons.visibility,
              obscureText: true,
              onSuffixIconPressed: () => _showMessage('密码可见性切换'),
            ),
            const SizedBox(height: 16),
            const BamcInput(
              labelText: '邮箱',
              hintText: '请输入邮箱地址',
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              errorText: '请输入有效的邮箱地址',
            ),

            // 进度条组件演示
            const SizedBox(height: 32),
            _buildSection('进度条组件'),
            BamcProgressBar(
              value: _progressValue,
              label: '下载进度',
              showPercentage: true,
            ),
            const SizedBox(height: 16),
            const BamcProgressBar(
              value: 45,
              type: BamcProgressBarType.secondary,
              label: '安装进度',
              showPercentage: true,
            ),
            const SizedBox(height: 16),
            const BamcProgressBar(
              value: 80,
              type: BamcProgressBarType.warning,
              label: '警告进度',
              showPercentage: true,
            ),
            const SizedBox(height: 16),
            const BamcProgressBar(
              value: 95,
              type: BamcProgressBarType.success,
              label: '成功进度',
              showPercentage: true,
            ),
            const SizedBox(height: 16),
            const BamcProgressBar(
              value: 70,
              type: BamcProgressBarType.pixel,
              label: '像素风格进度条',
              showPercentage: true,
            ),

            // 列表组件演示
            const SizedBox(height: 32),
            _buildSection('列表组件'),
            SizedBox(
              height: 300,
              child: BamcList<String>(
                items: _listItems,
                selectedItem: _selectedItem,
                onSelectionChanged: (item) {
                  setState(() {
                    _selectedItem = item;
                  });
                  _showMessage('选中: $item');
                },
                contextMenuItems: (item, index) => [
                  ContextMenuItem(
                    text: '启动',
                    icon: Icons.play_arrow,
                    onTap: () => _showMessage('启动: $item'),
                  ),
                  ContextMenuItem(
                    text: '编辑',
                    icon: Icons.edit,
                    onTap: () => _showMessage('编辑: $item'),
                  ),
                  ContextMenuDivider(),
                  ContextMenuItem(
                    text: '删除',
                    icon: Icons.delete,
                    onTap: () => _showMessage('删除: $item'),
                  ),
                ],
                itemBuilder: (context, item, index, isSelected) {
                  return BamcListItem(
                    leading: const Icon(Icons.gamepad),
                    title: Text(item),
                    subtitle: Text('版本 $index'),
                    trailing: const Icon(Icons.chevron_right),
                    selected: isSelected,
                  );
                },
              ),
            ),

            // 右键菜单演示
            const SizedBox(height: 32),
            _buildSection('右键菜单演示'),
            BamcContextMenu(
              items: [
                ContextMenuItem(
                  text: '复制',
                  icon: Icons.copy,
                  shortcut: 'Ctrl+C',
                  onTap: () => _showMessage('复制'),
                ),
                ContextMenuItem(
                  text: '粘贴',
                  icon: Icons.paste,
                  shortcut: 'Ctrl+V',
                  onTap: () => _showMessage('粘贴'),
                ),
                ContextMenuDivider(),
                ContextMenuItem(
                  text: '设置',
                  icon: Icons.settings,
                  onTap: () => _showMessage('设置'),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(color: BamcColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('右键点击此处查看菜单'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: BamcColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
