import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../core/logger.dart';
import '../core/network_client.dart';
import '../platform/platform_adapter.dart';

/// Terracotta 服务状态枚举
///
/// 用于表示 Terracotta 服务当前的运行状态，便于 UI 层根据不同状态
/// 显示相应的界面元素或执行相应的操作。
///
/// 状态流转：
/// - [notInstalled] → [installing] → [stopped] → [starting] → [running]
/// - 任何状态都可能因错误转为 [error]
/// - [running] 和 [starting] 可以转为 [stopped]
enum TerracottaServiceStatus {
  /// 未安装状态：Terracotta 二进制文件不存在于系统中
  notInstalled,

  /// 安装中状态：正在下载或解压 Terracotta
  installing,

  /// 已停止状态：Terracotta 已安装但未运行
  stopped,

  /// 启动中状态：正在启动 Terracotta 服务
  starting,

  /// 运行中状态：Terracotta 服务正常运行，可以创建/加入房间
  running,

  /// 错误状态：服务启动失败或运行过程中发生错误
  error,
}

/// 网络类型枚举
///
/// 定义 Terracotta 支持的网络连接类型，不同类型有不同的特点和适用场景。
///
/// 各类型特点：
/// - [lan]: 局域网模式，适用于同一局域网内的设备连接，延迟最低
/// - [p2p]: 点对点模式，通过 NAT 穿透实现直连，适用于互联网环境
/// - [relay]: 中继模式，通过服务器中转流量，适用于无法直连的情况
enum NetworkType {
  /// 局域网模式
  lan,

  /// 点对点模式（P2P）
  p2p,

  /// 中继模式
  relay,
}

/// Terracotta 房间信息模型类
///
/// 用于表示 Terracotta 网络中的一个游戏房间，包含房间的基本信息
/// 如名称、主机地址、端口、玩家数量等。该类是不可变的，所有字段都是 final。
///
/// 使用示例：
/// ```dart
/// final room = TerracottaRoom(
///   id: 'room-001',
///   name: '我的游戏房间',
///   host: '192.168.1.100',
///   gamePort: 25565,
///   networkType: NetworkType.p2p,
///   playerCount: 3,
///   hasPassword: true,
/// );
/// ```
///
/// JSON 序列化/反序列化：
/// ```dart
/// // 从 JSON 创建
/// final room = TerracottaRoom.fromJson(jsonMap);
///
/// // 转换为 JSON
/// final json = room.toJson();
/// ```
class TerracottaRoom {
  /// 房间唯一标识符
  ///
  /// 由 Terracotta 服务生成，用于在 API 调用中唯一标识房间。
  final String id;

  /// 房间名称
  ///
  /// 用户创建房间时设置的显示名称，用于在房间列表中展示。
  final String name;

  /// 房间主机地址
  ///
  /// 房间创建者的网络地址，可以是 IP 地址或域名。
  final String host;

  /// 游戏端口
  ///
  /// Minecraft 游戏服务器监听的端口号，默认为 25565。
  final String gamePort;

  /// 网络类型
  ///
  /// 房间使用的网络连接类型，决定客户端如何连接到房间。
  final NetworkType networkType;

  /// 当前玩家数量
  ///
  /// 房间内当前的玩家数量，包括房主。
  final int playerCount;

  /// 是否需要密码
  ///
  /// 如果为 true，加入房间时需要提供正确的密码。
  final bool hasPassword;

  /// 创建 TerracottaRoom 实例
  ///
  /// 所有参数都是必需的，[hasPassword] 默认为 false。
  ///
  /// 参数：
  /// - [id]: 房间唯一标识符
  /// - [name]: 房间名称
  /// - [host]: 主机地址
  /// - [gamePort]: 游戏端口
  /// - [networkType]: 网络类型
  /// - [playerCount]: 玩家数量
  /// - [hasPassword]: 是否有密码，默认 false
  TerracottaRoom({
    required this.id,
    required this.name,
    required this.host,
    required this.gamePort,
    required this.networkType,
    required this.playerCount,
    this.hasPassword = false,
  });

