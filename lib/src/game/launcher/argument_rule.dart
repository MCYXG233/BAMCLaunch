import 'dart:io';

/// 操作系统类型
enum OSType {
  windows,
  linux,
  osx,
}

/// 架构类型
enum ArchType {
  x64,
  arm64,
  x86,
}

/// 平台信息
class PlatformInfo {
  /// 操作系统类型
  final OSType os;

  /// 系统架构
  final ArchType arch;

  /// 系统版本（可选，用于正则匹配）
  final String? version;

  /// 操作系统名称（如 "Windows 10"）
  final String? osName;

  /// 操作系统版本号（如 "10.0.19041"）
  final String? osVersion;

  const PlatformInfo({
    required this.os,
    required this.arch,
    this.version,
    this.osName,
    this.osVersion,
  });

  /// 获取当前平台信息
  factory PlatformInfo.current() {
    return PlatformInfo._detect();
  }

  factory PlatformInfo._detect() {
    final platform = Platform.operatingSystem;
    OSType os;
    switch (platform) {
      case 'windows':
        os = OSType.windows;
        break;
      case 'linux':
        os = OSType.linux;
        break;
      case 'macos':
        os = OSType.osx;
        break;
      default:
        os = OSType.windows;
    }

    // 检测架构 - 通过环境变量或路径推断
    ArchType arch = ArchType.x64;  // 默认值

    // 尝试通过环境变量检测
    final archEnv = Platform.environment['PROCESSOR_ARCHITECTURE'] ??
                     Platform.environment['HOSTNAME'] ?? '';

    if (archEnv.contains('arm64') || archEnv.contains('aarch64')) {
      arch = ArchType.arm64;
    } else if (archEnv.contains('x86_64') || archEnv.contains('AMD64')) {
      arch = ArchType.x64;
    } else if (archEnv.contains('x86') || archEnv.contains('i386')) {
      arch = ArchType.x86;
    }

    return PlatformInfo(
      os: os,
      arch: arch,
      osVersion: Platform.operatingSystemVersion,
    );
  }

  /// 创建Windows平台信息
  const PlatformInfo.windows({
    this.arch = ArchType.x64,
    this.version,
    this.osName,
    this.osVersion,
  }) : os = OSType.windows;

  /// 创建Linux平台信息
  const PlatformInfo.linux({
    this.arch = ArchType.x64,
    this.version,
    this.osName,
    this.osVersion,
  }) : os = OSType.linux;

  /// 创建macOS平台信息
  const PlatformInfo.osx({
    this.arch = ArchType.x64,
    this.version,
    this.osName,
    this.osVersion,
  }) : os = OSType.osx;

  @override
  String toString() {
    return 'PlatformInfo(os: $os, arch: $arch, version: $version)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlatformInfo &&
        other.os == os &&
        other.arch == arch;
  }

  @override
  int get hashCode => Object.hash(os, arch);
}

/// 规则动作类型
enum RuleAction {
  allow,
  disallow,
}

/// 平台规则
class PlatformRule {
  /// 规则动作
  final RuleAction action;

  /// 操作系统约束（可选）
  final OSConstraint? os;

  /// 架构约束（可选）
  final ArchConstraint? arch;

  /// 版本约束（可选，支持正则表达式）
  final VersionConstraint? version;

  /// 创建平台规则
  const PlatformRule({
    required this.action,
    this.os,
    this.arch,
    this.version,
  });

  /// 从JSON创建
  factory PlatformRule.fromJson(Map<String, dynamic> json) {
    return PlatformRule(
      action: json['action'] == 'allow' ? RuleAction.allow : RuleAction.disallow,
      os: json['os'] != null ? OSConstraint.fromJson(json['os'] as Map<String, dynamic>) : null,
      arch: json['arch'] != null ? ArchConstraint.fromJson(json['arch'] as Map<String, dynamic>) : null,
      version: json['version'] != null ? VersionConstraint.fromJson(json['version'] as Map<String, dynamic>) : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'action': action.name,
      if (os != null) 'os': os!.toJson(),
      if (arch != null) 'arch': arch!.toJson(),
      if (version != null) 'version': version!.toJson(),
    };
  }
}

/// 操作系统约束
class OSConstraint {
  /// 操作系统名称（windows/linux/osx）
  final String? name;

  /// 版本约束（支持正则）
  final String? version;

  /// 创建操作系统约束
  const OSConstraint({
    this.name,
    this.version,
  });

  /// 从JSON创建
  factory OSConstraint.fromJson(Map<String, dynamic> json) {
    return OSConstraint(
      name: json['name'] as String?,
      version: json['version'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (version != null) 'version': version,
    };
  }

  /// 检查是否匹配给定平台
  bool matches(PlatformInfo platform) {
    if (name != null) {
      switch (name!) {
        case 'windows':
          if (platform.os != OSType.windows) return false;
          break;
        case 'linux':
          if (platform.os != OSType.linux) return false;
          break;
        case 'osx':
        case 'macos':
          if (platform.os != OSType.osx) return false;
          break;
        default:
          // 未知操作系统名称，视为不匹配
          return false;
      }
    }

    if (version != null && platform.version != null) {
      final regex = RegExp(version!);
      if (!regex.hasMatch(platform.version!)) {
        return false;
      }
    }

    return true;
  }
}

/// 架构约束
class ArchConstraint {
  /// 架构名称（x64/arm64/x86）
  final String? name;

  /// 创建架构约束
  const ArchConstraint({
    this.name,
  });

