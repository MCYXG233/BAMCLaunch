abstract class IDownloadSource {
  String get name;

  String get baseUrl;

  List<String> get mirrors;

  Future<String> resolveUrl(String originalUrl);

  bool isValid();

  Future<int> getResponseTime();
}