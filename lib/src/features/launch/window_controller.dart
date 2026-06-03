import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import '../../../core/logger.dart';
import '../../../event/event.dart';
import '../../../event/event_bus.dart';

/// 窗口可见性模式
enum WindowVisibilityMode {
  /// 始终显示
  always,

  /// 运行时隐藏（游戏就绪后隐藏，退出时显示）
  runningHidden,

  /// 启动时隐藏（游戏启动后隐藏，退出时关闭）
  startHidden,
}

/// 窗口状态
class WindowState {
  /// 是否可见
  final bool isVisible;

  /// 是否获取焦点
  final bool isFocused;

  /// 是否最小化
  final bool isMinimized;

  /// 是否最大化
  final bool isMaximized;

  WindowState({
    required this.isVisible,
    required this.isFocused,
    required this.isMinimized,
    required this.isMaximized,
  });

  factory WindowState.initial() => WindowState(
    isVisible: true,
    isFocused: true,
    isMinimized: false,
    isMaximized: false,
  );

  WindowState copyWith({
    bool? isVisible,
    bool? isFocused,
    bool? isMinimized,
    bool? isMaximized,
  }) {
    return WindowState(
      isVisible: isVisible ?? this.isVisible,
      isFocused: isFocused ?? this.isFocused,
      isMinimized: isMinimized ?? this.isMinimized,
      isMaximized: isMaximized ?? this.isMaximized,
    );
  }
}

/// 窗口控制器
///
/// 控制启动器窗口的可见性和状态
class WindowController {
  static WindowController? _instance;

  factory WindowController() {
    return _instance ??= WindowController._internal();
  }

  WindowController._internal();

  static WindowController get instance =>
      _instance ??= WindowController._internal();

  static void reset() {
    _instance = null;
  }

  final Logger _logger = Logger('WindowController');
  final EventBus _eventBus = EventBus.instance;

  WindowState _currentState = WindowState.initial();
  WindowVisibilityMode _visibilityMode = WindowVisibilityMode.always;
  String? _currentProcessId;
  bool _initialized = false;

  StreamSubscription<GameReadyEvent>? _gameReadySubscription;
  StreamSubscription<GameStoppedEvent>? _gameStoppedSubscription;
  StreamSubscription<GameCrashedEvent>? _gameCrashedSubscription;

  /// 当前可见性模式
  WindowVisibilityMode get visibilityMode => _visibilityMode;

  /// 当前窗口状态
  WindowState get currentState => _currentState;

  /// 是否已初始化
  bool get isInitialized => _initialized;

  /// 初始化窗口控制器
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _logger.info('WindowController initialized');

    // 订阅游戏事件
    _gameReadySubscription = _eventBus.subscribe<GameReadyEvent>((event) {
      _onGameReady(event);
    });

    _gameStoppedSubscription = _eventBus.subscribe<GameStoppedEvent>((event) {
      _onGameStopped(event);
    });

