import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import '../../core/logger.dart';
import '../../platform/platform_adapter.dart';
import '../../platform/platform_adapter_factory.dart';

/// 披风数据模型
class CapeData {
  /// 披风图像数据
  final Uint8List imageData;

  /// 披风文件路径
  final String? filePath;

  /// 披风名称
  final String name;

  /// 披风哈希值
  final String hash;

  /// 创建时间
  final DateTime createdAt;

  /// 关联的账户ID
  final String accountId;

  CapeData({
    required this.imageData,
    this.filePath,
    required this.name,
    required this.hash,
    required this.createdAt,
    required this.accountId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'hash': hash,
      'createdAt': createdAt.toIso8601String(),
      'accountId': accountId,
      'filePath': filePath,
    };
  }

  factory CapeData.fromJson(Map<String, dynamic> json) {
    return CapeData(
      imageData: Uint8List(0), // 图像数据不存储在JSON中
      filePath: json['filePath'] as String?,
      name: json['name'] as String,
      hash: json['hash'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      accountId: json['accountId'] as String,
    );
  }
}

/// 披风验证结果
class CapeValidationResult {
  /// 是否有效
  final bool isValid;

  /// 错误信息
  final String? errorMessage;

  /// 图像尺寸
  final int width;

  /// 图像高度
  final int height;

  CapeValidationResult({
    required this.isValid,
    this.errorMessage,
    this.width = 0,
    this.height = 0,
  });
}

/// 披风管理器
/// 负责披风的上传、验证、存储和管理
class CapeManager {
  static CapeManager? _instance;
  final Logger _logger = Logger('CapeManager');
  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();

  /// 披风目录
  Directory? _capeDir;

  /// 披风元数据缓存
  final Map<String, CapeData> _capeCache = {};

  /// 披风元数据文件
  File? _metadataFile;

  /// 必需的披风尺寸
  static const int requiredWidth = 64;
  static const int requiredHeight = 32;

  CapeManager._internal();

  static CapeManager get instance {
    _instance ??= CapeManager._internal();
    return _instance!;
  }

  factory CapeManager() => instance;

  /// 初始化披风管理器
  Future<void> initialize() async {
    if (_capeDir != null) return;

    try {
      final supportDir = await _platformAdapter.getApplicationSupportDirectory();
      _capeDir = Directory(path.join(supportDir, 'capes'));

      if (!await _capeDir!.exists()) {
        await _capeDir!.create(recursive: true);
      }

      // 加载元数据
      await _loadMetadata();

      _logger.info('Cape manager initialized, cape dir: ${_capeDir!.path}');
    } catch ( e, stackTrace) {
      _logger.error('Failed to initialize cape manager', e, stackTrace);
    }
  }

  /// 加载元数据
  Future<void> _loadMetadata() async {
    if (_capeDir == null) return;

    _metadataFile = File(path.join(_capeDir!.path, 'capes_metadata.json'));

    if (!await _metadataFile!.exists()) {
      return;
    }

    try {
      final content = await _metadataFile!.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);

      for (final json in jsonList) {
        final capeData = CapeData.fromJson(json as Map<String, dynamic>);
        _capeCache[capeData.accountId] = capeData;
      }

      _logger.info('Loaded ${_capeCache.length} cape metadata entries');
    } catch (e) {
      _logger.warn('Failed to load cape metadata: $e');
    }
  }

  /// 保存元数据
  Future<void> _saveMetadata() async {
    if (_metadataFile == null || _capeDir == null) return;

    try {
      final jsonList = _capeCache.values.map((c) => c.toJson()).toList();
      await _metadataFile!.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      _logger.error('Failed to save cape metadata', e);
    }
  }

