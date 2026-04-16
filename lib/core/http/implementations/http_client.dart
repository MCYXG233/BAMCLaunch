import '../i_http_client.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../../logger/logger.dart';

class HttpClient implements IHttpClient {
  final http.Client _client;
  final Map<String, CachedResponse> _cache = {};
  final Map<String, Completer<HttpResponse>> _pendingRequests = {};
  final Duration _cacheExpiry = const Duration(minutes: 5);
  final Duration _timeout = const Duration(seconds: 30);
  final int _maxRetries = 3;

  HttpClient() : _client = http.Client();

  @override
  Future<HttpResponse> get(String url, {Map<String, String>? headers}) async {
    // 检查是否有相同的请求正在进行
    if (_pendingRequests.containsKey(url)) {
      return _pendingRequests[url]!.future;
    }

    // 检查缓存
    final cachedResponse = _getCachedResponse(url);
    if (cachedResponse != null) {
      logger.debug('Cache hit for $url');
      return cachedResponse;
    }

    // 创建新的请求
    final completer = Completer<HttpResponse>();
    _pendingRequests[url] = completer;

    try {
      // 带超时和重试的请求
      final response = await _executeWithRetry(() async {
        return await _client.get(
          Uri.parse(url),
          headers: headers,
        ).timeout(_timeout);
      });

      final httpResponse = HttpResponse(
        statusCode: response.statusCode,
        body: response.body,
        headers: Map.from(response.headers),
      );

      // 缓存成功的GET请求
      if (response.statusCode == 200) {
        _cacheResponse(url, httpResponse);
      }

      completer.complete(httpResponse);
      return httpResponse;
    } catch (e) {
      logger.error('HTTP GET request failed: $url, error: $e');
      completer.completeError(e);
      rethrow;
    } finally {
      _pendingRequests.remove(url);
    }
  }

  @override
  Future<HttpResponse> post(String url, {Map<String, String>? headers, dynamic body}) async {
    return _executeWithRetry(() async {
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      ).timeout(_timeout);

      return HttpResponse(
        statusCode: response.statusCode,
        body: response.body,
        headers: Map.from(response.headers),
      );
    });
  }

  @override
  Future<HttpResponse> put(String url, {Map<String, String>? headers, dynamic body}) async {
    return _executeWithRetry(() async {
      final response = await _client.put(
        Uri.parse(url),
        headers: headers,
        body: body,
      ).timeout(_timeout);

      return HttpResponse(
        statusCode: response.statusCode,
        body: response.body,
        headers: Map.from(response.headers),
      );
    });
  }

  @override
  Future<HttpResponse> delete(String url, {Map<String, String>? headers}) async {
    return _executeWithRetry(() async {
      final response = await _client.delete(
        Uri.parse(url),
        headers: headers,
      ).timeout(_timeout);

      return HttpResponse(
        statusCode: response.statusCode,
        body: response.body,
        headers: Map.from(response.headers),
      );
    });
  }

  Future<HttpResponse> _executeWithRetry(Future<http.Response> Function() request) async {
    int retries = 0;
    while (true) {
      try {
        final response = await request();
        return response;
      } catch (e) {
        retries++;
        if (retries > _maxRetries) {
          rethrow;
        }
        logger.warn('Request failed, retrying ($retries/$_maxRetries): $e');
        await Future.delayed(Duration(milliseconds: 100 * retries));
      }
    }
  }

  CachedResponse? _getCachedResponse(String url) {
    final cached = _cache[url];
    if (cached == null) return null;

    if (DateTime.now().difference(cached.timestamp) > _cacheExpiry) {
      _cache.remove(url);
      return null;
    }

    return cached.response;
  }

  void _cacheResponse(String url, HttpResponse response) {
    _cache[url] = CachedResponse(
      response: response,
      timestamp: DateTime.now(),
    );
  }

  void clearCache() {
    _cache.clear();
    logger.debug('HTTP cache cleared');
  }

  void close() {
    _client.close();
    _cache.clear();
    _pendingRequests.clear();
  }
}

class CachedResponse {
  final HttpResponse response;
  final DateTime timestamp;

  CachedResponse({required this.response, required this.timestamp});
}
