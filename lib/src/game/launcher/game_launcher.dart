import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:window_manager/window_manager.dart';
import '../java/models.dart';
import '../java/java_manager.dart';
import '../../account/account.dart';
import '../../account/account_manager.dart';
import '../../version/version_manager.dart';
import '../../version/models.dart';
import '../../config/config_manager.dart';
import '../../config/config_keys.dart';
import '../../core/constants.dart';
import '../../di/service_locator.dart';
import '../../platform/platform_adapter.dart';
import '../../platform/platform_adapter_factory.dart';
import '../../event/event.dart';
import '../../event/event_bus.dart';
import '../../core/logger.dart';
import '../../instance/instance_manager.dart';
import '../../download/index.dart';
import 'models.dart';
import 'argument_builder.dart';
import 'native_library_manager.dart';
import 'game_file_validator.dart';

/// 游戏启动器接口
///
/// 定义了游戏启动器的核心功能接口，包括：
/// - 启动游戏进程
/// - 停止游戏进程
/// - 获取游戏日志流
/// - 获取游戏进程状态流
/// - 管理运行中的进程
///
/// 实现类应确保线程安全，并正确处理进程生命周期。
abstract class IGameLauncher {
  /// 启动游戏
  ///
  /// 根据提供的启动参数启动游戏进程。
  ///
  /// [args] 启动参数，包含游戏版本、账户信息、内存配置等
  ///
  /// 返回 [GameProcessInfo] 包含进程信息的对象
  ///
  /// 可能抛出以下异常：
  /// - [LaunchError.noSuitableJava] 没有找到合适的 Java 运行时
  /// - [LaunchError.selectedJavaUnavailable] 用户指定的 Java 不可用
  /// - [LaunchError.playerValidationFailed] 玩家验证失败
  /// - [LaunchError.processStartFailed] 进程启动失败
  Future<GameProcessInfo> launch(LaunchArguments args);

  /// 停止指定的游戏进程
  ///
  /// [processId] 要停止的进程ID
  ///
  /// 注意：此方法不会等待进程完全终止，只是发送终止信号。
  Future<void> stop(String processId);

  /// 获取指定进程的日志流
  ///
  /// [processId] 进程ID
  ///
  /// 返回一个 [GameLog] 流，如果进程不存在则返回空流。
  Stream<GameLog> getLogStream(String processId);

  /// 获取指定进程的状态流
  ///
  /// [processId] 进程ID
  ///
  /// 返回一个 [GameProcessStatus] 流，用于监听进程状态变化。
  Stream<GameProcessStatus> getStatusStream(String processId);

  /// 获取当前运行中的所有游戏进程
  ///
  /// 返回一个不可修改的进程信息映射表，键为进程ID。
  Map<String, GameProcessInfo> get runningProcesses;

  /// 初始化游戏启动器
  ///
  /// 在首次使用前调用，用于初始化内部状态。
  /// 此方法是幂等的，多次调用不会重复初始化。
  Future<void> initialize();

  /// 释放资源
  ///
  /// 停止所有运行中的进程，关闭所有流控制器，清理内部状态。
  /// 调用此方法后，启动器将不再可用。
  void dispose();
}

/// 游戏启动器实现类
///
/// 负责管理游戏进程的完整生命周期，包括：
/// - Java 运行时选择和验证
/// - 游戏文件完整性校验
/// - 玩家身份验证
/// - 游戏进程启动和监控
/// - 日志收集和状态追踪
///
/// 启动流程分为4个步骤：
/// 1. 选择合适的 Java 运行时
/// 2. 验证游戏文件完整性
/// 3. 验证玩家身份
/// 4. 启动游戏进程
///
/// 使用示例：
/// ```dart
/// final launcher = GameLauncher();
/// await launcher.initialize();
/// final processInfo = await launcher.launch(launchArgs);
/// ```
///
/// 注意：此类采用单例模式，使用 [GameLauncher.instance] 或 [GameLauncher()] 获取实例。
class GameLauncher implements IGameLauncher {
  /// 已知故障模式库
  ///
  /// 键为错误特征字符串，值为对应的诊断建议。
  /// 用于在游戏崩溃时快速匹配并提供修复指导。
  static const Map<String, String> _knownCrashPatterns = {
    'OutOfMemoryError': '内存不足。请在设置中增加分配的内存，或关闭其他程序释放内存。',
    'java.lang.OutOfMemoryError': 'Java 堆内存不足。请在设置中增加分配的内存。',
    'ClassNotFoundException': '缺少必要的类文件。请检查游戏完整性或重新安装。',
    'NoClassDefFoundError': '缺少必要的类文件。请检查 Mod 兼容性或重新安装。',
    'IncompatibleClassChangeError': '类版本冲突。请检查 Mod 兼容性。',
    'UnsupportedClassVersionError': 'Java 版本不兼容。请检查是否使用了正确版本的 Java。',
    'GLFW error 65542': 'GLFW 错误：显卡驱动不兼容。请更新显卡驱动。',
    'GLFW error 65548': 'GLFW 错误：OpenGL 版本过低。请更新显卡驱动。',
    'Could not create the Java Virtual Machine': '无法创建 Java 虚拟机。请检查 Java 路径和 JVM 参数。',
    'java.lang.StackOverflowError': '栈溢出。请检查是否有无限递归或增加栈大小。',
    'LWJGL error': 'LWJGL 初始化失败。请更新显卡驱动或检查 OpenGL 支持。',
    'Shaders not supported': '显卡不支持着色器。请关闭着色器或更新显卡驱动。',
    'Failed to authenticate': '认证失败。请重新登录账户。',
    'Session ID is null': '会话 ID 为空。请重新登录账户。',
    'TimeoutException': '连接超时。请检查网络连接。',
    'SocketException': '网络连接失败。请检查网络设置。',
    'java.net.ConnectException': '连接被拒绝。请检查服务器地址和端口。',
  };

