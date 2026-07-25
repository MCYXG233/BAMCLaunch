import 'package:flutter_test/flutter_test.dart';
import 'package:bamclaunch/src/account/account.dart';
import 'package:bamclaunch/src/game/launcher/models.dart';

void main() {
  group('GameLauncher Models Tests', () {
    test('LaunchArguments should create correctly', () {
      final account = Account(
        id: 'test_id',
        username: 'TestUser',
        type: AccountType.offline,
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
      );

      final args = LaunchArguments(
        javaPath: '/usr/bin/java',
        gameVersion: '1.20.4',
        account: account,
        gameDirectory: '/home/user/.minecraft',
        memory: 2048,
        jvmArguments: ['-XX:+UseG1GC'],
        gameArguments: ['--width', '854'],
        serverAddress: 'mc.example.com',
        serverPort: 25565,
      );

      expect(args.javaPath, equals('/usr/bin/java'));
      expect(args.gameVersion, equals('1.20.4'));
      expect(args.account.id, equals('test_id'));
      expect(args.gameDirectory, equals('/home/user/.minecraft'));
      expect(args.memory, equals(2048));
      expect(args.jvmArguments, hasLength(1));
      expect(args.gameArguments, hasLength(2));
      expect(args.serverAddress, equals('mc.example.com'));
      expect(args.serverPort, equals(25565));
    });

    test('LaunchArguments copyWith should work correctly', () {
      final account = Account(
        id: 'test_id',
        username: 'TestUser',
        type: AccountType.offline,
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
      );

      final original = LaunchArguments(
        javaPath: '/usr/bin/java',
        gameVersion: '1.20.4',
        account: account,
        gameDirectory: '/home/user/.minecraft',
        memory: 2048,
        jvmArguments: [],
        gameArguments: [],
      );

      final updated = original.copyWith(
        memory: 4096,
        serverAddress: 'new.example.com',
      );

      expect(updated.memory, equals(4096));
      expect(updated.serverAddress, equals('new.example.com'));
      expect(updated.javaPath, equals(original.javaPath));
      expect(updated.gameVersion, equals(original.gameVersion));
      expect(updated, isNot(same(original)));
    });

    test('GameProcessStatus should work correctly', () {
      expect(GameProcessStatus.starting.name, equals('starting'));
      expect(GameProcessStatus.running.name, equals('running'));
      expect(GameProcessStatus.stopped.name, equals('stopped'));
      expect(GameProcessStatus.crashed.name, equals('crashed'));
    });

    test('GameLogLevel should work correctly', () {
      expect(GameLogLevel.debug.name, equals('debug'));
      expect(GameLogLevel.info.name, equals('info'));
      expect(GameLogLevel.warn.name, equals('warn'));
      expect(GameLogLevel.error.name, equals('error'));
    });

    test('GameLog should create and format correctly', () {
      final now = DateTime.now();
      final log = GameLog(
        timestamp: now,
        level: GameLogLevel.info,
        message: 'Test log message',
        source: 'stdout',
      );

      expect(log.timestamp, equals(now));
      expect(log.level, equals(GameLogLevel.info));
      expect(log.message, equals('Test log message'));
      expect(log.source, equals('stdout'));
      expect(log.format(), contains('INFO'));
      expect(log.format(), contains('Test log message'));
    });

    test('GameLog should serialize and deserialize correctly', () {
      final log = GameLog(
        timestamp: DateTime.now(),
        level: GameLogLevel.error,
        message: 'Error message',
        source: 'stderr',
      );

      final json = log.toJson();
      final reconstructed = GameLog.fromJson(json);

      expect(reconstructed.level, equals(log.level));
      expect(reconstructed.message, equals(log.message));
      expect(reconstructed.source, equals(log.source));
    });

    test('GameProcessInfo should create correctly', () {
      final account = Account(
        id: 'test_id',
        username: 'TestUser',
        type: AccountType.offline,
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
      );

      final args = LaunchArguments(
        javaPath: '/usr/bin/java',
        gameVersion: '1.20.4',
        account: account,
        gameDirectory: '/home/user/.minecraft',
        memory: 2048,
        jvmArguments: [],
        gameArguments: [],
      );

      final now = DateTime.now();
      final processInfo = GameProcessInfo(
        processId: 'proc_123',
        arguments: args,
        status: GameProcessStatus.running,
        pid: 12345,
        startTime: now,
      );

      expect(processInfo.processId, equals('proc_123'));
      expect(processInfo.status, equals(GameProcessStatus.running));
      expect(processInfo.pid, equals(12345));
      expect(processInfo.isRunning, isTrue);
    });

    test('GameProcessInfo isRunning should work correctly', () {
      final account = Account(
        id: 'test_id',
        username: 'TestUser',
        type: AccountType.offline,
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
      );

      final args = LaunchArguments(
        javaPath: '/usr/bin/java',
        gameVersion: '1.20.4',
        account: account,
        gameDirectory: '/home/user/.minecraft',
        memory: 2048,
        jvmArguments: [],
        gameArguments: [],
      );

      final startingProcess = GameProcessInfo(
        processId: 'proc_1',
        arguments: args,
        status: GameProcessStatus.starting,
        startTime: DateTime.now(),
      );

      final runningProcess = GameProcessInfo(
        processId: 'proc_2',
        arguments: args,
        status: GameProcessStatus.running,
        startTime: DateTime.now(),
      );

      final stoppedProcess = GameProcessInfo(
        processId: 'proc_3',
        arguments: args,
        status: GameProcessStatus.stopped,
        startTime: DateTime.now(),
      );

      final crashedProcess = GameProcessInfo(
        processId: 'proc_4',
        arguments: args,
        status: GameProcessStatus.crashed,
        startTime: DateTime.now(),
      );

      expect(startingProcess.isRunning, isTrue);
      expect(runningProcess.isRunning, isTrue);
      expect(stoppedProcess.isRunning, isFalse);
      expect(crashedProcess.isRunning, isFalse);
    });

    test('GameProcessInfo addLog should work correctly', () {
      final account = Account(
        id: 'test_id',
        username: 'TestUser',
        type: AccountType.offline,
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
      );

      final args = LaunchArguments(
        javaPath: '/usr/bin/java',
        gameVersion: '1.20.4',
        account: account,
        gameDirectory: '/home/user/.minecraft',
        memory: 2048,
        jvmArguments: [],
        gameArguments: [],
      );

      final processInfo = GameProcessInfo(
        processId: 'proc_123',
        arguments: args,
        status: GameProcessStatus.running,
        startTime: DateTime.now(),
      );

      expect(processInfo.logs, isEmpty);

      final log1 = GameLog(
        timestamp: DateTime.now(),
        level: GameLogLevel.info,
        message: 'Log 1',
        source: 'stdout',
      );

      processInfo.addLog(log1);
      expect(processInfo.logs, hasLength(1));

      final log2 = GameLog(
        timestamp: DateTime.now(),
        level: GameLogLevel.error,
        message: 'Log 2',
        source: 'stderr',
      );

      processInfo.addLog(log2);
      expect(processInfo.logs, hasLength(2));
    });

    test('GameProcessInfo getRecentLogs should work correctly', () {
      final account = Account(
        id: 'test_id',
        username: 'TestUser',
        type: AccountType.offline,
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
      );

      final args = LaunchArguments(
        javaPath: '/usr/bin/java',
        gameVersion: '1.20.4',
        account: account,
        gameDirectory: '/home/user/.minecraft',
        memory: 2048,
        jvmArguments: [],
        gameArguments: [],
      );

      final processInfo = GameProcessInfo(
        processId: 'proc_123',
        arguments: args,
        status: GameProcessStatus.running,
        startTime: DateTime.now(),
      );

      for (int i = 0; i < 10; i++) {
        processInfo.addLog(
          GameLog(
            timestamp: DateTime.now(),
            level: GameLogLevel.info,
            message: 'Log $i',
            source: 'stdout',
          ),
        );
      }

      final recent = processInfo.getRecentLogs(5);
      expect(recent, hasLength(5));
      expect(recent.last.message, equals('Log 9'));

      final all = processInfo.getRecentLogs(100);
      expect(all, hasLength(10));
    });

    test('GameProcessInfo copyWith should work correctly', () {
      final account = Account(
        id: 'test_id',
        username: 'TestUser',
        type: AccountType.offline,
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
      );

      final args = LaunchArguments(
        javaPath: '/usr/bin/java',
        gameVersion: '1.20.4',
        account: account,
        gameDirectory: '/home/user/.minecraft',
        memory: 2048,
        jvmArguments: [],
        gameArguments: [],
      );

      final original = GameProcessInfo(
        processId: 'proc_123',
        arguments: args,
        status: GameProcessStatus.running,
        startTime: DateTime.now(),
      );

      final updated = original.copyWith(
        status: GameProcessStatus.stopped,
        exitCode: 0,
      );

      expect(updated.status, equals(GameProcessStatus.stopped));
      expect(updated.exitCode, equals(0));
      expect(updated.processId, equals(original.processId));
      expect(updated, isNot(same(original)));
    });
  });
}
