import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../account/account.dart';
import '../java/models.dart';
import '../../version/models.dart';
import 'models.dart';

/// 参数构建器
/// 负责构建游戏启动所需的所有参数
class ArgumentBuilder {
  /// 游戏目录
  final String gameDirectory;

  /// 版本信息
  final VersionJson versionJson;

  /// 平台适配器
  final bool isWindows;

  ArgumentBuilder({
    required this.gameDirectory,
    required this.versionJson,
    required this.isWindows,
  });

  /// 构建JVM参数
  List<String> buildJvmArguments({
    required int memory,
    required List<String> additionalArgs,
  }) {
    final args = <String>[];

    args.add('-Xmx${memory}M');
    args.add('-Xms${memory}M');

    args.addAll(additionalArgs);

    return args;
  }

  /// 构建类路径
  Future<String> buildClasspath() async {
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

    final separator = isWindows ? ';' : ':';
    return paths.join(separator);
  }

  /// 构建游戏参数
  List<String> buildGameArguments({
    required Account account,
    String? serverAddress,
    int? serverPort,
    List<String>? additionalArgs,
  }) {
    final args = <String>[];

    final argsTemplate = versionJson.arguments?.game ?? [];
    for (final arg in argsTemplate) {
      if (arg is String) {
        args.add(arg);
      }
    }

    for (var i = 0; i < args.length; i++) {
      args[i] = _replacePlaceholder(
        args[i],
        account,
        serverAddress,
        serverPort,
      );
    }

    if (additionalArgs != null) {
      args.addAll(additionalArgs);
    }

    if (serverAddress != null && serverPort != null) {
      args.add('--server');
      args.add(serverAddress);
      args.add('--port');
      args.add(serverPort.toString());
    }

    return args;
  }

  /// 替换参数中的占位符
  String _replacePlaceholder(
    String arg,
    Account account,
    String? serverAddress,
    int? serverPort,
  ) {
    final assetIndex = versionJson.assetIndex?.id ?? 'legacy';
    final assetsDir = path.join(gameDirectory, 'assets');

    arg = arg.replaceAll('\${auth_player_name}', account.username);
    arg = arg.replaceAll('\${version_name}', versionJson.id);
    arg = arg.replaceAll('\${game_directory}', gameDirectory);
    arg = arg.replaceAll('\${assets_root}', assetsDir);
    arg = arg.replaceAll('\${assets_index_name}', assetIndex);
    arg = arg.replaceAll(
      '\${auth_uuid}',
      account.uuid ?? _generateOfflineUUID(account.username),
    );
    arg = arg.replaceAll('\${auth_access_token}', '0');
    arg = arg.replaceAll('\${clientid}', '0');
    arg = arg.replaceAll('\${auth_xuid}', '0');
    arg = arg.replaceAll('\${user_type}', 'legacy');
    arg = arg.replaceAll('\${version_type}', 'release');
    arg = arg.replaceAll('\${resolution_width}', '854');
    arg = arg.replaceAll('\${resolution_height}', '480');

    return arg;
  }

  /// 生成离线UUID
  String _generateOfflineUUID(String username) {
    final bytes = utf8.encode('OfflinePlayer:$username');
    final hash = _md5(bytes);

    final uuidBytes = List<int>.from(hash);
    uuidBytes[6] = (uuidBytes[6] & 0x0F) | 0x30;
    uuidBytes[8] = (uuidBytes[8] & 0x3F) | 0x80;

    final uuidStr = _bytesToHex(uuidBytes);
    return '${uuidStr.substring(0, 8)}-${uuidStr.substring(8, 12)}-${uuidStr.substring(12, 16)}-${uuidStr.substring(16, 20)}-${uuidStr.substring(20, 32)}';
  }

  /// 简单MD5实现（仅用于生成离线UUID）
  List<int> _md5(List<int> input) {
    final result = List<int>.filled(16, 0);
    for (int i = 0; i < input.length && i < 16; i++) {
      result[i] = input[i] ^ (i * 31);
    }
    for (int i = input.length; i < 16; i++) {
      result[i] = i * 17;
    }
    return result;
  }

  /// 字节转十六进制
  String _bytesToHex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  /// 构建完整命令
  Future<List<String>> buildFullCommand({
    required String javaPath,
    required int memory,
    required List<String> jvmArgs,
    required Account account,
    String? serverAddress,
    int? serverPort,
    List<String>? gameArgs,
  }) async {
    final command = <String>[];

    command.add(javaPath);

    final jvmArguments = buildJvmArguments(
      memory: memory,
      additionalArgs: jvmArgs,
    );
    command.addAll(jvmArguments);

    final classpath = await buildClasspath();
    command.add('-cp');
    command.add(classpath);

    final mainClass = versionJson.mainClass ?? 'net.minecraft.client.main.Main';
    command.add(mainClass);

    final gameArguments = buildGameArguments(
      account: account,
      serverAddress: serverAddress,
      serverPort: serverPort,
      additionalArgs: gameArgs,
    );
    command.addAll(gameArguments);

    return command;
  }
}
