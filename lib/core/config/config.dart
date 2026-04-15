import '../platform/platform.dart';
import 'i_config_manager.dart';
import 'config_manager.dart';

/// 导出配置相关的接口和实现
export 'i_config_manager.dart';
export 'config_manager.dart';
export 'aes_encryption.dart';
export 'models/global_config.dart';
export 'config_service.dart';

/// 全局配置管理器单例
/// 用于管理应用配置的读写和加密
final IConfigManager configManager = ConfigManager(PlatformAdapterFactory.getInstance());