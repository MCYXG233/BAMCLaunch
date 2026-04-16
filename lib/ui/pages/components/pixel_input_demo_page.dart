import 'package:flutter/material.dart';
import '../../components/inputs/pixel_input.dart';
import '../../components/icons/pixel_icon.dart';
import '../../components/layout/breadcrumb_navigation.dart';
import '../../theme/colors.dart';

class PixelInputDemoPage extends StatelessWidget {
  const PixelInputDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BamcColors.background,
      body: Column(
        children: [
          BreadcrumbNavigation(
            items: [
              BreadcrumbItem(
                title: '首页',
                onTap: () {},
              ),
              BreadcrumbItem(
                title: '组件库',
                onTap: () {},
              ),
              BreadcrumbItem(
                title: '像素风输入框',
                isActive: true,
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    '像素风输入框组件',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: BamcColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '圆角矩形描边，聚焦时主色柔和发光，像素风前缀图标',
                    style: TextStyle(
                      fontSize: 16,
                      color: BamcColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildBasicExamples(),
                  const SizedBox(height: 32),
                  _buildWithPixelIcons(),
                  const SizedBox(height: 32),
                  _buildDifferentSizes(),
                  const SizedBox(height: 32),
                  _buildWithStates(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '基础示例',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: BamcColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        const PixelInput(
          hintText: '请输入文本...',
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        const PixelInput(
          labelText: '用户名',
          hintText: '请输入用户名',
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildWithPixelIcons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '像素风图标示例',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: BamcColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        const PixelInput(
          labelText: '搜索',
          hintText: '搜索内容...',
          prefixIcon: PixelIconType.search,
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        const PixelInput(
          labelText: '用户名',
          hintText: '请输入用户名',
          prefixIcon: PixelIconType.user,
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        const PixelInput(
          labelText: '密码',
          hintText: '请输入密码',
          prefixIcon: PixelIconType.lock,
          obscureText: true,
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        const PixelInput(
          labelText: '邮箱',
          hintText: 'example@email.com',
          prefixIcon: PixelIconType.email,
          keyboardType: TextInputType.emailAddress,
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        const PixelInput(
          labelText: '设置',
          hintText: '配置选项...',
          prefixIcon: PixelIconType.settings,
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        const PixelInput(
          labelText: '游戏',
          hintText: '搜索游戏...',
          prefixIcon: PixelIconType.gamepad,
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        const PixelInput(
          labelText: '资源包',
          hintText: '查找资源包...',
          prefixIcon: PixelIconType.chest,
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        const PixelInput(
          labelText: '合成',
          hintText: '输入物品名称...',
          prefixIcon: PixelIconType.craftTable,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildDifferentSizes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '不同尺寸',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: BamcColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        const PixelInput(
          labelText: '小尺寸 (Small)',
          hintText: '小尺寸输入框',
          prefixIcon: PixelIconType.search,
          size: PixelInputSize.small,
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        const PixelInput(
          labelText: '中尺寸 (Medium)',
          hintText: '中尺寸输入框',
          prefixIcon: PixelIconType.search,
          size: PixelInputSize.medium,
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        const PixelInput(
          labelText: '大尺寸 (Large)',
          hintText: '大尺寸输入框',
          prefixIcon: PixelIconType.search,
          size: PixelInputSize.large,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildWithStates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '不同状态',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: BamcColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        const PixelInput(
          labelText: '禁用状态',
          hintText: '此输入框已禁用',
          prefixIcon: PixelIconType.search,
          enabled: false,
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        const PixelInput(
          labelText: '只读状态',
          hintText: '此输入框为只读',
          prefixIcon: PixelIconType.user,
          readOnly: true,
          initialValue: '只读内容',
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        const PixelInput(
          labelText: '错误状态',
          hintText: '请输入有效的内容',
          prefixIcon: PixelIconType.email,
          errorText: '邮箱格式不正确',
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        const PixelInput(
          labelText: '带初始值',
          hintText: '请输入...',
          prefixIcon: PixelIconType.user,
          initialValue: 'Hello Pixel World!',
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        const PixelInput(
          labelText: '多行输入',
          hintText: '请输入多行文本...',
          prefixIcon: PixelIconType.craftTable,
          maxLines: 4,
          minLines: 3,
          fullWidth: true,
        ),
      ],
    );
  }
}
