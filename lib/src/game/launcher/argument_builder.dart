import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import '../../account/account.dart';
import '../../account/skin_manager.dart';
import '../java/models.dart';
import '../../version/models.dart';
import 'models.dart';
import 'argument_rule.dart';

enum GarbageCollector {
  auto,
  g1gc,
  zgc,
  shenandoah,
  parallel,
  serial,
}

class LaunchTemplateArguments {
  final String gameAssets;
  final String assetsRoot;
  final String assetsIndexName;
  final String gameDirectory;
  final String versionName;
  final String versionType;
  final String nativesDirectory;
  final String launcherName;
  final String launcherVersion;
  final String authAccessToken;
  final String authPlayerName;
  final String userType;
  final String authUuid;
  final String clientid;
  final String authXuid;
  final String userProperties;
  final String libraryDirectory;
  final String classpathSeparator;
  final bool demo;
  final int resolutionWidth;
  final int resolutionHeight;
  final String quickPlaySingleplayer;
  final String quickPlayMultiplayer;
  final String quickPlayRealms;
  final String quickPlayPath;

  const LaunchTemplateArguments({
    required this.gameAssets,
    required this.assetsRoot,
    required this.assetsIndexName,
    required this.gameDirectory,
    required this.versionName,
    required this.versionType,
    required this.nativesDirectory,
    required this.launcherName,
    required this.launcherVersion,
    required this.authAccessToken,
    required this.authPlayerName,
    required this.userType,
    required this.authUuid,
    required this.clientid,
    required this.authXuid,
    required this.userProperties,
    required this.libraryDirectory,
    required this.classpathSeparator,
    this.demo = false,
    this.resolutionWidth = 854,
    this.resolutionHeight = 480,
    this.quickPlaySingleplayer = '',
    this.quickPlayMultiplayer = '',
    this.quickPlayRealms = '',
    this.quickPlayPath = '',
  });

  Map<String, String> toJson() {
    return {
      'gameAssets': gameAssets,
      'assetsRoot': assetsRoot,
      'assetsIndexName': assetsIndexName,
      'gameDirectory': gameDirectory,
      'versionName': versionName,
      'versionType': versionType,
      'nativesDirectory': nativesDirectory,
      'launcherName': launcherName,
      'launcherVersion': launcherVersion,
      'authAccessToken': authAccessToken,
      'authPlayerName': authPlayerName,
      'userType': userType,
      'authUuid': authUuid,
      'clientid': clientid,
      'authXuid': authXuid,
      'userProperties': userProperties,
      'libraryDirectory': libraryDirectory,
      'classpathSeparator': classpathSeparator,
      'demo': demo.toString(),
      'resolutionWidth': resolutionWidth.toString(),
      'resolutionHeight': resolutionHeight.toString(),
      'quickPlaySingleplayer': quickPlaySingleplayer,
      'quickPlayMultiplayer': quickPlayMultiplayer,
      'quickPlayRealms': quickPlayRealms,
      'quickPlayPath': quickPlayPath,
    };
  }
}

class ArgumentBuilder {
  final String gameDirectory;
  final VersionJson versionJson;
  final bool isWindows;

  ArgumentBuilder({
    required this.gameDirectory,
    required this.versionJson,
    required this.isWindows,
  });

  Map<String, String> buildTemplateMap({
    required LaunchTemplateArguments args,
  }) {
    final map = <String, String>{};
    final json = args.toJson();
    for (final entry in json.entries) {
      map['\${${entry.key}}'] = entry.value;
    }
    for (final entry in json.entries) {
      map['\${${_camelToSnake(entry.key)}}'] = entry.value;
    }
    return map;
  }

  String _camelToSnake(String s) {
    return s.replaceAllMapped(RegExp(r'([A-Z])'), (m) => '_${m[1]!.toLowerCase()}');
  }

