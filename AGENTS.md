# AGENTS.md

## Project

Flutter/Dart cross-platform Minecraft launcher. Package name: `bamclauncher`.

## Commands

```bash
flutter pub get                  # install deps
flutter analyze                  # static analysis (must pass with 0 errors)
dart format --set-exit-if-changed .  # format check (CI enforces)
flutter test                     # run all tests
flutter run -d windows           # run desktop app
```

Single test file: `flutter test test/path/to/file_test.dart`

## Architecture

```
lib/
  main.dart              # app entrypoint
  core/                  # backend logic
    core.dart            # barrel file re-exporting all core modules
    globals.dart         # global singletons (platformAdapter, logger, configManager, etc.)
    auth/                # account management (offline + Microsoft auth)
    config/              # app config with AES encryption support
    content/             # mod/resource pack/shader/map downloads (CurseForge + Modrinth APIs)
    download/            # download engine with mirror support
    game/                # game launcher, Java management, launch args builder
    http/                # HTTP client abstraction
    ipc/                 # inter-process communication
    logger/              # logging, crash analysis, error reporting
    modpack/             # modpack management
    performance/         # memory optimizer, performance monitor
    platform/            # platform adapters (Windows/macOS/Linux), window manager, tray
    server/              # server management with Minecraft SLP protocol
    update/              # self-update with delta update support
    version/             # version/mod loader management
  ui/
    components/          # reusable widgets (buttons, dialogs, inputs, layout, lists, menus, progress, tables, tabs)
    pages/               # feature pages (home, account, content, server, settings, version, modpack)
    theme/               # BamcColors, BamcTheme
    utils/               # BamcEffects, debouncer, error handler, keyboard shortcuts
```

Each core module follows: `interfaces/` (abstract), `implementations/` (concrete), `models/` (data classes).

## Key patterns

- Global singletons are defined in `lib/core/globals.dart` and imported via `package:bamclauncher/core/core.dart`
- UI components import theme via relative paths: `../../theme/colors.dart`, `../../utils/effects.dart`
- `PlatformAdapterFactory.getInstance()` returns platform-specific adapter (singleton)
- JSON serialization uses `json_serializable` with `build_runner` codegen
- Constants use `BamcColors.*` and `BamcEffects.*` throughout UI code

## Encoding gotcha

Many source files originally had corrupted UTF-8 (truncated Chinese characters in comments/strings). The Dart analyzer silently fails on invalid UTF-8, reporting files as "URI doesn't exist" rather than giving an encoding error. If you see `uri_does_not_exist` errors for files that clearly exist, check file encoding with a hex editor. Fix by replacing invalid byte sequences with valid UTF-8.

## CI pipeline

- Runs on: push to `main`/`develop`, PRs to `main`/`develop`
- Flutter version: 3.22.x (stable channel)
- Checks: `flutter analyze`, `dart format`, unused imports, test coverage
- Test matrix: Ubuntu, Windows, macOS

## Dependencies to know

- `window_manager` - desktop window control
- `system_tray` - system tray integration
- `sqflite_common_ffi` - SQLite (desktop)
- `webview_flutter` - Microsoft login webview
- `archive` - ZIP extraction for updates/modpacks
- `crypto` - hashing for download verification

## Warnings

44 warnings remain (unused fields/variables, unused imports, dead code). These are non-blocking but should be cleaned up over time. Run `flutter analyze` to see them.

## Architecture Improvements

参考 HMCL/PCL2 架构，已完成以下改进：

### 下载引擎优化
- `DownloadTaskManager`: 统一的下载任务管理，支持任务状态流和进度流
- `DownloadSourceManager`: 下载源管理器，支持源健康检查和自动切换
- 支持多线程分块下载、断点续传、自动重试

### 游戏启动流程改进
- `GameLaunchManager`: 游戏启动管理器，记录启动历史和事件
- 支持崩溃分析、启动状态跟踪、错误恢复

### 错误处理增强
- `ErrorRecoveryManager`: 错误恢复管理器，支持自动错误恢复
- 定义了网络、下载、文件、版本、游戏启动等错误类型的恢复策略
- 支持重试机制和错误历史记录

## Testing

Tests have been added to cover core functionality:
- `test/core/config/global_config_test.dart` - Config model serialization tests
- `test/core/auth/account_test.dart` - Account model tests
- `test/core/version/version_models_test.dart` - Version model tests
- `test/comprehensive_integration_test.dart` - Integration tests
- `test/enhanced_cross_platform_test.dart` - Cross-platform tests
- `test/stress_test.dart` - Performance stress tests

Run tests with: `flutter test test/`
