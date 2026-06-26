import 'dart:io';
import 'package:flutter/material.dart';
import '../ui/theme/colors.dart';
import '../ui/theme/typography.dart';
import '../ui/theme/app_theme.dart';
import '../ui/components/ba_buttons.dart';
import '../core/logger.dart';
import '../platform/platform_adapter_factory.dart';
import 'java_download_service.dart';

/// Java 选择对话框
class JavaSelectorDialog extends StatefulWidget {
  final String? currentJavaPath;
  final int? recommendedVersion;

  const JavaSelectorDialog({
    super.key,
    this.currentJavaPath,
    this.recommendedVersion,
  });

  /// 显示 Java 选择对话框
  static Future<String?> show(
    BuildContext context, {
    String? currentJavaPath,
    int? recommendedVersion,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => JavaSelectorDialog(
        currentJavaPath: currentJavaPath,
        recommendedVersion: recommendedVersion,
      ),
    );
  }

  @override
  State<JavaSelectorDialog> createState() => _JavaSelectorDialogState();
}

class _JavaSelectorDialogState extends State<JavaSelectorDialog> {
  final Logger _logger = Logger('JavaSelectorDialog');

  List<JavaInfo> _installedJava = [];
  bool _isLoading = true;
  bool _isDownloading = false;
  String _downloadStatus = '';
  double _downloadProgress = 0;
  String? _selectedJavaPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInstalledJava();
  }

  Future<void> _loadInstalledJava() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final platformAdapter = PlatformAdapterFactory.create();
      final javaPaths = await platformAdapter.findJavaInstallations();

      final javaList = <JavaInfo>[];
      for (final javaPath in javaPaths) {
        final info = await _getJavaInfo(javaPath);
        if (info != null) {
          javaList.add(info);
        }
      }

      setState(() {
        _installedJava = javaList;
        _isLoading = false;
        _selectedJavaPath = widget.currentJavaPath;
      });
    } catch (e, stackTrace) {
      _logger.error('Failed to load Java installations', e, stackTrace);
      setState(() {
        _isLoading = false;
        _error = '加载 Java 安装失败';
      });
    }
  }

  Future<JavaInfo?> _getJavaInfo(String javaPath) async {
    try {
      final result = await Process.run(
        javaPath,
        ['-version'],
        stdoutEncoding: SystemEncoding(),
        stderrEncoding: SystemEncoding(),
      );

      if (result.exitCode != 0) return null;

      final output = (result.stderr as String?) ?? '';
      final versionMatch = RegExp(r'"(\d+\.\d+\.\d+[^"]*)"').firstMatch(output);
      final version = versionMatch?.group(1) ?? 'Unknown';

      final majorVersion = int.tryParse(version.split('.').first) ?? 0;
      final is64Bit = output.contains('64-Bit') ||
                      output.contains('amd64') ||
                      output.contains('x86_64');

      return JavaInfo(
        path: javaPath,
        version: version,
        majorVersion: majorVersion,
        is64Bit: is64Bit,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _downloadJava() async {
    try {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0;
        _downloadStatus = '准备下载...';
      });

      // 使用推荐的 Java 版本，默认 17
      final targetVersion = widget.recommendedVersion ?? 17;

      // 获取 Java 下载服务
      final downloadService = JavaDownloadService.instance;

      // 获取默认安装路径
      final installPath = '${Platform.environment['APPDATA']}\\BAMCLauncher\\java\\jdk-$targetVersion';

      final javaPath = await downloadService.downloadAndInstallJava(
        majorVersion: targetVersion,
        destinationPath: installPath,
        onProgress: (received, total) {
          setState(() {
            _downloadProgress = received / total;
          });
        },
        onStatus: (status) {
          setState(() {
            _downloadStatus = status;
          });
        },
      );

      // 验证下载的 Java
      final info = await _getJavaInfo(javaPath);

      setState(() {
        _isDownloading = false;
        if (info != null) {
          _installedJava.insert(0, info);
          _selectedJavaPath = javaPath;
        }
      });
    } catch (e, stackTrace) {
      _logger.error('Failed to download Java', e, stackTrace);
      setState(() {
        _isDownloading = false;
        _error = '下载失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        height: 500,
        decoration: BoxDecoration(
          color: BAColors.surfaceOf(context),
          borderRadius: BATheme.borderRadius,
          boxShadow: BATheme.shadowsOf(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题栏
            _buildHeader(context),

            // 内容
            Expanded(
              child: _buildContent(context),
            ),

            // 按钮栏
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BAColors.primaryOf(context).withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.coffee, color: BAColors.primaryOf(context), size: 28),
          const SizedBox(width: 16),
          Text(
            '选择 Java',
            style: BATypography.headlineMedium.copyWith(
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close, color: BAColors.textSecondaryOf(context)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '正在扫描已安装的 Java...',
              style: BATypography.bodyMedium.copyWith(
                color: BAColors.textSecondaryOf(context),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null && !_isDownloading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: BAColors.dangerOf(context), size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: BATypography.bodyMedium.copyWith(
                color: BAColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 16),
            BAPrimaryButton(
              text: '重试',
              onPressed: _loadInstalledJava,
            ),
          ],
        ),
      );
    }

    if (_isDownloading) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: _downloadProgress > 0 ? _downloadProgress : null,
            ),
            const SizedBox(height: 16),
            if (_downloadProgress > 0)
              Text(
                '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                style: BATypography.bodyLarge.copyWith(
                  color: BAColors.textPrimaryOf(context),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              _downloadStatus,
              style: BATypography.bodyMedium.copyWith(
                color: BAColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '正在下载 Java ${widget.recommendedVersion ?? 17}...',
              style: BATypography.bodyMedium.copyWith(
                color: BAColors.textPrimaryOf(context),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 已安装的 Java
          Text(
            '已安装的 Java',
            style: BATypography.titleMedium.copyWith(
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _installedJava.isEmpty
                ? _buildEmptyState(context)
                : _buildJavaList(context),
          ),

          const SizedBox(height: 16),

          // 推荐提示
          if (widget.recommendedVersion != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BAColors.primaryOf(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: BAColors.primaryOf(context).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: BAColors.primaryOf(context), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '推荐使用 Java ${widget.recommendedVersion}，与您的 Minecraft 版本最兼容',
                      style: BATypography.bodySmall.copyWith(
                        color: BAColors.textPrimaryOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 下载按钮
            Center(
              child: BASecondaryButton(
                text: '下载 Java ${widget.recommendedVersion}',
                onPressed: _downloadJava,
                leadingIcon: Icon(Icons.download, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off,
            color: BAColors.textSecondaryOf(context),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            '未找到已安装的 Java',
            style: BATypography.bodyLarge.copyWith(
              color: BAColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮下载 Java',
            style: BATypography.bodySmall.copyWith(
              color: BAColors.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJavaList(BuildContext context) {
    return ListView.builder(
      itemCount: _installedJava.length,
      itemBuilder: (context, index) {
        final java = _installedJava[index];
        final isSelected = _selectedJavaPath == java.path;

        return Card(
          color: isSelected
              ? BAColors.primaryOf(context).withOpacity(0.1)
              : BAColors.surfaceOf(context),
          child: ListTile(
            leading: Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? BAColors.primaryOf(context) : BAColors.textSecondaryOf(context),
            ),
            title: Text(
              'Java ${java.majorVersion}',
              style: BATypography.titleMedium.copyWith(
                color: BAColors.textPrimaryOf(context),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  java.version,
                  style: BATypography.bodySmall.copyWith(
                    color: BAColors.textSecondaryOf(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  java.path,
                  style: BATypography.caption.copyWith(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (java.is64Bit)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: BAColors.successOf(context).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '64-bit',
                      style: BATypography.labelSmall.copyWith(
                        color: BAColors.successOf(context),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                if (java.majorVersion == widget.recommendedVersion)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: BAColors.primaryOf(context).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '推荐',
                      style: BATypography.labelSmall.copyWith(
                        color: BAColors.primaryOf(context),
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () {
              setState(() {
                _selectedJavaPath = java.path;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: BAColors.borderOf(context),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          BASecondaryButton(
            text: '取消',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          BAPrimaryButton(
            text: '确认',
            onPressed: _selectedJavaPath != null
                ? () => Navigator.of(context).pop(_selectedJavaPath)
                : null,
          ),
        ],
      ),
    );
  }
}

/// Java 信息
class JavaInfo {
  final String path;
  final String version;
  final int majorVersion;
  final bool is64Bit;

  JavaInfo({
    required this.path,
    required this.version,
    required this.majorVersion,
    required this.is64Bit,
  });
}
