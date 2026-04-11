abstract class IUpdateManager {
  Future<UpdateInfo?> checkForUpdates();
  
  Future<void> downloadUpdate(
    UpdateInfo updateInfo, {
    Function(double)? onProgress,
    Function(String)? onError,
  });
  
  Future<bool> installUpdate(UpdateInfo updateInfo);
  
  Future<bool> rollbackUpdate();
  
  Future<bool> isUpdateAvailable();
  
  Future<UpdateStatus> getUpdateStatus();
  
  Future<void> cancelUpdate();
}

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String changelog;
  final String checksum;
  final String checksumType;
  final int fileSize;
  final DateTime releaseDate;
  
  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.changelog,
    required this.checksum,
    required this.checksumType,
    required this.fileSize,
    required this.releaseDate,
  });
}

enum UpdateStatus {
  none,
  checking,
  available,
  downloading,
  downloaded,
  installing,
  installed,
  failed,
  rolledBack,
}

class UpdateException implements Exception {
  final String message;
  
  UpdateException(this.message);
  
  @override
  String toString() => 'UpdateException: $message';
}