import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart' as archive;
import 'error_codes.dart';
import 'retry_helper.dart';
import 'logger.dart';

/// 网络客户端类
///
/// 这是一个单例模式的网络请求工具类，负责处理所有HTTP请求。
/// 主要职责包括：
/// - 提供统一的HTTP请求接口（GET、POST等）
/// - 管理请求头配置，避免因缺少必要请求头而导致的403错误
/// - 支持文件下载及进度回调
/// - 支持JSON数据的自动解析（包括gzip压缩数据）
/// - 提供自动重试机制
/// - 统一处理网络异常并转换为应用异常
///
/// 使用示例：
/// ```dart
/// final client = NetworkClient();
///
/// // 发送GET请求
/// final response = await client.get('https://api.example.com/data');
///
/// // 获取JSON数据
/// final json = await client.getJson('https://api.example.com/json');
///
/// // 下载文件
/// await client.downloadFile(
///   'https://example.com/file.zip',
///   '/path/to/save/file.zip',
///   onProgress: (downloaded, total) => print('$downloaded / $total'),
/// );
/// ```
class NetworkClient {
  /// 单例实例
  static final NetworkClient _instance = NetworkClient._internal();

  /// 工厂构造函数，返回单例实例
  factory NetworkClient() => _instance;

  /// 私有构造函数，防止外部实例化
  NetworkClient._internal();

  /// HTTP客户端实例，用于发送网络请求
  final http.Client _client = http.Client();

  /// 日志记录器实例，用于记录网络操作日志
  final Logger _logger = Logger('NetworkClient');

  /// 默认请求头
  ///
  /// 包含所有HTTP请求通用的请求头配置，用于模拟正常浏览器行为，
  /// 避免被服务器拒绝访问。
  ///
  /// 包含的请求头：
  /// - `User-Agent`: 标识客户端身份
  /// - `Accept`: 指定接受的响应内容类型
  /// - `Accept-Language`: 指定接受的语言
  /// - `Accept-Encoding`: 支持的压缩编码
  /// - `Connection`: 连接类型
  /// - `Cache-Control`: 缓存控制
  /// - `Pragma`: 缓存指令（HTTP/1.0兼容）
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
  ///
  /// 在默认请求头基础上添加BMCLAPI所需的Referer和Origin请求头，
  /// 用于访问BMCLAPI（Bangbang93的Minecraft镜像源）。
  ///
  /// 返回包含以下额外请求头的Map：
  /// - `Referer`: https://bmclapi2.bangbang93.com/
  /// - `Origin`: https://bmclapi2.bangbang93.com
  static Map<String, String> get bmclapiHeaders {
    return {
      ...defaultHeaders,
      'Referer': 'https://bmclapi2.bangbang93.com/',
      'Origin': 'https://bmclapi2.bangbang93.com',
    };
  }

  /// Modrinth专用请求头
  ///
  /// 在默认请求头基础上添加Modrinth平台所需的请求头，
  /// 用于访问Modrinth API（Minecraft模组平台）。
  ///
  /// 返回包含以下额外请求头的Map：
  /// - `Referer`: https://modrinth.com/
  /// - `Origin`: https://modrinth.com
  /// - `X-User-Agent`: 自定义用户代理标识
  static Map<String, String> get modrinthHeaders {
    return {
      ...defaultHeaders,
      'Referer': 'https://modrinth.com/',
      'Origin': 'https://modrinth.com',
      'X-User-Agent': 'BAMCLauncher/2.0.0',
    };
  }

  /// CurseForge专用请求头
  ///
  /// 在默认请求头基础上添加CurseForge平台所需的请求头，
  /// 用于访问CurseForge API（Minecraft模组资源平台）。
  ///
  /// 返回包含以下额外请求头的Map：
  /// - `Referer`: https://www.curseforge.com/
  /// - `Origin`: https://www.curseforge.com
  static Map<String, String> get curseforgeHeaders {
    return {
      ...defaultHeaders,
      'Referer': 'https://www.curseforge.com/',
      'Origin': 'https://www.curseforge.com',
    };
  }

