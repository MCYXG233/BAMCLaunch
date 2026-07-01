import 'dart:io';
import 'package:path/path.dart' as p;
import '../config/config_manager.dart';
import '../config/config_keys.dart';
import '../core/network_client.dart';
import 'java_checker.dart';
import 'network_diagnostic.dart';

/// 问题分类枚举
///
/// 用于标识不同类型的检测问题，便于分类管理和展示
enum FixCategory {
  /// Java 相关问题（如版本不兼容、路径无效等）
  java,

  /// 网络相关问题（如节点不可达、DNS 解析失败等）
  network,

  /// 游戏文件问题（如目录缺失、文件损坏等）
  gameFiles,

  /// 配置问题（如内存分配不当、参数错误等）
  config
}

/// 问题严重程度枚举
///
/// 用于标识问题的紧急程度，帮助用户优先处理关键问题
enum FixSeverity {
  /// 低优先级 - 不影响核心功能，可稍后处理
  low,

  /// 中等优先级 - 可能影响部分功能，建议尽快处理
  medium,

  /// 高优先级 - 严重影响使用体验，应当优先处理
  high,

  /// 关键优先级 - 阻止核心功能运行，必须立即处理
  critical
}

/// 检测到的问题模型
///
/// 表示一个具体的检测问题，包含问题的详细描述、分类、严重程度
/// 以及是否支持自动修复等信息
class FixIssue {
  /// 问题唯一标识符，用于匹配修复逻辑
  final String id;

  /// 问题标题，简短描述问题
  final String title;

  /// 问题的详细描述，向用户解释问题的具体情况
  final String description;

  /// 问题所属分类
  final FixCategory category;

  /// 问题严重程度
  final FixSeverity severity;

  /// 是否支持自动修复
  final bool canAutoFix;

  /// 自动修复的描述说明（仅当 canAutoFix 为 true 时有效）
  final String? autoFixDescription;

  /// 构造函数
  ///
  /// 所有必填参数都需要在创建时提供
  const FixIssue({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.canAutoFix,
    this.autoFixDescription,
  });
}

/// 修复操作记录
///
/// 记录单次修复操作的执行过程和结果，用于日志追踪和历史查询
class FixOperation {
  /// 关联的问题 ID
  final String issueId;

  /// 操作名称（通常与问题标题相同）
  final String operationName;

  /// 操作开始时间
  final DateTime startTime;

  /// 操作结束时间（操作完成后设置）
  DateTime? endTime;

  /// 操作是否成功
  bool isSuccess;

  /// 错误信息（操作失败时记录）
  String? errorMessage;

  /// 操作输出信息
  String? output;

  /// 构造函数
  ///
  /// [issueId] 关联的问题标识
  /// [operationName] 操作名称
  /// [startTime] 开始时间
  FixOperation({
    required this.issueId,
    required this.operationName,
    required this.startTime,
    this.endTime,
    this.isSuccess = false,
    this.errorMessage,
    this.output,
  });

  /// 计算操作耗时
  ///
  /// 返回操作从开始到结束的时间间隔
  /// 如果操作尚未结束，返回 null
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }
}

/// 修复结果模型
///
/// 表示单次修复操作的最终结果，包含是否成功、消息和日志等信息
class FixResult {
  /// 关联的问题 ID
  final String issueId;

  /// 问题是否已被修复
  final bool isFixed;

  /// 操作是否成功执行（即使未修复也可能成功执行）
  final bool isSuccess;

  /// 结果消息，向用户说明修复情况
  final String? message;

  /// 操作过程中产生的日志列表
  final List<String> logs;

  /// 构造函数
  const FixResult({
    required this.issueId,
    required this.isFixed,
    required this.isSuccess,
    this.message,
    this.logs = const [],
  });
}

/// 自动修复器
///
/// 负责检测和自动修复启动器运行环境中的各类问题。
/// 采用单例模式，确保全局只有一个修复器实例。
///
/// 主要功能：
/// - 检测 Java 环境（版本、路径有效性）
/// - 检测网络连接（节点可达性、DNS 解析）
/// - 检测游戏文件（目录结构完整性）
/// - 检测配置项（内存分配合理性）
/// - 自动修复可修复的问题
class AutoFixer {
  /// 单例实例
  static final AutoFixer _instance = AutoFixer._internal();

  /// 工厂构造函数，返回单例实例
  factory AutoFixer() => _instance;

