# BAMCLauncher

A cross-platform Minecraft launcher built with Flutter.

## Features

- **Microsoft OAuth2 Authentication** - Official login with Xbox Live support
- **Multi-version Support** - Release, snapshot, old alpha/beta versions
- **Mod Loader Installation** - Forge, Fabric, Quilt, NeoForge, LiteLoader
- **Content Management** - Mods, resource packs, shader packs from CurseForge & Modrinth
- **Modpack Support** - Import/export CurseForge, Modrinth, MMC, PCL, HMCL formats
- **Server Management** - Server list with one-click join
- **BMCLAPI Mirror** - Built-in download mirror for users in China

## Platform Support

| Platform | Minimum Version |
|----------|----------------|
| Windows  | 10 (x64)       |
| macOS    | 10.15 (x64/arm64) |
| Linux    | Ubuntu 20.04+, Fedora 34+, Arch Linux |

## Getting Started

### Install from Release

Download the installer for your platform from [GitHub Releases](https://github.com/MCYXG233/BAMC_Launcher/releases).

### Build from Source

```bash
git clone https://github.com/MCYXG233/BAMC_Launcher.git
cd BAMC_Launcher
flutter pub get
flutter run -d windows   # or macos, linux
```

### Build Release

```bash
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

## Development

### Prerequisites

- Flutter 3.24+ (stable channel)
- Dart SDK 3.5+
- Platform-specific tools:
  - **Windows**: Visual Studio 2022 (Desktop development with C++)
  - **macOS**: Xcode 14+
  - **Linux**: cmake, ninja-build, clang, libgtk-3-dev

### Commands

```bash
flutter pub get                  # Install dependencies
flutter analyze                  # Static analysis (must pass with 0 errors)
dart format --set-exit-if-changed .  # Format check
flutter test                     # Run tests
flutter run -d windows           # Run in development mode
```

### Project Structure

```
lib/
├── main.dart                    # App entrypoint
├── core/                        # Backend logic
│   ├── core.dart                # Barrel file
│   ├── globals.dart             # Global singletons
│   ├── auth/                    # Account management
│   ├── config/                  # App configuration
│   ├── content/                 # Mod/resource pack management
│   ├── download/                # Download engine with mirror support
│   ├── game/                    # Game launcher, Java management
│   ├── logger/                  # Logging & crash analysis
│   ├── platform/                # Platform adapters (Windows/macOS/Linux)
│   ├── version/                 # Version & mod loader management
│   └── ...
└── ui/                          # Frontend
    ├── components/              # Reusable widgets
    ├── pages/                   # Feature pages
    ├── theme/                   # BamcColors, BamcTheme
    └── utils/                   # Utilities
```

Each core module follows the pattern: `interfaces/` (abstract), `implementations/` (concrete), `models/` (data classes).

## Architecture

```
┌───────────────────────────────────────┐
│  UI Layer (BAMC UI Kit)              │
├───────────────────────────────────────┤
│  Business Layer (Modular units)      │
├───────────────────────────────────────┤
│  Core Adapter Layer (Interfaces)     │
├───────────────────────────────────────┤
│  Native Bridge Layer (Platform impl) │
└───────────────────────────────────────┘
```

## Distribution

| Platform | Format |
|----------|--------|
| Windows  | MSI installer + Portable ZIP |
| macOS    | DMG (Intel / Apple Silicon) |
| Linux    | DEB, RPM, AppImage |

## Contributing

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m 'feat: add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

## Acknowledgments

- [HMCL](https://github.com/HMCL-dev/HMCL) - Architecture reference
- [BMCLAPI](https://bmclapi2.bangbang93.com/) - Download mirror service
