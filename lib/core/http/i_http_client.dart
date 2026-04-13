import 'dart:io';

abstract class IHttpClient {
  Future<HttpResponse> get(String url, {Map<String, String>? headers});
  
  Future<HttpResponse> post(String url, {Map<String, String>? headers, dynamic body});
  
  Future<HttpResponse> put(String url, {Map<String, String>? headers, dynamic body});
  
  Future<HttpResponse> delete(String url, {Map<String, String>? headers});
}

class HttpResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;

  HttpResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
  });
}