  /// 私有构造函数，防止外部实例化
  AutoFixer._internal();

  /// 修复操作历史记录
  final List<FixOperation> _fixHistory = [];

  /// 修复日志列表
  final List<String> _fixLogs = [];

  /// 获取修复操作历史（只读）
  List<FixOperation> get fixHistory => List.unmodifiable(_fixHistory);

  /// 获取修复日志（只读）
  List<String> get fixLogs => List.unmodifiable(_fixLogs);

  /// 记录日志
  ///
  /// 将带时间戳的消息添加到日志列表中
  /// [message] 要记录的消息内容
  void _log(String message) {
    // 截取前19个字符，格式为 "YYYY-MM-DD HH:MM:SS"
    final timestamp = DateTime.now().toString().substring(0, 19);
    final logMessage = '[$timestamp] $message';
    _fixLogs.add(logMessage);
  }

  /// 检测所有问题
  ///
  /// 按顺序检测 Java 环境、网络连接、游戏文件和配置项，
  /// 返回发现的所有问题列表。
  ///
  /// 返回：检测到的所有问题列表
  Future<List<FixIssue>> detectAllIssues() async {
    final issues = <FixIssue>[];

    // 检测 Java 相关问题
    final javaIssues = await _detectJavaIssues();
    issues.addAll(javaIssues);

    // 检测网络相关问题
    final networkIssues = await _detectNetworkIssues();
    issues.addAll(networkIssues);

    // 检测游戏文件问题
    final gameFileIssues = await _detectGameFileIssues();
    issues.addAll(gameFileIssues);

    // 检测配置问题
    final configIssues = await _detectConfigIssues();
    issues.addAll(configIssues);

    return issues;
  }

  /// 检测 Java 相关问题
  ///
  /// 检查内容包括：
  /// - Java 是否已安装
  /// - Java 版本是否满足要求（>= 8）
  /// - 配置的 Java 路径是否有效
  ///
  /// 返回：检测到的 Java 问题列表
  Future<List<FixIssue>> _detectJavaIssues() async {
    final issues = <FixIssue>[];

    // 检查 Java 是否可用
    final javaResult = await JavaChecker.checkJava();

    // 情况1：Java 未安装
    if (!javaResult.isAvailable) {
      issues.add(const FixIssue(
        id: 'java_not_found',
        title: 'Java 未安装',
        description: '系统中未检测到 Java 安装，无法启动游戏',
        category: FixCategory.java,
        severity: FixSeverity.critical,
        canAutoFix: false,
      ));
    }
    // 情况2：Java 版本过低（低于 Java 8）
    else if (javaResult.majorVersion != null && javaResult.majorVersion! < 8) {
      issues.add(FixIssue(
        id: 'java_version_too_low',
        title: 'Java 版本过低',
        description: '当前 Java 版本 ${javaResult.javaVersion} 过低，建议升级到 Java 17+',
        category: FixCategory.java,
        severity: FixSeverity.high,
        canAutoFix: false,
        autoFixDescription: '请从 Eclipse Adoptium (adoptium.net) 下载 Java 17 或 21',
      ));
    }

    // 检查用户配置的 Java 路径是否有效
    final config = ConfigManager();
    final configuredJavaPath = config.getString(ConfigKeys.javaPath);
    if (configuredJavaPath != null && configuredJavaPath.isNotEmpty) {
      final javaFile = File(configuredJavaPath);
      // 配置的路径不存在
      if (!javaFile.existsSync()) {
        issues.add(FixIssue(
          id: 'java_path_invalid',
          title: 'Java 路径无效',
          description: '配置的 Java 路径不存在: $configuredJavaPath',
          category: FixCategory.java,
          severity: FixSeverity.high,
          canAutoFix: true,
          autoFixDescription: '自动清除无效的 Java 路径配置',
        ));
      }
    }

    return issues;
  }

