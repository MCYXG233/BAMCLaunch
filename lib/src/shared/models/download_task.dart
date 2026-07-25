// 下载任务跟踪视图（用于 UI / 持久化层）
//
// 与 `download/download_task.dart` 中的 `DownloadTask`（核心执行类，继承 Task<String>）
// 职责不同：
// - `DownloadTask` (download/): 实际下载执行（url/savePath/hash/Task<String> 子类）
// - `TrackedDownloadTask` (shared/): UI 层的任务跟踪视图（id/request/status/progress/时间戳）
//
// ## 引用规则
//
// - 业务逻辑层（队列、调度、下载执行）：使用 `download/DownloadTask`
// - UI 层 / 持久化 / 通知：使用 `TrackedDownloadTask`
//
// Re-export canonical types from download/models.dart
// HashType, DownloadRequest, and DownloadProgress are defined there.
export '../../download/models.dart'
    show HashType, DownloadRequest, DownloadProgress;

import '../../download/models.dart'
    show HashType, DownloadRequest, DownloadProgress;

/// 下载任务状态
enum DownloadStatus { pending, downloading, paused, completed, failed }

/// 下载任务跟踪视图
///
/// UI 层和持久化层使用的"任务跟踪"包装，区别于下载执行类 `DownloadTask`。
class TrackedDownloadTask {
  final String id;
  final DownloadRequest request;
  final DownloadStatus status;
  final DownloadProgress? progress;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final int retryCount;

  TrackedDownloadTask({
    required this.id,
    required this.request,
    this.status = DownloadStatus.pending,
    this.progress,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.retryCount = 0,
  });

  TrackedDownloadTask copyWith({
    String? id,
    DownloadRequest? request,
    DownloadStatus? status,
    DownloadProgress? progress,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    int? retryCount,
  }) {
    return TrackedDownloadTask(
      id: id ?? this.id,
      request: request ?? this.request,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request': {
        'url': request.url,
        'savePath': request.savePath,
        'hash': request.hash,
        'hashType': request.hashType?.name,
      },
      'status': status.name,
      'progress': progress != null
          ? {
              'downloadedBytes': progress!.downloadedBytes,
              'totalBytes': progress!.totalBytes,
              'progress': progress!.progress,
              'speed': progress!.speed,
              'remainingTime': progress!.remainingTime,
            }
          : null,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'errorMessage': errorMessage,
      'retryCount': retryCount,
    };
  }

  factory TrackedDownloadTask.fromJson(Map<String, dynamic> json) {
    final requestJson = json['request'] as Map<String, dynamic>;
    final request = DownloadRequest(
      url: requestJson['url'] as String,
      savePath: requestJson['savePath'] as String,
      hash: requestJson['hash'] as String?,
      hashType: requestJson['hashType'] != null
          ? HashType.values.firstWhere(
              (e) => e.name == requestJson['hashType'],
              orElse: () => HashType.sha1,
            )
          : null,
    );

    final progressJson = json['progress'] as Map<String, dynamic>?;
    DownloadProgress? progress;
    if (progressJson != null) {
      progress = DownloadProgress(
        downloadedBytes: progressJson['downloadedBytes'] as int,
        totalBytes: progressJson['totalBytes'] as int,
        progress: progressJson['progress'] as double,
        speed: progressJson['speed'] as int,
        remainingTime: progressJson['remainingTime'] as int,
      );
    }

    return TrackedDownloadTask(
      id: json['id'] as String,
      request: request,
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DownloadStatus.pending,
      ),
      progress: progress,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }
}
