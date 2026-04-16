import 'package:flutter/material.dart';
import '../../components/layout/bamc_card.dart';
import '../../components/progress/minecraft_xp_bar.dart';
import '../../theme/colors.dart';

class MinecraftXpBarDemoPage extends StatefulWidget {
  const MinecraftXpBarDemoPage({super.key});

  @override
  State<MinecraftXpBarDemoPage> createState() => _MinecraftXpBarDemoPageState();
}

class _MinecraftXpBarDemoPageState extends State<MinecraftXpBarDemoPage> {
  double _progressValue = 50.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BamcColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Minecraft 风格经验条组件',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: BamcColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '融合MC经验条的方块化填充设计，圆角清新风格，像素化进度动画',
              style: TextStyle(
                fontSize: 14,
                color: BamcColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            _buildProgressControl(),
            const SizedBox(height: 32),
            _buildAllStylesDemo(),
            const SizedBox(height: 32),
            _buildCustomizationDemo(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressControl() {
    return BamcCard(
      title: '进度控制',
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '拖动滑块调整所有进度条的进度值',
            style: TextStyle(
              fontSize: 14,
              color: BamcColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _progressValue,
                  min: 0,
                  max: 100,
                  onChanged: (value) {
                    setState(() {
                      _progressValue = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: BamcColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_progressValue.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: BamcColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MinecraftXpBar(
            value: _progressValue,
            style: MinecraftXpBarStyle.grass,
            showPercentage: true,
            label: '示例进度',
          ),
        ],
      ),
    );
  }

  Widget _buildAllStylesDemo() {
    return BamcCard(
      title: '所有样式展示',
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildStyleItem(
            style: MinecraftXpBarStyle.grass,
            name: '草方块 (Grass)',
          ),
          const SizedBox(height: 24),
          _buildStyleItem(
            style: MinecraftXpBarStyle.gold,
            name: '金块 (Gold)',
          ),
          const SizedBox(height: 24),
          _buildStyleItem(
            style: MinecraftXpBarStyle.diamond,
            name: '钻石 (Diamond)',
          ),
          const SizedBox(height: 24),
          _buildStyleItem(
            style: MinecraftXpBarStyle.redstone,
            name: '红石 (Redstone)',
          ),
          const SizedBox(height: 24),
          _buildStyleItem(
            style: MinecraftXpBarStyle.emerald,
            name: '绿宝石 (Emerald)',
          ),
          const SizedBox(height: 24),
          _buildStyleItem(
            style: MinecraftXpBarStyle.lapis,
            name: '青金石 (Lapis)',
          ),
          const SizedBox(height: 24),
          _buildStyleItem(
            style: MinecraftXpBarStyle.netherite,
            name: '下界合金 (Netherite)',
          ),
        ],
      ),
    );
  }

  Widget _buildStyleItem({
    required MinecraftXpBarStyle style,
    required String name,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: BamcColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        MinecraftXpBar(
          value: _progressValue,
          style: style,
          showPercentage: true,
        ),
      ],
    );
  }

  Widget _buildCustomizationDemo() {
    return BamcCard(
      title: '自定义选项',
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            '不同高度',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: BamcColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          MinecraftXpBar(
            value: _progressValue,
            style: MinecraftXpBarStyle.diamond,
            height: 16,
            showPercentage: false,
          ),
          const SizedBox(height: 12),
          MinecraftXpBar(
            value: _progressValue,
            style: MinecraftXpBarStyle.diamond,
            height: 24,
            showPercentage: false,
          ),
          const SizedBox(height: 12),
          MinecraftXpBar(
            value: _progressValue,
            style: MinecraftXpBarStyle.diamond,
            height: 36,
            showPercentage: false,
          ),
          const SizedBox(height: 24),
          Text(
            '不同方块数量',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: BamcColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          MinecraftXpBar(
            value: _progressValue,
            style: MinecraftXpBarStyle.emerald,
            totalBlocks: 10,
            showPercentage: false,
          ),
          const SizedBox(height: 12),
          MinecraftXpBar(
            value: _progressValue,
            style: MinecraftXpBarStyle.emerald,
            totalBlocks: 20,
            showPercentage: false,
          ),
          const SizedBox(height: 12),
          MinecraftXpBar(
            value: _progressValue,
            style: MinecraftXpBarStyle.emerald,
            totalBlocks: 40,
            showPercentage: false,
          ),
          const SizedBox(height: 24),
          Text(
            '带前后缀组件',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: BamcColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          MinecraftXpBar(
            value: _progressValue,
            style: MinecraftXpBarStyle.redstone,
            showPercentage: false,
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: BamcColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.flash_on,
                size: 16,
                color: BamcColors.warning,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: BamcColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${_progressValue.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: BamcColors.warning,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '可点击交互',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: BamcColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          MinecraftXpBar(
            value: _progressValue,
            style: MinecraftXpBarStyle.gold,
            showPercentage: true,
            label: '点击重置',
            onTap: () {
              setState(() {
                _progressValue = 0;
              });
            },
          ),
        ],
      ),
    );
  }
}
