import 'package:flutter/material.dart';
import '../../../core/core.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  final UpdateManager updateManager;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.updateManager,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  bool _isInstalling = false;
  bool _isCancelling = false;
  double _downloadProgress = 0.0;
  String _statusMessage = '准备下载更新...';
  String _updateType = '';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.update,
              size: 48,
              color: Color(0xFF64B5F6),
            ),
            const SizedBox(height: 16),
            Text(
              '发现新版本 ${widget.updateInfo.version}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_updateType.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF64B5F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _updateType,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64B5F6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Text(
                  widget.updateInfo.changelog,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isDownloading) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor: Colors.grey[200],
                      color: const Color(0xFF64B5F6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _statusMessage,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64B5F6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (_isInstalling) ...[
              const Column(
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF64B5F6),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '正在安装更新，请稍候...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '安装过程中请勿关闭应用',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
            if (_isCancelling) ...[
              const Column(
                children: [
                  CircularProgressIndicator(
                    color: Colors.orange,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '正在取消更新...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isDownloading || _isInstalling || _isCancelling
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: const BorderSide(color: Color(0xFF64B5F6)),
                    ),
                    child: const Text(
                      '稍后提醒',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF64B5F6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (_isDownloading) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCancelling ? null : _cancelUpdate,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '取消',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isInstalling || _isCancelling
                          ? null
                          : _downloadAndInstallUpdate,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFF64B5F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _isDownloading ? '下载中...' : '立即更新',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAndInstallUpdate() async {
    setState(() {
      _isDownloading = true;
      _statusMessage = '开始下载更新...';
      _updateType = '检测更新类型...';
    });

    try {
      await widget.updateManager.downloadUpdate(
        widget.updateInfo,
        onProgress: (progress) {
          setState(() {
            _downloadProgress = progress;
            _statusMessage = '下载中...';
          });
        },
        onError: (error) {
          setState(() {
            _isDownloading = false;
            _statusMessage = '下载失败';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('更新下载失败: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );

      setState(() {
        _isDownloading = false;
        _isInstalling = true;
      });

      bool success =
          await widget.updateManager.installUpdate(widget.updateInfo);

      if (success) {
        setState(() {
          _isInstalling = false;
        });
        Navigator.of(context).pop();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('更新成功'),
            content: const Text('更新安装成功，请重启应用以应用更新'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('确定'),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          _isInstalling = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('更新失败'),
            content: const Text('更新安装失败，已自动回滚到之前版本'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _isInstalling = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('更新失败'),
          content: Text('更新过程中发生错误: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _cancelUpdate() async {
    setState(() {
      _isCancelling = true;
    });

    try {
      await widget.updateManager.cancelUpdate();
      setState(() {
        _isCancelling = false;
        _isDownloading = false;
        _downloadProgress = 0.0;
        _statusMessage = '更新已取消';
      });
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isCancelling = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('取消失败'),
          content: Text('取消更新时发生错误: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }
}

class UpdateFailedDialog extends StatelessWidget {
  final String errorMessage;

  const UpdateFailedDialog({
    super.key,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Color(0xFFE53935),
            ),
            const SizedBox(height: 16),
            const Text(
              '更新失败',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                backgroundColor: const Color(0xFF64B5F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }
}
