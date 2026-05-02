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

69 warnings remain (unused fields/variables, unused imports, dead code). These are non-blocking but should be cleaned up over time. Run `flutter analyze` to see them.