  /// Microsoft OAuth专用请求头
  ///
  /// 在默认请求头基础上添加Microsoft OAuth认证所需的请求头，
  /// 用于Microsoft账户登录认证流程。
  ///
  /// 返回包含以下额外请求头的Map：
  /// - `Content-Type`: application/x-www-form-urlencoded（表单编码格式）
  static Map<String, String> get microsoftHeaders {
    return {
      ...defaultHeaders,
      'Content-Type': 'application/x-www-form-urlencoded',
    };
  }

  /// Xbox Live/Minecraft专用请求头
  ///
  /// 在默认请求头基础上添加Xbox Live和Minecraft服务所需的请求头，
  /// 用于Xbox Live认证和Minecraft API访问。
  ///
  /// 返回包含以下额外请求头的Map：
  /// - `Accept`: application/json
  /// - `Content-Type`: application/json（JSON格式）
  static Map<String, String> get xboxLiveHeaders {
    return {
      ...defaultHeaders,
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  /// Minecraft API专用请求头
  ///
  /// 在默认请求头基础上添加Minecraft API所需的请求头，
  /// 用于访问Minecraft官方API服务。
  ///
  /// 返回包含以下额外请求头的Map：
  /// - `Accept`: application/json
  /// - `Content-Type`: application/json（JSON格式）
  static Map<String, String> get minecraftApiHeaders {
    return {
      ...defaultHeaders,
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  /// 发送GET请求
  ///
  /// 向指定URL发送HTTP GET请求，支持自定义请求头、查询参数、
  /// 超时设置和自动重试。
  ///
  /// 参数：
  /// - [url] 请求的目标URL地址
  /// - [headers] 可选的自定义请求头，会与默认请求头合并
  /// - [queryParameters] 可选的URL查询参数，会被添加到URL后面
  /// - [timeoutSeconds] 请求超时时间（秒），默认为30秒
  /// - [retryConfig] 可选的重试配置，默认使用网络请求的重试配置
  ///
  /// 返回：
  /// - 返回 `Future<http.Response>` 对象，包含响应状态码、头信息和响应体
  ///
  /// 异常：
  /// - 抛出 [AppException] 异常，错误码可能为：
  ///   - [ErrorCodes.networkTimeout]: 请求超时
  ///   - [ErrorCodes.networkConnectionFailed]: 网络连接失败
  ///   - [ErrorCodes.networkHttpError]: HTTP错误
  ///
  /// 使用示例：
  /// ```dart
  /// final client = NetworkClient();
  ///
  /// // 简单GET请求
  /// final response = await client.get('https://api.example.com/data');
  ///
  /// // 带查询参数的GET请求
  /// final response = await client.get(
  ///   'https://api.example.com/search',
  ///   queryParameters: {'q': 'minecraft', 'limit': '10'},
  /// );
  ///
  /// // 使用自定义请求头
  /// final response = await client.get(
  ///   'https://api.example.com/data',
  ///   headers: {'Authorization': 'Bearer token'},
  /// );
  /// ```
  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    int timeoutSeconds = 30,
    RetryConfig? retryConfig,
  }) async {
    // 使用重试助手执行请求，支持自动重试机制
    return RetryHelper.execute(
      config: retryConfig ?? RetryConfig.network,
      operation: () async {
        // 构建请求URI，如果有查询参数则添加到URL中
        final uri = queryParameters != null
            ? Uri.parse(url).replace(queryParameters: queryParameters)
            : Uri.parse(url);

        // 合并默认请求头和自定义请求头，自定义请求头优先级更高
        final finalHeaders = {...defaultHeaders, if (headers != null) ...headers};

        try {
          // 发送GET请求并设置超时
          final response = await _client
              .get(uri, headers: finalHeaders)
              .timeout(Duration(seconds: timeoutSeconds));
          return response;
        } on TimeoutException catch (e, stackTrace) {
          // 处理请求超时异常
          throw AppException.fromCode(
            ErrorCodes.networkTimeout,
            originalError: e,
            stackTrace: stackTrace,
            retryable: true,
          );
        } on SocketException catch (e, stackTrace) {
          // 处理网络连接失败异常
          throw AppException.fromCode(
            ErrorCodes.networkConnectionFailed,
            originalError: e,
            stackTrace: stackTrace,
            retryable: true,
          );
        } on HttpException catch (e, stackTrace) {
          // 处理HTTP协议异常
          throw AppException.fromCode(
            ErrorCodes.networkHttpError,
            detail: e.message,
            originalError: e,
            stackTrace: stackTrace,
            retryable: true,
          );
        } catch (e, stackTrace) {
          // 处理其他未知异常
          throw AppException.fromCode(
            ErrorCodes.networkHttpError,
            detail: e.toString(),
            originalError: e,
            stackTrace: stackTrace,
            retryable: true,
          );
        }
      },
    );
  }

  /// 发送POST请求
  ///
  /// 向指定URL发送HTTP POST请求，支持自定义请求头、请求体、
  /// 超时设置和自动重试。
  ///
  /// 参数：
  /// - [url] 请求的目标URL地址
  /// - [headers] 可选的自定义请求头，会与默认请求头合并
  /// - [body] 可选的请求体内容，可以是字符串、字节列表或Map
  /// - [timeoutSeconds] 请求超时时间（秒），默认为30秒
  /// - [retryConfig] 可选的重试配置，默认使用网络请求的重试配置
  ///
  /// 返回：
  /// - 返回 `Future<http.Response>` 对象，包含响应状态码、头信息和响应体
  ///
  /// 异常：
  /// - 抛出 [AppException] 异常，错误码可能为：
  ///   - [ErrorCodes.networkTimeout]: 请求超时
  ///   - [ErrorCodes.networkConnectionFailed]: 网络连接失败
  ///   - [ErrorCodes.networkHttpError]: HTTP错误
  ///
  /// 使用示例：
  /// ```dart
  /// final client = NetworkClient();
  ///
  /// // 发送表单数据
  /// final response = await client.post(
  ///   'https://api.example.com/login',
  ///   body: {'username': 'user', 'password': 'pass'},
  /// );
  ///
  /// // 发送字符串数据
  /// final response = await client.post(
  ///   'https://api.example.com/data',
  ///   headers: {'Content-Type': 'text/plain'},
  ///   body: 'raw data',
  /// );
  /// ```
  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    int timeoutSeconds = 30,
    RetryConfig? retryConfig,
  }) async {
    // 使用重试助手执行请求，支持自动重试机制
    return RetryHelper.execute(
      config: retryConfig ?? RetryConfig.network,
      operation: () async {
        // 解析URL
        final uri = Uri.parse(url);
        // 合并默认请求头和自定义请求头，自定义请求头优先级更高
        final finalHeaders = {...defaultHeaders, if (headers != null) ...headers};

        try {
          // 发送POST请求并设置超时
          final response = await _client
              .post(uri, headers: finalHeaders, body: body)
              .timeout(Duration(seconds: timeoutSeconds));
          return response;
        } on TimeoutException catch (e, stackTrace) {
          // 处理请求超时异常
          throw AppException.fromCode(
            ErrorCodes.networkTimeout,
            originalError: e,
            stackTrace: stackTrace,
            retryable: true,
          );
        } on SocketException catch (e, stackTrace) {
          // 处理网络连接失败异常
          throw AppException.fromCode(
            ErrorCodes.networkConnectionFailed,
            originalError: e,
            stackTrace: stackTrace,
            retryable: true,
          );
        } on HttpException catch (e, stackTrace) {
          // 处理HTTP协议异常
          throw AppException.fromCode(
            ErrorCodes.networkHttpError,
            detail: e.message,
            originalError: e,
            stackTrace: stackTrace,
            retryable: true,
          );
        } catch (e, stackTrace) {
          // 处理其他未知异常
          throw AppException.fromCode(
            ErrorCodes.networkHttpError,
            detail: e.toString(),
            originalError: e,
            stackTrace: stackTrace,
            retryable: true,
          );
        }
      },
    );
  }

