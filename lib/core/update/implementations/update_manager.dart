import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:bamclauncher/core/platform/i_platform_adapter.dart';
import 'package:bamclauncher/core/config/i_config_manager.dart';
import 'package:bamclauncher/core/download/i_download_engine.dart';
import 'package:bamclauncher/core/logger/i_logger.dart';
import '../interfaces/i_update_manager.dart';

class UpdateManager implements IUpdateManager {
  final IPlatformAdapter _platformAdapter;
  final IConfigManager _configManager;
  final IDownloadEngine _downloadEngine;
  final ILogger _logger;
  
  UpdateStatus _updateStatus = UpdateStatus.none;
  UpdateInfo? _pendingUpdate;
  String? _updateDownloadPath;
  String? _backupPath;
  String? _deltaUpdatePath;
  bool _isDeltaUpdate = false;
  
  UpdateManager({
    required IPlatformAdapter platformAdapter,
    required IConfigManager configManager,
    required IDownloadEngine downloadEngine,
    required ILogger logger,
  })  : _platformAdapter = platformAdapter,
        _configManager = configManager,
        _downloadEngine = downloadEngine,
        _logger = logger;
  
  @override
  Future<UpdateInfo?> checkForUpdates() async {
    try {
      _updateStatus = UpdateStatus.checking;
      _logger.info('开始检查更新...');
      
      String currentVersion = await _getCurrentVersion();
      _logger.info('当前版本: $currentVersion');
      
      UpdateInfo? latestVersion = await _fetchLatestVersionInfo();
      if (latestVersion == null) {
        _updateStatus = UpdateStatus.none;
        return null;
      }
      
      if (_isVersionNewer(latestVersion.version, currentVersion)) {
        _pendingUpdate = latestVersion;
        _updateStatus = UpdateStatus.available;
        await _configManager.saveConfig('pending_update', jsonEncode({
          'version': latestVersion.version,
          'downloadUrl': latestVersion.downloadUrl,
          'changelog': latestVersion.changelog,
          'checksum': latestVersion.checksum,
          'checksumType': latestVersion.checksumType,
          'fileSize': latestVersion.fileSize,
          'releaseDate': latestVersion.releaseDate.toIso8601String(),
        }));
        _logger.info('发现新版本: ${latestVersion.version}');
        return latestVersion;
      } else {
        _updateStatus = UpdateStatus.none;
        _logger.info('当前已是最新版本');
        return null;
      }
    } catch (e) {
      _updateStatus = UpdateStatus.failed;
      _logger.error('检查更新失败: $e');
      throw UpdateException('检查更新失败: $e');
    }
  }
  
  @override
  Future<void> downloadUpdate(
    UpdateInfo updateInfo, {
    Function(double)? onProgress,
    Function(String)? onError,
  }) async {
    try {
      _updateStatus = UpdateStatus.downloading;
      _logger.info('开始下载更新: ${updateInfo.version}');
      
      String updateDir = '${_platformAdapter.cacheDirectory}${Platform.pathSeparator}updates';
      await _platformAdapter.createDirectory(updateDir);
      
      // 检查是否支持增量更新
      _isDeltaUpdate = await _checkDeltaUpdateSupport(updateInfo);
      
      if (_isDeltaUpdate) {
        _logger.info('使用增量更新');
        String currentVersion = await _getCurrentVersion();
        String deltaUrl = '${updateInfo.downloadUrl.replaceAll('.zip', '')}_delta_${currentVersion}_${updateInfo.version}.zip';
        _deltaUpdatePath = '$updateDir${Platform.pathSeparator}bamclauncher_delta_${currentVersion}_${updateInfo.version}.zip';
        
        await _downloadEngine.downloadFile(
          deltaUrl,
          _deltaUpdatePath!,
          onProgress: (progress) {
            onProgress?.call(progress);
            _logger.info('增量更新下载进度: ${(progress * 100).toStringAsFixed(2)}%');
          },
          onError: (error) {
            _logger.warn('增量更新下载失败，回退到全量更新: $error');
            _isDeltaUpdate = false;
            onError?.call('增量更新失败，正在尝试全量更新');
          },
        );
      }
      
      // 如果增量更新失败或不支持，使用全量更新
      if (!_isDeltaUpdate) {
        _logger.info('使用全量更新');
        _updateDownloadPath = '$updateDir${Platform.pathSeparator}bamclauncher_update_${updateInfo.version}.zip';
        
        await _downloadEngine.downloadFile(
          updateInfo.downloadUrl,
          _updateDownloadPath!,
          checksum: updateInfo.checksum,
          checksumType: updateInfo.checksumType,
          onProgress: (progress) {
            onProgress?.call(progress);
            _logger.info('全量更新下载进度: ${(progress * 100).toStringAsFixed(2)}%');
          },
          onError: (error) {
            onError?.call(error);
            _logger.error('全量更新下载失败: $error');
          },
        );
        
        bool isValid = await _downloadEngine.verifyFile(
          _updateDownloadPath!,
          updateInfo.checksum,
          updateInfo.checksumType,
        );
        
        if (!isValid) {
          throw UpdateException('更新包校验失败');
        }
      }
      
      _updateStatus = UpdateStatus.downloaded;
      _logger.info('更新包下载完成: ${updateInfo.version}');
    } catch (e) {
      _updateStatus = UpdateStatus.failed;
      _logger.error('下载更新失败: $e');
      throw UpdateException('下载更新失败: $e');
    }
  }
  
