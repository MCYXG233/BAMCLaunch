import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../../diagnostic/java_checker.dart';
import '../../diagnostic/crash_analyzer.dart';
import '../../diagnostic/log_analyzer.dart';
import '../../game/launcher/game_launcher.dart';
import '../../game/launcher/models.dart';
import '../../config/config_manager.dart';
import '../../config/config_keys.dart';

enum DiagnosticStatus { pending, running, passed, warning, failed }

class _DiagnosticItem {
  final String title;
  final String description;
  DiagnosticStatus status;
  String? detail;
  List<String> suggestions;

  _DiagnosticItem({
    required this.title,
    required this.description,
    this.status = DiagnosticStatus.pending,
    this.detail,
    this.suggestions = const [],
  });
}

class BADiagnosticPage extends StatefulWidget {
  final String? processId;

  const BADiagnosticPage({super.key, this.processId});

  @override
  State<BADiagnosticPage> createState() => _BADiagnosticPageState();
}

class _BADiagnosticPageState extends State<BADiagnosticPage>
    with TickerProviderStateMixin {
  bool _isRunning = false;
  bool _isDone = false;
  CrashAnalysis? _crashAnalysis;
  LogAnalysisResult? _logAnalysis;

  final List<_DiagnosticItem> _items = [
    _DiagnosticItem(
      title: 'Java 环境检查',
      description: '检查 Java 是否安装及版本兼容性',
    ),
    _DiagnosticItem(
      title: '内存配置检查',
      description: '检查游戏内存分配是否合理',
    ),
    _DiagnosticItem(
      title: '磁盘空间检查',
      description: '检查游戏目录剩余空间',
    ),
    _DiagnosticItem(
      title: '模组兼容性检查',
      description: '分析游戏日志检查模组问题',
    ),
  ];

  final Map<int, bool> _expanded = {};
  final Map<int, AnimationController> _animControllers = {};

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _items.length; i++) {
      _animControllers[i] = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _animControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleExpand(int index) {
    setState(() {
      if (_expanded[index] == true) {
        _expanded[index] = false;
        _animControllers[index]!.reverse();
      } else {
        _expanded[index] = true;
        _animControllers[index]!.forward();
      }
    });
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _isRunning = true;
      _isDone = false;
      _crashAnalysis = null;
      _logAnalysis = null;
      for (final item in _items) {
        item.status = DiagnosticStatus.running;
      }
    });

    await _checkJava();
    await _checkMemory();
    await _checkDiskSpace();
    await _checkModCompatibility();

    setState(() {
      _isRunning = false;
      _isDone = true;
    });
  }

  Future<void> _checkJava() async {
    try {
      final result = await JavaChecker.checkJava();
      if (!mounted) return;

      setState(() {
        if (result.isAvailable) {
          final versionInfo = result.javaVersion ?? '未知版本';
          final bitInfo = result.is64Bit == true ? '64位' : '32位';
          final pathInfo = result.javaPath ?? '';

          _items[0].status = DiagnosticStatus.passed;
          _items[0].detail =
              'Java $versionInfo ($bitInfo)\n路径: $pathInfo';

          if (result.majorVersion != null && result.majorVersion! < 8) {
            _items[0].status = DiagnosticStatus.warning;
            _items[0].detail =
                'Java $versionInfo 版本过低，建议升级到 Java 17+\n路径: $pathInfo';
            _items[0].suggestions = [
              '当前 Java 版本较低，可能无法运行较新的游戏版本',
              '建议从 Eclipse Adoptium (https://adoptium.net) 下载 Java 17 或 21',
            ];
          }
        } else {
          _items[0].status = DiagnosticStatus.failed;
          _items[0].detail = result.errorMessage ?? '未检测到 Java';
          _items[0].suggestions = [
            '请安装 Java 8 或更高版本',
            '推荐从 Eclipse Adoptium (https://adoptium.net) 下载',
            '安装后在设置中配置 Java 路径',
          ];
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items[0].status = DiagnosticStatus.failed;
        _items[0].detail = '检查过程中发生错误: $e';
      });
    }
  }

  Future<void> _checkMemory() async {
    try {
      final config = ConfigManager();
      final memoryMB = config.getInt(ConfigKeys.memoryAllocation) ?? 2048;
      final systemMemoryMB = _getSystemMemoryMB();

      if (!mounted) return;

      final suggestions = <String>[];
      var status = DiagnosticStatus.passed;
      var detail = '当前分配: ${memoryMB} MB';

      if (systemMemoryMB > 0) {
        detail += '\n系统总内存: ${systemMemoryMB} MB';
        final ratio = memoryMB / systemMemoryMB;

        if (ratio > 0.8) {
          status = DiagnosticStatus.warning;
          detail += '\n内存分配占比过高 (${(ratio * 100).toStringAsFixed(0)}%)';
          suggestions.add(
              '内存分配不应超过系统总内存的 75%，建议设置为 ${(systemMemoryMB * 0.6).toInt()} MB');
        }
      }

      if (memoryMB < 2048) {
        status = DiagnosticStatus.warning;
        detail += '\n内存分配偏低';
        suggestions.add('建议将内存分配至少设为 2048 MB 以获得更好的游戏体验');
        if (memoryMB < 1024) {
          status = DiagnosticStatus.failed;
          detail += '（严重不足）';
          suggestions.add('内存分配低于 1024 MB，游戏可能无法正常启动');
        }
      }

      if (memoryMB > 12288) {
        status = DiagnosticStatus.warning;
        detail += '\n内存分配较高';
        suggestions.add('分配超过 12 GB 可能导致 GC 停顿，建议控制在 4-8 GB');
      }

      setState(() {
        _items[1].status = status;
        _items[1].detail = detail;
        _items[1].suggestions = suggestions;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items[1].status = DiagnosticStatus.warning;
        _items[1].detail = '无法读取内存配置: $e';
      });
    }
  }

  int _getSystemMemoryMB() {
    try {
      final info = Process.runSync('wmic', ['OS', 'get', 'TotalVisibleMemorySize', '/Value']);
      final output = info.stdout.toString();
      final match = RegExp(r'TotalVisibleMemorySize=(\d+)').firstMatch(output);
      if (match != null) {
        final kb = int.parse(match.group(1)!);
        return (kb / 1024).round();
      }
    } catch (_) {}
    return 0;
  }

  Future<void> _checkDiskSpace() async {
    try {
      final config = ConfigManager();
      String gameDir = config.getString(ConfigKeys.gameDirectory) ?? '';

      if (gameDir.isEmpty) {
        if (!mounted) return;
        setState(() {
          _items[2].status = DiagnosticStatus.warning;
          _items[2].detail = '未配置游戏目录，无法检查磁盘空间';
          _items[2].suggestions = ['请在设置中配置游戏目录路径'];
        });
        return;
      }

      final directory = Directory(gameDir);
      if (!await directory.exists()) {
        if (!mounted) return;
        setState(() {
          _items[2].status = DiagnosticStatus.warning;
          _items[2].detail = '游戏目录不存在: $gameDir';
          _items[2].suggestions = ['请检查游戏目录配置是否正确'];
        });
        return;
      }

      final freeSpaceGB = await _getFreeDiskSpaceGB(gameDir);

      if (!mounted) return;

      if (freeSpaceGB < 0) {
        setState(() {
          _items[2].status = DiagnosticStatus.warning;
          _items[2].detail = '无法获取磁盘空间信息';
        });
        return;
      }

      var status = DiagnosticStatus.passed;
      var detail = '游戏目录: $gameDir\n剩余空间: ${freeSpaceGB.toStringAsFixed(1)} GB';
      final suggestions = <String>[];

      if (freeSpaceGB < 1) {
        status = DiagnosticStatus.failed;
        detail += '\n磁盘空间严重不足！';
        suggestions.add('请清理磁盘空间，至少保留 2 GB 以上');
        suggestions.add('可以删除不需要的游戏版本和旧的模组来释放空间');
      } else if (freeSpaceGB < 5) {
        status = DiagnosticStatus.warning;
        detail += '\n磁盘空间偏低';
        suggestions.add('建议保留至少 10 GB 空间用于游戏数据和模组');
      }

      setState(() {
        _items[2].status = status;
        _items[2].detail = detail;
        _items[2].suggestions = suggestions;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items[2].status = DiagnosticStatus.warning;
        _items[2].detail = '检查磁盘空间时出错: $e';
      });
    }
  }

  Future<double> _getFreeDiskSpaceGB(String pathStr) async {
    try {
      final result = await Process.run('wmic', [
        'logicaldisk',
        'where',
        'DeviceID="${pathStr.substring(0, 2)}"',
        'get',
        'FreeSpace',
        '/Value',
      ]);
      final output = result.stdout.toString();
      final match = RegExp(r'FreeSpace=(\d+)').firstMatch(output);
      if (match != null) {
        final bytes = int.parse(match.group(1)!);
        return bytes / (1024 * 1024 * 1024);
      }
    } catch (_) {}
    return -1;
  }

  Future<void> _checkModCompatibility() async {
    try {
      List<String> logLines = [];

      if (widget.processId != null) {
        final launcher = GameLauncher();
        final processInfo = launcher.runningProcesses[widget.processId];
        if (processInfo != null) {
          logLines = processInfo.logs.map((l) => l.format()).toList();
        }
      }

      if (logLines.isEmpty) {
        if (!mounted) return;
        setState(() {
          _items[3].status = DiagnosticStatus.passed;
          _items[3].detail = widget.processId != null
              ? '未找到关联的日志数据'
              : '未指定进程，跳过日志分析';
          _items[3].suggestions = widget.processId != null
              ? ['进程可能已结束，日志数据已被清理']
              : ['启动游戏后可以分析该进程的日志'];
        });
        return;
      }

      _logAnalysis = LogAnalyzer.analyze(logLines);

      if (widget.processId != null) {
        final launcher = GameLauncher();
        final processInfo = launcher.runningProcesses[widget.processId];
        final exitCode = processInfo?.exitCode?.toString();
        final status = processInfo?.status;

        if (status == GameProcessStatus.crashed) {
          _crashAnalysis = CrashAnalyzer.analyze(exitCode, logLines);
        }
      }

      if (!mounted) return;

      final analysis = _logAnalysis!;
      DiagnosticStatus status;
      String detail;
      List<String> suggestions = [];

      if (_crashAnalysis != null) {
        status = DiagnosticStatus.failed;
        detail = '崩溃类型: ${_crashAnalysis!.title}\n${_crashAnalysis!.description}';
        suggestions = _crashAnalysis!.suggestions;
      } else if (analysis.hasErrors) {
        status = DiagnosticStatus.warning;
        detail = '${analysis.summary}\n发现 ${analysis.errorCount} 个错误';
        final errorIssues =
            analysis.issues.where((i) => i.severity == 'error').take(3);
        for (final issue in errorIssues) {
          detail += '\n  · ${issue.message}';
          if (issue.suggestion != null) {
            suggestions.add(issue.suggestion!);
          }
        }
      } else if (analysis.hasIssues) {
        status = DiagnosticStatus.warning;
        detail = analysis.summary;
        for (final issue in analysis.issues.where((i) => i.suggestion != null).take(3)) {
          suggestions.add(issue.suggestion!);
        }
      } else {
        status = DiagnosticStatus.passed;
        detail = analysis.summary;
      }

      setState(() {
        _items[3].status = status;
        _items[3].detail = detail;
        _items[3].suggestions = suggestions;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items[3].status = DiagnosticStatus.warning;
        _items[3].detail = '日志分析过程中出错: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BAColors.backgroundOf(context),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _buildBody(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        border: Border(
          bottom: BorderSide(
            color: BAColors.borderOf(context).withOpacity(0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: BAColors.primaryOf(context).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: BAColors.textSecondaryOf(context), size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [BAColors.primaryOf(context), BAColors.primaryLightOf(context)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: BAColors.primaryOf(context).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.build_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            '系统诊断',
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.processId != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: BAColors.primaryOf(context).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '进程 ${widget.processId}',
                style: TextStyle(
                  color: BAColors.primaryOf(context),
                  fontSize: 11,
                ),
              ),
            ),
          ],
          const Spacer(),
          _buildStartButton(context),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _isRunning ? null : _runDiagnostic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: _isRunning
                ? null
                : LinearGradient(
                    colors: [BAColors.primaryOf(context), BAColors.primaryLightOf(context)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: _isRunning ? BAColors.surfaceVariantOf(context) : null,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isRunning
                  ? BAColors.borderOf(context)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isRunning)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: BAColors.primaryOf(context),
                  ),
                )
              else
                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                _isRunning ? '诊断中...' : '开始诊断',
                style: TextStyle(
                  color: _isRunning
                      ? BAColors.textSecondaryOf(context)
                      : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(_items.length, (index) => _buildDiagnosticCard(context, index)),
          if (_isDone) ...[
            const SizedBox(height: 24),
            _buildSummary(context),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDiagnosticCard(BuildContext context, int index) {
    final item = _items[index];
    final isExpanded = _expanded[index] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        cursor: item.status == DiagnosticStatus.pending
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: item.status == DiagnosticStatus.pending
              ? null
              : () => _toggleExpand(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: BAColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getBorderColor(context, item.status).withOpacity(0.6),
                width: item.status == DiagnosticStatus.running ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getBorderColor(context, item.status).withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      _buildStatusIcon(context, item.status),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                color: BAColors.textPrimaryOf(context),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.status == DiagnosticStatus.running
                                  ? '正在检查...'
                                  : item.description,
                              style: TextStyle(
                                color: item.status == DiagnosticStatus.running
                                    ? BAColors.infoOf(context)
                                    : BAColors.textSecondaryOf(context),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.status == DiagnosticStatus.running)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: BAColors.infoOf(context),
                          ),
                        )
                      else if (item.status != DiagnosticStatus.pending &&
                          item.detail != null)
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            Icons.expand_more_rounded,
                            color: BAColors.textSecondaryOf(context),
                            size: 22,
                          ),
                        ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: isExpanded && item.detail != null
                      ? _buildExpandedContent(context, item)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, _DiagnosticItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: BAColors.borderOf(context).withOpacity(0.5), height: 1),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BAColors.surfaceVariantOf(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: BAColors.borderOf(context).withOpacity(0.4),
              ),
            ),
            child: Text(
              item.detail!,
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 13,
                height: 1.5,
                fontFamily: 'monospace',
              ),
            ),
          ),
          if (item.suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '修复建议:',
              style: TextStyle(
                color: BAColors.textPrimaryOf(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...item.suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Icon(
                          Icons.circle,
                          size: 5,
                          color: BAColors.primaryOf(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s,
                          style: TextStyle(
                            color: BAColors.textSecondaryOf(context),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context, DiagnosticStatus status) {
    switch (status) {
      case DiagnosticStatus.pending:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: BAColors.surfaceVariantOf(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.hourglass_empty_rounded,
            color: BAColors.textDisabledOf(context),
            size: 20,
          ),
        );
      case DiagnosticStatus.running:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: BAColors.infoOf(context).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            width: 20,
            height: 20,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: BAColors.infoOf(context),
              ),
            ),
          ),
        );
      case DiagnosticStatus.passed:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: BAColors.successOf(context).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.check_circle_rounded,
            color: BAColors.successOf(context),
            size: 20,
          ),
        );
      case DiagnosticStatus.warning:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: BAColors.warningOf(context).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            color: BAColors.warningOf(context),
            size: 20,
          ),
        );
      case DiagnosticStatus.failed:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: BAColors.dangerOf(context).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.error_rounded,
            color: BAColors.dangerOf(context),
            size: 20,
          ),
        );
    }
  }

  Color _getBorderColor(BuildContext context, DiagnosticStatus status) {
    switch (status) {
      case DiagnosticStatus.pending:
        return BAColors.borderOf(context).withOpacity(0.5);
      case DiagnosticStatus.running:
        return BAColors.infoOf(context).withOpacity(0.6);
      case DiagnosticStatus.passed:
        return BAColors.successOf(context).withOpacity(0.3);
      case DiagnosticStatus.warning:
        return BAColors.warningOf(context).withOpacity(0.3);
      case DiagnosticStatus.failed:
        return BAColors.dangerOf(context).withOpacity(0.3);
    }
  }

  Widget _buildSummary() {
    final passed = _items.where((i) => i.status == DiagnosticStatus.passed).length;
    final warnings = _items.where((i) => i.status == DiagnosticStatus.warning).length;
    final failed = _items.where((i) => i.status == DiagnosticStatus.failed).length;

    Color overallColor;
    String overallText;
    IconData overallIcon;

    if (failed > 0) {
      overallColor = BAThemeColors.danger;
      overallText = '发现 $failed 个严重问题';
      overallIcon = Icons.error_rounded;
    } else if (warnings > 0) {
      overallColor = BAThemeColors.warning;
      overallText = '发现 $warnings 个需要关注的问题';
      overallIcon = Icons.warning_amber_rounded;
    } else {
      overallColor = BAThemeColors.success;
      overallText = '所有检查项目通过';
      overallIcon = Icons.check_circle_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            overallColor.withOpacity(0.08),
            overallColor.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: overallColor.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(overallIcon, color: overallColor, size: 24),
              const SizedBox(width: 10),
              Text(
                '诊断报告',
                style: TextStyle(
                  color: overallColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            overallText,
            style: const TextStyle(
              color: BAThemeColors.textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSummaryBadge('通过', passed, BAThemeColors.success),
              const SizedBox(width: 8),
              _buildSummaryBadge('警告', warnings, BAThemeColors.warning),
              const SizedBox(width: 8),
              _buildSummaryBadge('失败', failed, BAThemeColors.danger),
            ],
          ),
          if (_crashAnalysis != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: BAThemeColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: BAThemeColors.danger.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '崩溃分析: ${_crashAnalysis!.title}',
                    style: const TextStyle(
                      color: BAThemeColors.danger,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _crashAnalysis!.description,
                    style: const TextStyle(
                      color: BAThemeColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
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

  Widget _buildSummaryBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