  /// 从 JSON Map 创建 TerracottaRoom 实例
  ///
  /// 工厂构造函数，用于从 API 响应或存储的 JSON 数据反序列化房间信息。
  ///
  /// 参数：
  /// - [json]: 包含房间信息的 Map，键名遵循 snake_case 命名规范
  ///
  /// 返回值：
  /// - 解析后的 [TerracottaRoom] 实例
  ///
  /// JSON 字段映射：
  /// - `id` → [id]
  /// - `name` → [name]
  /// - `host` → [host]
  /// - `game_port` → [gamePort]
  /// - `network_type` → [networkType]
  /// - `player_count` → [playerCount]
  /// - `has_password` → [hasPassword]
  ///
  /// 注意：所有字段都有默认值处理，防止 JSON 中缺少字段导致异常。
  factory TerracottaRoom.fromJson(Map<String, dynamic> json) {
    return TerracottaRoom(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      host: json['host'] as String? ?? '',
      // 端口号默认为 Minecraft 标准端口 25565
      gamePort: json['game_port'] as int? ?? 25565,
      // 网络类型从字符串名称匹配，如果无法匹配则默认为 lan
      networkType: NetworkType.values.firstWhere(
        (t) => t.name == json['network_type'],
        orElse: () => NetworkType.lan,
      ),
      playerCount: json['player_count'] as int? ?? 0,
      hasPassword: json['has_password'] as bool? ?? false,
    );
  }

  /// 将房间信息转换为 JSON Map
  ///
  /// 用于序列化房间信息以便存储或通过网络传输。
  ///
  /// 返回值：
  /// - 包含所有房间信息的 [Map<String, dynamic>]，键名使用 snake_case
  ///
  /// JSON 字段：
  /// - `id`: 房间 ID
  /// - `name`: 房间名称
  /// - `host`: 主机地址
  /// - `game_port`: 游戏端口
  /// - `network_type`: 网络类型名称
  /// - `player_count`: 玩家数量
  /// - `has_password`: 是否有密码
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'game_port': gamePort,
      'network_type': networkType.name,
      'player_count': playerCount,
      'has_password': hasPassword,
    };
  }
}

/// Terracotta 集成管理器
///
/// 负责管理 Terracotta 服务的完整生命周期，包括：
/// - 下载和安装 Terracotta 二进制文件
/// - 启动和停止 Terracotta 服务进程
/// - 通过 HTTP API 与 Terracotta 服务通信
/// - 创建、查询、加入和离开游戏房间
///
/// 该类采用单例模式，确保整个应用中只有一个 Terracotta 服务实例被管理。
///
/// 使用示例：
/// ```dart
/// // 获取单例实例
/// final manager = TerracottaManager();
///
/// // 初始化并检查安装
/// await manager.initialize();
///
/// // 如果未安装，进行安装
/// if (manager.status == TerracottaServiceStatus.notInstalled) {
///   await manager.install(onProgress: (status, progress) {
///     print('$status: ${(progress * 100).toStringAsFixed(1)}%');
///   });
/// }
///
/// // 启动服务
/// await manager.startService(onMessage: (msg) {
///   print('Terracotta: $msg');
/// });
///
/// // 创建房间
/// final room = await manager.createRoom(
///   name: '我的房间',
///   gamePort: 25565,
///   networkType: NetworkType.p2p,
/// );
///
/// // 使用完毕后清理
/// manager.dispose();
/// ```
///
/// 线程安全说明：
/// 该类不是线程安全的，应在主线程中使用。异步操作通过 Future 实现。
class TerracottaManager {
  /// 单例实例
  ///
  /// 使用懒加载方式创建，首次访问 [TerracottaManager()] 时初始化。
  static TerracottaManager? _instance;

  /// 获取 TerracottaManager 单例实例
  ///
  /// 工厂构造函数，确保全局只有一个 TerracottaManager 实例。
  /// 如果实例不存在则创建，否则返回已有实例。
  ///
  /// 返回值：
  /// - [TerracottaManager] 的单例实例
  factory TerracottaManager() {
    _instance ??= TerracottaManager._internal();
    return _instance!;
  }

  /// 私有内部构造函数
  ///
  /// 防止外部直接创建实例，强制使用工厂构造函数获取单例。
  TerracottaManager._internal();

  /// 日志记录器实例
  ///
  /// 用于记录 Terracotta 服务的运行日志，包括信息、警告和错误。
  final Logger _logger = Logger('Terracotta');

  /// 网络客户端实例
  ///
  /// 用于与 Terracotta HTTP API 通信，以及下载 Terracotta 二进制文件。
  final NetworkClient _networkClient = NetworkClient();