  /// 验证披风图像
  /// [imageData] 披风图像数据
  /// [fileName] 文件名（用于错误信息）
  Future<CapeValidationResult> validateCape(Uint8List imageData, String fileName) async {
    // 检查文件大小
    if (imageData.isEmpty) {
      return CapeValidationResult(
        isValid: false,
        errorMessage: '披风文件为空',
      );
    }

    // 检查文件大小限制（最大100KB）
    if (imageData.length > 100 * 1024) {
      return CapeValidationResult(
        isValid: false,
        errorMessage: '披风文件过大（最大100KB）',
      );
    }

    // 检查是否为PNG格式
    if (imageData.length < 8) {
      return CapeValidationResult(
        isValid: false,
        errorMessage: '文件格式无效',
      );
    }

    // PNG文件签名检查
    final pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];
    for (int i = 0; i < 8; i++) {
      if (imageData[i] != pngSignature[i]) {
        return CapeValidationResult(
          isValid: false,
          errorMessage: '仅支持PNG格式',
        );
      }
    }

    // 解析PNG IHDR chunk获取尺寸
    try {
      final dimensions = _parsePngDimensions(imageData);

      // 验证尺寸
      if (dimensions['width'] != requiredWidth || dimensions['height'] != requiredHeight) {
        return CapeValidationResult(
          isValid: false,
          errorMessage: '披风尺寸必须为 ${requiredWidth}x$requiredHeight 像素',
          width: dimensions['width'] ?? 0,
          height: dimensions['height'] ?? 0,
        );
      }

      return CapeValidationResult(
        isValid: true,
        width: dimensions['width']!,
        height: dimensions['height']!,
      );
    } catch (e) {
      return CapeValidationResult(
        isValid: false,
        errorMessage: '无法读取PNG图像信息',
      );
    }
  }

  /// 解析PNG尺寸
  Map<String, int> _parsePngDimensions(Uint8List data) {
    // PNG尺寸在IHDR chunk中，位于签名后的第16-23字节
    // width: 4 bytes (big-endian)
    // height: 4 bytes (big-endian)
    final width = (data[16] << 24) | (data[17] << 16) | (data[18] << 8) | data[19];
    final height = (data[20] << 24) | (data[21] << 16) | (data[22] << 8) | data[23];

    return {'width': width, 'height': height};
  }

  /// 上传披风
  /// [accountId] 账户ID
  /// [imageData] 披风图像数据
  /// [fileName] 原始文件名
  Future<CapeData?> uploadCape(String accountId, Uint8List imageData, String fileName) async {
    await initialize();

    // 验证披风
    final validation = await validateCape(imageData, fileName);
    if (!validation.isValid) {
      _logger.warn('Cape validation failed: ${validation.errorMessage}');
      return null;
    }

    try {
      // 计算哈希值
      final hash = sha1.convert(imageData).toString();

      // 生成存储文件名
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storedFileName = '${accountId}_$timestamp.png';
      final filePath = path.join(_capeDir!.path, storedFileName);

      // 保存文件
      final file = File(filePath);
      await file.writeAsBytes(imageData);

      // 创建披风数据
      final capeData = CapeData(
        imageData: imageData,
        filePath: filePath,
        name: fileName,
        hash: hash,
        createdAt: DateTime.now(),
        accountId: accountId,
      );

      // 更新缓存和元数据
      _capeCache[accountId] = capeData;
      await _saveMetadata();

      _logger.info('Cape uploaded successfully for account: $accountId');
      return capeData;
    } catch (e, stackTrace) {
      _logger.error('Failed to upload cape', e, stackTrace);
      return null;
    }
  }

  /// 从文件上传披风
  /// [accountId] 账户ID
  /// [filePath] 文件路径
  Future<CapeData?> uploadCapeFromFile(String accountId, String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _logger.warn('Cape file not found: $filePath');
        return null;
      }

      final imageData = await file.readAsBytes();
      final fileName = path.basename(filePath);

      return await uploadCape(accountId, imageData, fileName);
    } catch (e, stackTrace) {
      _logger.error('Failed to upload cape from file', e, stackTrace);
      return null;
    }
  }

  /// 获取账户的披风
  /// [accountId] 账户ID
  Future<CapeData?> getCape(String accountId) async {
    await initialize();

    if (!_capeCache.containsKey(accountId)) {
      return null;
    }

    final capeData = _capeCache[accountId]!;

    // 如果图像数据为空，尝试从文件加载
    if (capeData.imageData.isEmpty && capeData.filePath != null) {
      try {
        final file = File(capeData.filePath!);
        if (await file.exists()) {
          final imageData = await file.readAsBytes();
          return CapeData(
            imageData: imageData,
            filePath: capeData.filePath,
            name: capeData.name,
            hash: capeData.hash,
            createdAt: capeData.createdAt,
            accountId: capeData.accountId,
          );
        }
      } catch (e) {
        _logger.warn('Failed to load cape image: $e');
      }
    }

    return capeData;
  }

  /// 获取披风图像数据
  Future<Uint8List?> getCapeImage(String accountId) async {
    final cape = await getCape(accountId);
    return cape?.imageData;
  }

  /// 删除披风
  /// [accountId] 账户ID
  Future<bool> deleteCape(String accountId) async {
    await initialize();

    if (!_capeCache.containsKey(accountId)) {
      return true;
    }

    try {
      final capeData = _capeCache[accountId]!;

      // 删除文件
      if (capeData.filePath != null) {
        final file = File(capeData.filePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // 从缓存移除
      _capeCache.remove(accountId);
      await _saveMetadata();

      _logger.info('Cape deleted for account: $accountId');
      return true;
    } catch (e, stackTrace) {
      _logger.error('Failed to delete cape', e, stackTrace);
      return false;
    }
  }

  /// 列出所有披风
  Future<List<CapeData>> listCapes() async {
    await initialize();
    return _capeCache.values.toList();
  }

  /// 检查账户是否有披风
  Future<bool> hasCape(String accountId) async {
    await initialize();
    return _capeCache.containsKey(accountId);
  }

  /// 获取披风存储目录
  Future<String> getCapeDirectory() async {
    await initialize();
    final homeDir = Platform.environment['USERPROFILE'] ??
                    Platform.environment['HOME'] ??
                    _capeDir?.path ??
                    '';
    return path.join(homeDir, '.minecraft', 'capes');
  }

  /// 导出披风到Minecraft披风目录
  Future<bool> exportToMinecraftCapes(String accountId) async {
    await initialize();

    final capeData = await getCape(accountId);
    if (capeData == null || capeData.imageData.isEmpty) {
      return false;
    }

    try {
      final minecraftCapesDir = await getCapeDirectory();
      final dir = Directory(minecraftCapesDir);

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final exportPath = path.join(minecraftCapesDir, '${accountId}_cape.png');
      final file = File(exportPath);
      await file.writeAsBytes(capeData.imageData);

      _logger.info('Cape exported to: $exportPath');
      return true;
    } catch (e, stackTrace) {
      _logger.error('Failed to export cape', e, stackTrace);
      return false;
    }
  }

  /// 清理无效的披风条目
  Future<void> cleanInvalidEntries() async {
    await initialize();

    final invalidAccountIds = <String>[];

    for (final entry in _capeCache.entries) {
      final capeData = entry.value;

      // 检查文件是否存在
      if (capeData.filePath != null) {
        final file = File(capeData.filePath!);
        if (!await file.exists()) {
          invalidAccountIds.add(entry.key);
          continue;
        }

        // 检查文件是否可读
        try {
          await file.readAsBytes();
        } catch (e) {
          invalidAccountIds.add(entry.key);
        }
      } else if (capeData.imageData.isEmpty) {
        invalidAccountIds.add(entry.key);
      }
    }

    // 移除无效条目
    for (final accountId in invalidAccountIds) {
      _capeCache.remove(accountId);
    }

    if (invalidAccountIds.isNotEmpty) {
      await _saveMetadata();
      _logger.info('Cleaned ${invalidAccountIds.length} invalid cape entries');
    }
  }

  /// 设置自定义披风
  ///
  /// 为指定账户设置自定义披风。
  ///
  /// [accountId] 要设置披风的账户ID
  /// [capeData] 披风图像的字节数据
  Future<void> setCustomCape(String accountId, Uint8List capeData) async {
    await uploadCape(accountId, capeData, 'custom_cape_${DateTime.now().millisecondsSinceEpoch}.png');
  }
}