  /// 单例实例
  static GameLauncher? _instance;

  /// 工厂构造函数，返回单例实例
  ///
  /// 如果实例不存在则创建新实例，否则返回现有实例。
  factory GameLauncher() {
    _instance ??= GameLauncher._internal();
    return _instance!;
  }

  /// 内部构造函数
  GameLauncher._internal();

  /// 获取单例实例
  static GameLauncher get instance =>
      ServiceLocator.instance.tryGet<GameLauncher>() ??
      (_instance ??= GameLauncher._internal());

  /// 重置单例实例
  ///
  /// 主要用于测试场景，清除现有实例。
  static void reset() {
    _instance = null;
  }

  // ==================== 依赖注入字段 ====================

  /// 平台适配器，用于处理平台相关的操作
  final IPlatformAdapter _platformAdapter = PlatformAdapterFactory.create();

  /// 配置管理器，用于读取用户配置
  final IConfigManager _configManager = ConfigManager();

  /// 事件总线，用于发布游戏相关事件
  final EventBus _eventBus = EventBus();

  /// 日志记录器
  final Logger _logger = Logger('GameLauncher');

  // ==================== 进程管理字段 ====================

  /// 运行中的进程信息映射表，键为进程ID
  final Map<String, GameProcessInfo> _runningProcesses = {};

  /// 进程对象映射表，键为进程ID
  final Map<String, Process> _processes = {};

  /// 日志流控制器映射表，键为进程ID
  final Map<String, StreamController<GameLog>> _logControllers = {};

  /// 状态流控制器映射表，键为进程ID
  final Map<String, StreamController<GameProcessStatus>> _statusControllers = {};

  /// 启动状态映射表，键为进程ID
  final Map<String, LaunchingState> _launchingStates = {};

  /// 已检测到的崩溃模式映射表，键为进程ID，值为匹配到的模式 -> 建议
  final Map<String, Map<String, String>> _detectedCrashPatterns = {};

  /// 进程ID计数器，用于生成唯一进程ID
  int _processIdCounter = 0;

  /// 是否已初始化
  bool _initialized = false;

  /// 获取当前运行中的所有游戏进程
  ///
  /// 返回一个不可修改的进程信息映射表。
  @override
  Map<String, GameProcessInfo> get runningProcesses => Map.unmodifiable(_runningProcesses);