    _gameCrashedSubscription = _eventBus.subscribe<GameCrashedEvent>((event) {
      _onGameCrashed(event);
    });
  }

  /// 设置可见性模式
  Future<void> setVisibilityMode(WindowVisibilityMode mode) async {
    _visibilityMode = mode;
    _logger.info('Window visibility mode set to: $mode');

    switch (mode) {
      case WindowVisibilityMode.always:
        await show();
        break;
      case WindowVisibilityMode.runningHidden:
      case WindowVisibilityMode.startHidden:
        // 不立即隐藏，等待游戏事件
        break;
    }
  }

  /// 显示窗口
  Future<bool> show() async {
    try {
      if (Platform.isWindows) {
        return await _showWindowWindows();
      } else if (Platform.isLinux) {
        return await _showWindowLinux();
      } else if (Platform.isMacOS) {
        return await _showWindowMacOS();
      }
      return false;
    } catch (e, stackTrace) {
      _logger.error('Failed to show window', e, stackTrace);
      return false;
    }
  }

  /// 隐藏窗口
  Future<bool> hide() async {
    try {
      if (Platform.isWindows) {
        return await _hideWindowWindows();
      } else if (Platform.isLinux) {
        return await _hideWindowLinux();
      } else if (Platform.isMacOS) {
        return await _hideWindowMacOS();
      }
      return false;
    } catch (e, stackTrace) {
      _logger.error('Failed to hide window', e, stackTrace);
      return false;
    }
  }

  /// 聚焦窗口
  Future<bool> focus() async {
    try {
      if (Platform.isWindows) {
        return await _focusWindowWindows();
      } else if (Platform.isLinux) {
        return await _focusWindowLinux();
      } else if (Platform.isMacOS) {
        return await _focusWindowMacOS();
      }
      return false;
    } catch (e, stackTrace) {
      _logger.error('Failed to focus window', e, stackTrace);
      return false;
    }
  }

  /// 最小化窗口
  Future<bool> minimize() async {
    try {
      if (Platform.isWindows) {
        return await _minimizeWindowWindows();
      }
      return false;
    } catch (e, stackTrace) {
      _logger.error('Failed to minimize window', e, stackTrace);
      return false;
    }
  }

  /// 最大化窗口
  Future<bool> maximize() async {
    try {
      if (Platform.isWindows) {
        return await _maximizeWindowWindows();
      }
      return false;
    } catch (e, stackTrace) {
      _logger.error('Failed to maximize window', e, stackTrace);
      return false;
    }
  }

  /// 还原窗口
  Future<bool> restore() async {
    try {
      if (Platform.isWindows) {
        return await _restoreWindowWindows();
      }
      return false;
    } catch (e, stackTrace) {
      _logger.error('Failed to restore window', e, stackTrace);
      return false;
    }
  }

  /// 窗口就绪事件处理
  void _onGameReady(GameReadyEvent event) {
    _currentProcessId = event.processId;
    _logger.info('Game ready event received for process: ${event.processId}');

    if (_visibilityMode == WindowVisibilityMode.runningHidden) {
      hide();
    }
  }

  /// 游戏停止事件处理
  void _onGameStopped(GameStoppedEvent event) {
    _logger.info('Game stopped event received for process: ${event.processId}');

    if (_visibilityMode == WindowVisibilityMode.runningHidden) {
      show();
      focus();
    }

    if (_visibilityMode == WindowVisibilityMode.startHidden) {
      // 仅在startHidden模式下，退出时直接退出程序
      _logger.info('Exiting launcher due to startHidden mode');
      exit(0);
    }

    _currentProcessId = null;
  }

  /// 游戏崩溃事件处理
  void _onGameCrashed(GameCrashedEvent event) {
    _logger.info('Game crashed event received for process: ${event.processId}');

    // 游戏崩溃时显示窗口
    show();
    focus();

    _currentProcessId = null;
  }

  // ============ Windows API ============

  /// Windows ShowWindow 命令
  static const int SW_HIDE = 0;
  static const int SW_SHOW = 5;
  static const int SW_MINIMIZE = 6;
  static const int SW_MAXIMIZE = 3;
  static const int SW_RESTORE = 9;
  static const int SW_SHOWDEFAULT = 10;

  /// Windows API 函数类型
  late final DynamicLibrary _user32;
  late final Pointer<NativeFunction<Int32 Function(IntPtr, Int32)>> _showWindowPtr;
  late final Pointer<NativeFunction<IntPtr Function()>> _getForegroundWindowPtr;
  late final Pointer<NativeFunction<Bool Function(IntPtr)>> _setForegroundWindowPtr;
  late final Pointer<NativeFunction<Bool Function(IntPtr)>> _showOwnedPopupsPtr;

  bool _initWindowsApi() {
    try {
      _user32 = DynamicLibrary.open('user32.dll');
      _showWindowPtr = _user32.lookup('ShowWindow');
      _getForegroundWindowPtr = _user32.lookup('GetForegroundWindow');
      _setForegroundWindowPtr = _user32.lookup('SetForegroundWindow');
      _showOwnedPopupsPtr = _user32.lookup('ShowOwnedPopups');
      return true;
    } catch (e) {
      _logger.warn('Failed to initialize Windows API: $e');
      return false;
    }
  }

  Future<bool> _showWindowWindows() async {
    // 由于Flutter窗口管理的限制，使用命令行方式
    try {
      // 使用 PowerShell 获取窗口并显示
      final result = await Process.run('powershell', [
        '-Command',
        '''
        Add-Type -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;
        public class WindowHelper {
            [DllImport("user32.dll")]
            public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
            [DllImport("user32.dll")]
            public static extern IntPtr GetForegroundWindow();
        }
"@
        \$hwnd = (Get-Process -Id \$PID).MainWindowHandle
        if (\$hwnd -ne [IntPtr]::Zero) {
            [WindowHelper]::ShowWindow(\$hwnd, 5) | Out-Null
        }
        '''
      ]);

      _currentState = _currentState.copyWith(isVisible: true);
      _logger.debug('Window shown via Windows API');
      return result.exitCode == 0;
    } catch (e) {
      _logger.warn('Failed to show window via Windows API: $e');
      return false;
    }
  }

  Future<bool> _hideWindowWindows() async {
    try {
      final result = await Process.run('powershell', [
        '-Command',
        '''
        Add-Type -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;
        public class WindowHelper {
            [DllImport("user32.dll")]
            public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        }
"@
        \$hwnd = (Get-Process -Id \$PID).MainWindowHandle
        if (\$hwnd -ne [IntPtr]::Zero) {
            [WindowHelper]::ShowWindow(\$hwnd, 0) | Out-Null
        }
        '''
      ]);

      _currentState = _currentState.copyWith(isVisible: false);
      _logger.debug('Window hidden via Windows API');
      return result.exitCode == 0;
    } catch (e) {
      _logger.warn('Failed to hide window via Windows API: $e');
      return false;
    }
  }

  Future<bool> _focusWindowWindows() async {
    try {
      final result = await Process.run('powershell', [
        '-Command',
        '''
        Add-Type -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;
        public class WindowHelper {
            [DllImport("user32.dll")]
            public static extern bool SetForegroundWindow(IntPtr hWnd);
            [DllImport("user32.dll")]
            public static extern bool ShowOwnedPopups(IntPtr hWnd, bool fShow);
        }
"@
        \$hwnd = (Get-Process -Id \$PID).MainWindowHandle
        if (\$hwnd -ne [IntPtr]::Zero) {
            [WindowHelper]::SetForegroundWindow(\$hwnd) | Out-Null
            [WindowHelper]::ShowOwnedPopups(\$hwnd, \$true) | Out-Null
        }
        '''
      ]);

      _currentState = _currentState.copyWith(isFocused: true);
      return result.exitCode == 0;
    } catch (e) {
      _logger.warn('Failed to focus window via Windows API: $e');
      return false;
    }
  }

  Future<bool> _minimizeWindowWindows() async {
    try {
      final result = await Process.run('powershell', [
        '-Command',
        '''
        Add-Type -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;
        public class WindowHelper {
            [DllImport("user32.dll")]
            public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        }
"@
        \$hwnd = (Get-Process -Id \$PID).MainWindowHandle
        if (\$hwnd -ne [IntPtr]::Zero) {
            [WindowHelper]::ShowWindow(\$hwnd, 6) | Out-Null
        }
        '''
      ]);

      _currentState = _currentState.copyWith(isMinimized: true);
      return result.exitCode == 0;
    } catch (e) {
      _logger.warn('Failed to minimize window: $e');
      return false;
    }
  }

  Future<bool> _maximizeWindowWindows() async {
    try {
      final result = await Process.run('powershell', [
        '-Command',
        '''
        Add-Type -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;
        public class WindowHelper {
            [DllImport("user32.dll")]
            public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        }
"@
        \$hwnd = (Get-Process -Id \$PID).MainWindowHandle
        if (\$hwnd -ne [IntPtr]::Zero) {
            [WindowHelper]::ShowWindow(\$hwnd, 3) | Out-Null
        }
        '''
      ]);

      _currentState = _currentState.copyWith(isMaximized: true, isMinimized: false);
      return result.exitCode == 0;
    } catch (e) {
      _logger.warn('Failed to maximize window: $e');
      return false;
    }
  }

  Future<bool> _restoreWindowWindows() async {
    try {
      final result = await Process.run('powershell', [
        '-Command',
        '''
        Add-Type -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;
        public class WindowHelper {
            [DllImport("user32.dll")]
            public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        }
"@
        \$hwnd = (Get-Process -Id \$PID).MainWindowHandle
        if (\$hwnd -ne [IntPtr]::Zero) {
            [WindowHelper]::ShowWindow(\$hwnd, 9) | Out-Null
        }
        '''
      ]);

      _currentState = _currentState.copyWith(isMaximized: false, isMinimized: false);
      return result.exitCode == 0;
    } catch (e) {
      _logger.warn('Failed to restore window: $e');
      return false;
    }
  }

  // ============ Linux API ============

  Future<bool> _showWindowLinux() async {
    try {
      // 使用 xdotool 或 wmctrl 显示窗口
      final result = await Process.run('xdotool', ['search', '--name', 'BAMCLaunch', 'activate']);
      _currentState = _currentState.copyWith(isVisible: true);
      return result.exitCode == 0;
    } catch (e) {
      _logger.warn('Failed to show window on Linux: $e');
      return false;
    }
  }

  Future<bool> _hideWindowLinux() async {
    try {
      final result = await Process.run('xdotool', ['search', '--name', 'BAMCLaunch', 'minimize']);
      _currentState = _currentState.copyWith(isVisible: false);
      return result.exitCode == 0;
    } catch (e) {
      _logger.warn('Failed to hide window on Linux: $e');
      return false;
    }
  }

  Future<bool> _focusWindowLinux() async {
    try {
      final result = await Process.run('xdotool', ['search', '--name', 'BAMCLaunch', 'raise']);
      _currentState = _currentState.copyWith(isFocused: true);
      return result.exitCode == 0;
    } catch (e) {
      _logger.warn('Failed to focus window on Linux: $e');
      return false;
    }
  }

  // ============ macOS API ============

  Future<bool> _showWindowMacOS() async {
    try {
      final result = await Process.run('osascript', [
        '-e',
        'tell application "System Events" to set visible of process "BAMCLaunch" to true'
      ]);
      _currentState = _currentState.copyWith(isVisible: true);
      return result.exitCode == 0;
    } catch (e) {
      _logger.warn('Failed to show window on macOS: $e');
      return false;
    }
  }

  Future<bool> _hideWindowMacOS() async {
    try {
      final result = await Process.run('osascript', [
        '-e',
        'tell application "System Events" to set visible of process "BAMCLaunch" to false'
      ]);
      _currentState = _currentState.copyWith(isVisible: false);
      return result.exitCode == 0;
    } catch (e) {
      _logger.warn('Failed to hide window on macOS: $e');
      return false;
    }
  }

  Future<bool> _focusWindowMacOS() async {
    try {
      final result = await Process.run('osascript', [
        '-e',
        'tell application "BAMCLaunch" to activate'
      ]);
      _currentState = _currentState.copyWith(isFocused: true);
      return result.exitCode == 0;
    } catch (e) {
      _logger.warn('Failed to focus window on macOS: $e');
      return false;
    }
  }

  /// 释放资源
  void dispose() {
    _gameReadySubscription?.cancel();
    _gameStoppedSubscription?.cancel();
    _gameCrashedSubscription?.cancel();
    _initialized = false;
    _logger.info('WindowController disposed');
  }
}
