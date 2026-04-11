typedef IpcRequestHandler = Future<IpcResponse> Function(IpcRequest request);

enum IpcStatus {
  success,
  error,
  pending,
}

class IpcRequest {
  final String id;
  final String action;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  IpcRequest({
    required this.id,
    required this.action,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory IpcRequest.fromJson(Map<String, dynamic> json) {
    return IpcRequest(
      id: json['id'],
      action: json['action'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class IpcResponse {
  final String requestId;
  final IpcStatus status;
  final Map<String, dynamic>? data;
  final String? errorMessage;
  final DateTime timestamp;

  IpcResponse({
    required this.requestId,
    required this.status,
    this.data,
    this.errorMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'status': status.index,
      'data': data,
      'errorMessage': errorMessage,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory IpcResponse.fromJson(Map<String, dynamic> json) {
    return IpcResponse(
      requestId: json['requestId'],
      status: IpcStatus.values[json['status']],
      data: json['data'],
      errorMessage: json['errorMessage'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class IpcEvent {
  final String name;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  IpcEvent({
    required this.name,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory IpcEvent.fromJson(Map<String, dynamic> json) {
    return IpcEvent(
      name: json['name'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class TerracottaIntegrationConfig {
  final bool enabled;
  final String terracottaPath;
  final String apiEndpoint;
  final bool autoStart;
  final Map<String, dynamic> customConfig;

  TerracottaIntegrationConfig({
    required this.enabled,
    required this.terracottaPath,
    required this.apiEndpoint,
    required this.autoStart,
    required this.customConfig,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'terracottaPath': terracottaPath,
      'apiEndpoint': apiEndpoint,
      'autoStart': autoStart,
      'customConfig': customConfig,
    };
  }

  factory TerracottaIntegrationConfig.fromJson(Map<String, dynamic> json) {
    return TerracottaIntegrationConfig(
      enabled: json['enabled'] ?? false,
      terracottaPath: json['terracottaPath'] ?? '',
      apiEndpoint: json['apiEndpoint'] ?? 'http://localhost:8080',
      autoStart: json['autoStart'] ?? false,
      customConfig: json['customConfig'] ?? {},
    );
  }
}