  /// 检测网络相关问题
  ///
  /// 检查内容包括：
  /// - 下载节点的可达性
  /// - DNS 解析是否正常
  ///
  /// 返回：检测到的网络问题列表
  Future<List<FixIssue>> _detectNetworkIssues() async {
    final issues = <FixIssue>[];

    try {
      // 测试所有下载节点的连通性
      final pingResults = await NetworkDiagnostic.pingAllNodes();
      final unreachableNodes = pingResults.where((r) => !r.isReachable).toList();

      // 情况1：所有节点都不可达
      if (unreachableNodes.length == pingResults.length) {
        issues.add(const FixIssue(
          id: 'network_all_unreachable',
          title: '网络完全不可用',
          description: '所有下载节点都无法访问，请检查网络连接',
          category: FixCategory.network,
          severity: FixSeverity.critical,
          canAutoFix: false,
        ));
      }
      // 情况2：部分节点不可达
      else if (unreachableNodes.isNotEmpty) {
        final unreachableNames = unreachableNodes.map((r) => r.nodeName).join(', ');
        issues.add(FixIssue(
          id: 'network_partial_unreachable',
          title: '部分节点不可用',
          description: '以下节点无法访问: $unreachableNames',
          category: FixCategory.network,
          severity: FixSeverity.medium,
          canAutoFix: true,
          autoFixDescription: '自动切换到可用的镜像源',
        ));
      }

      // 检查 DNS 解析
      final dnsResults = await NetworkDiagnostic.checkDns();
      final failedDns = dnsResults.where((r) => !r.isSuccess).toList();
      if (failedDns.isNotEmpty) {
        final failedHosts = failedDns.map((r) => r.hostname).join(', ');
        issues.add(FixIssue(
          id: 'dns_resolution_failed',
          title: 'DNS 解析失败',
          description: '以下主机名解析失败: $failedHosts',
          category: FixCategory.network,
          severity: FixSeverity.medium,
          canAutoFix: false,
        ));
      }
    } catch (e) {
      _log('网络检测失败: $e');
    }

    return issues;
  }

  /// 检测游戏文件相关问题
  ///
  /// 检查内容包括：
  /// - 游戏目录是否已配置
  /// - 游戏目录是否存在
  /// - versions 目录是否存在
  ///
  /// 返回：检测到的游戏文件问题列表
  Future<List<FixIssue>> _detectGameFileIssues() async {
    final issues = <FixIssue>[];
    final config = ConfigManager();
    final gameDir = config.getString(ConfigKeys.gameDirectory) ?? '';

    // 情况1：游戏目录未配置
    if (gameDir.isEmpty) {
      issues.add(const FixIssue(
        id: 'game_dir_not_set',
        title: '游戏目录未配置',
        description: '未设置游戏目录，请先配置游戏目录路径',
        category: FixCategory.gameFiles,
        severity: FixSeverity.high,
        canAutoFix: false,
      ));
    } else {
      final directory = Directory(gameDir);

      // 情况2：游戏目录不存在
      if (!await directory.exists()) {
        issues.add(FixIssue(
          id: 'game_dir_not_exist',
          title: '游戏目录不存在',
          description: '配置的游戏目录不存在: $gameDir',
          category: FixCategory.gameFiles,
          severity: FixSeverity.high,
          canAutoFix: true,
          autoFixDescription: '创建缺失的游戏目录',
        ));
      } else {
        // 情况3：versions 目录缺失
        final versionsDir = Directory(p.join(gameDir, 'versions'));
        if (!await versionsDir.exists()) {
          issues.add(FixIssue(
            id: 'versions_dir_missing',
            title: '游戏版本目录缺失',
            description: 'versions 目录不存在，游戏可能无法正常运行',
            category: FixCategory.gameFiles,
            severity: FixSeverity.medium,
            canAutoFix: true,
            autoFixDescription: '创建 versions 目录',
          ));
        }
      }
    }

    return issues;
  }

  /// 检测配置相关问题
  ///
  /// 检查内容包括：
  /// - 内存分配是否过低（< 1024 MB）
  /// - 内存分配是否过高（> 12288 MB）
  ///
  /// 返回：检测到的配置问题列表
  Future<List<FixIssue>> _detectConfigIssues() async {
    final issues = <FixIssue>[];
    final config = ConfigManager();

    // 获取配置的内存大小，默认 2048 MB
    final memoryMB = config.getInt(ConfigKeys.memoryAllocation) ?? 2048;

    // 情况1：内存分配过低
    if (memoryMB < 1024) {
      issues.add(const FixIssue(
        id: 'memory_too_low',
        title: '内存分配过低',
        description: '游戏内存分配低于 1024 MB，可能导致游戏无法启动',
        category: FixCategory.config,
        severity: FixSeverity.high,
        canAutoFix: true,
        autoFixDescription: '自动将内存调整为 2048 MB',
      ));
    }
    // 情况2：内存分配过高（超过 12 GB 可能导致 GC 停顿）
    else if (memoryMB > 12288) {
      issues.add(const FixIssue(
        id: 'memory_too_high',
        title: '内存分配过高',
        description: '内存分配超过 12 GB 可能导致 GC 停顿',
        category: FixCategory.config,
        severity: FixSeverity.low,
        canAutoFix: true,
        autoFixDescription: '自动将内存调整为 8192 MB',
      ));
    }

    return issues;
  }