  List<String> buildJvmArguments({
    required int memory,
    required int javaMajorVersion,
    required GameConfig gameConfig,
    required String nativesDirectory,
    required String libraryDirectory,
    required String classpathSeparator,
    String? classpath,
    String? clientJarPath,
    String? authlibJarPath,
    String? authServerUrl,
    String? authServerMeta,
    String? unsafeAgentPath,
  }) {
    final args = <String>[];

    // 处理版本 JSON 中的 arguments.jvm（MC 1.13+）
    if (versionJson.arguments?.jvm != null) {
      final jvmVarMap = _buildJvmVariableMap(
        nativesDirectory: nativesDirectory,
        libraryDirectory: libraryDirectory,
        classpathSeparator: classpathSeparator,
        classpath: classpath ?? '',
      );
      for (final arg in versionJson.arguments!.jvm!) {
        if (arg is String) {
          // 跳过 -cp 和 ${classpath}，这些由启动命令构建器单独处理
          if (arg == '-cp' || arg == r'${classpath}') continue;
          args.add(_replaceJvmVariables(arg, jvmVarMap));
        } else if (arg is Map<String, dynamic>) {
          if (_shouldUseRule(arg)) {
            final value = arg['value'];
            if (value is String) {
              if (value == '-cp' || value == r'${classpath}') continue;
              args.add(_replaceJvmVariables(value, jvmVarMap));
            } else if (value is List) {
              for (final v in value) {
                final s = v.toString();
                if (s == '-cp' || s == r'${classpath}') continue;
                args.add(_replaceJvmVariables(s, jvmVarMap));
              }
            }
          }
        }
      }
    }

    // 设置 -Djava.library.path（确保 JVM 能找到 native 库）
    args.add('-Djava.library.path=$nativesDirectory');

    args.add('-Xmx${memory}M');

    if (!gameConfig.noJvmArgs) {
      if (isWindows) {
        args.add('-XX:HeapDumpPath=MojangTricksIntelDriversForPerformance_javaw.exe_minecraft.exe.heapdump');
      }

      if (clientJarPath != null) {
        args.add('-Dminecraft.client.jar=$clientJarPath');
      }

      if (gameConfig.gcStrategy == 'g1gc') {
        args.add('-XX:+UseG1GC');
      } else if (gameConfig.gcStrategy == 'zgc') {
        args.add('-XX:+UseZGC');
      } else if (gameConfig.gcStrategy == 'shenandoah') {
        args.add('-XX:+UseShenandoahGC');
      } else if (gameConfig.gcStrategy == 'parallel') {
        args.add('-XX:+UseParallelGC');
      } else if (gameConfig.gcStrategy == 'serial') {
        args.add('-XX:+UseSerialGC');
      }

      args.addAll([
        '-Djava.rmi.server.useCodebaseOnly=true',
        '-Dcom.sun.jndi.rmi.object.trustURLCodebase=false',
        '-Dcom.sun.jndi.cosnaming.object.trustURLCodebase=false',
      ]);

      args.addAll([
        '-Dfml.ignoreInvalidMinecraftCertificates=true',
        '-Dfml.ignorePatchDiscrepancies=true',
      ]);

      if (javaMajorVersion < 19) {
        args.addAll([
          '-Dsun.stdout.encoding=UTF-8',
          '-Dsun.stderr.encoding=UTF-8',
        ]);
      } else {
        args.addAll([
          '-Dstdout.encoding=UTF-8',
          '-Dstderr.encoding=UTF-8',
        ]);
      }
    }

    if (gameConfig.jvmArgs.isNotEmpty) {
      args.addAll(gameConfig.jvmArgs);
    }

    if (authServerUrl != null && authServerMeta != null && authlibJarPath != null) {
      args.add('-javaagent:$authlibJarPath=$authServerUrl');
      args.add('-Dauthlibinjector.side=client');
      args.add('-Dauthlibinjector.yggdrasil.prefetched=${_base64Encode(authServerMeta)}');
    }

    if (gameConfig.useLwjglUnsafeAgent && unsafeAgentPath != null) {
      args.add('-javaagent:$unsafeAgentPath');
    }

    return args;
  }

  Map<String, String> _buildJvmVariableMap({
    required String nativesDirectory,
    required String libraryDirectory,
    required String classpathSeparator,
    required String classpath,
  }) {
    return {
      '\${natives_directory}': nativesDirectory,
      '\${launcher_name}': 'BAMC Launcher',
      '\${launcher_version}': '1.0.0',
      '\${version_name}': versionJson.id,
      '\${library_directory}': libraryDirectory,
      '\${classpath_separator}': classpathSeparator,
      '\${classpath}': classpath,
    };
  }

