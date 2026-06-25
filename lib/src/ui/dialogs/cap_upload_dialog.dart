import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../../core/logger.dart';
import '../../features/skin/cape_manager.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import '../components/ba_buttons.dart';
import '../components/ba_dialog.dart';

/// 披风上传对话框
/// 用于选择和上传披风图像
class CapeUploadDialog extends StatefulWidget {
  /// 账户ID
  final String accountId;

  /// 账户用户名
  final String accountName;

  /// 现有披风（如果有）
  final Uint8List? existingCapeImage;

  /// 上传成功回调
  final void Function(Uint8List capeImage)? onUploadSuccess;

  /// 删除成功回调
  final VoidCallback? onDeleteSuccess;

  const CapeUploadDialog({
    super.key,
    required this.accountId,
    required this.accountName,
    this.existingCapeImage,
    this.onUploadSuccess,
    this.onDeleteSuccess,
  });

  /// 显示披风上传对话框
  static Future<void> show({
    required BuildContext context,
    required String accountId,
    required String accountName,
    Uint8List? existingCapeImage,
    void Function(Uint8List capeImage)? onUploadSuccess,
    VoidCallback? onDeleteSuccess,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => CapeUploadDialog(
        accountId: accountId,
        accountName: accountName,
        existingCapeImage: existingCapeImage,
        onUploadSuccess: onUploadSuccess,
        onDeleteSuccess: onDeleteSuccess,
      ),
    );
  }

  @override
  State<CapeUploadDialog> createState() => _CapeUploadDialogState();
}

class _CapeUploadDialogState extends State<CapeUploadDialog> {
  final CapeManager _capeManager = CapeManager();
  final Logger _logger = Logger('CapeUploadDialog');