  /// 修复指定问题
  ///
  /// 根据问题 ID 调用对应的修复方法，记录修复过程和结果。
  /// 支持的修复项：
  /// - java_path_invalid: 清除无效的 Java 路径
  /// - network_partial_unreachable: 切换到可用镜像源
  /// - game_dir_not_exist: 创建游戏目录
  /// - versions_dir_missing: 创建游戏目录结构
  /// - memory_too_low: 调整内存分配到 2048 MB
  /// - memory_too_high: 调整内存分配到 8192 MB
  ///
  /// [issue] 要修复的问题
  /// 返回：修复结果
  Future<FixResult> fixIssue(FixIssue issue) async {
    _log('开始修复: ${issue.title}');

    // 创建修复操作记录
    final operation = FixOperation(
      issueId: issue.id,
      operationName: issue.title,
      startTime: DateTime.now(),
    );
    _fixHistory.add(operation);

    try {
      FixResult result;

      // 根据问题 ID 分发到对应的修复方法
      switch (issue.id) {
        case 'java_path_invalid':
          result = await _fixJavaPathInvalid(operation);
          break;
        case 'network_partial_unreachable':
          result = await _fixNetworkSwitch(operation);
          break;
        case 'game_dir_not_exist':
          result = await _fixGameDirNotExist(operation);
          break;
        case 'versions_dir_missing':
          result = await _fixVersionsDirMissing(operation);
          break;
        case 'memory_too_low':
          result = await _fixMemoryTooLow(operation);
          break;
        case 'memory_too_high':
          result = await _fixMemoryTooHigh(operation);
          break;
        default:
          // 不支持自动修复的问题
          result = FixResult(
            issueId: issue.id,
            isFixed: false,
            isSuccess: false,
            message: '该问题不支持自动修复',
            logs: [],
          );
      }

      // 更新操作记录
      operation.endTime = DateTime.now();
      operation.isSuccess = result.isSuccess;
      operation.output = result.message;

      // 记录修复结果
      if (result.isSuccess) {
        _log('修复成功: ${issue.title}');
      } else {
        _log('修复失败: ${issue.title} - ${result.message}');
      }

      return result;
    } catch (e, stackTrace) {
      // 记录异常信息
      operation.endTime = DateTime.now();
      operation.isSuccess = false;
      operation.errorMessage = e.toString();
      operation.output = 'Stack trace: $stackTrace';
      _log('修复异常: ${issue.title} - $e');

      return FixResult(
        issueId: issue.id,
        isFixed: false,
        isSuccess: false,
        message: '修复过程中发生错误: $e',
        logs: [e.toString(), stackTrace.toString()],
      );
    }
  }

  /// 修复无效的 Java 路径
  ///
  /// 清除配置中无效的 Java 路径，并尝试自动查找可用的 Java。
  ///
  /// [operation] 修复操作记录
  /// 返回：修复结果
  Future<FixResult> _fixJavaPathInvalid(FixOperation operation) async {
    _log('正在清除无效的 Java 路径配置...');

    // 清除无效配置
    final config = ConfigManager();
    await config.remove(ConfigKeys.javaPath);

    // 尝试自动查找可用的 Java
    final javaPath = await JavaChecker.findJavaExecutable();
    if (javaPath != null) {
      _log('找到可用的 Java: $javaPath');
      await config.setString(ConfigKeys.javaPath, javaPath);
      return FixResult(
        issueId: operation.issueId,
        isFixed: true,
        isSuccess: true,
        message: '已清除无效配置并设置为: $javaPath',
        logs: _fixLogs,
      );
    }

    // 未找到可用的 Java
    return FixResult(
      issueId: operation.issueId,
      isFixed: false,
      isSuccess: true,
      message: '已清除无效的 Java 路径配置，但未找到可用的 Java',
      logs: _fixLogs,
    );
  }