  @override
  Future<bool> installUpdate(UpdateInfo updateInfo) async {
    try {
      _updateStatus = UpdateStatus.installing;
      _logger.info('开始安装更新: ${updateInfo.version}');
      
      String executablePath = await _platformAdapter.getExecutablePath();
      String appDirectory = Directory(executablePath).parent.path;
      
      // 创建备份
      _backupPath = '${_platformAdapter.cacheDirectory}${Platform.pathSeparator}backup_${DateTime.now().millisecondsSinceEpoch}';
      await _platformAdapter.createDirectory(_backupPath!);
      
      // 备份当前应用
      await _backupApp(appDirectory, _backupPath!);
      
      // 应用更新
      if (_isDeltaUpdate && _deltaUpdatePath != null) {
        await _applyDeltaUpdate(_deltaUpdatePath!, appDirectory);
      } else if (_updateDownloadPath != null) {
        await _applyFullUpdate(_updateDownloadPath!, appDirectory);
      } else {
        throw UpdateException('找不到更新包');
      }
      
      // 更新配置
      await _configManager.saveConfig('update_installed', true);
      await _configManager.saveConfig('last_update_version', updateInfo.version);
      await _configManager.removeConfig('pending_update');
      
      _updateStatus = UpdateStatus.installed;
      _logger.info('更新安装完成: ${updateInfo.version}');
      return true;
    } catch (e) {
      _updateStatus = UpdateStatus.failed;
      _logger.error('安装更新失败: $e');
      
      // 自动回滚
      if (_backupPath != null) {
        await rollbackUpdate();
      }
      
      throw UpdateException('安装更新失败: $e');
    }
  }
  
  @override
  Future<bool> rollbackUpdate() async {
    try {
      _logger.info('开始回滚更新...');
      
      String executablePath = await _platformAdapter.getExecutablePath();
      String appDirectory = Directory(executablePath).parent.path;
      
      if (_backupPath == null || !(await _platformAdapter.isDirectory(_backupPath!))) {
        _logger.error('没有找到备份，无法回滚');
        return false;
      }
      
      // 关闭所有相关进程
      await _platformAdapter.killProcesses('bamclauncher');
      
      // 恢复备份
      await _restoreFromBackup(_backupPath!, appDirectory);
      
      // 更新配置
      await _configManager.saveConfig('update_rolled_back', true);
      await _configManager.removeConfig('update_installed');
      
      _updateStatus = UpdateStatus.rolledBack;
      _logger.info('更新回滚完成');
      return true;
    } catch (e) {
      _logger.error('回滚更新失败: $e');
      return false;
    }
  }
  
  @override
  Future<bool> isUpdateAvailable() async {
    if (_pendingUpdate != null) {
      return true;
    }
    
    bool hasPendingUpdate = await _configManager.containsKey('pending_update');
    return hasPendingUpdate;
  }
  
  @override
  Future<UpdateStatus> getUpdateStatus() async {
    return _updateStatus;
  }
  
  @override
  Future<void> cancelUpdate() async {
    // 清理下载文件
    if (_updateDownloadPath != null && await _platformAdapter.isFile(_updateDownloadPath!)) {
      await _platformAdapter.delete(_updateDownloadPath!);
    }
    if (_deltaUpdatePath != null && await _platformAdapter.isFile(_deltaUpdatePath!)) {
      await _platformAdapter.delete(_deltaUpdatePath!);
    }
    
    // 清理状态
    _updateStatus = UpdateStatus.none;
    _pendingUpdate = null;
    _updateDownloadPath = null;
    _deltaUpdatePath = null;
    _backupPath = null;
    _isDeltaUpdate = false;
    
    _logger.info('更新已取消');
  }
  