  /// 当前服务状态
  ///
  /// 内部维护的状态变量，通过 [status] getter 对外暴露只读访问。
  TerracottaServiceStatus _status = TerracottaServiceStatus.notInstalled;

  /// Terracotta 可执行文件的绝对路径
  ///
  /// 在 [initialize] 方法中设置，用于启动服务进程。
  String? _binaryPath;

  /// API 服务端口号
  ///
  /// Terracotta 服务启动后监听的 HTTP API 端口，默认使用 8080。
  int? _apiPort;

  /// API 访问令牌
  ///
  /// 用于验证 API 请求的身份，启动服务时生成并在后续请求中使用。
  String? _apiToken;

  /// Terracotta 进程实例
  ///
  /// 保存启动的进程引用，用于监控进程状态和终止进程。
  Process? _process;

  /// 当前已知的房间列表
  ///
  /// 缓存从服务获取的房间信息，通过 [rooms] getter 提供只读访问。
  final List<TerracottaRoom> _rooms = [];

  /// 获取当前服务状态
  ///
  /// 返回值：
  /// - 当前 [TerracottaServiceStatus] 枚举值
  TerracottaServiceStatus get status => _status;

  /// 获取当前房间列表
  ///
  /// 返回值：
  /// - 不可修改的房间列表 [List<TerracottaRoom>]
  ///
  /// 注意：返回的是不可修改视图，尝试修改会抛出异常。
  List<TerracottaRoom> get rooms => List.unmodifiable(_rooms);

