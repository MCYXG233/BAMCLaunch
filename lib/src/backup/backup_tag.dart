import 'dart:convert';
import 'dart:ui';
import '../config/config_manager.dart';
import '../di/service_locator.dart';

/// 备份标签
class BackupTag {
  /// 标签ID
  final String id;

  /// 标签名称
  final String name;

  /// 标签颜色（ARGB值）
  final int colorValue;

  BackupTag({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'colorValue': colorValue,
  };

  factory BackupTag.fromJson(Map<String, dynamic> json) {
    return BackupTag(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: json['colorValue'] as int,
    );
  }

  BackupTag copyWith({
    String? id,
    String? name,
    int? colorValue,
  }) {
    return BackupTag(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Color get color => Color(colorValue);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackupTag && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 预定义标签颜色
class BackupTagColors {
  static const List<int> predefined = [
    0xFF4CAF50, // 绿色
    0xFF2196F3, // 蓝色
    0xFFF44336, // 红色
    0xFFFF9800, // 橙色
    0xFF9C27B0, // 紫色
    0xFF00BCD4, // 青色
    0xFFFFEB3B, // 黄色
    0xFF795548, // 棕色
    0xFF607D8B, // 蓝灰色
    0xFFE91E63, // 粉色
  ];

  static int getRandomColor() {
    return predefined[DateTime.now().millisecondsSinceEpoch % predefined.length];
  }
}

/// 备份标签管理器
class BackupTagManager {
  static BackupTagManager? _instance;

  final ConfigManager _configManager = ConfigManager();

  List<BackupTag> _tags = [];
  bool _initialized = false;

  BackupTagManager._internal();

  factory BackupTagManager() {
    _instance ??= BackupTagManager._internal();
    return _instance!;
  }

  /// 获取单例实例
  static BackupTagManager get instance =>
      ServiceLocator.instance.tryGet<BackupTagManager>() ??
      (_instance ??= BackupTagManager._internal());

  /// 初始化
  Future<void> initialize() async {
    if (_initialized) return;
    await _loadTags();
    _initialized = true;
  }

  /// 加载标签
  Future<void> _loadTags() async {
    final tagsJson = _configManager.getString('backupTags');
    if (tagsJson != null) {
      try {
        final List<dynamic> tagsList = jsonDecode(tagsJson);
        _tags = tagsList
            .map((e) => BackupTag.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        _tags = [];
      }
    }
  }

  /// 保存标签
  Future<void> _saveTags() async {
    final tagsJson = jsonEncode(_tags.map((t) => t.toJson()).toList());
    await _configManager.setString('backupTags', tagsJson);
  }

  /// 获取所有标签
  List<BackupTag> get tags => List.unmodifiable(_tags);

  /// 获取标签
  BackupTag? getTag(String id) {
    try {
      return _tags.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 创建标签
  Future<BackupTag> createTag({
    required String name,
    int? colorValue,
  }) async {
    final id = 'tag_${DateTime.now().millisecondsSinceEpoch}';
    final tag = BackupTag(
      id: id,
      name: name,
      colorValue: colorValue ?? BackupTagColors.getRandomColor(),
    );

    _tags.add(tag);
    await _saveTags();
    return tag;
  }

  /// 更新标签
  Future<void> updateTag(BackupTag tag) async {
    final index = _tags.indexWhere((t) => t.id == tag.id);
    if (index >= 0) {
      _tags[index] = tag;
      await _saveTags();
    }
  }

  /// 删除标签
  Future<void> deleteTag(String id) async {
    _tags.removeWhere((t) => t.id == id);
    await _saveTags();
  }

  /// 为备份添加标签
  Future<void> addTagToBackup(String backupId, String tagId) async {
    final backupTagsJson = _configManager.getString('backupTagsMap') ?? '{}';
    try {
      final Map<String, dynamic> backupTags = jsonDecode(backupTagsJson);
      final List<dynamic> tags = backupTags[backupId] ?? [];
      if (!tags.contains(tagId)) {
        tags.add(tagId);
        backupTags[backupId] = tags;
        await _configManager.setString('backupTagsMap', jsonEncode(backupTags));
      }
    } catch (e) {
      final Map<String, dynamic> backupTags = {};
      backupTags[backupId] = [tagId];
      await _configManager.setString('backupTagsMap', jsonEncode(backupTags));
    }
  }

  /// 从备份移除标签
  Future<void> removeTagFromBackup(String backupId, String tagId) async {
    final backupTagsJson = _configManager.getString('backupTagsMap') ?? '{}';
    try {
      final Map<String, dynamic> backupTags = jsonDecode(backupTagsJson);
      final List<dynamic> tags = backupTags[backupId] ?? [];
      tags.remove(tagId);
      backupTags[backupId] = tags;
      await _configManager.setString('backupTagsMap', jsonEncode(backupTags));
    } catch (e) {
      // Ignore
    }
  }

  /// 获取备份的所有标签
  List<String> getBackupTags(String backupId) {
    try {
      final backupTagsJson = _configManager.getString('backupTagsMap') ?? '{}';
      final Map<String, dynamic> backupTags = jsonDecode(backupTagsJson);
      return List<String>.from(backupTags[backupId] ?? []);
    } catch (e) {
      return [];
    }
  }

  /// 按标签筛选备份
  List<String> filterBackupsByTag(String tagId) {
    try {
      final backupTagsJson = _configManager.getString('backupTagsMap') ?? '{}';
      final Map<String, dynamic> backupTags = jsonDecode(backupTagsJson);
      final result = <String>[];
      backupTags.forEach((backupId, tags) {
        if ((tags as List).contains(tagId)) {
          result.add(backupId);
        }
      });
      return result;
    } catch (e) {
      return [];
    }
  }

  /// 清除备份的所有标签
  Future<void> clearBackupTags(String backupId) async {
    final backupTagsJson = _configManager.getString('backupTagsMap') ?? '{}';
    try {
      final Map<String, dynamic> backupTags = jsonDecode(backupTagsJson);
      backupTags.remove(backupId);
      await _configManager.setString('backupTagsMap', jsonEncode(backupTags));
    } catch (e) {
      // Ignore
    }
  }
}
