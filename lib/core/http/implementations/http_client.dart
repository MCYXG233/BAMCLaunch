import '../i_http_client.dart';
import 'package:http/http.dart' as http;

class HttpClient implements IHttpClient {
  final http.Client _client;

  HttpClient() : _client = http.Client();

  @override
  Future<HttpResponse> get(String url, {Map<String, String>? headers}) async {
    final response = await _client.get(
      Uri.parse(url),
      headers: headers,
    );

    return HttpResponse(
      statusCode: response.statusCode,
      body: response.body,
      headers: Map.from(response.headers),
    );
  }

  @override
  Future<HttpResponse> post(String url, {Map<String, String>? headers, dynamic body}) async {
    final response = await _client.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    return HttpResponse(
      statusCode: response.statusCode,
      body: response.body,
      headers: Map.from(response.headers),
    );
  }

  @override
  Future<HttpResponse> put(String url, {Map<String, String>? headers, dynamic body}) async {
    final response = await _client.put(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    return HttpResponse(
      statusCode: response.statusCode,
      body: response.body,
      headers: Map.from(response.headers),
    );
  }

  @override
  Future<HttpResponse> delete(String url, {Map<String, String>? headers}) async {
    final response = await _client.delete(
      Uri.parse(url),
      headers: headers,
    );

    return HttpResponse(
      statusCode: response.statusCode,
      body: response.body,
      headers: Map.from(response.headers),
    );
  }

  void close() {
    _client.close();
  }
}
