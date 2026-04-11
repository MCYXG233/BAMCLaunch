import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../logger/logger.dart';

class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final Map<String, DownloadTask> _activeTasks = {};
  final Map<String, Completer> _taskCompleters = {};

  Future<void> downloadVersion(
    String versionId, {
    required String downloadUrl,
    required String savePath,
    required Function(double) onProgress,
    String? loaderType,
    bool verifyFiles = true,
  }) async {
    final taskId = 'version_$versionId';

    if (_activeTasks.containsKey(taskId)) {
      // 如果任务已存在，等待其完成
      return _taskCompleters[taskId]?.future ?? Future.value();
    }

    final completer = Completer();
    _taskCompleters[taskId] = completer;

    try {
      // 创建下载任务
      final task = DownloadTask(
        id: taskId,
        url: downloadUrl,
        savePath: savePath,
        onProgress: onProgress,
      );
      _activeTasks[taskId] = task;

      // 开始下载
      await task.start();

      // 如果需要校验文件完整性
      if (verifyFiles) {
        await _verifyFileIntegrity(savePath);
      }

      // 如果指定了模组加载器，安装加载器
      if (loaderType != null) {
        await _installLoader(versionId, loaderType);
      }

      completer.complete();
    } catch (e) {
      completer.completeError(e);
    } finally {
      _activeTasks.remove(taskId);
      _taskCompleters.remove(taskId);
    }

    return completer.future;
  }

  Future<void> installLoader(String versionId, String loaderType) async {
    // 获取加载器下载地址
    final loaderUrl = await _getLoaderUrl(versionId, loaderType);
    if (loaderUrl == null) {
      throw Exception('未找到兼容的$loaderType版本');
    }

    // 构建保存路径
    final loaderPath =
        '${Directory.current.path}/versions/$versionId/${loaderType.toLowerCase()}.jar';

    // 创建下载目录
    await Directory(loaderPath).parent.create(recursive: true);

    // 下载加载器
    await downloadVersion(
      '${versionId}_$loaderType',
      downloadUrl: loaderUrl,
      savePath: loaderPath,
      onProgress: (progress) =>
          print('$loaderType下载进度: ${(progress * 100).toStringAsFixed(2)}%'),
    );

    // 更新版本JSON文件，添加加载器信息
    await _updateVersionJson(versionId, loaderType);
  }

  Future<void> installOptiFine(String versionId) async {
    // 获取OptiFine下载地址
    final optifineUrl = await _getOptiFineUrl(versionId);
    if (optifineUrl == null) {
      throw Exception('未找到兼容的OptiFine版本');
    }

    // 构建保存路径
    final optifinePath =
        '${Directory.current.path}/versions/$versionId/optifine.jar';

    // 创建下载目录
    await Directory(optifinePath).parent.create(recursive: true);

    // 下载OptiFine
    await downloadVersion(
      '${versionId}_optifine',
      downloadUrl: optifineUrl,
      savePath: optifinePath,
      onProgress: (progress) =>
          print('OptiFine下载进度: ${(progress * 100).toStringAsFixed(2)}%'),
    );

    // 更新版本JSON文件，添加OptiFine信息
    await _updateVersionJson(versionId, 'OptiFine');
  }

  Future<void> installShaderCore(String versionId) async {
    // 获取光影核心下载地址
    final shaderUrl = await _getShaderCoreUrl(versionId);
    if (shaderUrl == null) {
      throw Exception('未找到兼容的光影核心版本');
    }

    // 构建保存路径
    final shaderPath =
        '${Directory.current.path}/versions/$versionId/shader_core.jar';

    // 创建下载目录
    await Directory(shaderPath).parent.create(recursive: true);

    // 下载光影核心
    await downloadVersion(
      '${versionId}_shader',
      downloadUrl: shaderUrl,
      savePath: shaderPath,
      onProgress: (progress) =>
          print('光影核心下载进度: ${(progress * 100).toStringAsFixed(2)}%'),
    );

    // 更新版本JSON文件，添加光影核心信息
    await _updateVersionJson(versionId, 'ShaderCore');
  }

  Future<String?> _getLoaderUrl(String versionId, String loaderType) async {
    // 模拟获取加载器下载地址
    await Future.delayed(const Duration(seconds: 1));
    return 'https://example.com/loaders/${loaderType.toLowerCase()}/$versionId.jar';
  }

  Future<String?> _getOptiFineUrl(String versionId) async {
    // 模拟获取OptiFine下载地址
    await Future.delayed(const Duration(seconds: 1));
    return 'https://example.com/optifine/$versionId.jar';
  }

  Future<String?> _getShaderCoreUrl(String versionId) async {
    // 模拟获取光影核心下载地址
    await Future.delayed(const Duration(seconds: 1));
    return 'https://example.com/shader_core/$versionId.jar';
  }

  Future<void> _verifyFileIntegrity(String filePath) async {
    // 模拟文件完整性校验
    await Future.delayed(const Duration(milliseconds: 500));
    print('文件完整性校验完成');
  }

  Future<void> _updateVersionJson(String versionId, String component) async {
    final jsonPath =
        '${Directory.current.path}/versions/$versionId/$versionId.json';
    final file = File(jsonPath);

    if (await file.exists()) {
      final content = await file.readAsString();
      final json = jsonDecode(content);

      // 添加组件信息
      if (json['arguments'] == null) {
        json['arguments'] = {
          'game': [],
        };
      }

      if (json['arguments']['game'] == null) {
        json['arguments']['game'] = [];
      }

      // 添加组件JAR路径
      final jarPath = 'versions/$versionId/${component.toLowerCase()}.jar';
      if (!json['arguments']['game'].contains('-jar')) {
        json['arguments']['game'].add('-jar');
        json['arguments']['game'].add(jarPath);
      }

      // 写回文件
      await file.writeAsString(jsonEncode(json));
    }
  }

  bool isDownloading(String taskId) {
    return _activeTasks.containsKey(taskId);
  }

  DownloadTask? getTask(String taskId) {
    return _activeTasks[taskId];
  }

  void cancelDownload(String taskId) {
    final task = _activeTasks[taskId];
    if (task != null) {
      task.cancel();
      _activeTasks.remove(taskId);
      _taskCompleters.remove(taskId);
    }
  }

  void cancelAll() {
    for (var task in _activeTasks.values) {
      task.cancel();
    }
    _activeTasks.clear();
    _taskCompleters.clear();
  }

  Future<void> _installLoader(String versionId, String loaderType) async {
    // 这里实现模组加载器的安装逻辑
    // 根据loaderType安装对应的加载器
    logger.info('安装模组加载器: $loaderType 到版本: $versionId');
  }
}

