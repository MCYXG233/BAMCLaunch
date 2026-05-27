class ModInfo {
  final String id;
  final String name;
  final String? version;
  final String? author;
  final String? description;
  final String fileName;
  final String filePath;
  final bool isEnabled;
  final String? modLoader;
  final String? modId;
  final List<String> dependencies;
  final DateTime? lastModified;
  final int fileSize;

  const ModInfo({
    required this.id,
    required this.name,
    this.version,
    this.author,
    this.description,
    required this.fileName,
    required this.filePath,
    this.isEnabled = true,
    this.modLoader,
    this.modId,
    this.dependencies = const [],
    this.lastModified,
    this.fileSize = 0,
  });

  ModInfo copyWith({
    String? id,
    String? name,
    String? version,
    String? author,
    String? description,
    String? fileName,
    String? filePath,
    bool? isEnabled,
    String? modLoader,
    String? modId,
    List<String>? dependencies,
    DateTime? lastModified,
    int? fileSize,
  }) {
    return ModInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      author: author ?? this.author,
      description: description ?? this.description,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      isEnabled: isEnabled ?? this.isEnabled,
      modLoader: modLoader ?? this.modLoader,
      modId: modId ?? this.modId,
      dependencies: dependencies ?? this.dependencies,
      lastModified: lastModified ?? this.lastModified,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'author': author,
      'description': description,
      'fileName': fileName,
      'filePath': filePath,
      'isEnabled': isEnabled,
      'modLoader': modLoader,
      'modId': modId,
      'dependencies': dependencies,
      'lastModified': lastModified?.toIso8601String(),
      'fileSize': fileSize,
    };
  }

  factory ModInfo.fromJson(Map<String, dynamic> json) {
    return ModInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String?,
      author: json['author'] as String?,
      description: json['description'] as String?,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      modLoader: json['modLoader'] as String?,
      modId: json['modId'] as String?,
      dependencies: (json['dependencies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
      fileSize: json['fileSize'] as int? ?? 0,
    );
  }
}