  /// 获取 Terracotta 下载地址
  ///
  /// 根据当前运行平台返回对应的下载链接。
  ///
  /// 返回值：
  /// - 对应平台的下载 URL 字符串
  ///
  /// 异常：
  /// - [UnsupportedError]: 当运行在不支持的平台上时抛出
  ///
  /// 支持的平台：
  /// - Windows: Terracotta-windows.zip
  /// - Linux: Terracotta-linux.tar.gz
  /// - macOS: Terracotta-macos.zip
  String get _downloadUrl {
    if (Platform.isWindows) {
      return 'https://github.com/burningtnt/Terracotta/releases/latest/download/Terracotta-windows.zip';
    } else if (Platform.isLinux) {
      return 'https://github.com/burningtnt/Terracotta/releases/latest/download/Terracotta-linux.tar.gz';
    } else if (Platform.isMacOS) {
      return 'https://github.com/burningtnt/Terracotta/releases/latest/download/Terracotta-macos.zip';
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// 初始化 Terracotta 管理器并检查安装状态
  ///
  /// 该方法应该在使用其他功能之前首先调用。它会：
  /// 1. 创建 Terracotta 数据目录（如果不存在）
  /// 2. 检查 Terracotta 二进制文件是否存在
  /// 3. 更新内部状态为 [stopped] 或 [notInstalled]
  ///
  /// 返回值：
  /// - [Future<void>]：初始化完成后完成
  ///
  /// 副作用：
  /// - 可能创建目录
  /// - 更新 [_binaryPath] 和 [_status]
  ///
  /// 使用示例：
  /// ```dart
  /// final manager = TerracottaManager();
  /// await manager.initialize();
  /// if (manager.status == TerracottaServiceStatus.notInstalled) {
  ///   // 需要安装
  /// }
  /// ```
  Future<void> initialize() async {
    // 获取应用数据目录
    final appDir = PlatformAdapter.getDataDirectory();
    // 构建 Terracotta 专用目录路径
    final terracottaDir = Directory(path.join(appDir, 'terracotta'));

    // 确保目录存在
    if (!await terracottaDir.exists()) {
      await terracottaDir.create(recursive: true);
    }

    // 设置二进制文件路径
    _binaryPath = path.join(terracottaDir.path, _getBinaryName());

    // 检查二进制文件是否存在并更新状态
    if (await File(_binaryPath!).exists()) {
      _status = TerracottaServiceStatus.stopped;
      _logger.info('Terracotta binary found at $_binaryPath');
    } else {
      _status = TerracottaServiceStatus.notInstalled;
      _logger.info('Terracotta not installed');
    }
  }

  /// 获取当前平台的二进制文件名
  ///
  /// 返回值：
  /// - Windows: 'Terracotta.exe'
  /// - 其他平台: 'Terracotta'
  ///
  /// 返回值：
  /// - 可执行文件名字符串
  String _getBinaryName() {
    if (Platform.isWindows) {
      return 'Terracotta.exe';
    }
    return 'Terracotta';
  }

  /// 下载并安装 Terracotta
  ///
  /// 从 GitHub Releases 下载 Terracotta 并安装到本地数据目录。
  /// 安装过程包括下载、解压和复制可执行文件。
  ///
  /// 参数：
  /// - [onProgress]: 可选的进度回调函数
  ///   - `status`: 当前状态描述文本
  ///   - `progress`: 进度值（0.0 到 1.0）
  ///
  /// 返回值：
  /// - [Future<bool>]: 安装成功返回 true，失败返回 false
  ///
  /// 状态变化：
  /// - 开始时：[notInstalled] → [installing]
  /// - 成功时：[installing] → [stopped]
  /// - 失败时：[installing] → [error]
  ///
  /// 进度分布：
  /// - 下载阶段：0% - 60%
  /// - 解压阶段：60% - 80%
  /// - 安装阶段：80% - 100%
  ///
  /// 使用示例：
  /// ```dart
  /// final success = await manager.install(
  ///   onProgress: (status, progress) {
  ///     print('$status: ${(progress * 100).toFixed(1)}%');
  ///   },
  /// );
  /// if (success) {
  ///   print('安装成功');
  /// }
  /// ```
  ///
  /// 注意：
  /// - 如果已经安装（状态不是 [notInstalled]），直接返回 true
  /// - 安装过程会创建临时文件，完成后自动清理
  Future<bool> install({
    void Function(String status, double progress)? onProgress,
  }) async {
    // 如果不是未安装状态，直接返回成功
    if (_status != TerracottaServiceStatus.notInstalled) {
      return true;
    }

    _logger.info('Downloading Terracotta...');
    _status = TerracottaServiceStatus.installing;

    try {
      // 创建临时目录用于下载和解压
      final tempDir = Directory.systemTemp.createTempSync('terracotta_');
      final zipPath = path.join(tempDir.path, 'terracotta.zip');
      final downloadUrl = _downloadUrl;

      // 开始下载，进度 0%
      onProgress?.call('正在下载 Terracotta...', 0.0);

      // 下载文件，下载进度占总体进度的 60%
      await _networkClient.downloadFile(
        downloadUrl,
        zipPath,
        onProgress: (received, total) {
          if (total > 0) {
            onProgress?.call(
              '正在下载 Terracotta...',
              received / total * 0.6, // 下载进度映射到 0-60%
            );
          }
        },
      );

      // 下载完成，开始解压
      onProgress?.call('正在解压...', 0.6);

      // 创建解压目标目录
      final extractDir = Directory(path.join(tempDir.path, 'extract'));
      await extractDir.create(recursive: true);

      // 执行解压操作
      await _extractArchive(zipPath, extractDir.path);

      // 解压完成，开始安装
      onProgress?.call('正在安装...', 0.8);

      // 在解压目录中查找并复制二进制文件到目标位置
      await _findAndCopyBinary(extractDir.path);

      // 安装完成
      onProgress?.call('安装完成', 1.0);
      _status = TerracottaServiceStatus.stopped;

      // 清理临时目录
      await tempDir.delete(recursive: true);
      _logger.info('Terracotta installed successfully');

      return true;
    } catch (e, stack) {
      // 安装失败，记录错误并更新状态
      _logger.error('Failed to install Terracotta', e, stack);
      _status = TerracottaServiceStatus.error;
      return false;
    }
  }

  /// 解压归档文件
  ///
  /// 将下载的压缩包解压到指定目录。
  ///
  /// 参数：
  /// - [zipPath]: 压缩包文件的绝对路径
  /// - [destPath]: 解压目标目录的绝对路径
  ///
  /// 返回值：
  /// - [Future<void>]: 解压完成后完成
  ///
  /// 注意：
  /// 当前实现为简化版本，实际项目可能需要引入完整的 ZIP 解压库。
  /// TODO: 实现完整的 ZIP/TAR.GZ 解压逻辑
  Future<void> _extractArchive(String zipPath, String destPath) async {
    // 简单的 ZIP 解压占位实现
    // 实际项目可能需要完整的 ZIP 库支持，如 archive 包
    _logger.info('Extracting $zipPath to $destPath');
  }

  /// 在解压目录中查找并复制二进制文件
  ///
  /// 递归遍历解压目录，找到 Terracotta 可执行文件并复制到目标位置。
  /// 对于非 Windows 平台，还会设置可执行权限。
  ///
  /// 参数：
  /// - [extractDir]: 解压目录的绝对路径
  ///
  /// 返回值：
  /// - [Future<void>]: 复制完成后完成
  ///
  /// 异常：
  /// - [Exception]: 如果在解压目录中找不到二进制文件
  ///
  /// 副作用：
  /// - 复制文件到 [_binaryPath] 指定的位置
  /// - 在非 Windows 平台上执行 chmod +x
  Future<void> _findAndCopyBinary(String extractDir) async {
    final dir = Directory(extractDir);

    // 递归遍历目录查找二进制文件
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith(_getBinaryName())) {
        // 找到匹配的文件，复制到目标位置
        await entity.copy(_binaryPath!);

        // 在非 Windows 平台上设置可执行权限
        if (!Platform.isWindows) {
          await Process.run('chmod', ['+x', _binaryPath!]);
        }
        return;
      }
    }

    // 遍历完整个目录都没找到二进制文件
    throw Exception('Binary file not found');
  }