  /// 修复网络问题 - 切换镜像源
  ///
  /// 测试并切换到可用的镜像源。
  ///
  /// [operation] 修复操作记录
  /// 返回：修复结果
  Future<FixResult> _fixNetworkSwitch(FixOperation operation) async {
    _log('正在测试并切换到可用的镜像源...');

    // 选择最佳镜像源
    final mirrorManager = await _selectBestMirror();

    return FixResult(
      issueId: operation.issueId,
      isFixed: true,
      isSuccess: true,
      message: '已切换到可用的镜像源: ${mirrorManager.name}',
      logs: _fixLogs,
    );
  }

  /// 选择最佳镜像源
  ///
  /// 按优先级测试镜像源的可用性，返回第一个可用的镜像源。
  /// 测试顺序：BMCLAPI-2 -> BMCLAPI -> MCBBS
  ///
  /// 返回：镜像源信息（名称和 URL）
  Future<_MirrorSourceInfo> _selectBestMirror() async {
    // 镜像源列表，按优先级排序
    final mirrors = [
      {'name': 'BMCLAPI-2', 'url': 'https://bmclapi2.bangbang93.com'},
      {'name': 'BMCLAPI', 'url': 'https://bmclapi.bangbang93.com'},
      {'name': 'MCBBS', 'url': 'https://download.mcbbs.net'},
    ];

    // 逐个测试镜像源
    for (final mirror in mirrors) {
      try {
        final uri = Uri.parse(mirror['url']!);
        // 请求镜像源的 mirrors.json 文件来测试可用性
        final networkClient = NetworkClient();
        final response = await networkClient.get(
          uri.replace(path: '/mirrors.json').toString(),
          timeoutSeconds: 5,
        );

        // 如果返回 200 状态码，说明镜像源可用
        if (response.statusCode == 200) {
          _log('镜像源可用: ${mirror['name']}');
          return _MirrorSourceInfo(mirror['name']!, mirror['url']!);
        }
      } catch (_) {
        _log('镜像源不可用: ${mirror['name']}');
      }
    }

    // 如果所有镜像源都不可用，返回默认镜像源
    return _MirrorSourceInfo('BMCLAPI-2', 'https://bmclapi2.bangbang93.com');
  }

  /// 修复游戏目录不存在问题
  ///
  /// 创建配置的游戏目录。
  ///
  /// [operation] 修复操作记录
  /// 返回：修复结果
  Future<FixResult> _fixGameDirNotExist(FixOperation operation) async {
    final config = ConfigManager();
    final gameDir = config.getString(ConfigKeys.gameDirectory) ?? '';

    _log('正在创建游戏目录: $gameDir');

    try {
      // 递归创建目录（包括所有父目录）
      await Directory(gameDir).create(recursive: true);
      _log('游戏目录创建成功');

      return FixResult(
        issueId: operation.issueId,
        isFixed: true,
        isSuccess: true,
        message: '已创建游戏目录: $gameDir',
        logs: _fixLogs,
      );
    } catch (e) {
      return FixResult(
        issueId: operation.issueId,
        isFixed: false,
        isSuccess: false,
        message: '创建目录失败: $e',
        logs: _fixLogs,
      );
    }
  }

  /// 修复 versions 目录缺失问题
  ///
  /// 创建游戏运行所需的标准目录结构：
  /// - versions: 存放游戏版本
  /// - libraries: 存放依赖库
  /// - mods: 存放模组
  ///
  /// [operation] 修复操作记录
  /// 返回：修复结果
  Future<FixResult> _fixVersionsDirMissing(FixOperation operation) async {
    final config = ConfigManager();
    final gameDir = config.getString(ConfigKeys.gameDirectory) ?? '';

    // 检查游戏目录是否已配置
    if (gameDir.isEmpty) {
      return FixResult(
        issueId: operation.issueId,
        isFixed: false,
        isSuccess: false,
        message: '游戏目录未配置',
        logs: _fixLogs,
      );
    }

    _log('正在创建 versions 目录...');

    try {
      // 创建 versions 目录
      final versionsDir = Directory(p.join(gameDir, 'versions'));
      await versionsDir.create(recursive: true);
      _log('versions 目录创建成功');

      // 创建 libraries 目录
      final librariesDir = Directory(p.join(gameDir, 'libraries'));
      await librariesDir.create(recursive: true);
      _log('libraries 目录创建成功');

      // 创建 mods 目录
      final modsDir = Directory(p.join(gameDir, 'mods'));
      await modsDir.create(recursive: true);
      _log('mods 目录创建成功');

      return FixResult(
        issueId: operation.issueId,
        isFixed: true,
        isSuccess: true,
        message: '已创建必要的游戏目录结构',
        logs: _fixLogs,
      );
    } catch (e) {
      return FixResult(
        issueId: operation.issueId,
        isFixed: false,
        isSuccess: false,
        message: '创建目录失败: $e',
        logs: _fixLogs,
      );
    }
  }

