# BAMCLaunch Domain Model

## Language

**Account**:
A Minecraft player account with authentication credentials. Can be offline, Microsoft, or Authlib type.
_Avoid_: user, profile (reserved for Minecraft profile data)

**Instance**:
A configured Minecraft game environment with specific version, mods, and settings.
_Avoid_: game instance, profile (overloaded), configuration

**Resource**:
A mod, resource pack, shader pack, or world file used by an Instance.
_Avoid_: addon, plugin (Minecraft-specific terminology)

**Launcher**:
The core component responsible for starting Minecraft with the correct arguments.

**Platform Adapter**:
Abstraction layer for platform-specific operations (file system, paths, etc.).

**Service Locator**:
Dependency injection container for managing service instances.

**Event Bus**:
Publish-subscribe mechanism for inter-component communication.

## Relationships

- An **Account** can be selected as the active account for launching
- An **Instance** belongs to one **Game Directory**
- An **Instance** contains many **Resources**
- The **Launcher** uses one **Account** and one **Instance** to start the game
- The **Service Locator** manages all core services

## Flagged ambiguities

- "Profile" is overloaded - used for both Minecraft player profiles and launch configurations
- "Configuration" appears in multiple contexts (InstanceConfig, app config)
- "Resource" includes multiple types (mods, resource packs, shader packs)

## Resolved Decisions

### Portable Mode

- **Portable Root**: The directory containing the launcher executable or `.app` bundle
  - On macOS: The directory containing the `.app` bundle (e.g., `/Applications`, `~/Desktop`)
  - On Windows/Linux: The directory containing the executable
- **Portable Flag**: A file named `portable.txt` placed in the portable root
  - NOT inside the `.app` bundle (which is read-only on macOS)
  - NOT in a subdirectory
- **Portable Data**: Game data stored at `{portableRoot}/.minecraft` when portable mode is active

### Sandbox Detection (Linux)

- **Detection**: Check for `FLATPAK_ID` or `SNAP` environment variables
- **Permission Check**: Use proactive detection via write-test file (not exception catching)
- **Fallback Strategy**: 
  1. Try `~/.minecraft` first
  2. If inaccessible, use sandbox-internal data directory
  3. Never silently degrade from portable to installed mode

## Open Questions

1. Should we distinguish between "launch configuration" and "instance"?
2. How should we handle the relationship between ResourceCenter and ModManager?
3. ~~Should ServiceLocator itself be injectable or remain a singleton?~~ **RESOLVED: Use Root Widget Injection**

### Architecture > DI Strategy

- **ServiceLocator is NOT a singleton** - it should be a regular object injected via `Provider`/`InheritedWidget`
- **Lifecycle**: Created at app startup, passed through widget tree
- **Testing**: Each test creates its own `ServiceLocator` instance for isolation
- **Usage**: `Provider.of<ServiceLocator>(context).get<T>()` or `context.read<ServiceLocator>().get<T>()`
- **Benefits**: 
  - No global mutable state pollution in tests
  - Runtime service replacement (e.g., switching AuthService on logout)
  - Explicit dependency visibility

### Architecture > Event Strategy

**Event Classification:**
- **Global Events**: Theme changes, user logout, network changes - use `GlobalEventBus` singleton
- **Local Events**: Download progress, list refresh, form state - use BLoC/Riverpod per component

**GlobalEventBus Rules:**
- MUST return `StreamSubscription` from `on()` method
- MUST provide `EventBusMixin` for automatic subscription cleanup
- PROHIBITED from sending UI-bound local events

**Local Event Rules:**
- Use BLoC or Riverpod StateNotifier per feature
- Each component manages its own stream lifecycle

### Architecture > Error Handling Strategy

**Exception Hierarchy (sealed class):**
- `AppException` (base)
  - `NetworkException` - HTTP errors, timeouts
  - `AuthException` - Token expired, invalid credentials
  - `FileSystemException` - Path not found, permission denied
  - `GameLaunchException` - Java not found, JVM crash

**Error Presentation:**
- `userFriendlyMessage`: Short, actionable message for UI
- `debugDescription`: Full technical details for logging
- `ErrorHandler.report()`: Centralized logging and remote reporting

**Failure Severity Matrix:**
| Severity | Examples | Strategy |
|----------|----------|----------|
| Low | Background refresh fails | Silent fail + log |
| Medium | User-initiated action fails | Show SnackBar/Toast |
| High | Config save, instance create | Dialog with retry options |
| Critical | Game launch fails | Diagnostic UI + copyable info |
| Auth | Token expired | Auto-show login, preserve context |