  /// 从JSON创建
  factory ArchConstraint.fromJson(Map<String, dynamic> json) {
    return ArchConstraint(
      name: json['name'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
    };
  }

  /// 检查是否匹配给定架构
  bool matches(PlatformInfo platform) {
    if (name == null) return true;

    switch (name!) {
      case 'x64':
      case 'x86_64':
        return platform.arch == ArchType.x64;
      case 'arm64':
      case 'aarch64':
        return platform.arch == ArchType.arm64;
      case 'x86':
      case 'i386':
        return platform.arch == ArchType.x86;
      default:
        return false;
    }
  }
}

/// 版本约束（支持正则表达式）
class VersionConstraint {
  /// 版本号约束（支持正则表达式）
  final String version;

  /// 创建版本约束
  const VersionConstraint({
    required this.version,
  });

  /// 从JSON创建
  factory VersionConstraint.fromJson(Map<String, dynamic> json) {
    return VersionConstraint(
      version: json['version'] as String,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {'version': version};
  }

  /// 检查是否匹配给定版本
  bool matches(String? platformVersion) {
    if (platformVersion == null) return true;
    final regex = RegExp(version);
    return regex.hasMatch(platformVersion);
  }
}

/// 启动参数规则引擎
class LaunchArgumentRule {
  /// 规则列表
  final List<PlatformRule> rules;

  /// 创建启动参数规则
  const LaunchArgumentRule({
    required this.rules,
  });

  /// 从JSON数组创建
  factory LaunchArgumentRule.fromJsonList(List<dynamic> jsonList) {
    return LaunchArgumentRule(
      rules: jsonList
          .map((json) => PlatformRule.fromJson(json as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 检查给定平台是否匹配此规则
  bool matches(PlatformInfo platform) {
    // 如果没有规则，默认允许
    if (rules.isEmpty) return true;

    // 应用所有规则
    // 规则评估顺序：allow规则让参数可用，disallow规则让参数不可用
    bool result = true;

    for (final rule in rules) {
      if (_ruleMatches(rule, platform)) {
        if (rule.action == RuleAction.allow) {
          result = true;
        } else {
          result = false;
        }
      }
    }

    return result;
  }

  bool _ruleMatches(PlatformRule rule, PlatformInfo platform) {
    // 检查OS约束
    if (rule.os != null && !rule.os!.matches(platform)) {
      return false;
    }

    // 检查架构约束
    if (rule.arch != null && !rule.arch!.matches(platform)) {
      return false;
    }

    // 检查版本约束
    if (rule.version != null && !rule.version!.matches(platform.version)) {
      return false;
    }

    return true;
  }

  /// 将规则应用到参数列表
  /// 返回过滤后的参数列表
  List<T> apply<T>({
    required List<T> arguments,
    required PlatformInfo platform,
    required String Function(T) argumentExtractor,
  }) {
    if (rules.isEmpty) return arguments;

    return arguments.where((arg) {
      return matches(platform);
    }).toList();
  }
}

/// 带有规则的条件参数
class ConditionalArgument {
  /// 参数字符串或值
  final dynamic value;

  /// 规则列表
  final List<PlatformRule> rules;

  /// 创建条件参数
  const ConditionalArgument({
    required this.value,
    required this.rules,
  });

  /// 从JSON创建
  factory ConditionalArgument.fromJson(Map<String, dynamic> json) {
    final rulesJson = json['rules'] as List<dynamic>? ?? [];

    return ConditionalArgument(
      value: json['value'],
      rules: rulesJson
          .map((r) => PlatformRule.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 检查给定平台是否匹配此条件
  bool matches(PlatformInfo platform) {
    if (rules.isEmpty) return true;

    for (final rule in rules) {
      if (_ruleMatches(rule, platform)) {
        if (rule.action == RuleAction.allow) {
          return true;
        }
      }
    }

    return false;
  }

  bool _ruleMatches(PlatformRule rule, PlatformInfo platform) {
    if (rule.os != null && !rule.os!.matches(platform)) {
      return false;
    }
    if (rule.arch != null && !rule.arch!.matches(platform)) {
      return false;
    }
    if (rule.version != null && !rule.version!.matches(platform.version)) {
      return false;
    }
    return true;
  }

  /// 获取实际值
  dynamic getValue(PlatformInfo platform) {
    if (!matches(platform)) {
      return null;
    }
    return value;
  }
}

/// 参数规则评估结果
class ArgumentRuleResult {
  /// 原始参数
  final dynamic originalArgument;

  /// 是否应该包含
  final bool included;

  /// 匹配的平台信息
  final PlatformInfo platform;

  /// 创建评估结果
  const ArgumentRuleResult({
    required this.originalArgument,
    required this.included,
    required this.platform,
  });
}

/// ArgumentBuilder的规则扩展
extension ArgumentBuilderRuleExtension on ArgumentBuilderHelper {
  /// 使用平台规则过滤参数
  static List<String> filterArgumentsWithRules({
    required List<dynamic> arguments,
    required PlatformInfo platform,
  }) {
    final result = <String>[];

    for (final arg in arguments) {
      if (arg is String) {
        result.add(arg);
      } else if (arg is Map<String, dynamic>) {
        final conditionalArg = ConditionalArgument.fromJson(arg);
        final value = conditionalArg.getValue(platform);
        if (value != null) {
          if (value is String) {
            result.add(value);
          } else if (value is List) {
            result.addAll(value.cast<String>());
          }
        }
      }
    }

    return result;
  }
}

/// 辅助类
class ArgumentBuilderHelper {
  // 空实现，仅用于扩展方法
}