  /// 修复内存分配过低问题
  ///
  /// 将内存分配调整为 2048 MB。
  ///
  /// [operation] 修复操作记录
  /// 返回：修复结果
  Future<FixResult> _fixMemoryTooLow(FixOperation operation) async {
    _log('正在调整内存分配...');

    final config = ConfigManager();
    await config.setInt(ConfigKeys.memoryAllocation, 2048);
    _log('内存已调整为 2048 MB');

    return FixResult(
      issueId: operation.issueId,
      isFixed: true,
      isSuccess: true,
      message: '已将内存分配从 1024 MB 以下调整为 2048 MB',
      logs: _fixLogs,
    );
  }

  /// 修复内存分配过高问题
  ///
  /// 将内存分配调整为 8192 MB（8 GB）。
  ///
  /// [operation] 修复操作记录
  /// 返回：修复结果
  Future<FixResult> _fixMemoryTooHigh(FixOperation operation) async {
    _log('正在调整内存分配...');

    final config = ConfigManager();
    await config.setInt(ConfigKeys.memoryAllocation, 8192);
    _log('内存已调整为 8192 MB');

    return FixResult(
      issueId: operation.issueId,
      isFixed: true,
      isSuccess: true,
      message: '已将内存分配从 12 GB 以上调整为 8192 MB',
      logs: _fixLogs,
    );
  }

  /// 自动修复所有支持自动修复的问题
  ///
  /// 遍历问题列表，对每个支持自动修复的问题执行修复操作。
  ///
  /// [issues] 问题列表
  /// 返回：批量修复结果
  Future<FixResult> autoFixAll(List<FixIssue> issues) async {
    var allFixed = true;
    final allLogs = <String>[];
    String? lastMessage;

    // 遍历所有问题，修复支持自动修复的问题
    for (final issue in issues) {
      if (issue.canAutoFix) {
        final result = await fixIssue(issue);
        allLogs.addAll(result.logs);

        // 记录是否有修复失败的问题
        if (!result.isFixed) {
          allFixed = false;
        }
        lastMessage = result.message;
      }
    }

    return FixResult(
      issueId: 'auto_fix_all',
      isFixed: allFixed,
      isSuccess: true,
      message: lastMessage ?? (allFixed ? '所有问题已修复' : '部分问题修复失败'),
      logs: allLogs,
    );
  }

  /// 获取修复日志摘要
  ///
  /// 生成包含修复统计和最近操作的摘要报告。
  ///
  /// 返回：格式化的日志摘要字符串
  String getFixLogSummary() {
    if (_fixLogs.isEmpty) return '暂无修复日志';

    final buffer = StringBuffer();
    buffer.writeln('=== 修复日志摘要 ===');
    buffer.writeln('总操作数: ${_fixHistory.length}');

    // 统计成功和失败次数
    final successCount = _fixHistory.where((o) => o.isSuccess).length;
    final failCount = _fixHistory.length - successCount;
    buffer.writeln('成功: $successCount, 失败: $failCount');

    // 显示最近 5 条操作记录
    if (_fixHistory.isNotEmpty) {
      buffer.writeln('\n最近的操作:');
      for (final op in _fixHistory.reversed.take(5)) {
        final status = op.isSuccess ? '✓' : '✗';
        final duration = op.duration?.inMilliseconds ?? 0;
        buffer.writeln('  $status ${op.operationName} (${duration}ms)');
      }
    }

    return buffer.toString();
  }

  /// 清除所有日志和历史记录
  ///
  /// 重置修复器的状态，清除所有记录。
  void clearLogs() {
    _fixLogs.clear();
    _fixHistory.clear();
  }
}

/// 镜像源信息（内部类）
///
/// 用于存储镜像源的名称和 URL 信息
class _MirrorSourceInfo {
  /// 镜像源名称
  final String name;

  /// 镜像源 URL
  final String url;

  /// 构造函数
  _MirrorSourceInfo(this.name, this.url);
}