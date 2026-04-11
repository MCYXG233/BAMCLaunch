import 'ipc_models.dart';

class IpcProtocol {
  static const String actionGetServerInfo = 'getServerInfo';
  static const String actionConnectToServer = 'connectToServer';
  static const String actionStartLanServer = 'startLanServer';
  static const String actionStopLanServer = 'stopLanServer';
  static const String actionPingServer = 'pingServer';
  static const String actionGetServerList = 'getServerList';
  static const String actionAddServer = 'addServer';
  static const String actionUpdateServer = 'updateServer';
  static const String actionDeleteServer = 'deleteServer';
  static const String actionDiscoverLanServers = 'discoverLanServers';
  static const String actionCreatePortMapping = 'createPortMapping';
  static const String actionDeletePortMapping = 'deletePortMapping';
  static const String actionGetTerracottaStatus = 'getTerracottaStatus';
  static const String actionStartTerracotta = 'startTerracotta';
  static const String actionStopTerracotta = 'stopTerracotta';

  static const String eventServerStatusChanged = 'serverStatusChanged';
  static const String eventLanServerStarted = 'lanServerStarted';
  static const String eventLanServerStopped = 'lanServerStopped';
  static const String eventIpcConnected = 'ipcConnected';
  static const String eventIpcDisconnected = 'ipcDisconnected';
  static const String eventTerracottaStarted = 'terracottaStarted';
  static const String eventTerracottaStopped = 'terracottaStopped';

  static const String errorCodeInvalidRequest = 'INVALID_REQUEST';
  static const String errorCodeServerNotFound = 'SERVER_NOT_FOUND';
  static const String errorCodeConnectionFailed = 'CONNECTION_FAILED';
  static const String errorCodePermissionDenied = 'PERMISSION_DENIED';
  static const String errorCodeInternalError = 'INTERNAL_ERROR';
}

class IpcRequestBuilder {
  static IpcRequest createGetServerInfo(String serverName) {
    return IpcRequest(
      id: _generateId(),
      action: IpcProtocol.actionGetServerInfo,
      data: {'serverName': serverName},
    );
  }

  static IpcRequest createConnectToServer(String serverName, String gameVersion) {
    return IpcRequest(
      id: _generateId(),
      action: IpcProtocol.actionConnectToServer,
      data: {
        'serverName': serverName,
        'gameVersion': gameVersion,
      },
    );
  }

  static IpcRequest createStartLanServer(String worldName, int port) {
    return IpcRequest(
      id: _generateId(),
      action: IpcProtocol.actionStartLanServer,
      data: {
        'worldName': worldName,
        'port': port,
      },
    );
  }

  static IpcRequest createStopLanServer() {
    return IpcRequest(
      id: _generateId(),
      action: IpcProtocol.actionStopLanServer,
      data: {},
    );
  }

  static IpcRequest createPingServer(String address, int port) {
    return IpcRequest(
      id: _generateId(),
      action: IpcProtocol.actionPingServer,
      data: {
        'address': address,
        'port': port,
      },
    );
  }

  static IpcRequest createGetServerList() {
    return IpcRequest(
      id: _generateId(),
      action: IpcProtocol.actionGetServerList,
      data: {},
    );
  }

  static IpcRequest createAddServer(Map<String, dynamic> serverData) {
    return IpcRequest(
      id: _generateId(),
      action: IpcProtocol.actionAddServer,
      data: {'server': serverData},
    );
  }

  static IpcRequest createUpdateServer(Map<String, dynamic> serverData) {
    return IpcRequest(
      id: _generateId(),
      action: IpcProtocol.actionUpdateServer,
      data: {'server': serverData},
    );
  }

  static IpcRequest createDeleteServer(String serverName) {
    return IpcRequest(
      id: _generateId(),
      action: IpcProtocol.actionDeleteServer,
      data: {'serverName': serverName},
    );
  }

  static IpcRequest createDiscoverLanServers() {
    return IpcRequest(
      id: _generateId(),
      action: IpcProtocol.actionDiscoverLanServers,
      data: {},
    );
  }

  static IpcRequest createCreatePortMapping(int internalPort, int externalPort) {
    return IpcRequest(
      id: _generateId(),
      action: IpcProtocol.actionCreatePortMapping,
      data: {
        'internalPort': internalPort,
        'externalPort': externalPort,
      },
    );
  }

  static IpcRequest createDeletePortMapping(int externalPort) {
    return IpcRequest(
      id: _generateId(),
      action: IpcProtocol.actionDeletePortMapping,
      data: {'externalPort': externalPort},
    );
  }

  static IpcRequest createGetTerracottaStatus() {
    return IpcRequest(
      id: _generateId(),
      action: IpcProtocol.actionGetTerracottaStatus,
      data: {},
    );
  }

  static IpcRequest createStartTerracotta() {
    return IpcRequest(
      id: _generateId(),
      action: IpcProtocol.actionStartTerracotta,
      data: {},
    );
  }

  static IpcRequest createStopTerracotta() {
    return IpcRequest(
      id: _generateId(),
      action: IpcProtocol.actionStopTerracotta,
      data: {},
    );
  }

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

class IpcResponseBuilder {
  static IpcResponse createSuccess(String requestId, Map<String, dynamic>? data) {
    return IpcResponse(
      requestId: requestId,
      status: IpcStatus.success,
      data: data,
    );
  }

  static IpcResponse createError(String requestId, String errorMessage, String errorCode) {
    return IpcResponse(
      requestId: requestId,
      status: IpcStatus.error,
      errorMessage: errorMessage,
      data: {'errorCode': errorCode},
    );
  }
}

class IpcEventBuilder {
  static IpcEvent createServerStatusChanged(Map<String, dynamic> serverData) {
    return IpcEvent(
      name: IpcProtocol.eventServerStatusChanged,
      data: {'server': serverData},
    );
  }

  static IpcEvent createLanServerStarted(String worldName, int port) {
    return IpcEvent(
      name: IpcProtocol.eventLanServerStarted,
      data: {
        'worldName': worldName,
        'port': port,
      },
    );
  }

  static IpcEvent createLanServerStopped() {
    return IpcEvent(
      name: IpcProtocol.eventLanServerStopped,
      data: {},
    );
  }

  static IpcEvent createIpcConnected() {
    return IpcEvent(
      name: IpcProtocol.eventIpcConnected,
      data: {},
    );
  }

  static IpcEvent createIpcDisconnected() {
    return IpcEvent(
      name: IpcProtocol.eventIpcDisconnected,
      data: {},
    );
  }

  static IpcEvent createTerracottaStarted() {
    return IpcEvent(
      name: IpcProtocol.eventTerracottaStarted,
      data: {},
    );
  }

  static IpcEvent createTerracottaStopped() {
    return IpcEvent(
      name: IpcProtocol.eventTerracottaStopped,
      data: {},
    );
  }
}