  bool _isLoading = false;
  bool _isDragging = false;
  String? _errorMessage;
  String? _successMessage;
  Uint8List? _previewImage;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _previewImage = widget.existingCapeImage;
  }

  Future<void> _handleFileDrop(String filePath) async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _selectedFileName = path.basename(filePath);
    });

    await _processFile(filePath);
  }

  Future<void> _processFile(String filePath) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        setState(() {
          _errorMessage = '文件不存在';
          _isLoading = false;
        });
        return;
      }

      final imageData = await file.readAsBytes();

      // 验证披风
      final validation = await _capeManager.validateCape(imageData, path.basename(filePath));

      if (!validation.isValid) {
        setState(() {
          _errorMessage = validation.errorMessage ?? '披风验证失败';
          _isLoading = false;
        });
        return;
      }

      // 上传披风
      final capeData = await _capeManager.uploadCape(
        widget.accountId,
        imageData,
        path.basename(filePath),
      );

      if (capeData != null) {
        setState(() {
          _previewImage = imageData;
          _successMessage = '披风上传成功！';
          _isLoading = false;
        });

        widget.onUploadSuccess?.call(imageData);
      } else {
        setState(() {
          _errorMessage = '披风上传失败';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to process cape file', e, stackTrace);
      setState(() {
        _errorMessage = '处理文件时出错: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleFilePick() async {
    // 注意：在实际Flutter应用中，可以使用file_picker包
    // 这里简化处理，直接提示用户
    setState(() {
      _errorMessage = '请拖拽PNG文件到对话框中，或联系开发者添加文件选择器';
      _isLoading = false;
    });
  }

  Future<void> _handleDelete() async {
    final confirmed = await BAConfirmDialog.show(
      context: context,
      title: '删除披风',
      content: '确定要删除 "${widget.accountName}" 的披风吗？',
      confirmText: '删除',
      cancelText: '取消',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _capeManager.deleteCape(widget.accountId);

      if (success) {
        setState(() {
          _previewImage = null;
          _successMessage = '披风已删除';
          _isLoading = false;
        });

        widget.onDeleteSuccess?.call();
      } else {
        setState(() {
          _errorMessage = '删除披风失败';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to delete cape', e, stackTrace);
      setState(() {
        _errorMessage = '删除披风时出错: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 480,
            constraints: const BoxConstraints(maxWidth: 520, minWidth: 360),
            decoration: BoxDecoration(
              color: BAColors.glassOf(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: BAColors.borderOf(context).withOpacity(0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: BAColors.shadowOf(context),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                _buildContent(context),
                _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BAColors.primaryOf(context).withOpacity(0.2),
            BAColors.primaryOf(context).withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: BAColors.borderOf(context).withOpacity(0.4),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '披风管理',
                  style: TextStyle(
                    color: BAColors.textPrimaryOf(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '为 ${widget.accountName} 管理披风',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: BAColors.surfaceVariantOf(context).withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.close,
                size: 18,
                color: BAColors.textSecondaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 披风要求说明
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
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: BAColors.primaryOf(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '披风要求：PNG格式，尺寸 64x32 像素',
                    style: TextStyle(
                      color: BAColors.textSecondaryOf(context),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 拖拽区域
          DragTarget<String>(
            onWillAcceptWithDetails: (data) {
              setState(() => _isDragging = true);
              return true;
            },
            onLeave: (data) {
              setState(() => _isDragging = false);
            },
            onAcceptWithDetails: (data) {
              setState(() => _isDragging = false);
              _handleFileDrop(data.data);
            },
            builder: (context, candidateData, rejectedData) {
              return GestureDetector(
                onTap: _handleFilePick,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 160,
                    decoration: BoxDecoration(
                      color: _isDragging
                          ? BAColors.primaryOf(context).withOpacity(0.1)
                          : BAColors.surfaceVariantOf(context).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isDragging
                            ? BAColors.primaryOf(context)
                            : BAColors.borderOf(context).withOpacity(0.6),
                        width: _isDragging ? 2 : 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Center(
                      child: _isLoading
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 12),
                                Text(
                                  '处理中...',
                                  style: TextStyle(
                                    color: BAColors.textSecondaryOf(context),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 48,
                                  color: _isDragging
                                      ? BAColors.primaryOf(context)
                                      : BAColors.textSecondaryOf(context),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _isDragging
                                      ? '释放以上传'
                                      : '拖拽PNG文件到此处',
                                  style: TextStyle(
                                    color: _isDragging
                                        ? BAColors.primaryOf(context)
                                        : BAColors.textSecondaryOf(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_selectedFileName != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedFileName!,
                                    style: TextStyle(
                                      color: BAColors.textSecondaryOf(context),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 披风预览
          if (_previewImage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BAColors.surfaceVariantOf(context).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: BAColors.borderOf(context).withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: BAColors.borderOf(context),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Image.memory(
                        _previewImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '披风预览',
                          style: TextStyle(
                            color: BAColors.textPrimaryOf(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '64x32 像素',
                          style: TextStyle(
                            color: BAColors.textSecondaryOf(context),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 错误消息
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BAColors.dangerOf(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: BAColors.dangerOf(context).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 18,
                    color: BAColors.dangerOf(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: BAColors.dangerOf(context),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 成功消息
          if (_successMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BAColors.successOf(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: BAColors.successOf(context).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: BAColors.successOf(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: TextStyle(
                        color: BAColors.successOf(context),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: BAColors.borderOf(context).withOpacity(0.4),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.existingCapeImage != null || _previewImage != null) ...[
            BADangerButton(
              text: '删除披风',
              onPressed: _handleDelete,
              enabled: !_isLoading,
            ),
            const SizedBox(width: 12),
          ],
          BASecondaryButton(
            text: '关闭',
            onPressed: () => Navigator.of(context).pop(),
            enabled: !_isLoading,
          ),
        ],
      ),
    );
  }
}

/// 图片滤镜（用于Dialog）
class ImageFilter {
  static const blur = uiBlur;

  static ImageFilter blur({double sigmaX = 0, double sigmaY = 0}) => uiBlur(sigmaX: sigmaX, sigmaY: sigmaY);
}

class uiBlur {
  final double sigmaX;
  final double sigmaY;

  const uiBlur({required this.sigmaX, required this.sigmaY});
}