**Result Type:**
- Use `Result<T, E>` / `Either` for expected failures
- Reserve exceptions for truly unexpected system errors

### Features > Authentication

**Token Refresh Strategy:**
- Lazy refresh: Check token validity before any API call
- Pre-check on launcher startup: Refresh if expires within 1 hour
- Force validate before game launch: Refresh if expires within 10 minutes
- On 401 response: Attempt refresh, then re-authenticate if refresh token expired

**Multi-Account Model:**
- Account types: `microsoft`, `offline`
- Global active account: One account can be globally active
- Instance binding: Each instance can override with specific account
- Selection priority: Instance binding > Global active > First valid > Prompt user

**Offline Mode:**
- Stored as separate account type (no tokens)
- Generates local UUID on first creation
- No network authentication required
- Warning shown when joining servers that may require premium

### Features > Download Engine

**Resume Support:**
- HTTP Range requests for partial downloads
- Temp files + `.meta` files store: url, size, etag, downloaded bytes
- On restart: read `.meta`, resume from byte offset
- Verify SHA-1/SHA-256 after completion

**Multi-Source Strategy:**
- Primary: Official CDN (Mojang, Modrinth, CurseForge)
- Fallback: BMCLAPI mirror (China), custom mirrors
- Auto-switch on failure (5xx, timeout, connection error)
- Source health check on startup or hourly

**Concurrency Control:**
- Default 3-5 concurrent downloads
- Configurable via settings (1-20 range)
- Priority queue: game core files > mods
- Use Semaphore/Pool pattern

**Rate Limiting (Optional):**
- Token bucket algorithm
- UI toggle: Unlimited / 5 MB/s / 10 MB/s
- Interface预留，初期可省略

### Features > Instance Management

**Missing Instance Handling:**
- Detect on startup and on user interaction
- Mark as `InstanceStatus.missing`, disable launch
- Provide "relocate" button to re-point to new directory
- Validate new directory contains Minecraft structure

**Corrupted Config Handling:**
- Backup to `.instance.json.corrupted`
- Attempt recovery: read version from `versions/` folder, use defaults for rest
- On failure: prompt user with options (manual fix, delete, recreate)

**Import from Other Launchers:**
- Support: HMCL, PCL2, BakaXL, Official
- Auto-detect launcher type from directory structure
- Use symlinks by default to save space
- Wizard UI: select source → show versions → choose copy/symlink → confirm

### Architecture > State Management

**Library**: Riverpod (not Provider)
- No BuildContext dependency (can read state in services)
- Compile-time type safety
- Composable providers

**State Layers:**
| Type | Examples | Storage |
|------|----------|---------|
| Global App | Theme, account, download queue, blur strength | Riverpod top-level |
| Page/Component | Selected instance, dialog visibility | StatefulWidget or StateProvider |
| Persisted | Theme, animation speed, concurrency | SharedPreferences/Hive + auto-sync |

**Blue Archive UI Requirements:**
- Theme switching: `themeProvider` controls entire app theme
- Blur intensity: Adjustable via `blurStrengthProvider`
- Page transitions: Hero + custom curves
- Responsive layout: `screenSizeProvider`

### Features > Mod Compatibility

**Version Compatibility:**
- Browse: Filter by loader (Fabric/Forge/NeoForge) and game version
- Manual add: Allow but mark incompatible with red warning
- Version switch: Auto-recheck all mods

**Conflict Detection:**
- Known conflict database (JSON): OptiFine vs Sodium, Lithium vs BetterFps, etc.
- Library version conflicts: Detect duplicate embedded libraries
- Never auto-disable: Warn only, let user decide

**OptiFine Alternative:**
- Detect OptiFine + Sodium/Iris coexistence
- Recommend alternatives: Sodium + Lithium + Phosphor + Iris (Fabric)
- Offer "disable OptiFine and install recommended" button

**Load Order:**
- Let Forge/Fabric handle ordering automatically
- Startup check: Ensure all dependencies are present
- Block duplicate mod IDs

### Architecture > Testing Strategy

**Test Pyramid:**
- 70% Unit tests (fast, cheap)
- 20% Integration tests (critical flows)
- 10% UI tests (core user paths)

**Priority:**
| Priority | Test Targets | Reason |
|----------|--------------|--------|
| P0 | AuthManager, DownloadEngine | Core functionality |
| P1 | InstanceManager, Version parsing | File operations, boundaries |
| P2 | Error handling, Mod compatibility | Diagnostics, complexity |
| P3 | UI rendering | Key paths only |

**Mock Strategy:**
- Use `mocktail` for mocking
- Fake implementations for: FileSystem, Clock, HTTP client
- Inject fakes via DI for full control

