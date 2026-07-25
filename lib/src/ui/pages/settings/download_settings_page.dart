import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/config_keys.dart';
import '../../../config/config_manager.dart';
import '../../../download/mirror_manager.dart';
import '../../animations/ba_animations.dart';
import '../../components/ba_notification.dart';
import '../../theme/colors.dart';
import 'settings_components.dart';

/// 下载设置页：下载源/目录/重试、并发与限速、镜像管理、HTTP 代理
///
/// 完全自包含的 ConsumerStatefulWidget：
/// - 内部通过 [ConfigManager] 与 [MirrorManager] 单例读写配置
/// - 不接收外部参数，避免父级构造函数参数爆炸
/// - 本地 UI 状态（controller/focusNode/slider 拖动值）仍用 setState 管理
class DownloadSettingsPage extends ConsumerStatefulWidget {
  const DownloadSettingsPage({super.key});

  @override
  ConsumerState<DownloadSettingsPage> createState() =>
      _DownloadSettingsPageState();
}

class _DownloadSettingsPageState extends ConsumerState<DownloadSettingsPage> {
  final ConfigManager _configManager = ConfigManager();
  final MirrorManager _mirrorManager = MirrorManager();

  String _downloadSource = 'official';
  int _concurrentDownloads = 3;
  String _downloadPath = '';
  bool _autoRetryDownload = true;
  String _proxyHost = '';
  int _proxyPort = 0;

  List<MirrorSpeedTestResult> _speedTestResults = [];
  bool _isSpeedTesting = false;
  bool _autoSelectMirror = true;
  bool _enableSpeedLimit = false;
  double _speedLimitValue = 1024;
  int _speedLimitUnit = 0;

  late final TextEditingController _proxyHostController;
  late final TextEditingController _proxyPortController;
  late final FocusNode _proxyHostFocusNode;
  late final FocusNode _proxyPortFocusNode;
  late final TextEditingController _customMirrorUrlController;
  late final TextEditingController _customMirrorNameController;
  late final FocusNode _customMirrorNameFocusNode;
  late final FocusNode _customMirrorUrlFocusNode;

  @override
  void initState() {
    super.initState();
    _proxyHostController = TextEditingController();
    _proxyPortController = TextEditingController();
    _proxyHostFocusNode = FocusNode();
    _proxyPortFocusNode = FocusNode();
    _customMirrorUrlController = TextEditingController();
    _customMirrorNameController = TextEditingController();
    _customMirrorNameFocusNode = FocusNode();
    _customMirrorUrlFocusNode = FocusNode();

    _proxyHostFocusNode.addListener(_onProxyHostFocusChange);
    _proxyPortFocusNode.addListener(_onProxyPortFocusChange);

    _loadSettings();
  }

