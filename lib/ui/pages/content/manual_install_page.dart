import 'dart:io';
import 'package:flutter/material.dart';
import '../../../ui/theme/colors.dart';
import '../../components/buttons/bamc_button.dart';

class ManualInstallPage extends StatefulWidget {
  const ManualInstallPage({super.key});

  @override
  State<ManualInstallPage> createState() => _ManualInstallPageState();
}

class _ManualInstallPageState extends State<ManualInstallPage> {
  String? _selectedFilePath;
  String? _installPath;
  bool _isParsing = false;
  bool _overrideExisting = false;
  Map<String, dynamic>? _parsedInfo;
  Map<String, dynamic>? _compatibilityInfo;

  void _handleFileSelect() {
    // 这里将实现文件选择功能
    setState(() {
      _selectedFilePath = '示例文件路径';
      _isParsing = true;
    });

    // 模拟解析过程
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isParsing = false;
        _parsedInfo = {
          'type': '游戏版本',
          'name': 'Minecraft 1.20.1',
          'version': '1.20.1',
          'size': '32MB',
          'modLoader': 'Forge',
          'dependencies': ['Java 17', 'Forge 47.1.44'],
        };
        _compatibilityInfo = {
          'compatible': true,
          'message': '该版本与当前系统兼容',
          'warning': null,
        };
        _installPath = '${Directory.current.path}/versions/1.20.1';
      });
    });
  }

  void _handleInstall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('安装确认'),
        content: const Text('确定要安装选中的文件吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performInstall();
            },
            child: const Text('安装'),
          ),
        ],
      ),
    );
  }

  void _performInstall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('安装成功')),
    );
  }

  Widget _buildFileSelectArea() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border.all(
          color: BamcColors.border,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.file_upload,
            size: 64,
            color: BamcColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            '点击选择文件或拖拽文件到此处',
            style: TextStyle(color: BamcColors.textSecondary),
          ),
          const SizedBox(height: 16),
          BamcButton(
            text: '选择文件',
            onPressed: _handleFileSelect,
            type: BamcButtonType.primary,
            size: BamcButtonSize.medium,
            icon: Icons.file_open,
          ),
        ],
      ),
    );
  }

  Widget _buildParsedInfo() {
    if (_parsedInfo == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BamcColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BamcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '文件信息',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('类型: '),
              Text(_parsedInfo!['type']),
            ],
          ),
          Row(
            children: [
              const Text('名称: '),
              Text(_parsedInfo!['name']),
            ],
          ),
          Row(
            children: [
              const Text('版本: '),
              Text(_parsedInfo!['version']),
            ],
          ),
          Row(
            children: [
              const Text('大小: '),
              Text(_parsedInfo!['size']),
            ],
          ),
          if (_parsedInfo!['modLoader'] != null)
            Row(
              children: [
                const Text('模组加载器: '),
                Text(_parsedInfo!['modLoader']),
              ],
            ),
          const SizedBox(height: 16),

          // 兼容性信息
          if (_compatibilityInfo != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _compatibilityInfo!['compatible']
                    ? BamcColors.success.withOpacity(0.1)
                    : BamcColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _compatibilityInfo!['message'],
                    style: TextStyle(
                      color: _compatibilityInfo!['compatible']
                          ? BamcColors.success
                          : BamcColors.danger,
                    ),
                  ),
                  if (_compatibilityInfo!['warning'] != null)
                    Text(
                      _compatibilityInfo!['warning'],
                      style: const TextStyle(
                        color: BamcColors.warning,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // 安装路径设置
          const Text('安装路径:'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: _installPath),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '选择安装路径',
                  ),
                  onChanged: (value) {
                    setState(() => _installPath = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              BamcButton(
                text: '浏览',
                onPressed: () {
                  // 浏览文件夹功能
                },
                type: BamcButtonType.outline,
                size: BamcButtonSize.small,
                icon: Icons.folder_open,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 覆盖选项
          CheckboxListTile(
            title: const Text('覆盖现有文件'),
            value: _overrideExisting,
            onChanged: (value) {
              setState(() => _overrideExisting = value ?? false);
            },
          ),

          const SizedBox(height: 16),

          // 依赖信息
          if (_parsedInfo!['dependencies'] != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BamcColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('依赖项:'),
                  const SizedBox(height: 8),
                  ..._parsedInfo!['dependencies'].map((dep) => Text('- $dep')),
                ],
              ),
            ),

          const SizedBox(height: 20),

          BamcButton(
            text: '安装',
            onPressed: _handleInstall,
            type: BamcButtonType.primary,
            size: BamcButtonSize.medium,
            icon: Icons.install_desktop,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '手动安装包',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            '支持本地文件导入安装，自动识别安装包类型',
            style: TextStyle(color: BamcColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // 文件选择区域
          _buildFileSelectArea(),

          // 解析结果
          if (_isParsing)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            _buildParsedInfo(),
        ],
      ),
    );
  }
}
