import 'package:flutter/material.dart';

import '../../animations/ba_animations.dart';
import '../../theme/colors.dart';
import 'settings_components.dart';

/// 游戏设置页:路径(游戏目录/Java)、性能(内存/分辨率)、高级参数(JVM/游戏参数)
class GameSettingsPage extends StatefulWidget {
  const GameSettingsPage({
    super.key,
    required this.gameDirectory,
    required this.javaPath,
    required this.memoryAllocation,
    required this.gameWindowSize,
    this.initialJvmArgs,
    this.initialGameArgs,
    required this.onPickGameDirectory,
    required this.onPickJavaPath,
    required this.onMemoryAllocationChanged,
    required this.onMemoryAllocationCommitted,
    required this.onGameWindowSizeChanged,
  });

  final String gameDirectory;
  final String javaPath;
  final double memoryAllocation;
  final String gameWindowSize;
  final String? initialJvmArgs;
  final String? initialGameArgs;

  final VoidCallback onPickGameDirectory;
  final VoidCallback onPickJavaPath;
  final ValueChanged<double> onMemoryAllocationChanged;
  final ValueChanged<double> onMemoryAllocationCommitted;
  final ValueChanged<String> onGameWindowSizeChanged;

  @override
  State<GameSettingsPage> createState() => _GameSettingsPageState();
}

class _GameSettingsPageState extends State<GameSettingsPage> {
  late final TextEditingController _jvmArgsController;
  late final FocusNode _jvmArgsFocusNode;
  late final TextEditingController _gameArgsController;
  late final FocusNode _gameArgsFocusNode;

  @override
  void initState() {
    super.initState();
    _jvmArgsController = TextEditingController(
      text: widget.initialJvmArgs ?? '',
    );
    _jvmArgsFocusNode = FocusNode();
    _gameArgsController = TextEditingController(
      text: widget.initialGameArgs ?? '',
    );
    _gameArgsFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _jvmArgsController.dispose();
    _jvmArgsFocusNode.dispose();
    _gameArgsController.dispose();
    _gameArgsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        SettingsCard(
          title: '路径设置',
          children: [
            SettingsRow(
              icon: Icons.folder,
              title: '游戏目录',
              subtitle: widget.gameDirectory.isEmpty
                  ? '未设置'
                  : widget.gameDirectory,
              control: SettingsPathSelector(
                path: widget.gameDirectory,
                placeholder: '未设置',
                buttonText: '浏览',
                onBrowse: widget.onPickGameDirectory,
              ),
            ),
            SettingsRow(
              icon: Icons.developer_mode,
              title: 'Java路径',
              subtitle: widget.javaPath.isEmpty ? '自动检测' : widget.javaPath,
              control: SettingsPrimaryButton(
                text: '选择',
                onPressed: widget.onPickJavaPath,
              ),
            ),
          ],
        ),
        SettingsCard(
          title: '性能设置',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Builder(
                builder: (context) {
                  final isLight =
                      Theme.of(context).brightness == Brightness.light;
                  final primaryText = BAColors.textPrimaryOf(context);
                  final secondaryText = BAColors.textSecondaryOf(context);
                  final accentBlue = BAColors.primaryLightOf(context);
                  final inactiveTrack = BAColors.surfaceTertiaryOf(context);

                  return Row(
                    children: [
                      BAAnimations.breathe(
                        isActive: true,
                        duration: const Duration(milliseconds: 3000),
                        minOpacity: 0.85,
                        maxOpacity: 1.0,
                        glowRadius: 6.0,
                        glowColor: accentBlue,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                BAColors.primaryOf(
                                  context,
                                ).withValues(alpha: 0.3),
                                accentBlue.withValues(alpha: 0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: accentBlue.withValues(alpha: 0.25),
                                blurRadius: 8,
                                spreadRadius: 0.5,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.memory,
                            color: accentBlue,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '最大内存',
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${widget.memoryAllocation.toInt()} MB',
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: BAColors.primaryOf(context),
                                inactiveTrackColor: inactiveTrack,
                                thumbColor: Colors.white,
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8,
                                ),
                                overlayColor: BAColors.primaryOf(
                                  context,
                                ).withValues(alpha: 0.2),
                              ),
                              child: Slider(
                                value: widget.memoryAllocation,
                                min: 1024,
                                max: 16384,
                                divisions: 15,
                                label: '${widget.memoryAllocation.toInt()} MB',
                                onChanged: widget.onMemoryAllocationChanged,
                                onChangeEnd: widget.onMemoryAllocationCommitted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SettingsRow(
              icon: Icons.aspect_ratio,
              title: '游戏窗口分辨率',
              subtitle: widget.gameWindowSize,
              control: SettingsDropdown<String>(
                value: widget.gameWindowSize,
                items: const [
                  DropdownMenuItem(value: '800x600', child: Text('800x600')),
                  DropdownMenuItem(value: '1280x720', child: Text('1280x720')),
                  DropdownMenuItem(
                    value: '1920x1080',
                    child: Text('1920x1080'),
                  ),
                  DropdownMenuItem(value: '自定义', child: Text('自定义')),
                ],
                onChanged: (value) {
                  if (value != null) widget.onGameWindowSizeChanged(value);
                },
              ),
            ),
          ],
        ),
        SettingsCard(
          title: '高级参数',
          children: [
            SettingsRow(
              icon: Icons.code,
              title: 'JVM额外参数',
              subtitle: _jvmArgsController.text.isEmpty
                  ? '无'
                  : _jvmArgsController.text,
              control: SettingsTextField(
                controller: _jvmArgsController,
                focusNode: _jvmArgsFocusNode,
                placeholder: '例如: -XX:+UseG1GC',
              ),
            ),
            SettingsRow(
              icon: Icons.play_arrow,
              title: '游戏启动参数',
              subtitle: _gameArgsController.text.isEmpty
                  ? '无'
                  : _gameArgsController.text,
              control: SettingsTextField(
                controller: _gameArgsController,
                focusNode: _gameArgsFocusNode,
                placeholder: '例如: --fullscreen',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
