import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart' as archive;

/// 网络请求工具类
/// 处理所有HTTP请求，添加正确的请求头以避免403错误
class NetworkClient {
  static final NetworkClient _instance = NetworkClient._internal();
  
  factory NetworkClient() => _instance;
  
  NetworkClient._internal();

  final http.Client _client = http.Client();

  /// 默认请求头
  static Map<String, String> get defaultHeaders {
    return {
      'User-Agent': 'BAMCLauncher/2.0.0 (Windows; https://github.com/BAMC)',
      'Accept': 'application/json',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
    };
  }

  /// BMCLAPI专用请求头
  static Map<String, String> get bmclapiHeaders {
    return {
      ...defaultHeaders,
      'Referer': 'https://bmclapi2.bangbang93.com/',
      'Origin': 'https://bmclapi2.bangbang93.com',
    };
  }

  /// Modrinth专用请求头
  static Map<String, String> get modrinthHeaders {
    return {
      ...defaultHeaders,
      'Referer': 'https://modrinth.com/',
      'Origin': 'https://modrinth.com',
      'X-User-Agent': 'BAMCLauncher/2.0.0',
    };
  }

  /// CurseForge专用请求头
  static Map<String, String> get curseforgeHeaders {
    return {
      ...defaultHeaders,
      'Referer': 'https://www.curseforge.com/',
      'Origin': 'https://www.curseforge.com',
    };
  }

  /// Microsoft OAuth专用请求头
  static Map<String, String> get microsoftHeaders {
    return {
      ...defaultHeaders,
      'Content-Type': 'application/x-www-form-urlencoded',
    };
  }

  /// Xbox Live/Minecraft专用请求头
  static Map<String, String> get xboxLiveHeaders {
    return {
      ...defaultHeaders,
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  /// Minecraft API专用请求头
  static Map<String, String> get minecraftApiHeaders {
    return {
      ...defaultHeaders,
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  /// 发送GET请求
  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    int timeoutSeconds = 30,
  }) async {
    final uri = queryParameters != null
        ? Uri.parse(url).replace(queryParameters: queryParameters)
        : Uri.parse(url);

    final finalHeaders = {...defaultHeaders, if (headers != null) ...headers};

    try {
      final response = await _client
          .get(uri, headers: finalHeaders)
          .timeout(Duration(seconds: timeoutSeconds));
      return response;
    } on TimeoutException {
      throw NetworkException('请求超时');
    } on SocketException {
      throw NetworkException('网络连接失败');
    } on HttpException catch (e) {
      throw NetworkException('HTTP错误: ${e.message}');
    } catch (e) {
      throw NetworkException('网络请求失败: $e');
    }
  }

  /// 发送POST请求
  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    int timeoutSeconds = 30,
  }) async {
    final uri = Uri.parse(url);
    final finalHeaders = {...defaultHeaders, if (headers != null) ...headers};

    try {
      final response = await _client
          .post(uri, headers: finalHeaders, body: body)
          .timeout(Duration(seconds: timeoutSeconds));
      return response;
    } on TimeoutException {
      throw NetworkException('请求超时');
    } on SocketException {
      throw NetworkException('网络连接失败');
    } on HttpException catch (e) {
      throw NetworkException('HTTP错误: ${e.message}');
    } catch (e) {
      throw NetworkException('网络请求失败: $e');
    }
  }

  /// 发送JSON POST请求
  Future<http.Response> postJson(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    int timeoutSeconds = 30,
  }) async {
    final uri = Uri.parse(url);
    final finalHeaders = {
      ...defaultHeaders,
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };

    try {
      final response = await _client
          .post(
            uri,
            headers: finalHeaders,
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: timeoutSeconds));
      return response;
    } on TimeoutException {
      throw NetworkException('请求超时');
    } on SocketException {
      throw NetworkException('网络连接失败');
    } on HttpException catch (e) {
      throw NetworkException('HTTP错误: ${e.message}');
    } catch (e) {
      throw NetworkException('网络请求失败: $e');
    }
  }

  /// 下载文件
  Future<void> downloadFile(
    String url,
    String destinationPath, {
    Map<String, String>? headers,
    void Function(int, int)? onProgress,
    int timeoutSeconds = 120,
  }) async {
    final uri = Uri.parse(url);
    final finalHeaders = {...defaultHeaders, if (headers != null) ...headers};

    try {
      final request = http.Request('GET', uri)..headers.addAll(finalHeaders);
      final response = await _client.send(request).timeout(
            Duration(seconds: timeoutSeconds),
          );

      if (response.statusCode != 200) {
        throw NetworkException('下载失败: HTTP ${response.statusCode}');
      }

      final file = File(destinationPath);
      final sink = file.openWrite();
      int downloadedBytes = 0;
      final contentLength = response.contentLength ?? 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        if (onProgress != null && contentLength > 0) {
          onProgress(downloadedBytes, contentLength);
        }
      }

      await sink.close();
    } on TimeoutException {
      throw NetworkException('下载超时');
    } on SocketException {
      throw NetworkException('网络连接失败');
    } catch (e) {
      throw NetworkException('下载失败: $e');
    }
  }

  /// 获取JSON数据
  Future<dynamic> getJson(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    int timeoutSeconds = 30,
  }) async {
    final response = await get(
      url,
      headers: headers,
      queryParameters: queryParameters,
      timeoutSeconds: timeoutSeconds,
    );

    if (response.statusCode == 200) {
      try {
        // 检查响应是否被 gzip 压缩
        final contentEncoding = response.headers['content-encoding'];
        if (contentEncoding != null && contentEncoding.contains('gzip')) {
          // 处理 gzip 压缩的数据
          final gzipDecoder = archive.GZipDecoder();
          final decodedBytes = gzipDecoder.decodeBytes(response.bodyBytes);
          return jsonDecode(utf8.decode(decodedBytes));
        }
        return jsonDecode(response.body);
      } catch (e) {
        throw NetworkException('JSON解析失败: $e');
      }
    } else {
      throw NetworkException('请求失败: ${response.statusCode}');
    }
  }

  /// 关闭客户端
  void close() {
    _client.close();
  }
}

/// 网络异常类
class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}