  /// 启动 Terracotta 服务
  ///
  /// 启动 Terracotta 进程并初始化 API 连接。服务启动后可以通过
  /// HTTP API 创建和管理房间。
  ///
  /// 参数：
  /// - [onMessage]: 可选的消息回调函数，用于接收进程的标准输出和错误输出
  ///   - `message`: 进程输出的消息文本
  ///
  /// 返回值：
  /// - [Future<bool>]: 启动成功返回 true，失败返回 false
  ///
  /// 状态变化：
  /// - 开始时：[stopped] → [starting]
  /// - 成功时：[starting] → [running]（检测到 "API server started" 消息）
  /// - 失败时：[starting] → [error]
  ///
  /// 启动参数：
  /// - `--api-port`: API 服务端口，默认 8080
  /// - `--api-token`: API 访问令牌，用于验证请求
  /// - `--ui-mode headless`: 无界面模式运行
  ///
  /// 使用示例：
  /// ```dart
  /// final success = await manager.startService(
  ///   onMessage: (msg) {
  ///     print('Terracotta: $msg');
  ///   },
  /// );
  /// if (success) {
  ///   print('服务启动成功');
  /// }
  /// ```
  ///
  /// 注意：
  /// - 如果服务已经在运行，直接返回 true
  /// - 如果 [_binaryPath] 未设置，会自动调用 [initialize]
  /// - 方法会等待 3 秒确认服务启动成功
  Future<bool> startService({
    void Function(String message)? onMessage,
  }) async {
    // 如果服务已经在运行，直接返回成功
    if (_status == TerracottaServiceStatus.running) {
      return true;
    }

    _logger.info('Starting Terracotta service...');
    _status = TerracottaServiceStatus.starting;

    try {
      // 确保二进制路径已初始化
      if (_binaryPath == null) {
        await initialize();
      }

      // 设置 API 端口和生成访问令牌
      // TODO: 实现动态端口分配，避免端口冲突
      _apiPort = 8080;
      // 生成基于时间戳的唯一令牌
      _apiToken = 'bamclaunch_' + DateTime.now().millisecondsSinceEpoch.toString();

      // 构建启动参数
      final args = [
        '--api-port', _apiPort.toString(),
        '--api-token', _apiToken!,
        '--ui-mode', 'headless', // 无界面模式
      ];

      _logger.info('Starting Terracotta with args: $args');

      // 启动进程
      _process = await Process.start(
        _binaryPath!,
        args,
        workingDirectory: path.dirname(_binaryPath!),
      );

      // 监听标准输出
      _process!.stdout.listen((data) {
        final message = utf8.decode(data).trim();
        if (message.isNotEmpty) {
          _logger.info('[Terracotta] $message');
          onMessage?.call(message);

          // 检测服务启动成功的标志消息
          if (message.contains('API server started')) {
            _status = TerracottaServiceStatus.running;
          }
        }
      });

      // 监听错误输出
      _process!.stderr.listen((data) {
        final message = utf8.decode(data).trim();
        if (message.isNotEmpty) {
          _logger.warning('[Terracotta] $message');
          onMessage?.call('[ERROR] $message');
        }
      });

      // 监听进程退出
      _process!.exitCode.then((code) {
        _logger.info('Terracotta exited with code: $code');
        _status = TerracottaServiceStatus.stopped;
        _process = null;
      });

      // 等待服务启动
      await Future.delayed(const Duration(seconds: 3));
      return _status == TerracottaServiceStatus.running;
    } catch (e, stack) {
      _logger.error('Failed to start Terracotta', e, stack);
      _status = TerracottaServiceStatus.error;
      return false;
    }
  }

