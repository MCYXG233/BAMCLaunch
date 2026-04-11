import 'package:flutter/material.dart';
import '../layout/bamc_card.dart';

class CopyrightDialog extends StatelessWidget {
  const CopyrightDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: BamcCard(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '版权信息',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSection('BAMCLauncher', [
                '版权所有 © 2024 BAMCLauncher Team',
                '基于 GPLv3 许可证开源',
              ]),
              const SizedBox(height: 16),
              _buildSection('Terracotta 集成', [
                '版权所有 © Terracotta Project',
                '基于 GNU Affero General Public License v3.0 (AGPL v3.0) 许可证开源',
                '',
                'AGPL v3.0 许可证条款摘要:',
                '- 允许自由使用、修改和分发软件',
                '- 修改后的代码必须以相同许可证开源',
                '- 必须保留原始版权声明和许可证文本',
                '- 网络使用时必须提供源代码访问',
              ]),
              const SizedBox(height: 16),
              _buildSection('第三方依赖', [
                '本项目使用了以下开源库:',
                '- Flutter - BSD 3-Clause 许可证',
                '- Dart - BSD 3-Clause 许可证',
                '- 其他依赖项详见项目文档',
              ]),
              const SizedBox(height: 20),
              _buildAgplNotice(),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('我已知悉'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content
              .map((line) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildAgplNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AGPL v3.0 许可证要求',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '根据 AGPL v3.0 许可证，本软件包含的 Terracotta 组件要求:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '1. 如果您修改了 Terracotta 代码，必须以 AGPL v3.0 许可证重新发布',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Text(
            '2. 如果您通过网络提供 Terracotta 服务，必须提供源代码访问',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Text(
            '3. 必须保留所有版权声明和许可证文本',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}