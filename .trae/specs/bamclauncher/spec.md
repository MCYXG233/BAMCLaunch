# BAMCLauncher - Product Requirement Document

## Overview
- **Summary**: BAMCLauncher is a fully self-developed, cross-platform Minecraft launcher designed for Windows, macOS, and Linux desktop environments, featuring a layered architecture, unified abstract interfaces, and plugin-based modularization for robustness and extensibility.
- **Purpose**: To provide a high-quality, feature-rich Minecraft launcher that matches or exceeds industry-leading launchers while maintaining complete code control through self-developed core capabilities.
- **Target Users**: Minecraft players across Windows, macOS, and Linux platforms who need a reliable, feature-rich launcher with cross-platform consistency.

## Goals
- Create a cross-platform Minecraft launcher with native desktop experience on Windows, macOS, and Linux
- Implement a layered architecture with unified abstract interfaces for maximum extensibility
- Develop core capabilities in-house for complete code control and robustness
- Achieve full functionality parity with industry-leading launchers
- Ensure high performance, security, and user-friendly UI/UX

## Non-Goals (Out of Scope)
- Mobile platform support (iOS/Android)
- Third-party Minecraft launcher SDK integration
- Mobile-first UI patterns or touch-optimized interfaces
- Support for non-desktop platforms

## Background & Context
- BAMCLauncher is built on Flutter 3.22+ with Dart SDK 3.0+ for cross-platform development
- The project follows a strict self-development principle for core capabilities, only using mature low-level dependencies
- The launcher aims to compete with established launchers like PCL2, HMCL, BakaXL, and LaunchX
- The design incorporates Minecraft pixel style with Blue Archive fresh glassmorphism aesthetic

## Functional Requirements
- **FR-1**: Cross-platform compatibility across Windows, macOS, and Linux
- **FR-2**: Microsoft OAuth2 authentication flow (Xbox → XSTS → Minecraft full chain)
- **FR-3**: Multi-account management with offline accounts and Authlib-Injector support
- **FR-4**: Full MC version retrieval and vanilla installation
- **FR-5**: Mod loader auto-install (Forge/Fabric/Quilt/NeoForge)
- **FR-6**: Multi-threaded chunked download with resume and mirror source failover
- **FR-7**: Java auto-detection and installation
- **FR-8**: Game launch with JVM optimization and process monitoring
- **FR-9**: Mod/resource pack/shader/datapack management
- **FR-10**: All-format modpack import/export and auto-install
- **FR-11**: Server list management and one-click join
- **FR-12**: Global config management with encrypted storage
- **FR-13**: Hierarchical logging and global exception capture
- **FR-14**: Auto-update and rollback system
- **FR-15**: Desktop-native UI with Minecraft × Blue Archive design language

## Non-Functional Requirements
- **NFR-1**: Performance - 60fps UI, lazy loading for large lists, strict resource lifecycle management
- **NFR-2**: Security - AES-256 encryption for sensitive data, full HTTPS certificate verification, PKCE for OAuth2
- **NFR-3**: Robustness - Global exception capture, automatic fault tolerance, corruption detection and repair
- **NFR-4**: Cross-platform consistency - Identical behavior across Windows, macOS, and Linux
- **NFR-5**: Maintainability - Layered architecture, unified interfaces, comprehensive documentation

## Constraints
- **Technical**: Flutter 3.22+ (stable channel), Dart SDK 3.0+, only allowed UI dependency: `window_manager`
- **Business**: Full self-development for core capabilities, no third-party Minecraft launcher SDKs
- **Dependencies**: Only allowed low-level dependencies: `crypto`, `archive`, `sqflite_common_ffi`, `xml`

## Assumptions
- Minecraft EULA compliance is maintained
- Microsoft API terms are followed
- GPLv3 open-source license is applied
- Users have internet access for downloads and authentication
- Users have sufficient system resources to run Minecraft

## Acceptance Criteria

### AC-1: Cross-Platform Compatibility
- **Given**: BAMCLauncher is installed on Windows, macOS, and Linux
- **When**: User launches the application
- **Then**: The launcher starts successfully and provides identical functionality across all platforms
- **Verification**: `programmatic`

### AC-2: Microsoft Authentication
- **Given**: User initiates Microsoft login
- **When**: User completes OAuth2 flow
- **Then**: User is successfully authenticated and can access Minecraft accounts
- **Verification**: `programmatic`

### AC-3: Version Management
- **Given**: User requests installation of a specific Minecraft version
- **When**: Launcher downloads and installs the version
- **Then**: Version is installed correctly and can be launched
- **Verification**: `programmatic`

### AC-4: Mod Loader Installation
- **Given**: User requests installation of Forge/Fabric/Quilt/NeoForge
- **When**: Launcher downloads and installs the mod loader
- **Then**: Mod loader is installed correctly and integrated with the selected Minecraft version
- **Verification**: `programmatic`

### AC-5: Download Engine Performance
- **Given**: User initiates a large download (e.g., Minecraft version)
- **When**: Download progresses
- **Then**: Download uses multiple threads, resumes on interruption, and fails over to alternative mirrors if needed
- **Verification**: `programmatic`

### AC-6: Game Launch
- **Given**: User launches Minecraft
- **When**: Launcher detects Java, optimizes JVM, and starts the game
- **Then**: Minecraft starts successfully with optimal performance
- **Verification**: `programmatic`

### AC-7: Content Management
- **Given**: User manages mods/resource packs/shaders/datapacks
- **When**: User installs, updates, or removes content
- **Then**: Content is managed correctly with conflict detection and dependency resolution
- **Verification**: `programmatic`

### AC-8: Modpack Management
- **Given**: User imports or creates a modpack
- **When**: Launcher processes the modpack
- **Then**: Modpack is installed correctly with all dependencies
- **Verification**: `programmatic`

### AC-9: Server Management
- **Given**: User adds or joins a server
- **When**: User connects to the server
- **Then**: Connection is established successfully with mod auto-sync if needed
- **Verification**: `programmatic`

### AC-10: UI/UX Experience
- **Given**: User interacts with the launcher UI
- **When**: User navigates, clicks, or uses keyboard shortcuts
- **Then**: UI responds smoothly at 60fps with desktop-native interactions
- **Verification**: `human-judgment`

### AC-11: Robustness
- **Given**: Launcher encounters an error or exception
- **When**: Error occurs
- **Then**: Launcher captures the error, provides meaningful feedback, and continues operating
- **Verification**: `programmatic`

### AC-12: Auto-Update
- **Given**: A new version of BAMCLauncher is available
- **When**: Launcher checks for updates
- **Then**: Launcher downloads and installs the update, with rollback capability if needed
- **Verification**: `programmatic`

## Open Questions
- [ ] What specific Java versions should be supported for different Minecraft versions?
- [ ] How to handle platform-specific edge cases in Wayland (Linux) and sandbox (macOS)?
- [ ] What mirror sources should be included for download failover?
- [ ] How to optimize JVM arguments for different system configurations?
- [ ] What specific modpack formats should be supported?
- [ ] How to handle Minecraft EULA compliance for launcher distribution?
- [ ] What crash reporting mechanism should be implemented?
- [ ] How to optimize performance for low-end systems?