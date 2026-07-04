/// 集中管理的 API 端点
///
/// 所有外部 API 的 URL 都集中定义在此处，便于：
/// - 统一修改和维护
/// - 切换环境（开发/生产）
/// - 添加镜像源回退
class ApiEndpoints {
  ApiEndpoints._();

  // ━━━ Microsoft OAuth ━━━
  // 使用 Azure AD 注册的应用，统一使用 v2.0 端点
  static const String microsoftAuthAuthorize =
      'https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize';
  static const String microsoftAuthToken =
      'https://login.microsoftonline.com/consumers/oauth2/v2.0/token';
  static const String microsoftAuthDeviceCode =
      'https://login.microsoftonline.com/consumers/oauth2/v2.0/devicecode';
  static const String microsoftRedirectUri =
      'https://login.live.com/oauth20_desktop.srf';

  // ━━━ Xbox Live ━━━
  static const String xboxUserAuth =
      'https://user.auth.xboxlive.com/user/authenticate';
  static const String xboxXstsAuth =
      'https://xsts.auth.xboxlive.com/xsts/authorize';

  // ━━━ Minecraft Services ━━━
  static const String minecraftAuthLogin =
      'https://api.minecraftservices.com/authentication/login_with_xbox';
  static const String minecraftProfile =
      'https://api.minecraftservices.com/minecraft/profile';
  static const String minecraftEntitlements =
      'https://api.minecraftservices.com/entitlements/mcstore';

  // ━━━ Authlib Injector ━━━
  static const String authlibInjectorJar =
      'https://github.com/yushijinhun/authlib-injector/releases/latest/download/authlib-injector.jar';

  // ━━━ Modrinth ━━━
  static const String modrinthApi = 'https://api.modrinth.com/v2';
  static const String modrinthWebsite = 'https://modrinth.com';

  // ━━━ CurseForge ━━━
  static const String curseforgeApi = 'https://api.curseforge.com/v1';
  static const String curseforgeWebsite = 'https://www.curseforge.com';

  // ━━━ Maven 仓库 ━━━
  static const String fabricMaven = 'https://maven.fabricmc.net';
  static const String quiltMaven =
      'https://maven.quiltmc.org/repository/release';
  static const String forgeMaven = 'https://maven.minecraftforge.net';
  static const String neoforgeMaven = 'https://maven.neoforged.net';
  static const String optifineNet = 'https://optifine.net';

  // ━━━ 元数据源 ━━━
  static const String minecraftVersionManifest =
      'https://launchermeta.mojang.com/mc/game/version_manifest.json';
  static const String quiltApi = 'https://api.quiltmc.org/v2';

  // ━━━ 镜像源 ━━━
  static const String mojangLauncher = 'https://launcher.mojang.com';
  static const String bmclapi2 = 'https://bmclapi2.bangbang93.com';
  static const String bmclapi = 'https://bmclapi.bangbang93.com';
  static const String mcbbs = 'https://download.mcbbs.net';
}
