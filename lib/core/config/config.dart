import '../platform/platform.dart';
import 'i_config_manager.dart';
import 'config_manager.dart';

export 'i_config_manager.dart';
export 'config_manager.dart';
export 'aes_encryption.dart';
export 'models/global_config.dart';
export 'config_service.dart';

final IPlatformAdapter platformAdapter = PlatformAdapterFactory.getInstance();
final IConfigManager configManager = ConfigManager(platformAdapter);