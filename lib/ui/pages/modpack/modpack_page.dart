import 'package:flutter/material.dart';
import '../../../core/core.dart' hide Modpack;
import '../../../core/modpack/models/modpack_models.dart';
import '../../../ui/theme/colors.dart';
import '../../components/buttons/bamc_button.dart';
import 'package:file_picker/file_picker.dart';

class ModpackPage extends StatefulWidget {
  const ModpackPage({super.key});

  @override
  State<ModpackPage> createState() => _ModpackPageState();
}

class _ModpackPageState extends State<ModpackPage> {
  List<Modpack> _modpacks = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _importMessage = '准备导入...';
  double _importProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadModpacks();
  }

  Future<void> _loadModpacks() async {
    setState(() => _isLoading = true);
    try {
      final modpacks = await modpackManager.getInstalledModpacks();
      setState(() => _modpacks = modpacks);
    } catch (e) {
      _showError('加载整合包失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _importModpack() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'mrpack'],
        dialogTitle: '选择整合包文件',
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path!;
        _showImportProgress(filePath);
      }
    } catch (e) {
      _showError('文件选择失败: $e');
    }
  }

  void _showImportProgress(String filePath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('导入整合包'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Text(
                  _importMessage,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: _importProgress,
                  backgroundColor: BamcColors.surface,
                  color: BamcColors.primary,
                ),
                const SizedBox(height: 10),
                Text(
                  '进度: ${(_importProgress * 100).toInt()}%',
                  style: const TextStyle(fontSize: 12, color: BamcColors.textSecondary),
                ),
              ],
            );
          },
        ),
      ),
    );

    modpackManager.importModpackWithProgress(
      filePath,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _importMessage = progress.message ?? '导入中...';
            _importProgress = progress.progress;
          });
        }
      },
    ).then((result) {
      if (mounted) {
        Navigator.pop(context);
        if (result.success) {
          _loadModpacks();
          _showSuccess('整合包导入成功');
        } else {
          _showError('整合包导入失败: ${result.errorMessage}');
        }
      }
    }).catchError((e) {
      if (mounted) {
        Navigator.pop(context);
        _showError('整合包导入失败: $e');
      }
    });
  }

  void _deleteModpack(String modpackId) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除整合包'),
        content: const Text('确定要删除这个整合包吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await modpackManager.uninstallModpack(modpackId);
        _loadModpacks();
        _showSuccess('整合包删除成功');
      } catch (e) {
        _showError('删除整合包失败: $e');
      }
    }
  }

  void _createModpack() {
    final nameController = TextEditingController();
    final authorController = TextEditingController();
    final versionController = TextEditingController(text: '1.0');
    final descriptionController = TextEditingController();
    final mcVersionController = TextEditingController(text: '1.20.1');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建整合包'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '整合包名称'),
              ),
              TextField(
                controller: authorController,
                decoration: const InputDecoration(labelText: '作者'),
              ),
              TextField(
                controller: versionController,
                decoration: const InputDecoration(labelText: '版本'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: '描述'),
                maxLines: 2,
              ),
              TextField(
                controller: mcVersionController,
                decoration: const InputDecoration(labelText: 'Minecraft版本'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                _showError('请输入整合包名称');
                return;
              }
              
              try {
                await modpackManager.createModpack(ModpackCreateOptions(
                  name: nameController.text,
                  author: authorController.text,
                  version: versionController.text,
                  description: descriptionController.text,
                  minecraftVersion: mcVersionController.text,
                  format: ModpackFormat.curseforge,
                  includeFiles: [],
                  excludeFiles: [],
                ));
                Navigator.pop(context);
                _showSuccess('整合包创建成功');
                _loadModpacks();
              } catch (e) {
                Navigator.pop(context);
                _showError('创建整合包失败: $e');
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BamcColors.warning,
      ),
    );
  }

  void _repairModpack(String modpackId) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修复整合包'),
        content: const Text('确定要修复这个整合包吗？这将检查并修复损坏的文件。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('修复'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await modpackManager.repairModpack(modpackId);
        _loadModpacks();
        _showSuccess('整合包修复成功');
      } catch (e) {
        _showError('整合包修复失败: $e');
      }
    }
  }

  void _showInstallProgress(Modpack modpack) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('安装整合包: ${modpack.name}'),
        content: StatefulBuilder(
          builder: (context, setState) {
            double installProgress = 0.0;
            String installMessage = '准备安装...';

            modpackManager.installModpack(
              modpack.id,
              modpack.version,
            ).then((result) {
              if (mounted) {
                Navigator.pop(context);
                if (result.success) {
                  _showSuccess('整合包安装成功');
                } else {
                  _showError('整合包安装失败: ${result.error}');
                }
              }
            }).catchError((e) {
              if (mounted) {
                Navigator.pop(context);
                _showError('整合包安装失败: $e');
              }
            });

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Text(
                  installMessage,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: installProgress,
                  backgroundColor: BamcColors.surface,
                  color: BamcColors.primary,
                ),
                const SizedBox(height: 10),
                Text(
                  '进度: ${(installProgress * 100).toInt()}%',
                  style: const TextStyle(fontSize: 12, color: BamcColors.textSecondary),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BamcColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredModpacks = _searchQuery.isEmpty
        ? _modpacks
        : _modpacks
            .where((modpack) =>
                modpack.name
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                modpack.author
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()))
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActionBar(),
          const SizedBox(height: 20),
          _buildModpackGrid(filteredModpacks),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: BamcColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BamcColors.border),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: '搜索整合包...',
                hintStyle: TextStyle(color: BamcColors.textSecondary),
                prefixIcon: Icon(Icons.search, color: BamcColors.textSecondary),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        BamcButton(
          text: '导入整合包',
          onPressed: _importModpack,
          type: BamcButtonType.primary,
          size: BamcButtonSize.medium,
          icon: Icons.upload_file,
        ),
        const SizedBox(width: 16),
        BamcButton(
          text: '创建整合包',
          onPressed: _createModpack,
          type: BamcButtonType.outline,
          size: BamcButtonSize.medium,
          icon: Icons.add,
        ),
      ],
    );
  }

  Widget _buildModpackGrid(List<Modpack> modpacks) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (modpacks.isEmpty) {
      return const Center(
        child: Column(
          children: [
            Icon(Icons.folder_open, size: 64, color: BamcColors.textSecondary),
            SizedBox(height: 16),
            Text(
              '暂无整合包',
              style: TextStyle(
                fontSize: 16,
                color: BamcColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '点击"导入整合包"添加整合包',
              style: TextStyle(
                fontSize: 14,
                color: BamcColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: modpacks.length,
      itemBuilder: (context, index) => _buildModpackCard(modpacks[index]),
    );
  }

  Widget _buildModpackCard(Modpack modpack) {
    return Container(
      decoration: BoxDecoration(
        color: BamcColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BamcColors.border),
      ),
      child: Column(
        children: [
          // 整合包图标
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: BamcColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: BamcColors.border),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.archive,
                        size: 48,
                        color: BamcColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    modpack.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BamcColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '作者: ${modpack.author}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: BamcColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // 底部信息和操作按钮
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: BamcColors.border)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: BamcColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        modpack.minecraftVersion,
                        style: const TextStyle(
                          fontSize: 12,
                          color: BamcColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (modpack.loaderType != null)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: BamcColors.success.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          modpack.loaderType!.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: BamcColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: BamcButton(
                        text: '安装',
                        onPressed: () => _showInstallProgress(modpack),
                        type: BamcButtonType.primary,
                        size: BamcButtonSize.small,
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert,
                          color: BamcColors.textSecondary),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'export',
                          child: Text('导出'),
                        ),
                        const PopupMenuItem(
                          value: 'repair',
                          child: Text('修复'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('删除'),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteModpack(modpack.id);
                        } else if (value == 'export') {
                          _showExportDialog(modpack);
                        } else if (value == 'repair') {
                          _repairModpack(modpack.id);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(Modpack modpack) {
    var selectedFormat = ModpackFormat.curseforge;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出整合包'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('选择导出格式:'),
            const SizedBox(height: 16),
            RadioListTile(
              title: const Text('CurseForge格式'),
              value: ModpackFormat.curseforge,
              groupValue: selectedFormat,
              onChanged: (value) {
                selectedFormat = value!;
              },
            ),
            RadioListTile(
              title: const Text('Modrinth格式'),
              value: ModpackFormat.modrinth,
              groupValue: selectedFormat,
              onChanged: (value) {
                selectedFormat = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                final directory = await FilePicker.platform.getDirectoryPath(
                  dialogTitle: '选择导出目录',
                );
                
                if (directory != null) {
                  final exportPath = '$directory/${modpack.name}_v${modpack.version}.zip';
                  await modpackManager.exportModpack(
                    modpack.id,
                    exportPath,
                  );
                  _showSuccess('整合包导出成功');
                }
              } catch (e) {
                _showError('整合包导出失败: $e');
              }
            },
            child: const Text('导出'),
          ),
        ],
      ),
    );
  }
}