class DownloadTask {
  final String id;
  final String url;
  final String savePath;
  final Function(double) onProgress;

  late HttpClient _client;
  late HttpClientRequest _request;
  late HttpClientResponse _response;
  late File _file;
  late RandomAccessFile _raf;

  bool _isCancelled = false;
  int _totalBytes = 0;
  int _receivedBytes = 0;

  DownloadTask({
    required this.id,
    required this.url,
    required this.savePath,
    required this.onProgress,
  });

  Future<void> start() async {
    try {
      // 创建目录
      await Directory(savePath).parent.create(recursive: true);

      // 检查是否有断点续传
      final file = File(savePath);
      _receivedBytes = await file.exists() ? await file.length() : 0;

      // 创建HTTP客户端
      _client = HttpClient();

      // 创建请求
      _request = await _client.getUrl(Uri.parse(url));

      // 设置断点续传头
      if (_receivedBytes > 0) {
        _request.headers.add('Range', 'bytes=$_receivedBytes-');
      }

      // 发送请求
      _response = await _request.close();

      // 获取文件大小
      if (_response.statusCode == 206) {
        // 断点续传
        final range = _response.headers.value('content-range');
        if (range != null) {
          _totalBytes = int.parse(range.split('/').last);
        }
      } else if (_response.statusCode == 200) {
        // 正常下载
        _totalBytes =
            int.parse(_response.headers.value('content-length') ?? '0');
        _receivedBytes = 0;
      } else {
        throw Exception('HTTP错误: ${_response.statusCode}');
      }

      // 打开文件
      _file = File(savePath);
      _raf = await _file.open(
          mode: _receivedBytes > 0 ? FileMode.append : FileMode.write);

      // 开始下载
      await _download();
    } catch (e) {
      if (!_isCancelled) {
        rethrow;
      }
    } finally {
      await _cleanup();
    }
  }

  Future<void> _download() async {
    const chunkSize = 8192;
    final buffer = Uint8List(chunkSize);

    await for (var chunk in _response) {
      if (_isCancelled) {
        break;
      }

      await _raf.writeFrom(chunk);
      _receivedBytes += chunk.length;

      // 计算进度并回调
      if (_totalBytes > 0) {
        final progress = _receivedBytes / _totalBytes;
        onProgress(progress);
      }
    }

    if (_isCancelled) {
      throw Exception('下载已取消');
    }
  }

  void cancel() {
    _isCancelled = true;
    _request.abort();
  }

  Future<void> _cleanup() async {
    await _raf.close();
    _client.close();
  }
}

final downloadManager = DownloadManager();
