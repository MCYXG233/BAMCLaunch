import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../../resource_center/models.dart';
import '../../resource_center/download_manager.dart';

/// 实例选择对话框
///
/// 用户下载资源时弹出，让用户选择要安装到哪个实例。
class InstanceSelectDialog extends StatefulWidget {
  final Resource resource;
  final List<ResourceVersion> versions;
  final List<String> instances;

  const InstanceSelectDialog({
    super.key,
    required this.resource,
    required this.versions,
    this.instances = const ['默认实例'],
  });

  @override
  State<InstanceSelectDialog> createState() => _InstanceSelectDialogState();

  static Future<InstanceSelectResult?> show(
    BuildContext context, {
    required Resource resource,
    required List<ResourceVersion> versions,
    List<String> instances = const ['默认实例'],
  }) {
    return showDialog<InstanceSelectResult>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => InstanceSelectDialog(
        resource: resource,
        versions: versions,
        instances: instances,
      ),
    );
  }
}

class InstanceSelectResult {
  final ResourceVersion version;
  final String instance;
  final String gameVersion;
  final bool autoInstall;
  final bool resolveDependencies;

  InstanceSelectResult({
    required this.version,
    required this.instance,
    required this.gameVersion,
    this.autoInstall = true,
    this.resolveDependencies = true,
  });
}

class _InstanceSelectDialogState extends State<InstanceSelectDialog> {
  int? _selectedVersionIndex;
  String? _selectedInstance;
  final String _gameVersion = '1.20.4';
  bool _autoInstall = true;
  bool _resolveDependencies = true;

  @override
  void initState() {
    super.initState();
    if (widget.versions.isNotEmpty) {
      _selectedVersionIndex = 0;
    }
    if (widget.instances.isNotEmpty) {
      _selectedInstance = widget.instances.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Dialog(
      backgroundColor: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF1E2A44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        BAColors.primary,
                        BAColors.accentPink,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.install_mobile,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '安装 ${widget.resource.name}',
                        style: TextStyle(
                          color: isLight ? const Color(0xFF1A2744) : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '选择版本和目标实例',
                        style: TextStyle(
                          color:
                              isLight ? const Color(0xFF8899B5) : const Color(0xFFA0B0C8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isLight ? const Color(0xFF8899B5) : const Color(0xFFA0B0C8),
                  ),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '选择版本',
              style: TextStyle(
                color: isLight ? const Color(0xFF1A2744) : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFF0F5FF) : const Color(0xFF2A3A5A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isLight ? const Color(0xFFD0D8EE) : const Color(0xFF3A4D7A),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedVersionIndex,
                  isExpanded: true,
                  hint: Text(
                    '请选择版本',
                    style: TextStyle(
                      color: isLight ? const Color(0xFF8899B5) : const Color(0xFFA0B0C8),
                      fontSize: 13,
                    ),
                  ),
                  dropdownColor: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF1E2A44),
                  style: TextStyle(
                    color: isLight ? const Color(0xFF1A2744) : Colors.white,
                    fontSize: 13,
                  ),
                  items: widget.versions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final version = entry.value;
                    return DropdownMenuItem<int>(
                      value: index,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'v${version.versionNumber}',
                            style: TextStyle(
                              color: isLight ? const Color(0xFF1A2744) : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${version.gameVersions.take(2).join(', ')} · ${version.releaseType}',
                            style: TextStyle(
                              color: isLight ? const Color(0xFF8899B5) : const Color(0xFFA0B0C8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedVersionIndex = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '目标实例',
              style: TextStyle(
                color: isLight ? const Color(0xFF1A2744) : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFF0F5FF) : const Color(0xFF2A3A5A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isLight ? const Color(0xFFD0D8EE) : const Color(0xFF3A4D7A),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedInstance,
                  isExpanded: true,
                  dropdownColor: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF1E2A44),
                  style: TextStyle(
                    color: isLight ? const Color(0xFF1A2744) : Colors.white,
                    fontSize: 13,
                  ),
                  items: widget.instances.map((instance) {
                    return DropdownMenuItem<String>(
                      value: instance,
                      child: Text(instance),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedInstance = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionSwitch(
              context,
              title: '下载后自动安装到实例',
              subtitle: '将文件复制到对应的 mods 目录',
              value: _autoInstall,
              onChanged: (v) => setState(() => _autoInstall = v),
            ),
            const SizedBox(height: 12),
            _buildOptionSwitch(
              context,
              title: '自动解析并下载依赖',
              subtitle: '自动下载该资源必需的其他资源',
              value: _resolveDependencies,
              onChanged: (v) => setState(() => _resolveDependencies = v),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isLight ? const Color(0xFF1A2744) : Colors.white,
                      side: BorderSide(
                        color: isLight ? const Color(0xFFD0D8EE) : const Color(0xFF3A4D7A),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _selectedVersionIndex != null && _selectedInstance != null
                        ? () {
                            final result = InstanceSelectResult(
                              version: widget.versions[_selectedVersionIndex!],
                              instance: _selectedInstance!,
                              gameVersion: _gameVersion,
                              autoInstall: _autoInstall,
                              resolveDependencies: _resolveDependencies,
                            );
                            Navigator.pop(context, result);
                          }
                        : null,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('开始下载'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BAColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      disabledBackgroundColor:
                          isLight ? const Color(0xFFD0D8EE) : const Color(0xFF3A4D7A),
                      disabledForegroundColor:
                          isLight ? const Color(0xFF8899B5) : const Color(0xFFA0B0C8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionSwitch(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isLight ? const Color(0xFF1A2744) : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isLight ? const Color(0xFF8899B5) : const Color(0xFFA0B0C8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 24,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: BAColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
