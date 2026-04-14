import 'dart:async';
import 'dart:io';
import 'i_download_source.dart';

class DownloadSource implements IDownloadSource {
  @override
  final String name;

  @override
  final String baseUrl;

  @override
  final List<String> mirrors;

  DownloadSource({
    required this.name,
    required this.baseUrl,
    required this.mirrors,
  });

  @override
  Future<String> resolveUrl(String originalUrl) async {
    if (originalUrl.startsWith('http')) {
      final uri = Uri.parse(originalUrl);
      final path = uri.path;

      for (final mirror in mirrors) {
        try {
          final mirroredUrl = '$mirror$path';
          if (await _isUrlAccessible(mirroredUrl)) {
            return mirroredUrl;
          }
        } catch (_) {
          continue;
        }
      }

      return '$baseUrl$path';
    }
    return originalUrl;
  }

  @override
  bool isValid() {
    return Uri.parse(baseUrl).isAbsolute && mirrors.isNotEmpty;
  }

  @override
  Future<int> getResponseTime() async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    final client = HttpClient();
    
    try {
      final request = await client.getUrl(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 5));
      request.headers.add('Range', 'bytes=0-0');
      request.headers.add('User-Agent', 'BAMCLauncher/1.0');
      
      final response = await request.close()
          .timeout(const Duration(seconds: 5));
      await response.drain();

      final endTime = DateTime.now().millisecondsSinceEpoch;
      return endTime - startTime;
    } catch (e) {
      throw Exception('Failed to get response time: $e');
    } finally {
      client.close();
    }
  }

  @override
  String getName() {
    return name;
  }

  Future<bool> _isUrlAccessible(String url) async {
    final client = HttpClient();
    
    try {
      final request = await client.getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 3));
      request.headers.add('Range', 'bytes=0-0');
      request.headers.add('User-Agent', 'BAMCLauncher/1.0');
      
      final response = await request.close()
          .timeout(const Duration(seconds: 3));
      await response.drain();
      
      return response.statusCode == 206 || response.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }
}
