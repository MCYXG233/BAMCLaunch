import 'package:flutter/material.dart';
import '../../../../instance/instance_manager.dart';
import '../../../../instance/models.dart';
import '../../../../game/game_statistics.dart';
import '../../../theme/colors.dart';
import '../../../components/settings_panel/widgets/settings_theme.dart';

class GameLibraryDetailSidebar extends StatelessWidget {
  final GameInstance instance;
  final bool isRunning;
  final bool isLaunching;
  final GameStatisticsManager statsManager;
  final VoidCallback onLaunchGame;
  final VoidCallback onOpenInstanceFolder;
  final VoidCallback onOpenBackupManager;
  final VoidCallback onOpenModManager;
  final VoidCallback onDuplicateInstance;
  final VoidCallback onExportInstance;
  final VoidCallback onDeleteInstance;

  const GameLibraryDetailSidebar({
    super.key,
    required this.instance,
    required this.isRunning,
    required this.isLaunching,
    required this.statsManager,
    required this.onLaunchGame,
    required this.onOpenInstanceFolder,
    required this.onOpenBackupManager,
    required this.onOpenModManager,
    required this.onDuplicateInstance,
    required this.onExportInstance,
    required this.onDeleteInstance,
  });

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '$hours小时$minutes分';
    } else {
      return '$minutes分';
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '从未';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _inferInstanceType(String? loader) {
    if (loader == null || loader.isEmpty) return '原版 (Vanilla)';
    switch (loader.toLowerCase()) {
      case 'forge':
        return 'Forge';
      case 'fabric':
        return 'Fabric';
      case 'quilt':
        return 'Quilt';
      case 'optifine':
        return 'OptiFine';
      case 'neoforge':
        return 'NeoForge';
      case 'liteloader':
        return 'LiteLoader';
      default:
        return loader;
    }
  }

  String _resolveInstanceDirectoryPath(GameInstance instance) {
    final directory = InstanceManager().directories
        .where((d) => d.id == instance.directoryId)
        .firstOrNull;
    if (directory == null) return '未知目录';
    return directory.path;
  }

  @override
  Widget build(BuildContext context) {
    final instanceStats = statsManager.getInstanceStatistics(instance.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 12, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.85),
          width: 1,
        ),
        boxShadow: SettingsPalette.cardShadow(context),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '实例信息',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: SettingsPalette.textPrimary(context),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isRunning
                        ? [BAColors.successOf(context), BAColors.successDark]
                        : [
                            BAColors.primaryLightOf(context),
                            BAColors.primaryOf(context),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isRunning
                                  ? BAColors.successOf(context)
                                  : BAColors.primaryOf(context))
                              .withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sports_esports_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              instance.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: SettingsPalette.textPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              '${instance.version}${instance.loader != null && instance.loader!.isNotEmpty ? ' · ${instance.loader}' : ''}',
              style: TextStyle(
                fontSize: 11,
                color: SettingsPalette.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: (isRunning || isLaunching) ? null : onLaunchGame,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isRunning
                            ? [
                                BAColors.successOf(context),
                                BAColors.successDark,
                              ]
                            : isLaunching
                            ? [
                                BAColors.warningOf(context),
                                BAColors.warningDark,
                              ]
                            : [
                                BAColors.primaryLightOf(context),
                                BAColors.primaryOf(context),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isRunning
                                      ? BAColors.successOf(context)
                                      : isLaunching
                                      ? BAColors.warningOf(context)
                                      : BAColors.primaryOf(context))
                                  .withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isLaunching
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isRunning
                                      ? Icons.stop_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isRunning
                                      ? '运行中'
                                      : (isLaunching ? '启动中' : '启动游戏'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '快捷操作',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SettingsPalette.textSecondary(context),
              ),
            ),
            const SizedBox(height: 8),
            _buildSidebarAction(
              context,
              icon: Icons.folder_open_rounded,
              label: '在文件管理器中打开',
              onTap: onOpenInstanceFolder,
            ),
            _buildSidebarAction(
              context,
              icon: Icons.backup_rounded,
              label: '备份管理',
              onTap: onOpenBackupManager,
            ),
            _buildSidebarAction(
              context,
              icon: Icons.extension_rounded,
              label: '模组管理',
              onTap: onOpenModManager,
            ),
            _buildSidebarAction(
              context,
              icon: Icons.copy_rounded,
              label: '复制实例',
              onTap: onDuplicateInstance,
            ),
            _buildSidebarAction(
              context,
              icon: Icons.file_upload_rounded,
              label: '导出实例',
              onTap: onExportInstance,
            ),
            const SizedBox(height: 18),
            Text(
              '游戏信息',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SettingsPalette.textSecondary(context),
              ),
            ),
            const SizedBox(height: 8),
            _buildSidebarInfo(
              context,
              '核心',
              '${instance.version}${instance.loader != null ? ' · ${instance.loader}' : ''}',
            ),
            _buildSidebarInfo(
              context,
              '实例类型',
              _inferInstanceType(instance.loader),
            ),
            _buildSidebarInfo(
              context,
              '来源目录',
              _resolveInstanceDirectoryPath(instance),
            ),
            _buildSidebarInfo(
              context,
              '游玩时长',
              instanceStats != null
                  ? _formatDuration(
                      Duration(seconds: instanceStats.totalPlayTimeSeconds),
                    )
                  : '0分',
            ),
            _buildSidebarInfo(
              context,
              '最近游玩',
              _formatDateTime(
                instance.lastPlayed ?? instanceStats?.lastLaunchTime,
              ),
            ),
            const SizedBox(height: 14),
            _buildSidebarDanger(
              context,
              icon: Icons.delete_outline_rounded,
              label: '删除此实例',
              onTap: onDeleteInstance,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: SettingsPalette.textSecondary(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: SettingsPalette.textPrimary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarInfo(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 11,
            color: SettingsPalette.textSecondary(context),
            height: 1.5,
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: TextStyle(
                color: SettingsPalette.textPrimary(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarDanger(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 14, color: SettingsPalette.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: SettingsPalette.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: SettingsPalette.danger,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
