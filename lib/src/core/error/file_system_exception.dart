import 'dart:async' as async;
import 'app_exception.dart';

/// 文件系统错误类型
enum FileSystemErrorType {
  /// 路径不存在
  notFound,
  
  /// 权限被拒绝
  permissionDenied,
  
  /// 磁盘空间不足
  insufficientStorage,
  
  /// 文件正在被使用
  fileInUse,
  
  /// 路径格式无效
  invalidPath,
  
  /// 操作超时
  operationTimeout,
  
  /// IO 错误
  ioError,
  
  /// 未知错误
  unknown,
}

/// 文件系统异常
/// 
/// 当文件系统操作失败时抛出。
final class FileSystemException extends AppException {
  /// 相关的文件路径
  final String path;

  /// 错误类型
  final FileSystemErrorType errorType;

  /// 期望的操作（读、写、删除等）
  final String? operation;

  const FileSystemException({
    required String message,
    required this.path,
    this.errorType = FileSystemErrorType.unknown,
    this.operation,
    super.cause,
    super.stackTrace,
  });

  @override
  String get userFriendlyMessage {
    switch (errorType) {
      case FileSystemErrorType.notFound:
        return '文件或目录不存在：${_shortenPath(path)}';
      case FileSystemErrorType.permissionDenied:
        return '没有权限访问：${_shortenPath(path)}';
      case FileSystemErrorType.insufficientStorage:
        return '磁盘空间不足，请清理后重试';
      case FileSystemErrorType.fileInUse:
        return '文件正在被使用：${_shortenPath(path)}';
      case FileSystemErrorType.invalidPath:
        return '路径格式无效：${_shortenPath(path)}';
      case FileSystemErrorType.operationTimeout:
        return '操作超时，请重试';
      case FileSystemErrorType.ioError:
        return '文件读写错误';
      case FileSystemErrorType.unknown:
        return '文件操作失败：${_shortenPath(path)}';
    }
  }

  @override
  String get debugDescription {
    final buffer = StringBuffer('FileSystemException: $userFriendlyMessage');
    buffer.write(', path=$path');
    buffer.write(', errorType=$errorType');
    if (operation != null) buffer.write(', operation=$operation');
    return buffer.toString();
  }

  @override
  FailureSeverity get severity {
    switch (errorType) {
      case FileSystemErrorType.notFound:
      case FileSystemErrorType.permissionDenied:
      case FileSystemErrorType.insufficientStorage:
        return FailureSeverity.high;
      default:
        return FailureSeverity.medium;
    }
  }

  /// 缩短路径显示
  String _shortenPath(String path) {
    if (path.length <= 40) return path;
    // 保留路径的最后部分
    final lastPart = path.split('/').last.split('\\').last;
    if (lastPart.length >= 30) return '...${path.substring(path.length - 30)}';
    return '.../$lastPart';
  }

  /// 工厂方法：从 Dart 原生 FileSystemException 创建
  factory FileSystemException.fromDartException(
    Exception e,
    String path, {
    String? operation,
    StackTrace? stackTrace,
  }) {
    final message = e.toString().toLowerCase();
    FileSystemErrorType errorType;

    if (message.contains('not found') || message.contains('不存在')) {
      errorType = FileSystemErrorType.notFound;
    } else if (message.contains('permission denied') || message.contains('权限')) {
      errorType = FileSystemErrorType.permissionDenied;
    } else if (message.contains('in use') || message.contains('被使用')) {
      errorType = FileSystemErrorType.fileInUse;
    } else if (message.contains('invalid') || message.contains('无效')) {
      errorType = FileSystemErrorType.invalidPath;
    } else {
      errorType = FileSystemErrorType.unknown;
    }

    return FileSystemException(
      message: e.toString(),
      path: path,
      errorType: errorType,
      operation: operation,
      cause: e,
      stackTrace: stackTrace,
    );
  }
}