  String _replaceJvmVariables(String arg, Map<String, String> varMap) {
    var result = arg;
    for (final entry in varMap.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  String _base64Encode(String s) {
    return base64.encode(utf8.encode(s));
  }

  List<String> buildGameArguments({
    required LaunchTemplateArguments templateArgs,
    required GameConfig gameConfig,
    String? quickPlaySingleplayer,
    String? quickPlayMultiplayer,
    SkinType? skinType,
  }) {
    final args = <String>[];
    final templateMap = buildTemplateMap(args: templateArgs);

    if (versionJson.arguments != null) {
      final argsList = versionJson.arguments!.game ?? [];
      for (final arg in argsList) {
        if (arg is String) {
          args.add(arg);
        } else if (arg is Map<String, dynamic>) {
          if (_shouldUseRule(arg)) {
            final value = arg['value'];
            if (value is String) {
              args.add(value);
            } else if (value is List) {
              args.addAll(value.cast<String>());
            }
          }
        }
      }
    } else if (versionJson.minecraftArguments != null) {
      args.addAll(_splitMinecraftArguments(versionJson.minecraftArguments!));
    }

    final processedArgs = args.map((arg) {
      var result = arg;
      for (final entry in templateMap.entries) {
        result = result.replaceAll(entry.key, entry.value);
      }
      return result;
    }).toList();

    if (gameConfig.fullscreen) {
      processedArgs.add('--fullscreen');
    }

    if (quickPlaySingleplayer != null && quickPlaySingleplayer.isNotEmpty) {
      processedArgs.addAll(['--quickPlaySingleplayer', quickPlaySingleplayer]);
    } else if (quickPlayMultiplayer != null && quickPlayMultiplayer.isNotEmpty) {
      processedArgs.addAll(['--quickPlayMultiplayer', quickPlayMultiplayer]);
    } else if (gameConfig.autoJoinServer && gameConfig.serverAddress.isNotEmpty) {
      processedArgs.addAll(['--server', gameConfig.serverAddress, '--port', gameConfig.serverPort.toString()]);
    }

    // 添加皮肤模型参数
    // Alex模型使用 --slim 参数
    if (skinType == SkinType.alex) {
      processedArgs.add('--slim');
    }

    if (gameConfig.minecraftArgument.isNotEmpty) {
      processedArgs.addAll(_splitMinecraftArguments(gameConfig.minecraftArgument));
    }

    return processedArgs;
  }

  bool _shouldUseRule(Map<String, dynamic> rule) {
    final rules = rule['rules'] as List?;
    if (rules == null || rules.isEmpty) {
      return true;
    }

    // 使用新的规则引擎
    final platformInfo = PlatformInfo.current();
    final ruleEngine = LaunchArgumentRule.fromJsonList(rules);
    return ruleEngine.matches(platformInfo);
  }

  /// 使用新的规则引擎检查参数是否适用于当前平台
  List<dynamic> filterArgumentsWithRules(List<dynamic> arguments) {
    final platformInfo = PlatformInfo.current();
    final result = <dynamic>[];

    for (final arg in arguments) {
      if (arg is String) {
        result.add(arg);
      } else if (arg is Map<String, dynamic>) {
        final conditionalArg = ConditionalArgument.fromJson(arg);
        if (conditionalArg.matches(platformInfo)) {
          result.add(arg);
        }
      }
    }

    return result;
  }

  List<String> _splitMinecraftArguments(String args) {
    final parts = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (var i = 0; i < args.length; i++) {
      final char = args[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ' ' && !inQuotes) {
        if (buffer.isNotEmpty) {
          parts.add(buffer.toString());
          buffer.clear();
        }
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      parts.add(buffer.toString());
    }

    return parts;
  }

  Future<List<String>> buildClasspath({
    required String nativesDirectory,
  }) async {
    final paths = <String>[];
    final librariesDir = path.join(gameDirectory, 'libraries');

    for (final library in versionJson.libraries) {
      if (library.downloads?.artifact != null) {
        final artifact = library.downloads!.artifact!;
        final libPath = path.join(librariesDir, artifact.path);
        if (await File(libPath).exists()) {
          paths.add(libPath);
        }
      }
    }

    final versionDir = path.join(gameDirectory, 'versions', versionJson.id);
    final jarPath = path.join(versionDir, '${versionJson.id}.jar');
    if (await File(jarPath).exists()) {
      paths.add(jarPath);
    }

    return paths;
  }

  Future<LaunchCommand> buildLaunchCommand({
    required String javaPath,
    required GameConfig gameConfig,
    required Account account,
    required int javaMajorVersion,
    String? authServerUrl,
    String? authServerMeta,
    String? authlibJarPath,
    String? quickPlaySingleplayer,
    String? quickPlayMultiplayer,
  }) async {
    final versionDir = path.join(gameDirectory, 'versions', versionJson.id);
    final clientJarPath = path.join(versionDir, '${versionJson.id}.jar');
    final nativesDir = path.join(versionDir, 'natives');
    final librariesDir = path.join(gameDirectory, 'libraries');
    final assetsDir = path.join(gameDirectory, 'assets');

    // 先构建 classpath，以便 JVM 参数中 ${classpath} 可用
    final classpaths = await buildClasspath(nativesDirectory: nativesDir);
    final classpathStr = classpaths.join(isWindows ? ';' : ':');

    final templateArgs = LaunchTemplateArguments(
      gameAssets: path.join(assetsDir, 'virtual', 'legacy'),
      assetsRoot: assetsDir,
      assetsIndexName: versionJson.assetIndex?.id ?? 'legacy',
      gameDirectory: gameDirectory,
      versionName: versionJson.id,
      versionType: gameConfig.customInfo.isNotEmpty ? gameConfig.customInfo : 'BAMC Launcher',
      nativesDirectory: nativesDir,
      launcherName: 'BAMC Launcher',
      launcherVersion: '1.0.0',
      authAccessToken: account.accessToken ?? '0',
      authPlayerName: account.username,
      userType: _getUserType(account.type),
      authUuid: account.uuid ?? _generateOfflineUUID(account.username),
      clientid: '0',
      authXuid: '0',
      userProperties: '{}',
      libraryDirectory: librariesDir,
      classpathSeparator: isWindows ? ';' : ':',
      demo: false,
      resolutionWidth: gameConfig.resolutionWidth,
      resolutionHeight: gameConfig.resolutionHeight,
      quickPlaySingleplayer: quickPlaySingleplayer ?? '',
      quickPlayMultiplayer: quickPlayMultiplayer ?? (gameConfig.autoJoinServer ? gameConfig.serverAddress : ''),
      quickPlayRealms: '',
      quickPlayPath: '',
    );

    final jvmArgs = buildJvmArguments(
      memory: gameConfig.memory,
      javaMajorVersion: javaMajorVersion,
      gameConfig: gameConfig,
      nativesDirectory: nativesDir,
      libraryDirectory: librariesDir,
      classpathSeparator: isWindows ? ';' : ':',
      classpath: classpathStr,
      clientJarPath: clientJarPath,
      authlibJarPath: authlibJarPath,
      authServerUrl: authServerUrl,
      authServerMeta: authServerMeta,
      unsafeAgentPath: gameConfig.useLwjglUnsafeAgent ? path.join(librariesDir, 'lwjgl-unsafe-agent.jar') : null,
    );

    final gameArgs = buildGameArguments(
      templateArgs: templateArgs,
      gameConfig: gameConfig,
      quickPlaySingleplayer: quickPlaySingleplayer,
      quickPlayMultiplayer: quickPlayMultiplayer,
      skinType: account.modelType,
    );

    final mainClass = versionJson.mainClass ?? 'net.minecraft.client.main.Main';

    final fullCommand = <String>[];
    fullCommand.add(javaPath);
    fullCommand.addAll(jvmArgs);
    fullCommand.add('-cp');
    fullCommand.add(classpathStr);
    fullCommand.add(mainClass);
    fullCommand.addAll(gameArgs);

    return LaunchCommand(
      classPaths: classpaths,
      args: fullCommand,
    );
  }

  String exportFullLaunchCommand({
    required LaunchCommand command,
  }) {
    return command.args.join(' ');
  }

  String _getUserType(AccountType accountType) {
    switch (accountType) {
      case AccountType.microsoft:
        return 'msa';
      case AccountType.offline:
        return 'legacy';
      case AccountType.authlib:
        return 'mojang';
    }
  }

  String _generateOfflineUUID(String username) {
    final bytes = utf8.encode('OfflinePlayer:$username');
    final hash = md5.convert(bytes).bytes;
    final uuidBytes = List<int>.from(hash);
    uuidBytes[6] = (uuidBytes[6] & 0x0F) | 0x30;
    uuidBytes[8] = (uuidBytes[8] & 0x3F) | 0x80;
    final uuidStr = _bytesToHex(uuidBytes);
    return '${uuidStr.substring(0, 8)}-${uuidStr.substring(8, 12)}-${uuidStr.substring(12, 16)}-${uuidStr.substring(16, 20)}-${uuidStr.substring(20, 32)}';
  }

  String _bytesToHex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
