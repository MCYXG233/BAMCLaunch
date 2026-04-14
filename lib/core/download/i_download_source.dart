abstract class IDownloadSource {
  String get name;

  String get baseUrl;

  List<String> get mirrors;

  Future<String> resolveUrl(String originalUrl);

  bool isValid();

  Future<int> getResponseTime();

  /// 获取下载源名称
  String getName() => name;
}