**Platform Testing:**
- Isolate platform differences via `PlatformAdapter`
- Unit tests: Use `FakePlatformAdapter`
- Integration tests: Run on respective OS via CI matrix

### Architecture > Logging

**Log Levels:** DEBUG / INFO / WARN / ERROR / FATAL
- Production default: INFO
- Debug mode (user toggle): DEBUG

**Format:** Human-readable (not JSON by default)
```
[2025-01-15T10:23:45.123Z] [INFO] [AuthManager] Token refreshed
```
Structured JSON only for diagnostic export

**Output Targets:**
| Level | Console | File | Remote |
|-------|---------|------|--------|
| DEBUG | Dev only | No | No |
| INFO | Dev only | Yes | No |
| ERROR | Yes | Yes | 10% sample |
| FATAL | Yes | Yes | 100% |

**File Rotation:** 10MB max × 5 files
**Sanitization:** Tokens → `<redacted>`, UUIDs → `a1b2c3d4***`, paths → user replaced with `~`

### Architecture > CI/CD

**Platform:** GitHub Actions with matrix build

**Pipeline Triggers:**
| Event | Actions |
|-------|---------|
| PR | flutter analyze + unit tests |
| Push to main | + integration tests + dev build |
| Tag v* | + production build + GitHub Release |

**Version Management:**
- Based on git tags (e.g., `v1.2.3`)
- CI syncs version to `pubspec.yaml`

**Artifacts:**
- Windows: `.exe` installer or `.zip`
- macOS: `.dmg`
- Linux: `.AppImage` or `.deb`

**Signing:**
- Windows: EV code signing certificate
- macOS: Developer ID + notarization
- Linux: Optional GPG

### Architecture > Code Organization

**Directory Structure:**
```
lib/
├── main.dart
├── shared/           # Cross-module types, constants, utils
│   ├── models/       # Account, Instance, Mod, DownloadTask
│   ├── constants/    # Game versions, URLs
│   └── utils/        # General utilities
├── core/             # Infrastructure
│   ├── di/           # ServiceLocator, registration
│   ├── logging/      # LogManager
│   ├── error/        # AppException hierarchy
│   └── platform/     # IPlatformAdapter
└── features/
    ├── auth/
    ├── download/
    ├── instance/
    ├── mod/
    └── settings/
```

**Module Rules:**
- Each feature contains: services/, models/, viewmodels/, views/
- Pure Dart models in `shared/models/`
- Dependency direction: shared ← core ← features
- No circular dependencies between features
- Use barrel exports (`index.dart`) per module

### Architecture > Migration Strategy

**Phased Migration (Hybrid A+B):**

| Phase | Actions | Risk |
|-------|---------|------|
| 0 | Create new directory skeleton | None |
| 1 | Consolidate core/ infrastructure | Low |
| 2 | Copy shared models + export forwarding | Low |
| 3 | Move modules one-by-one | Medium |
| 4 | Delete old dirs + cleanup | Low |

**Shared Model Criteria:**
- Move to `shared/models/` if used by 2+ modules
- Examples: Account, Instance, Mod, DownloadTask
- Keep module-private models in `features/<module>/models/`

**Test Structure:**
```
test/
├── unit/         # Pure unit tests
├── integration/  # Integration tests
└── ui/           # Widget tests
```

**Backward Compatibility:**
- Use `export` forwarding during transition
- Delete forwarding after all imports updated

### Architecture > Riverpod Integration

**Migration Priority:**
| Priority | Scope | Reason |
|----------|-------|--------|
| P0 | Global state (theme, account, download queue) | High reuse |
| P1 | Instance list, Mod list | Core UI |
| P2 | Settings, secondary pages | Lower impact |
| P3 | Dialogs, form state | Use setState |

**Provider Selection:**
| State Type | Example | Provider |
|------------|---------|----------|
| Mutable collection | Download queue | `StateNotifierProvider` |
| Async data | Version list | `FutureProvider` |
| Stream | Progress events | `StreamProvider` |
| Service dependency | AuthManager | `Provider` |
| Derived state | Filtered instances | `Provider` (derived) |

**Integration with ServiceLocator:**
```dart
// ServiceLocator provider
final serviceLocatorProvider = Provider<ServiceLocator>((ref) { ... });

// Business providers consume services
final authManagerProvider = Provider<AuthManager>((ref) {
  return ref.watch(serviceLocatorProvider).get<AuthManager>();
});
```

**New Code Rule:** New features use Riverpod directly (`ConsumerWidget`)

**Backward Compatibility:** `ProviderScope` allows `ChangeNotifierProvider` and Riverpod coexist