  Future<String> _getCurrentVersion() async {
    try {
      String? version = await _configManager.loadConfig('app_version');
      if (version != null) {
        return version;
      }
      
      String pubspecPath = '${Directory.current.path}${Platform.pathSeparator}pubspec.yaml';
      if (await _platformAdapter.isFile(pubspecPath)) {
        String content = await _platformAdapter.readFile(pubspecPath);
        RegExp regex = RegExp(r'version:\s*(\d+\.\d+\.\d+)');
        Match? match = regex.firstMatch(content);
        if (match != null) {
          String version = match.group(1)!;
          await _configManager.saveConfig('app_version', version);
          return version;
        }
      }
      return '1.0.0';
    } catch (e) {
      _logger.error('获取当前版本失败: $e');
      return '1.0.0';
    }
  }
  
  Future<UpdateInfo?> _fetchLatestVersionInfo() async {
    try {
      String updateApiUrl = 'https://api.bamclauncher.com/v1/update';
      
      HttpClient client = HttpClient();
      HttpClientRequest request = await client.getUrl(Uri.parse(updateApiUrl));
      HttpClientResponse response = await request.close();
      
      if (response.statusCode == 200) {
        String responseBody = await response.transform(utf8.decoder).join();
        Map<String, dynamic> data = jsonDecode(responseBody);
        
        return UpdateInfo(
          version: data['version'],
          downloadUrl: data['downloadUrl'],
          changelog: data['changelog'],
          checksum: data['checksum'],
          checksumType: data['checksumType'],
          fileSize: data['fileSize'],
          releaseDate: DateTime.parse(data['releaseDate']),
        );
      } else {
        _logger.error('获取版本信息失败，状态码: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.error('获取版本信息失败: $e');
      return null;
    }
  }
  
  bool _isVersionNewer(String latestVersion, String currentVersion) {
    List<int> latestParts = latestVersion.split('.').map(int.parse).toList();
    List<int> currentParts = currentVersion.split('.').map(int.parse).toList();
    
    for (int i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    
    return false;
  }
  
  Future<bool> _checkDeltaUpdateSupport(UpdateInfo updateInfo) async {
    try {
      String currentVersion = await _getCurrentVersion();
      String deltaUrl = '${updateInfo.downloadUrl.replaceAll('.zip', '')}_delta_${currentVersion}_${updateInfo.version}.zip';
      
      HttpClient client = HttpClient();
      HttpClientRequest request = await client.headUrl(Uri.parse(deltaUrl));
      HttpClientResponse response = await request.close();
      
      bool supported = response.statusCode == 200;
      await response.drain();
      return supported;
    } catch (e) {
      _logger.warn('检查增量更新支持失败: $e');
      return false;
    }
  }
  
  Future<void> _backupApp(String appDir, String backupDir) async {
    _logger.info('正在备份应用到: $backupDir');
    
    List<String> files = await _platformAdapter.listFiles(appDir);
    for (String file in files) {
      String sourcePath = '$appDir${Platform.pathSeparator}$file';
      String destPath = '$backupDir${Platform.pathSeparator}$file';
      await _copyFile(sourcePath, destPath);
    }
    
    List<String> dirs = await _platformAdapter.listDirectories(appDir);
    for (String dir in dirs) {
      String sourcePath = '$appDir${Platform.pathSeparator}$dir';
      String destPath = '$backupDir${Platform.pathSeparator}$dir';
      await _copyDirectory(sourcePath, destPath);
    }
  }
  
  Future<void> _applyFullUpdate(String updatePath, String appDir) async {
    _logger.info('正在应用全量更新...');
    
    String tempExtractDir = '${_platformAdapter.cacheDirectory}${Platform.pathSeparator}update_extract';
    await _platformAdapter.createDirectory(tempExtractDir);
    
    await _extractZip(updatePath, tempExtractDir);
    
    await _copyDirectory(tempExtractDir, appDir);
    
    await _platformAdapter.delete(tempExtractDir, recursive: true);
  }
  
  Future<void> _applyDeltaUpdate(String deltaPath, String appDir) async {
    _logger.info('正在应用增量更新...');
    
    String tempExtractDir = '${_platformAdapter.cacheDirectory}${Platform.pathSeparator}delta_extract';
    await _platformAdapter.createDirectory(tempExtractDir);
    
    await _extractZip(deltaPath, tempExtractDir);
    
    await _applyDeltaPatch(tempExtractDir, appDir);
    
    await _platformAdapter.delete(tempExtractDir, recursive: true);
  }
  
  Future<void> _applyDeltaPatch(String deltaDir, String appDir) async {
    List<String> files = await _platformAdapter.listFiles(deltaDir);
    
    for (String file in files) {
      String sourcePath = '$deltaDir${Platform.pathSeparator}$file';
      String destPath = '$appDir${Platform.pathSeparator}$file';
      
      if (file.endsWith('.patch')) {
        await _applyFilePatch(sourcePath, destPath.replaceAll('.patch', ''));
      } else {
        await _copyFile(sourcePath, destPath);
      }
    }
    
    List<String> dirs = await _platformAdapter.listDirectories(deltaDir);
    for (String dir in dirs) {
      String sourcePath = '$deltaDir${Platform.pathSeparator}$dir';
      String destPath = '$appDir${Platform.pathSeparator}$dir';
      await _copyDirectory(sourcePath, destPath);
    }
  }
  
  Future<void> _applyFilePatch(String patchPath, String targetPath) async {
    _logger.info('应用文件补丁: $targetPath');
    File patchFile = File(patchPath);
    String patchContent = await patchFile.readAsString();
    
    // 这里实现简单的文件补丁逻辑
    // 实际项目中可能需要使用更复杂的补丁算法
    File targetFile = File(targetPath);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await targetFile.writeAsString(patchContent);
  }
  
  Future<void> _restoreFromBackup(String backupDir, String appDir) async {
    _logger.info('从备份恢复应用...');
    
    // 删除当前应用目录
    await _platformAdapter.delete(appDir, recursive: true);
    await _platformAdapter.createDirectory(appDir);
    
    // 从备份恢复
    await _copyDirectory(backupDir, appDir);
  }
  
  Future<void> _copyFile(String source, String dest) async {
    File sourceFile = File(source);
    File destFile = File(dest);
    
    await destFile.create(recursive: true);
    await sourceFile.copy(dest);
  }
  
  Future<void> _copyDirectory(String sourceDir, String destDir) async {
    await _platformAdapter.createDirectory(destDir);
    
    List<String> files = await _platformAdapter.listFiles(sourceDir);
    for (String file in files) {
      String sourcePath = '$sourceDir${Platform.pathSeparator}$file';
      String destPath = '$destDir${Platform.pathSeparator}$file';
      await _copyFile(sourcePath, destPath);
    }
    
    List<String> dirs = await _platformAdapter.listDirectories(sourceDir);
    for (String dir in dirs) {
      String sourcePath = '$sourceDir${Platform.pathSeparator}$dir';
      String destPath = '$destDir${Platform.pathSeparator}$dir';
      await _copyDirectory(sourcePath, destPath);
    }
  }
  
  Future<void> _extractZip(String zipPath, String destDir) async {
    _logger.info('正在解压更新包: $zipPath');
    
    try {
      // 使用archive库进行跨平台解压
      File file = File(zipPath);
      List<int> bytes = await file.readAsBytes();
      Archive archive = ZipDecoder().decodeBytes(bytes);
      
      for (ArchiveFile archiveFile in archive) {
        String path = '$destDir${Platform.pathSeparator}${archiveFile.name}';
        if (archiveFile.isFile) {
          List<int> data = archiveFile.content as List<int>;
          File destFile = File(path);
          await destFile.create(recursive: true);
          await destFile.writeAsBytes(data);
        } else {
          Directory dir = Directory(path);
          await dir.create(recursive: true);
        }
      }
    } catch (e) {
      _logger.error('使用archive库解压失败，尝试系统命令: $e');
      
      // 回退到系统命令
      if (Platform.isWindows) {
        ProcessResult result = await Process.run(
          'powershell',
          [
            '-Command',
            'Expand-Archive -Path "$zipPath" -DestinationPath "$destDir" -Force'
          ],
        );
        
        if (result.exitCode != 0) {
          throw UpdateException('解压更新包失败: ${result.stderr}');
        }
      } else if (Platform.isMacOS || Platform.isLinux) {
        ProcessResult result = await Process.run(
          'unzip',
          ['-o', zipPath, '-d', destDir],
        );
        
        if (result.exitCode != 0) {
          throw UpdateException('解压更新包失败: ${result.stderr}');
        }
      } else {
        throw UpdateException('不支持的操作系统');
      }
    }
  }
}