  @override
  void dispose() {
    _proxyHostFocusNode.removeListener(_onProxyHostFocusChange);
    _proxyPortFocusNode.removeListener(_onProxyPortFocusChange);
    _proxyHostController.dispose();
    _proxyPortController.dispose();
    _proxyHostFocusNode.dispose();
    _proxyPortFocusNode.dispose();
    _customMirrorUrlController.dispose();
    _customMirrorNameController.dispose();
    _customMirrorNameFocusNode.dispose();
    _customMirrorUrlFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final downloadSource =
          _configManager.getString(ConfigKeys.downloadSource) ?? 'official';
      final concurrentDownloads =
          _configManager.getInt(ConfigKeys.concurrentDownloads) ?? 3;
      final downloadPath =
          _configManager.getString(ConfigKeys.downloadPath) ?? '';
      final autoRetryDownload =
          _configManager.getBool(ConfigKeys.autoRetryDownload) ?? true;
      final proxyHost = _configManager.getString(ConfigKeys.proxyHost) ?? '';
      final proxyPort = _configManager.getInt(ConfigKeys.proxyPort) ?? 0;
      final autoSelectMirror =
          _configManager.getBool(ConfigKeys.autoSelectMirror) ?? true;
      final enableSpeedLimit =
          _configManager.getBool(ConfigKeys.enableSpeedLimit) ?? false;
      final speedLimitValue =
          _configManager.getInt(ConfigKeys.speedLimitValue) ?? 1024;
      final speedLimitUnit = _configManager.getInt('speedLimitUnit') ?? 0;

      await _mirrorManager.loadConfig();
      final speedTestResults = _mirrorManager.speedTestResults;

      if (mounted) {
        setState(() {
          _downloadSource = downloadSource;
          _concurrentDownloads = concurrentDownloads;
          _downloadPath = downloadPath;
          _autoRetryDownload = autoRetryDownload;
          _proxyHost = proxyHost;
          _proxyPort = proxyPort;
          _proxyHostController.text = proxyHost;
          _proxyPortController.text =
              proxyPort == 0 ? '' : proxyPort.toString();
          _autoSelectMirror = autoSelectMirror;
          _enableSpeedLimit = enableSpeedLimit;
          _speedLimitValue = speedLimitValue.toDouble();
          _speedLimitUnit = speedLimitUnit;
          _speedTestResults = speedTestResults;
        });
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('加载下载设置失败', message: e.toString());
      }
    }
  }

  Future<void> _saveDownloadSource(String source) async {
    try {
      await _configManager.setString(ConfigKeys.downloadSource, source);
      if (!mounted) return;
      setState(() {
        _downloadSource = source;
      });
      NotificationManager().showSuccess('下载源已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存下载源失败', message: e.toString());
      }
    }
  }

  Future<void> _saveConcurrentDownloads(int count) async {
    try {
      await _configManager.setInt(ConfigKeys.concurrentDownloads, count);
      if (!mounted) return;
      NotificationManager().showSuccess('下载线程已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存下载线程失败', message: e.toString());
      }
    }
  }

  Future<void> _saveAutoSelectMirror(bool value) async {
    try {
      await _configManager.setBool(ConfigKeys.autoSelectMirror, value);
      if (!mounted) return;
      setState(() {
        _autoSelectMirror = value;
      });
      NotificationManager().showSuccess('自动选择最快镜像已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存设置失败', message: e.toString());
      }
    }
  }

  Future<void> _saveEnableSpeedLimit(bool value) async {
    try {
      await _configManager.setBool(ConfigKeys.enableSpeedLimit, value);
      if (!mounted) return;
      setState(() {
        _enableSpeedLimit = value;
      });
      NotificationManager().showSuccess('限速设置已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存设置失败', message: e.toString());
      }
    }
  }

  Future<void> _saveSpeedLimitValue(double value, int unit) async {
    try {
      await _configManager.setInt(ConfigKeys.speedLimitValue, value.toInt());
      await _configManager.setInt('speedLimitUnit', unit);
      if (!mounted) return;
      setState(() {
        _speedLimitValue = value;
        _speedLimitUnit = unit;
      });
      NotificationManager().showSuccess('限速值已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存设置失败', message: e.toString());
      }
    }
  }

  Future<void> _speedTestMirrors() async {
    if (!mounted) return;
    setState(() {
      _isSpeedTesting = true;
    });
    try {
      final results = await _mirrorManager.speedTestAllMirrors();
      if (mounted) {
        setState(() {
          _speedTestResults = results;
          _isSpeedTesting = false;
        });
        NotificationManager().showSuccess('测速完成');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSpeedTesting = false;
        });
        NotificationManager().showError('测速失败', message: e.toString());
      }
    }
  }

  Future<void> _autoSelectFastestMirror() async {
    if (!mounted) return;
    setState(() {
      _isSpeedTesting = true;
    });
    try {
      final fastest = await _mirrorManager.autoSelectFastestMirror();
      if (mounted) {
        setState(() {
          _isSpeedTesting = false;
        });
        NotificationManager().showSuccess('已自动切换到最快镜像: ${fastest.name}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSpeedTesting = false;
        });
        NotificationManager().showError('自动选择失败', message: e.toString());
      }
    }
  }

  Future<void> _addCustomMirror() async {
    final url = _customMirrorUrlController.text.trim();
    final name = _customMirrorNameController.text.trim();

    if (url.isEmpty) {
      NotificationManager().showError('请输入镜像地址');
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      NotificationManager().showError('镜像地址必须以 http:// 或 https:// 开头');
      return;
    }

    try {
      final mirror = MirrorInfo(
        id: '',
        name: name.isEmpty ? Uri.parse(url).host : name,
        url: url,
      );
      await _mirrorManager.addCustomMirror(mirror);
      _customMirrorUrlController.clear();
      _customMirrorNameController.clear();
      if (mounted) {
        setState(() {});
        NotificationManager().showSuccess('自定义镜像已添加');
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('添加镜像失败', message: e.toString());
      }
    }
  }

  Future<void> _removeCustomMirror(String mirrorId) async {
    try {
      await _mirrorManager.removeCustomMirror(mirrorId);
      if (mounted) {
        setState(() {});
        NotificationManager().showSuccess('镜像已移除');
      }
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('移除镜像失败', message: e.toString());
      }
    }
  }

  void _selectMirror(String mirrorId) {
    _mirrorManager.setCurrentMirror(mirrorId);
    setState(() {});
    NotificationManager().showSuccess('已选择镜像');
  }

  Future<void> _saveDownloadPath(String dir) async {
    try {
      await _configManager.setString(ConfigKeys.downloadPath, dir);
      if (!mounted) return;
      setState(() {
        _downloadPath = dir;
      });
      NotificationManager().showSuccess('下载目录已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存下载目录失败', message: e.toString());
      }
    }
  }

  Future<void> _saveAutoRetryDownload(bool value) async {
    try {
      await _configManager.setBool(ConfigKeys.autoRetryDownload, value);
      if (!mounted) return;
      setState(() {
        _autoRetryDownload = value;
      });
      NotificationManager().showSuccess('下载失败自动重试设置已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError(
          '保存下载失败自动重试设置失败',
          message: e.toString(),
        );
      }
    }
  }

  Future<void> _saveProxyHost(String value) async {
    try {
      await _configManager.setString(ConfigKeys.proxyHost, value);
      if (!mounted) return;
      setState(() {
        _proxyHost = value;
      });
      NotificationManager().showSuccess('HTTP代理地址已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存HTTP代理地址失败', message: e.toString());
      }
    }
  }

  Future<void> _saveProxyPort(String value) async {
    try {
      final port = int.tryParse(value) ?? 0;
      await _configManager.setInt(ConfigKeys.proxyPort, port);
      if (!mounted) return;
      setState(() {
        _proxyPort = port;
      });
      NotificationManager().showSuccess('HTTP代理端口已保存');
    } catch (e) {
      if (mounted) {
        NotificationManager().showError('保存HTTP代理端口失败', message: e.toString());
      }
    }
  }

  void _onProxyHostFocusChange() {
    if (!_proxyHostFocusNode.hasFocus) {
      _saveProxyHost(_proxyHostController.text);
    }
  }

  void _onProxyPortFocusChange() {
    if (!_proxyPortFocusNode.hasFocus) {
      _saveProxyPort(_proxyPortController.text);
    }
  }

  Future<void> _pickDownloadPath() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        await _saveDownloadPath(result);
      }
    } catch (e) {
      NotificationManager().showError('选择目录失败', message: e.toString());
    }
  }

  String _downloadSourceDisplayName(String source) {
    switch (source) {
      case 'mirror':
        return '镜像源';
      default:
        return '官方源';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        SettingsCard(
          title: '下载设置',
          children: [
            SettingsRow(
              icon: Icons.cloud_download,
              title: '下载源',
              subtitle: _downloadSourceDisplayName(_downloadSource),
              control: SettingsDropdown<String>(
                value: _downloadSource,
                items: const [
                  DropdownMenuItem(value: 'official', child: Text('官方源')),
                  DropdownMenuItem(value: 'mirror', child: Text('镜像源')),
                ],
                onChanged: (value) {
                  if (value != null) _saveDownloadSource(value);
                },
              ),
            ),
            SettingsRow(
              icon: Icons.download,
              title: '下载目录',
              subtitle: _downloadPath.isEmpty ? '未设置' : _downloadPath,
              control: SettingsPathSelector(
                path: _downloadPath,
                placeholder: '未设置',
                buttonText: '浏览',
                onBrowse: _pickDownloadPath,
              ),
            ),
            SettingsRow(
              icon: Icons.refresh,
              title: '下载失败自动重试',
              subtitle: '下载失败时自动重试',
              control: SettingsSwitch(
                value: _autoRetryDownload,
                onChanged: _saveAutoRetryDownload,
              ),
            ),
          ],
        ),
        SettingsCard(
          title: '并发下载设置',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Builder(
                builder: (context) {
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
                          child: Icon(Icons.speed, color: accentBlue, size: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '并发下载数',
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$_concurrentDownloads 个线程',
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
                                value: _concurrentDownloads.toDouble(),
                                min: 1,
                                max: 10,
                                divisions: 9,
                                label: '$_concurrentDownloads',
                                onChanged: (value) {
                                  setState(() {
                                    _concurrentDownloads = value.toInt();
                                  });
                                },
                                onChangeEnd: (value) {
                                  _saveConcurrentDownloads(value.toInt());
                                },
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
              icon: Icons.data_usage,
              title: '限速设置',
              subtitle: _enableSpeedLimit
                  ? '${_speedLimitValue.toInt()} ${_speedLimitUnit == 0 ? "KB/s" : "MB/s"}'
                  : '未启用',
              control: SettingsSwitch(
                value: _enableSpeedLimit,
                onChanged: _saveEnableSpeedLimit,
              ),
            ),
            if (_enableSpeedLimit) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Builder(
                  builder: (context) {
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
                              Icons.speed,
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
                                '限速值',
                                style: TextStyle(
                                  color: primaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${_speedLimitValue.toInt()} ${_speedLimitUnit == 0 ? "KB/s" : "MB/s"}',
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
                                  value: _speedLimitValue,
                                  min: 1,
                                  max: _speedLimitUnit == 0 ? 10240 : 10,
                                  divisions: _speedLimitUnit == 0 ? 100 : 9,
                                  label: '${_speedLimitValue.toInt()}',
                                  onChanged: (value) {
                                    setState(() {
                                      _speedLimitValue = value;
                                    });
                                  },
                                  onChangeEnd: (value) {
                                    _saveSpeedLimitValue(
                                      value,
                                      _speedLimitUnit,
                                    );
                                  },
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
                icon: Icons.timer,
                title: '限速单位',
                subtitle: _speedLimitUnit == 0 ? 'KB/s' : 'MB/s',
                control: SettingsDropdown<int>(
                  value: _speedLimitUnit,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('KB/s')),
                    DropdownMenuItem(value: 1, child: Text('MB/s')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _speedLimitUnit = value;
                        if (value == 1 && _speedLimitValue > 10) {
                          _speedLimitValue = 10;
                        } else if (value == 0 && _speedLimitValue < 1) {
                          _speedLimitValue = 1024;
                        }
                      });
                      _saveSpeedLimitValue(_speedLimitValue, value);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
        SettingsCard(
          title: '镜像源管理',
          children: [
            SettingsRow(
              icon: Icons.auto_fix_high,
              title: '自动选择最快镜像',
              subtitle: '测速所有镜像并自动切换',
              control: SettingsSwitch(
                value: _autoSelectMirror,
                onChanged: _saveAutoSelectMirror,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: SettingsPrimaryButton(
                      text: _isSpeedTesting ? '' : '测速所有镜像',
                      onPressed: _speedTestMirrors,
                      isLoading: _isSpeedTesting,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SettingsSecondaryButton(
                      text: _isSpeedTesting ? '' : '自动选择最快',
                      onPressed: _autoSelectFastestMirror,
                      isLoading: _isSpeedTesting,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SettingsCard(
          title: '镜像列表',
          children: [
            ..._buildMirrorList(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Builder(
                builder: (context) {
                  final primaryText = BAColors.textPrimaryOf(context);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '添加自定义镜像',
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: SettingsTextField(
                              controller: _customMirrorNameController,
                              focusNode: _customMirrorNameFocusNode,
                              placeholder: '名称（可选）',
                              width: 120,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: SettingsTextField(
                              controller: _customMirrorUrlController,
                              focusNode: _customMirrorUrlFocusNode,
                              placeholder: 'https://example.com',
                              width: 250,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SettingsPrimaryButton(
                            text: '添加',
                            onPressed: _addCustomMirror,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        SettingsCard(
          title: '网络设置',
          children: [
            SettingsRow(
              icon: Icons.language,
              title: 'HTTP代理地址',
              subtitle: _proxyHost.isEmpty ? '未设置' : _proxyHost,
              control: SettingsTextField(
                controller: _proxyHostController,
                focusNode: _proxyHostFocusNode,
                placeholder: '例如: 127.0.0.1',
              ),
            ),
            SettingsRow(
              icon: Icons.numbers,
              title: 'HTTP代理端口',
              subtitle: _proxyPort == 0 ? '未设置' : '$_proxyPort',
              control: SettingsTextField(
                controller: _proxyPortController,
                focusNode: _proxyPortFocusNode,
                placeholder: '例如: 7890',
                width: 120,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildMirrorList() {
    final mirrors = _mirrorManager.allMirrors;
    final currentMirrorId = _mirrorManager.currentMirror.id;

    return mirrors.map((mirror) {
      final isSelected = mirror.id == currentMirrorId;
      final speedResult = _speedTestResults
          .where((r) => r.mirror.id == mirror.id)
          .firstOrNull;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Builder(
            builder: (context) {
              final primaryText = BAColors.textPrimaryOf(context);
              final secondaryText = BAColors.textSecondaryOf(context);
              final accentBlue = BAColors.primaryLightOf(context);
              final selectedBg = BAColors.surfaceTertiaryOf(context);
              final defaultBg = BAColors.surfaceOf(context);
              final borderColor = BAColors.borderOf(context);

              return GestureDetector(
                onTap: () => _selectMirror(mirror.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? selectedBg : defaultBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? BAColors.primaryOf(context)
                          : borderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? BAColors.primaryOf(context)
                                : secondaryText,
                            width: 2,
                          ),
                          color: isSelected
                              ? BAColors.primaryOf(context)
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  mirror.name,
                                  style: TextStyle(
                                    color: primaryText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (mirror.isOfficial) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: BAColors.primaryOf(
                                        context,
                                      ).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '官方',
                                      style: TextStyle(
                                        color: accentBlue,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                                if (mirror.isBuiltIn && !mirror.isOfficial) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: BAColors.accentPinkDarkOf(
                                        context,
                                      ).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '内置',
                                      style: TextStyle(
                                        color: BAColors.accentPinkDarkOf(
                                          context,
                                        ),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              mirror.url,
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (speedResult != null) ...[
                        if (speedResult.isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: BAColors.successOf(
                                context,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${speedResult.latencyMs}ms',
                              style: TextStyle(
                                color: BAColors.successOf(context),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: BAColors.accentPinkDarkOf(
                                context,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '不可用',
                              style: TextStyle(
                                color: BAColors.accentPinkDarkOf(context),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                      if (!mirror.isBuiltIn) ...[
                        const SizedBox(width: 8),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _removeCustomMirror(mirror.id),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: BAColors.accentPinkDarkOf(
                                  context,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                color: BAColors.accentPinkDarkOf(context),
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    }).toList();
  }
}