  /// 发送JSON POST请求
  ///
  /// 向指定URL发送JSON格式的HTTP POST请求，自动将请求体序列化为JSON字符串，
  /// 并设置正确的Content-Type请求头。
  ///
  /// 参数：
  /// - [url] 请求的目标URL地址
  /// - [body] 请求体内容，为一个Map，会被自动序列化为JSON字符串
  /// - [headers] 可选的自定义请求头，会与默认请求头合并
  /// - [timeoutSeconds] 请求超时时间（秒），默认为30秒
  /// - [retryConfig] 可选的重试配置，默认使用网络请求的重试配置
  ///
  /// 返回：
  /// - 返回 `Future<http.Response>` 对象，包含响应状态码、头信息和响应体
  ///
  /// 异常：
  /// - 抛出 [AppException] 异常，错误码可能为：
  ///   - [ErrorCodes.networkTimeout]: 请求超时
  ///   - [ErrorCodes.networkConnectionFailed]: 网络连接失败
  ///   - [ErrorCodes.networkHttpError]: HTTP错误
  ///
  /// 使用示例：
  /// ```dart
  /// final client = NetworkClient();
  ///
  /// // 发送JSON数据
  /// final response = await client.postJson(
  ///   'https://api.example.com/users',
  ///   {
  ///     'name': 'John',
  ///     'email': 'john@example.com',
  ///   },
  /// );
  ///
  /// // 带自定义请求头
  /// final response = await client.postJson(
  ///   'https://api.example.com/data',
  ///   {'key': 'value'},
  ///   headers: {'Authorization': 'Bearer token'},
  /// );
  /// ```
  Future<http.Response> postJson(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    int timeoutSeconds = 30,
    RetryConfig? retryConfig,
  }) async {
    // 使用重试助手执行请求，支持自动重试机制
    return RetryHelper.execute(
      config: retryConfig ?? RetryConfig.network,
      operation: () async {
        // 解析URL
        final uri = Uri.parse(url);
        // 构建请求头，确保包含JSON Content-Type
        final finalHeaders = {
          ...defaultHeaders,
          'Content-Type': 'application/json',
          if (headers != null) ...headers,
        };

        try {
          // 发送POST请求，将请求体序列化为JSON字符串
          final response = await _client
              .post(
                uri,
                headers: finalHeaders,
                body: jsonEncode(body),
              )
              .timeout(Duration(seconds: timeoutSeconds));
          return response;
        } on TimeoutException catch (e, stackTrace) {
          // 处理请求超时异常
          throw AppException.fromCode(
            ErrorCodes.networkTimeout,
            originalError: e,
            stackTrace: stackTrace,
            retryable: true,
          );
        } on SocketException catch (e, stackTrace) {
          // 处理网络连接失败异常
          throw AppException.fromCode(
            ErrorCodes.networkConnectionFailed,
            originalError: e,
            stackTrace: stackTrace,
            retryable: true,
          );
        } on HttpException catch (e, stackTrace) {
          // 处理HTTP协议异常
          throw AppException.fromCode(
            ErrorCodes.networkHttpError,
            detail: e.message,
            originalError: e,
            stackTrace: stackTrace,
            retryable: true,
          );
        } catch (e, stackTrace) {
          // 处理其他未知异常
          throw AppException.fromCode(
            ErrorCodes.networkHttpError,
            detail: e.toString(),
            originalError: e,
            stackTrace: stackTrace,
            retryable: true,
          );
        }
      },
    );
  }

  /// 下载文件
  ///
  /// 从指定URL下载文件并保存到本地路径，支持进度回调和自动重试。
  /// 该方法使用流式下载，适合下载大文件，不会将整个文件加载到内存中。
  ///
  /// 参数：
  /// - [url] 文件的下载URL地址
  /// - [destinationPath] 文件保存的本地路径（绝对路径）
  /// - [headers] 可选的自定义请求头，会与默认请求头合并
  /// - [onProgress] 可选的进度回调函数，参数为已下载字节数和总字节数
  /// - [timeoutSeconds] 请求超时时间（秒），默认为120秒（适合大文件）
  /// - [retryConfig] 可选的重试配置，默认使用网络请求的重试配置
  ///
  /// 返回：
  /// - 返回 `Future<void>`，下载完成时完成
  ///
  /// 异常：
  /// - 抛出 [AppException] 异常，错误码可能为：
  ///   - [ErrorCodes.networkTimeout]: 请求超时
  ///   - [ErrorCodes.networkConnectionFailed]: 网络连接失败
  ///   - [ErrorCodes.networkDownloadFailed]: 下载失败（包括HTTP错误和IO错误）
  ///
  /// 使用示例：
  /// ```dart
  /// final client = NetworkClient();
  ///
  /// // 简单下载
  /// await client.downloadFile(
  ///   'https://example.com/file.zip',
  ///   '/path/to/save/file.zip',
  /// );
  ///
  /// // 带进度回调的下载
  /// await client.downloadFile(
  ///   'https://example.com/large-file.zip',
  ///   '/path/to/save/large-file.zip',
  ///   onProgress: (downloaded, total) {
  ///     final percent = (downloaded / total * 100).toStringAsFixed(1);
  ///     print('下载进度: $percent%');
  ///   },
  /// );
  /// ```
  Future<void> downloadFile(
    String url,
    String destinationPath, {
    Map<String, String>? headers,
    void Function(int, int)? onProgress,
    int timeoutSeconds = 120,
    RetryConfig? retryConfig,
  }) async {
    // 使用重试助手执行下载操作，支持自动重试机制
    return RetryHelper.execute(
      config: retryConfig ?? RetryConfig.network,
      operation: () async {
        // 解析URL
        final uri = Uri.parse(url);
        // 合并默认请求头和自定义请求头
        final finalHeaders = {...defaultHeaders, if (headers != null) ...headers};

        try {
          // 创建HTTP GET请求
          final request = http.Request('GET', uri)..headers.addAll(finalHeaders);
          // 发送请求并获取响应流，设置超时
          final response = await _client.send(request).timeout(
                Duration(seconds: timeoutSeconds),
              );

          // 检查响应状态码，非200表示下载失败
          if (response.statusCode != 200) {
            throw AppException.fromCode(
              ErrorCodes.networkDownloadFailed,
              detail: 'HTTP ${response.statusCode}',
              // 服务器错误（5xx）可以重试
              retryable: response.statusCode >= 500,
            );
          }

          // 创建目标文件并打开写入流
          final file = File(destinationPath);
          final sink = file.openWrite();
          // 记录已下载字节数
          int downloadedBytes = 0;
          // 获取文件总大小（可能为0，表示服务器未返回Content-Length）
          final contentLength = response.contentLength ?? 0;

          // 流式读取响应数据并写入文件
          await for (final chunk in response.stream) {
            // 将数据块写入文件
            sink.add(chunk);
            // 更新已下载字节数
            downloadedBytes += chunk.length;
            // 如果有进度回调且知道总大小，则调用进度回调
            if (onProgress != null && contentLength > 0) {
              onProgress(downloadedBytes, contentLength);
            }
          }

          // 关闭文件写入流，确保数据写入磁盘
          await sink.close();
          // 记录下载完成日志
          _logger.info('Download completed: $destinationPath');
        } on TimeoutException catch (e, stackTrace) {
          // 处理请求超时异常
          throw AppException.fromCode(
            ErrorCodes.networkTimeout,
            originalError: e,
            stackTrace: stackTrace,
            retryable: true,
          );
        } on SocketException catch (e, stackTrace) {
          // 处理网络连接失败异常
          throw AppException.fromCode(
            ErrorCodes.networkConnectionFailed,
            originalError: e,
            stackTrace: stackTrace,
            retryable: true,
          );
        } catch (e, stackTrace) {
          // 处理其他异常（包括文件IO异常等）
          throw AppException.fromCode(
            ErrorCodes.networkDownloadFailed,
            detail: e.toString(),
            originalError: e,
            stackTrace: stackTrace,
            retryable: true,
          );
        }
      },
    );
  }

  /// 获取JSON数据
  ///
  /// 向指定URL发送GET请求并自动解析响应为JSON对象。
  /// 支持自动解压gzip压缩的响应数据。
  ///
  /// 参数：
  /// - [url] 请求的目标URL地址
  /// - [headers] 可选的自定义请求头，会与默认请求头合并
  /// - [queryParameters] 可选的URL查询参数，会被添加到URL后面
  /// - [timeoutSeconds] 请求超时时间（秒），默认为30秒
  /// - [retryConfig] 可选的重试配置，默认使用网络请求的重试配置
  ///
  /// 返回：
  /// - 返回 `Future<dynamic>` 对象，为解析后的JSON数据（可能是Map、List或基本类型）
  ///
  /// 异常：
  /// - 抛出 [AppException] 异常，错误码可能为：
  ///   - [ErrorCodes.networkHttpError]: HTTP错误或JSON解析失败
  ///   - 以及 [get] 方法可能抛出的其他异常
  ///
  /// 使用示例：
  /// ```dart
  /// final client = NetworkClient();
  ///
  /// // 获取JSON数据
  /// final data = await client.getJson('https://api.example.com/data');
  /// print(data['name']); // 访问JSON对象字段
  ///
  /// // 获取JSON数组
  /// final List items = await client.getJson('https://api.example.com/items');
  /// for (var item in items) {
  ///   print(item['name']);
  /// }
  ///
  /// // 带查询参数
  /// final data = await client.getJson(
  ///   'https://api.example.com/search',
  ///   queryParameters: {'q': 'minecraft'},
  /// );
  /// ```
  Future<dynamic> getJson(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    int timeoutSeconds = 30,
    RetryConfig? retryConfig,
  }) async {
    // 调用get方法发送请求
    final response = await get(
      url,
      headers: headers,
      queryParameters: queryParameters,
      timeoutSeconds: timeoutSeconds,
      retryConfig: retryConfig,
    );

    // 检查响应状态码
    if (response.statusCode == 200) {
      try {
        // 检查响应是否被 gzip 压缩
        final contentEncoding = response.headers['content-encoding'];
        if (contentEncoding != null && contentEncoding.contains('gzip')) {
          // 处理 gzip 压缩的数据：解码gzip数据后再解析JSON
          final gzipDecoder = archive.GZipDecoder();
          final decodedBytes = gzipDecoder.decodeBytes(response.bodyBytes);
          return jsonDecode(utf8.decode(decodedBytes));
        }
        // 普通响应：直接解析JSON
        return jsonDecode(response.body);
      } catch (e, stackTrace) {
        // JSON解析失败，抛出异常
        throw AppException.fromCode(
          ErrorCodes.networkHttpError,
          detail: 'JSON解析失败: $e',
          originalError: e,
          stackTrace: stackTrace,
        );
      }
    } else {
      // HTTP状态码非200，抛出异常
      throw AppException.fromCode(
        ErrorCodes.networkHttpError,
        detail: 'HTTP ${response.statusCode}',
        // 服务器错误（5xx）可以重试
        retryable: response.statusCode >= 500,
      );
    }
  }

  /// 关闭客户端
  ///
  /// 关闭HTTP客户端并释放相关资源。通常在应用程序退出时调用。
  /// 关闭后不应再使用此客户端实例发送请求。
  ///
  /// 使用示例：
  /// ```dart
  /// final client = NetworkClient();
  /// // 使用客户端...
  /// client.close(); // 释放资源
  /// ```
  void close() {
    _client.close();
  }
}

/// 网络异常类
///
/// 表示网络请求过程中发生的异常。这是一个简单的异常包装类，
/// 用于提供更清晰的错误信息。
///
/// 使用示例：
/// ```dart
/// try {
///   final response = await client.get('https://example.com');
/// } on NetworkException catch (e) {
///   print('网络错误: ${e.message}');
/// }
/// ```
class NetworkException implements Exception {
  /// 异常消息，描述错误详情
  final String message;

  /// 创建网络异常实例
  ///
  /// 参数：
  /// - [message] 异常消息
  NetworkException(this.message);

  /// 返回异常的字符串表示
  ///
  /// 格式：`NetworkException: {message}`
  @override
  String toString() => 'NetworkException: $message';
}