  /// 初始化游戏启动器
  ///
  /// 此方法是幂等的，多次调用只会执行一次初始化。
  /// 初始化完成后会记录日志。
  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _logger.info('GameLauncher initialized');
  }

  /// 启动游戏
  ///
  /// 这是游戏启动的主入口方法，负责协调整个启动流程。
  ///
  /// [args] 启动参数，包含以下信息：
  ///   - [LaunchArguments.gameVersion] 游戏版本
  ///   - [LaunchArguments.account] 玩家账户
  ///   - [LaunchArguments.gameDirectory] 游戏目录
  ///   - [LaunchArguments.memory] 分配内存（MB）
  ///   - [LaunchArguments.javaPath] Java路径（可选）
  ///   - [LaunchArguments.jvmArguments] JVM参数（可选）
  ///   - [LaunchArguments.serverAddress] 自动加入服务器地址（可选）
  ///   - [LaunchArguments.serverPort] 服务器端口（可选）
  ///
  /// 返回 [GameProcessInfo] 包含进程ID、启动时间、状态等信息。
  ///
  /// 可能抛出以下异常：
  /// - [LaunchError.selectedJavaUnavailable] 用户指定的Java路径无效
  /// - [LaunchError.noSuitableJava] 无法找到兼容的Java运行时
  /// - [LaunchError.playerValidationFailed] 玩家身份验证失败
  /// - [LaunchError.launchingStateNotFound] 启动状态丢失
  /// - [LaunchError.processStartFailed] 进程启动失败
  ///
  /// 使用示例：
  /// ```dart
  /// final args = LaunchArguments(
  ///   gameVersion: '1.20.1',
  ///   account: offlineAccount,
  ///   gameDirectory: '/path/to/game',
  ///   memory: 4096,
  /// );
  /// final processInfo = await launcher.launch(args);
  /// ```
  @override
  Future<GameProcessInfo> launch(LaunchArguments args) async {
    // 确保启动器已初始化
    if (!_initialized) {
      await initialize();
    }

    // 生成唯一的进程ID
    final processId = 'proc_${DateTime.now().millisecondsSinceEpoch}_${_processIdCounter++}';
    _logger.info('Launching game: ${args.gameVersion} with process ID: $processId');

    // 从配置中读取启动相关设置
    final gcStrategy = _configManager.getString(ConfigKeys.gcStrategy, defaultValue: 'auto')!;
    final fileValidatePolicyStr = _configManager.getString(ConfigKeys.fileValidatePolicy, defaultValue: 'normal')!;
    final launcherVisibility = _configManager.getString(ConfigKeys.launcherVisibility, defaultValue: 'always')!;
    
    // 解析文件验证策略
    FileValidatePolicy fileValidatePolicy = FileValidatePolicy.normal;
    if (fileValidatePolicyStr == 'disable') {
      fileValidatePolicy = FileValidatePolicy.disable;
    } else if (fileValidatePolicyStr == 'full') {
      fileValidatePolicy = FileValidatePolicy.full;
    }

    // 构建游戏配置对象
    final gameConfig = GameConfig(
      memory: args.memory,
      jvmArgs: args.jvmArguments,
      gcStrategy: gcStrategy,
      fileValidatePolicy: fileValidatePolicy,
      autoJoinServer: args.serverAddress != null,
      serverAddress: args.serverAddress ?? '',
      serverPort: args.serverPort ?? BAMCConstants.defaultMinecraftPort,
      launcherVisibility: launcherVisibility,
    );

    // 创建启动状态对象，用于跟踪启动进度
    final launchingState = LaunchingState(
      id: processId,
      currentStep: 1,
      gameVersion: args.gameVersion,
      gameDirectory: args.gameDirectory,
      memory: args.memory,
      jvmArgs: args.jvmArguments,
      serverAddress: args.serverAddress,
      serverPort: args.serverPort,
      startTime: DateTime.now(),
    );
    _launchingStates[processId] = launchingState;

    // 创建进程信息对象
    final processInfo = GameProcessInfo(
      processId: processId,
      arguments: args,
      status: GameProcessStatus.starting,
      startTime: DateTime.now(),
    );
    _runningProcesses[processId] = processInfo;
    
    // 创建日志和状态流控制器
    _logControllers[processId] = StreamController<GameLog>.broadcast();
    _statusControllers[processId] = StreamController<GameProcessStatus>.broadcast();
    _statusControllers[processId]!.add(GameProcessStatus.starting);

    try {
      // 执行启动流程的4个步骤
      await _step1SelectJava(processId, args, gameConfig);
      await _step2ValidateFiles(processId, args, gameConfig);
      await _step3ValidatePlayer(processId, args, gameConfig);
      await _step4LaunchGame(processId, args, gameConfig);
      return processInfo;
    } catch (e, stackTrace) {
      _handleLaunchError(processId, e, stackTrace);
      rethrow;
    }
  }

  /// 启动步骤1：选择 Java 运行时
  ///
  /// 根据游戏版本选择合适的 Java 运行时环境。
  /// 如果用户指定了 Java 路径，则验证该路径是否有效；
  /// 否则自动选择与游戏版本兼容的 Java。
  ///
  /// [processId] 进程ID，用于状态追踪
  /// [args] 启动参数
  /// [gameConfig] 游戏配置
  ///
  /// 可能抛出：
  /// - [LaunchError.selectedJavaUnavailable] 用户指定的Java不可用
  /// - [LaunchError.noSuitableJava] 没有找到合适的Java运行时
  Future<void> _step1SelectJava(String processId, LaunchArguments args, GameConfig gameConfig) async {
    _updateLaunchingStep(processId, 1);
    _logger.info('Step 1: Selecting Java runtime');

    JavaInstallation java;
    
    // 如果用户指定了Java路径，则验证并使用该路径
    if (args.javaPath.isNotEmpty) {
      final foundJava = await JavaManager.instance.getJavaInfo(args.javaPath);
      if (foundJava == null) {
        throw LaunchError.selectedJavaUnavailable;
      }
      java = foundJava;
    } else {
      // 否则自动选择与游戏版本兼容的Java
      final foundJava = await JavaManager.instance.getJavaForGameVersion(args.gameVersion);
      if (foundJava == null) {
        throw LaunchError.noSuitableJava;
      }
      java = foundJava;
    }

    _logger.info('Selected Java: ${java.version} at ${java.path}');

    // 检查Java与游戏版本的兼容性，不兼容时仅记录警告
    final isCompatible = JavaManager.instance.isJavaCompatibleWithGame(
      java.version,
      args.gameVersion,
    );
    if (!isCompatible) {
      _logger.warn(
        'Java ${java.version} may not be compatible with game version ${args.gameVersion}',
      );
    }

    // 更新启动状态，记录选中的Java信息
    _updateLaunchingState(processId, (state) => state.copyWith(
      javaPath: java.path,
      javaVersion: java.majorVersion,
    ));
  }

  /// 启动步骤2：验证游戏文件
  ///
  /// 检查游戏文件的完整性，下载缺失或损坏的文件，
  /// 并提取本地库文件（natives）。
  ///
  /// [processId] 进程ID，用于状态追踪
  /// [args] 启动参数
  /// [gameConfig] 游戏配置，包含文件验证策略
  ///
  /// 文件验证策略：
  /// - [FileValidatePolicy.disable] 禁用验证
  /// - [FileValidatePolicy.normal] 标准验证（默认）
  /// - [FileValidatePolicy.full] 完整验证
  Future<void> _step2ValidateFiles(String processId, LaunchArguments args, GameConfig gameConfig) async {
    _updateLaunchingStep(processId, 2);
    _logger.info('Step 2: Validating game files');

    // 获取版本JSON配置
    final versionJson = await _getVersionJson(args.gameVersion);

    // 验证所有游戏文件
    final invalidFiles = await GameFileValidator.instance.validateAll(
      versionJson, args.gameDirectory, gameConfig.fileValidatePolicy);

    // 如果存在无效文件，触发修复下载
    if (invalidFiles.isNotEmpty) {
      _logger.warn('Found ${invalidFiles.length} invalid files, triggering patch');
      await _patchFiles(processId, invalidFiles);
    }

    // 提取本地库文件（natives）到指定目录
    await NativeLibraryManager.instance.extractNativeLibraries(
      versionJson,
      '${args.gameDirectory}/libraries',
      '${args.gameDirectory}/versions/${args.gameVersion}/natives',
    );

    // 更新启动状态，记录版本JSON
    _updateLaunchingState(processId, (state) => state.copyWith(
      versionJson: versionJson.toJson(),
    ));
  }

  /// 修复缺失或损坏的游戏文件
  ///
  /// 遍历无效文件列表，逐个下载修复。
  ///
  /// [processId] 进程ID（用于日志记录）
  /// [invalidFiles] 无效文件列表
  Future<void> _patchFiles(String processId, List<InvalidFile> invalidFiles) async {
    _logger.info('Patching ${invalidFiles.length} files');
    for (final file in invalidFiles) {
      _logger.debug('Downloading missing file: ${file.path}');
      if (file.url != null) {
        await DownloadEngine.instance.download(file.url!, file.path);
      }
    }
    _logger.info('All files patched successfully');
  }

  /// 启动步骤3：验证玩家身份
  ///
  /// 验证玩家账户的访问令牌是否有效。
  /// 对于在线账户，如果令牌失效会尝试刷新。
  /// 离线账户跳过验证。
  ///
  /// [processId] 进程ID，用于状态追踪
  /// [args] 启动参数，包含账户信息
  /// [gameConfig] 游戏配置
  ///
  /// 可能抛出：
  /// - [LaunchError.playerValidationFailed] 玩家身份验证失败且无法刷新令牌
  Future<void> _step3ValidatePlayer(String processId, LaunchArguments args, GameConfig gameConfig) async {
    _updateLaunchingStep(processId, 3);
    _logger.info('Step 3: Validating player authentication');

    final account = args.account;

    // 仅对在线账户进行令牌验证
    if (account.type != AccountType.offline) {
      _logger.debug('Validating token for account: ${account.id}');
      final isTokenValid = await AccountManager.instance.isTokenValid(account);

      if (!isTokenValid) {
        // 令牌无效时尝试刷新
        _logger.warn('Token validation failed, attempting to refresh');
        final refreshed = await AccountManager.instance.refreshToken(account);

        if (!refreshed) {
          throw LaunchError.playerValidationFailed;
        }
      }
    }

    // 检查是否有有效的认证信息
    if (account.accessToken == null && account.uuid == null) {
      _logger.warn('No valid authentication, using offline mode');
    }

    // 更新启动状态，记录账户信息
    _updateLaunchingState(processId, (state) => state.copyWith(
      accountId: account.id,
      accountName: account.username,
      accountUuid: account.uuid,
      accountToken: account.accessToken,
    ));
  }

  /// 启动步骤4：启动游戏进程
  ///
  /// 构建启动命令并启动游戏进程，设置输出监听和退出处理。
  ///
  /// [processId] 进程ID，用于状态追踪
  /// [args] 启动参数
  /// [gameConfig] 游戏配置
  ///
  /// 可能抛出：
  /// - [LaunchError.launchingStateNotFound] 启动状态丢失
  /// - [LaunchError.processStartFailed] 进程启动失败
  Future<void> _step4LaunchGame(String processId, LaunchArguments args, GameConfig gameConfig) async {
    _updateLaunchingStep(processId, 4);
    _logger.info('Step 4: Launching game');

    // 获取启动状态
    final state = _launchingStates[processId];
    if (state == null) throw LaunchError.launchingStateNotFound;

    // 从状态中恢复版本JSON
    final versionJson = VersionJson.fromJson(state.versionJson!);

    // 构建启动参数
    final argumentBuilder = ArgumentBuilder(
      gameDirectory: args.gameDirectory,
      versionJson: versionJson,
      isWindows: _platformAdapter.isWindows,
    );

    // 生成完整的启动命令
    final command = await argumentBuilder.buildLaunchCommand(
      javaPath: state.javaPath!,
      gameConfig: gameConfig,
      account: args.account,
      javaMajorVersion: state.javaVersion!,
    );

    // 导出命令字符串用于日志记录
    final fullCommandStr = argumentBuilder.exportFullLaunchCommand(command: command);
    _logger.debug('Launch command: $fullCommandStr');

    // 启动游戏进程
    Process? process;
    try {
      process = await Process.start(
        command.args.first,
        command.args.sublist(1),
        workingDirectory: args.gameDirectory,
        mode: ProcessStartMode.normal,
      );
      _logger.info('Process started with PID: ${process.pid}');
    } catch (e, stackTrace) {
      _logger.error('Failed to start game process', e, stackTrace);
      throw LaunchError.processStartFailed;
    }

    // 更新进程信息
    _processes[processId] = process!;
    final processInfo = _runningProcesses[processId];
    if (processInfo == null) throw LaunchError.launchingStateNotFound;

    processInfo.pid = process!.pid;
    processInfo.status = GameProcessStatus.running;
    _statusControllers[processId]!.add(GameProcessStatus.running);

    // 更新启动状态
    _updateLaunchingState(processId, (state) => state.copyWith(
      fullCommand: fullCommandStr,
      pid: process!.pid,
    ));

    // 发布游戏启动事件
    _eventBus.publish(GameLaunchedEvent(
      processId: processId,
      version: args.gameVersion,
      username: args.account.username,
    ));

    // 根据配置处理启动器窗口可见性
    await _handleLauncherVisibility(gameConfig.launcherVisibility);

    // 设置进程输出和退出监听
    _listenToProcessOutput(processId, process);
    _listenToProcessExit(processId, process);
  }

  /// 处理启动器窗口可见性
  ///
  /// 根据配置决定是否隐藏启动器窗口。
  ///
  /// [visibility] 可见性配置：
  ///   - 'runningHidden' 游戏运行时隐藏
  ///   - 'startHidden' 启动后隐藏
  ///   - 'always' 始终显示（默认）
  Future<void> _handleLauncherVisibility(String visibility) async {
    switch (visibility) {
      case 'runningHidden':
        await windowManager.hide();
        break;
      case 'startHidden':
        await windowManager.hide();
        break;
      case 'always':
      default:
        break;
    }
  }

  /// 恢复启动器窗口可见性
  ///
  /// 在游戏退出后调用，显示并聚焦启动器窗口。
  Future<void> _restoreLauncherVisibility() async {
    await windowManager.show();
    await windowManager.focus();
  }

  /// 停止指定的游戏进程
  ///
  /// 根据操作系统使用不同的方式终止进程：
  /// - Windows: 使用 taskkill 命令强制终止
  /// - 其他系统: 发送 SIGTERM 信号
  ///
  /// [processId] 要停止的进程ID
  @override
  Future<void> stop(String processId) async {
    final process = _processes[processId];
    final processInfo = _runningProcesses[processId];

    if (process == null || processInfo == null) {
      _logger.warn('Process not found: $processId');
      return;
    }

    _logger.info('Stopping game process: $processId');

    // 根据平台选择不同的终止方式
    if (Platform.isWindows) {
      // Windows 使用 taskkill 强制终止进程
      unawaited(Process.run('taskkill', ['/F', '/PID', process.pid.toString()]));
    } else {
      // 其他平台发送终止信号
      process.kill(ProcessSignal.sigterm);
    }
  }

  /// 获取指定进程的日志流
  ///
  /// [processId] 进程ID
  ///
  /// 返回日志流，如果进程不存在则返回空流。
  @override
  Stream<GameLog> getLogStream(String processId) {
    return _logControllers[processId]?.stream ?? const Stream.empty();
  }

  /// 获取指定进程的状态流
  ///
  /// [processId] 进程ID
  ///
  /// 返回状态流，如果进程不存在则返回空流。
  @override
  Stream<GameProcessStatus> getStatusStream(String processId) {
    return _statusControllers[processId]?.stream ?? const Stream.empty();
  }

  /// 释放资源并清理所有进程
  ///
  /// 执行以下操作：
  /// 1. 停止所有运行中的游戏进程
  /// 2. 关闭所有日志和状态流控制器
  /// 3. 清空所有内部映射表
  /// 4. 重置初始化状态
  @override
  void dispose() {
    // 停止所有运行中的进程
    for (final processId in _processes.keys.toList()) {
      stop(processId);
    }

    // 关闭所有流控制器
    for (final controller in _logControllers.values) {
      controller.close();
    }
    for (final controller in _statusControllers.values) {
      controller.close();
    }

    // 清空所有映射表
    _logControllers.clear();
    _statusControllers.clear();
    _processes.clear();
    _runningProcesses.clear();
    _launchingStates.clear();
    _detectedCrashPatterns.clear();
    _initialized = false;
  }

  /// 获取版本JSON配置
  ///
  /// 通过版本管理器获取指定游戏版本的JSON配置文件。
  ///
  /// [versionId] 游戏版本ID
  ///
  /// 返回版本JSON对象。
  Future<VersionJson> _getVersionJson(String versionId) async {
    final versionManager = VersionManager();
    return await versionManager.fetchVersionJson(versionId);
  }

  /// 监听进程输出
  ///
  /// 设置进程的标准输出和错误输出监听，将输出转发到日志流。
  /// 同时将日志写入文件。
  ///
  /// [processId] 进程ID
  /// [process] 进程对象
  void _listenToProcessOutput(String processId, Process process) {
    final processInfo = _runningProcesses[processId];
    if (processInfo == null) return;

    // 尝试创建日志文件
    IOSink? logSink;

    try {
      final logDir = Directory('${processInfo.arguments.gameDirectory}/logs');
      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
      }
      final logFile = File('${processInfo.arguments.gameDirectory}/logs/launcher_${processId}.log');
      logSink = logFile.openWrite(mode: FileMode.append);
      logSink.writeln('=== Launcher Log - Process $processId - ${DateTime.now().toIso8601String()} ===');
    } catch (e) {
      _logger.warn('Failed to open log file: $e');
    }

    // 监听标准输出
    final stdoutSubscription = process.stdout
        .transform(const SystemEncoding().decoder)
        .listen(
          (data) => _handleOutput(processId, data, 'stdout', logSink),
          onError: (e) => _logger.error('Stdout stream error: $e'),
          onDone: () => _logger.debug('Stdout stream closed'),
        );

    // 监听错误输出
    final stderrSubscription = process.stderr
        .transform(const SystemEncoding().decoder)
        .listen(
          (data) => _handleOutput(processId, data, 'stderr', logSink),
          onError: (e) => _logger.error('Stderr stream error: $e'),
          onDone: () => _logger.debug('Stderr stream closed'),
        );

    // 进程退出时清理订阅和日志文件
    process.exitCode.then((_) {
      stdoutSubscription.cancel();
      stderrSubscription.cancel();
      logSink?.writeln('=== Log ended - ${DateTime.now().toIso8601String()} ===');
      logSink?.close();
    });
  }

  /// 处理进程输出
  ///
  /// 将进程输出解析为日志对象，添加到进程信息中，
  /// 并发送到日志流和日志文件。
  ///
  /// [processId] 进程ID
  /// [data] 输出数据
  /// [source] 输出来源（'stdout' 或 'stderr'）
  /// [logSink] 日志文件写入器（可选）
  void _handleOutput(String processId, String data, String source, [IOSink? logSink]) {
    final processInfo = _runningProcesses[processId];
    if (processInfo == null) return;

    // 按行处理输出
    final lines = data.split('\n');
    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      // 创建日志对象
      final log = GameLog(
        timestamp: DateTime.now(),
        level: _parseLogLevel(line),
        message: line,
        source: source,
      );

      // 添加到进程信息并发送到流
      processInfo.addLog(log);
      _logControllers[processId]?.add(log);

      // 写入日志文件
      if (logSink != null) {
        try {
          logSink.writeln(log.format());
        } catch (e) {
          _logger.warn('Failed to write to log file: $e');
        }
      }

      // 检查游戏是否就绪和是否有错误
      _checkGameReady(processId, line);
      _checkForErrors(processId, line);
    }
  }

  /// 检查输出中的错误信息
  ///
  /// 扫描输出行中是否包含错误关键字，与已知故障模式库进行匹配。
  /// 匹配到的模式会被记录到 [_detectedCrashPatterns] 中，用于后续崩溃诊断。
  ///
  /// [processId] 进程ID
  /// [line] 输出行
  void _checkForErrors(String processId, String line) {
    final lower = line.toLowerCase();
    // 检查常见的错误关键字
    if (lower.contains('error') ||
        lower.contains('exception') ||
        lower.contains('crash') ||
        lower.contains('failed') ||
        lower.contains('fatal')) {
      _logger.warn('Potential error detected in game output: $line');

      // 与已知故障模式库匹配
      for (final entry in _knownCrashPatterns.entries) {
        if (line.contains(entry.key)) {
          _detectedCrashPatterns.putIfAbsent(processId, () => {});
          final patterns = _detectedCrashPatterns[processId]!;
          if (!patterns.containsKey(entry.key)) {
            patterns[entry.key] = entry.value;
            _logger.warn('Crash pattern matched: ${entry.key} -> ${entry.value}');
          }
        }
      }
    }
  }

  /// 查找最新的崩溃报告文件
  ///
  /// 在游戏目录的 `crash-reports/` 子目录中查找最新的 `.txt` 崩溃报告文件，
  /// 并读取其最后 50 行内容。
  ///
  /// [gameDir] 游戏目录路径
  ///
  /// 返回崩溃报告内容，如果没有找到则返回 null。
  Future<String?> _findLatestCrashReport(String gameDir) async {
    try {
      final crashDir = Directory(path.join(gameDir, 'crash-reports'));
      if (!await crashDir.exists()) return null;

      File? latestFile;
      DateTime? latestTime;

      await for (final entity in crashDir.list()) {
        if (entity is File && entity.path.endsWith('.txt')) {
          final stat = await entity.stat();
          if (latestTime == null || stat.modified.isAfter(latestTime)) {
            latestTime = stat.modified;
            latestFile = entity;
          }
        }
      }

      if (latestFile != null) {
        final lines = await latestFile.readAsLines();
        final tailLines = lines.length > 50
            ? lines.sublist(lines.length - 50)
            : lines;
        return tailLines.join('\n');
      }
    } catch (e) {
      _logger.warn('Failed to read crash report: $e');
    }
    return null;
  }

  /// 分析崩溃日志，生成诊断报告
  ///
  /// 收集进程的最后 [maxLogLines] 行日志，结合已匹配的故障模式，
  /// 生成一份格式化的诊断报告并通过 [CrashDiagnosticEvent] 发布到 EventBus。
  ///
  /// [processId] 进程ID
  /// [maxLogLines] 收集的最大日志行数，默认 50
  ///
  /// 返回格式化的诊断报告字符串。
  Future<String> _analyzeCrashLog(String processId, {int maxLogLines = 50}) async {
    final processInfo = _runningProcesses[processId];
    final matchedPatterns = _detectedCrashPatterns[processId] ?? {};
    final buffer = StringBuffer();

    buffer.writeln('========== 崩溃诊断报告 ==========');
    buffer.writeln('进程ID: $processId');
    buffer.writeln('分析时间: ${DateTime.now().toLocal()}');

    if (processInfo != null) {
      buffer.writeln('游戏版本: ${processInfo.arguments.gameVersion}');
      buffer.writeln('退出码: ${processInfo.exitCode ?? "未知"}');
      buffer.writeln('运行时长: ${processInfo.duration.inSeconds} 秒');
    }

    // 输出匹配到的故障模式及建议
    buffer.writeln();
    if (matchedPatterns.isNotEmpty) {
      buffer.writeln('--- 匹配到的故障模式 ---');
      for (final entry in matchedPatterns.entries) {
        buffer.writeln('  [${entry.key}]');
        buffer.writeln('    建议: ${entry.value}');
      }
    } else {
      buffer.writeln('--- 未匹配到已知故障模式 ---');
      buffer.writeln('  请查看下方日志输出以获取更多线索。');
    }

    // 输出最近的日志上下文
    buffer.writeln();
    buffer.writeln('--- 最近 $maxLogLines 行日志 ---');

    // 检查 crash-reports 目录中的最新崩溃报告
    if (processInfo != null) {
      final crashReport = await _findLatestCrashReport(
        processInfo.arguments.gameDirectory,
      );
      if (crashReport != null) {
        buffer.writeln();
        buffer.writeln('--- crash-reports 最新报告 ---');
        buffer.writeln(crashReport);
        buffer.writeln('--- crash-reports 报告结束 ---');
        buffer.writeln();
      }
    }

    buffer.writeln();
    buffer.writeln('--- 最近 $maxLogLines 行游戏日志 ---');
    if (processInfo != null) {
      final recentLogs = processInfo.getRecentLogs(maxLogLines);
      for (final log in recentLogs) {
        buffer.writeln(log.format());
      }
    } else {
      buffer.writeln('  (进程信息不可用，无法收集日志)');
    }

    buffer.writeln('====================================');

    final report = buffer.toString();
    _logger.info('Crash diagnostic report generated for process $processId');

    // 通过 EventBus 发布诊断事件，使 UI 层能够获取诊断结果
    _eventBus.publish(CrashDiagnosticEvent(
      processId: processId,
      matchedPatterns: Map.unmodifiable(matchedPatterns),
      diagnosticReport: report,
    ));

    return report;
  }

  /// 检查游戏是否已就绪
  ///
  /// 通过检测输出中的特定关键字来判断游戏是否已完全启动。
  /// 检测到就绪后会发布 [GameReadyEvent] 事件。
  ///
  /// [processId] 进程ID
  /// [line] 输出行
  void _checkGameReady(String processId, String line) {
    final processInfo = _runningProcesses[processId];
    if (processInfo == null) return;
    final state = _launchingStates[processId];
    if (state == null) return;

    // 如果已经记录了就绪时间，则跳过
    if (processInfo.readyTime != null) return;

    // 检查游戏就绪的关键字
    final lower = line.toLowerCase();
    final readyKeywords = ['render thread', 'glfw', 'setting user', 'lwjgl'];

    if (readyKeywords.any((keyword) => lower.contains(keyword))) {
      _logger.info('Game is ready');
      processInfo.readyTime = DateTime.now();
      _updateLaunchingState(processId, (state) => state.copyWith(readyTime: DateTime.now()));
      
      // 发布游戏就绪事件
      _eventBus.publish(GameReadyEvent(
        processId: processId,
        version: processInfo.arguments.gameVersion,
        username: processInfo.arguments.account.username,
      ));
    }
  }

  /// 解析日志级别
  ///
  /// 根据输出内容判断日志级别。
  ///
  /// [line] 输出行
  ///
  /// 返回对应的日志级别。
  GameLogLevel _parseLogLevel(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('error') || lower.contains('exception')) {
      return GameLogLevel.error;
    } else if (lower.contains('warn') || lower.contains('warning')) {
      return GameLogLevel.warn;
    } else if (lower.contains('debug')) {
      return GameLogLevel.debug;
    }
    return GameLogLevel.info;
  }

  /// 监听进程退出
  ///
  /// 等待进程退出，根据退出码更新进程状态，
  /// 发布相应的事件，并清理资源。
  ///
  /// [processId] 进程ID
  /// [process] 进程对象
  void _listenToProcessExit(String processId, Process process) async {
    final exitCode = await process.exitCode;

    final processInfo = _runningProcesses[processId];
    if (processInfo == null) return;

    // 记录退出时间和退出码
    processInfo.stopTime = DateTime.now();
    processInfo.exitCode = exitCode;

    if (exitCode == 0) {
      // 正常退出
      processInfo.status = GameProcessStatus.stopped;
      _statusControllers[processId]?.add(GameProcessStatus.stopped);
      _eventBus.publish(GameStoppedEvent(processId: processId, exitCode: exitCode));
      await _restoreLauncherVisibility();
      await _recordPlayTime(processId);
    } else {
      // 异常退出（崩溃）：执行诊断分析
      processInfo.status = GameProcessStatus.crashed;
      processInfo.errorMessage = 'Exit code: $exitCode';
      _statusControllers[processId]?.add(GameProcessStatus.crashed);

      // 分析崩溃日志，生成诊断报告并发布 CrashDiagnosticEvent
      await _analyzeCrashLog(processId);

      _eventBus.publish(GameCrashedEvent(
        processId: processId,
        error: 'Exit code: $exitCode',
        logs: processInfo.getRecentLogs(50).map((log) => log.format()).toList(),
      ));
    }

    _cleanupProcess(processId);
  }

  /// 记录游戏时长
  ///
  /// 计算从游戏就绪到退出的时间，更新实例的游戏时长统计。
  ///
  /// [processId] 进程ID
  Future<void> _recordPlayTime(String processId) async {
    final processInfo = _runningProcesses[processId];
    if (processInfo == null) return;

    // 只有在有就绪时间和停止时间时才记录
    if (processInfo.readyTime != null && processInfo.stopTime != null) {
      final playTime = processInfo.stopTime!.difference(processInfo.readyTime!);
      _logger.info('Recorded play time: ${playTime.inSeconds} seconds');
      
      // 发布游戏时长记录事件
      _eventBus.publish(PlayTimeRecordedEvent(
        version: processInfo.arguments.gameVersion,
        playTime: playTime,
      ));

      // 尝试更新实例的游戏时长统计
      try {
        final instanceManager = InstanceManager();
        final instances = instanceManager.instances;
        try {
          final instance = instances.firstWhere(
            (i) => i.version == processInfo.arguments.gameVersion,
          );
          await instanceManager.updateInstance(
            id: instance.id,
            playTimeSeconds: (instance.playTimeSeconds ?? 0) + playTime.inSeconds,
          );
        } catch (e) {
          // 实例未找到，这是正常情况，不需要处理
        }
      } catch (e) {
        _logger.warn('Failed to update play time: $e');
      }
    }
  }

  /// 处理启动错误
  ///
  /// 记录错误日志，更新进程状态，发布崩溃事件，并清理资源。
  ///
  /// [processId] 进程ID
  /// [error] 错误对象
  /// [stackTrace] 堆栈跟踪
  void _handleLaunchError(String processId, Object error, StackTrace stackTrace) {
    _logger.error('Failed to launch game', error, stackTrace);
    final processInfo = _runningProcesses[processId];
    if (processInfo == null) return;

    // 更新进程状态为崩溃
    processInfo.status = GameProcessStatus.crashed;
    processInfo.errorMessage = error.toString();
    processInfo.stopTime = DateTime.now();
    _statusControllers[processId]?.add(GameProcessStatus.crashed);
    
    // 发布崩溃事件
    _eventBus.publish(GameCrashedEvent(
      processId: processId,
      error: error.toString(),
    ));

    _cleanupProcess(processId);
  }

  /// 更新启动步骤
  ///
  /// 更新启动状态的当前步骤。
  ///
  /// [processId] 进程ID
  /// [step] 步骤编号（1-4）
  void _updateLaunchingStep(String processId, int step) {
    _updateLaunchingState(processId, (state) => state.copyWith(currentStep: step));
  }

  /// 更新启动状态
  ///
  /// 使用更新函数修改启动状态。
  ///
  /// [processId] 进程ID
  /// [updater] 状态更新函数
  void _updateLaunchingState(String processId, LaunchingState Function(LaunchingState) updater) {
    final state = _launchingStates[processId];
    if (state == null) return;
    _launchingStates[processId] = updater(state);
  }

  /// 清理进程资源
  ///
  /// 从内部映射表中移除进程相关数据。
  /// 日志和状态流控制器会延迟10秒关闭，以便客户端能够读取最后的输出。
  ///
  /// [processId] 进程ID
  void _cleanupProcess(String processId) {
    // 立即移除进程和状态
    _processes.remove(processId);
    _runningProcesses.remove(processId);
    _launchingStates.remove(processId);
    _detectedCrashPatterns.remove(processId);

    // 延迟关闭流控制器，给客户端时间读取最后的输出
    Future.delayed(const Duration(seconds: 10), () {
      _logControllers[processId]?.close();
      _statusControllers[processId]?.close();
      _logControllers.remove(processId);
      _statusControllers.remove(processId);
    });
  }
}