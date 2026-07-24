/// Mod 加载器类型（权威枚举）
///
/// 统一全应用对 Mod 加载器（Forge/Fabric/Quilt/NeoForge）的枚举引用，
/// 原 mod/mod_loader_manager.dart 与 loader/loader_download_service.dart
/// 各自维护的 LoaderType 已被合并。
///
/// 该类型与加载器下载、安装、API 适配等逻辑解耦，仅保留：
/// - 枚举值（forge/fabric/quilt/neoforge）
/// - 人类可读的 displayName
///
/// 业务字段（如 installerUrl 等）请使用对应域的 LoaderInfo 模型。
enum LoaderType {
  fabric('Fabric'),
  forge('Forge'),
  quilt('Quilt'),
  neoforge('NeoForge');

  /// 人类可读的展示名称
  final String displayName;

  const LoaderType(this.displayName);

  /// 从字符串解析（大小写不敏感）
  static LoaderType? tryParse(String name) {
    final lower = name.toLowerCase();
    for (final t in values) {
      if (t.name == lower) return t;
    }
    return null;
  }

  /// 从字符串解析，找不到时返回 null
  static LoaderType? fromString(String? name) => tryParse(name ?? '');

  /// 序列化为字符串标识（用于 API/JSON）
  String get id => name;
}