  /// 停止 Terracotta 服务
  ///
  /// 终止正在运行的 Terracotta 进程并清理相关资源。
  ///
  /// 返回值：
  /// - [Future<void>]: 停止操作完成后完成
  ///
  /// 副作用：
  /// - 终止 [_process] 进程
  /// - 将 [_status] 设置为 [stopped]
  /// - 将 [_process] 设置为 null
  ///
  /// 使用示例：
  /// ```dart
  /// await manager.stopService();
  /// print('服务已停止');
  /// ```
  ///
  /// 注意：
  /// - 如果服务未运行，此方法不会执行任何操作
  /// - 方法会等待 1 秒确保进程完全终止
  Future<void> stopService() async {
    _logger.info('Stopping Terracotta service...');

    if (_process != null) {
      // 发送终止信号
      _process!.kill();

      // 等待进程完全终止
      await Future.delayed(const Duration(seconds: 1));
      _process = null;
    }

    _status = TerracottaServiceStatus.stopped;
  }

  /// 创建游戏房间
  ///
  /// 通过 Terracotta API 创建一个新的游戏房间。创建成功后房间信息
  /// 会被添加到本地缓存中。
  ///
  /// 参数：
  /// - [name]: 房间名称，将在房间列表中显示
  /// - [gamePort]: 游戏服务器端口号，通常是 Minecraft 的 25565
  /// - [password]: 可选的房间密码，设置后加入房间需要验证
  /// - [networkType]: 网络类型，默认为 [NetworkType.p2p]
  ///
  /// 返回值：
  /// - [Future<TerracottaRoom?>]: 创建成功返回房间信息，失败返回 null
  ///
  /// 异常：
  /// - 无显式异常抛出，所有错误都会被捕获并记录日志
  ///
  /// 前置条件：
  /// - 服务必须处于 [running] 状态
  ///
  /// 使用示例：
  /// ```dart
  /// final room = await manager.createRoom(
  ///   name: '我的游戏房间',
  ///   gamePort: 25565,
  ///   password: 'secret123',
  ///   networkType: NetworkType.p2p,
  /// );
  /// if (room != null) {
  ///   print('房间创建成功: ${room.id}');
  /// }
  /// ```
  ///
  /// 注意：
  /// - 如果服务未运行，会记录警告并返回 null
  /// - 创建成功后房间会自动添加到 [rooms] 列表中
  Future<TerracottaRoom?> createRoom({
    required String name,
    required int gamePort,
    String? password,
    NetworkType networkType = NetworkType.p2p,
  }) async {
    // 检查服务状态
    if (_status != TerracottaServiceStatus.running) {
      _logger.warning('Terracotta service not running');
      return null;
    }

    try {
      // 调用 API 创建房间
      final response = await _networkClient.post(
        'http://localhost:$_apiPort/api/v1/rooms',
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'game_port': gamePort,
          'password': password,
          'network_type': networkType.name,
        }),
      );

      // 检查响应状态
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final room = TerracottaRoom.fromJson(data);

