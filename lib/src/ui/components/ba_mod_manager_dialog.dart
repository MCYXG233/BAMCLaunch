import 'package:flutter/material.dart';
import '../pages/ba_mod_manager_page.dart';
import 'ba_dialog.dart';

/// 模组管理对话框
class BAModManagerDialog extends StatelessWidget {
  final String instanceId;
  final String instanceName;

  const BAModManagerDialog({
    super.key,
    required this.instanceId,
    required this.instanceName,
  });

  static Future<void> show({
    required BuildContext context,
    required String instanceId,
    required String instanceName,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => BAModManagerDialog(
        instanceId: instanceId,
        instanceName: instanceName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BADialog(
      title: '模组管理 - $instanceName',
      width: 1100,
      height: 650,
      onClose: () => Navigator.of(context).pop(),
      child: BAModManagerPage(instanceId: instanceId),
    );
  }
}