        // 添加到本地缓存
        _rooms.add(room);
        _logger.info('Created room: ${room.name}');
        return room;
      }

      _logger.error('Failed to create room: ${response.statusCode}');
      return null;
    } catch (e) {
      _logger.error('Error creating room', e);
      return null;
    }
  }

  /// 获取房间列表
  ///
  /// 从 Terracotta 服务获取当前所有可用的房间列表。
  /// 获取成功后会更新本地缓存。
  ///
  /// 返回值：
  /// - [Future<List<TerracottaRoom>>]: 房间列表，获取失败返回空列表
  ///
  /// 副作用：
  /// - 更新本地 [_rooms] 缓存
  ///
  /// 前置条件：
  /// - 服务应该处于 [running] 状态，否则返回空列表
  ///
  /// 使用示例：
  /// ```dart
  /// final rooms = await manager.fetchRooms();
  /// for (final room in rooms) {
  ///   print('${room.name} (${room.playerCount} 玩家)');
  /// }
  /// ```
  ///
  /// 注意：
  /// - 此方法会清空并重新填充本地房间缓存
  /// - 网络错误会被捕获并记录日志，返回空列表
  Future<List<TerracottaRoom>> fetchRooms() async {
    // 检查服务状态
    if (_status != TerracottaServiceStatus.running) {
      return [];
    }

    try {
      // 调用 API 获取房间列表
      final response = await _networkClient.get(
        'http://localhost:$_apiPort/api/v1/rooms',
        headers: {'Authorization': 'Bearer $_apiToken'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);

        // 更新本地缓存
        _rooms.clear();
        _rooms.addAll(list.map((d) => TerracottaRoom.fromJson(d)));

        return List.unmodifiable(_rooms);
      }
    } catch (e) {
      _logger.error('Error fetching rooms', e);
    }

    return [];
  }

  /// 加入游戏房间
  ///
  /// 通过 Terracotta API 加入指定的游戏房间。加入成功后会获得
  /// 一个本地端口，可以通过该端口连接到游戏服务器。
  ///
  /// 参数：
  /// - [roomId]: 要加入的房间 ID
  /// - [password]: 可选的房间密码，如果房间有密码保护则需要提供
  /// - [onConnected]: 连接成功回调，参数为本地端口号
  ///
  /// 返回值：
  /// - [Future<bool>]: 加入成功返回 true，失败返回 false
  ///
  /// 前置条件：
  /// - 服务必须处于 [running] 状态
  ///
  /// 使用示例：
  /// ```dart
  /// final success = await manager.joinRoom(
  ///   'room-001',
  ///   password: 'secret123',
  ///   onConnected: (localPort) {
  ///     print('已连接，本地端口: $localPort');
  ///     // 使用 localPort 连接到游戏服务器
  ///     // 例如: connectToServer('localhost', localPort)
  ///   },
  /// );
  /// ```
  ///
  /// 注意：
  /// - [onConnected] 回调只在成功加入后调用
  /// - 本地端口用于连接到 Terracotta 创建的隧道
  Future<bool> joinRoom(
    String roomId, {
    String? password,
    required Function(int localPort) onConnected,
  }) async {
    // 检查服务状态
    if (_status != TerracottaServiceStatus.running) {
      return false;
    }

    try {
      // 调用 API 加入房间
      final response = await _networkClient.post(
        'http://localhost:$_apiPort/api/v1/rooms/$roomId/join',
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final localPort = data['local_port'] as int?;

        if (localPort != null) {
          // 成功加入，回调通知本地端口
          onConnected(localPort);
          return true;
        }
      }

      return false;
    } catch (e) {
      _logger.error('Error joining room', e);
      return false;
    }
  }

  /// 离开游戏房间
  ///
  /// 通过 Terracotta API 离开当前加入的房间。
  ///
  /// 参数：
  /// - [roomId]: 要离开的房间 ID
  ///
  /// 返回值：
  /// - [Future<bool>]: 离开成功返回 true，失败返回 false
  ///
  /// 副作用：
  /// - 从本地 [_rooms] 缓存中移除该房间
  ///
  /// 前置条件：
  /// - 服务应该处于 [running] 状态，否则返回 false
  ///
  /// 使用示例：
  /// ```dart
  /// final success = await manager.leaveRoom('room-001');
  /// if (success) {
  ///   print('已离开房间');
  /// }
  /// ```
  ///
  /// 注意：
  /// - 即使 API 调用失败，也会尝试从本地缓存移除房间
  Future<bool> leaveRoom(String roomId) async {
    // 检查服务状态
    if (_status != TerracottaServiceStatus.running) {
      return false;
    }

    try {
      // 调用 API 离开房间
      await _networkClient.post(
        'http://localhost:$_apiPort/api/v1/rooms/$roomId/leave',
        headers: {'Authorization': 'Bearer $_apiToken'},
      );

      // 从本地缓存移除
      _rooms.removeWhere((r) => r.id == roomId);
      return true;
    } catch (e) {
      _logger.error('Error leaving room', e);
      return false;
    }
  }

  /// 清理资源
  ///
  /// 释放 TerracottaManager 占用的所有资源，包括停止服务进程。
  /// 在应用退出或不再需要 Terracotta 功能时调用。
  ///
  /// 使用示例：
  /// ```dart
  /// // 应用退出时
  /// manager.dispose();
  /// ```
  ///
  /// 注意：
  /// - 此方法是同步的，但内部会异步停止服务
  /// - 调用后不应再使用此实例
  void dispose() {
    stopService();
  }
}