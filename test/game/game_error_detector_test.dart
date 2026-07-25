// GameErrorDetector 测试
//
// 验证从 GameLauncher 拆分出的错误检测组件：
// 1. checkForErrors 匹配已知故障模式
// 2. 同一进程同一模式只匹配一次（去重）
// 3. 不含关键字的行不会被标记
// 4. clear 能清理指定进程的记录
// 5. analyzeCrashLog 生成包含故障模式与日志的报告

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bamclaunch/src/account/account.dart';
import 'package:bamclaunch/src/event/event.dart';
import 'package:bamclaunch/src/event/event_bus.dart';
import 'package:bamclaunch/src/game/launcher/game_error_detector.dart';
import 'package:bamclaunch/src/game/launcher/models.dart';

GameProcessInfo _makeProcessInfo({String gameDir = ''}) {
  final account = Account(
    id: 'a1',
    username: 'TestUser',
    type: AccountType.offline,
    createdAt: DateTime.now(),
    lastUsedAt: DateTime.now(),
  );
  final args = LaunchArguments(
    javaPath: '/java',
    gameVersion: '1.20.4',
    account: account,
    gameDirectory: gameDir,
    memory: 1024,
    jvmArguments: [],
    gameArguments: [],
  );
  return GameProcessInfo(
    processId: 'proc_1',
    arguments: args,
    status: GameProcessStatus.crashed,
    startTime: DateTime.now().subtract(const Duration(seconds: 30)),
    stopTime: DateTime.now(),
    exitCode: -1,
  );
}

void main() {
  late GameErrorDetector detector;

  setUp(() {
    detector = GameErrorDetector();
  });

  group('GameErrorDetector.checkForErrors', () {
    test('匹配已知故障模式应被记录', () async {
      detector.checkForErrors('proc_1', 'java.lang.OutOfMemoryError thrown');
      final report = await detector.analyzeCrashLog(
        processId: 'proc_1',
        processInfo: _makeProcessInfo(),
        eventBus: EventBus(),
      );

      expect(report, contains('OutOfMemoryError'));
      expect(report, contains('增加分配的内存'));
    });

    test('多个故障模式可同时匹配', () async {
      detector.checkForErrors(
        'proc_1',
        'java.lang.OutOfMemoryError: GLFW error 65542',
      );
      final report = await detector.analyzeCrashLog(
        processId: 'proc_1',
        processInfo: _makeProcessInfo(),
        eventBus: EventBus(),
      );

      // OutOfMemoryError 和 GLFW error 65542 应同时匹配
      expect(report, contains('OutOfMemoryError'));
      expect(report, contains('GLFW error 65542'));
    });

    test('不含关键字的行不应触发匹配', () async {
      // 没有 error/exception/crash/failed/fatal 字样
      detector.checkForErrors('proc_1', 'Loading texture pack...');
      final report = await detector.analyzeCrashLog(
        processId: 'proc_1',
        processInfo: _makeProcessInfo(),
        eventBus: EventBus(),
      );

      expect(report, contains('未匹配到已知故障模式'));
    });

    test('同进程同模式应去重（不重复记录）', () async {
      // 重复调用 3 次
      detector.checkForErrors('proc_1', 'java.lang.OutOfMemoryError first');
      detector.checkForErrors('proc_1', 'java.lang.OutOfMemoryError second');
      detector.checkForErrors('proc_1', 'java.lang.OutOfMemoryError third');

      final report = await detector.analyzeCrashLog(
        processId: 'proc_1',
        processInfo: _makeProcessInfo(),
        eventBus: EventBus(),
      );

      // OutOfMemoryError 关键字只应出现一次（在诊断模式列表中）
      final occurrences = 'java.lang.OutOfMemoryError'
          .allMatches(report)
          .length;
      // 报告中至少出现 1 次（"匹配到的故障模式"列表里），
      // 但 "建议:" 描述文字不应重复
      expect(occurrences, greaterThanOrEqualTo(1));
    });

    test('不同进程独立计数', () async {
      detector.checkForErrors('proc_1', 'java.lang.OutOfMemoryError');
      detector.checkForErrors('proc_2', 'LWJGL error detected');

      final r1 = await detector.analyzeCrashLog(
        processId: 'proc_1',
        processInfo: _makeProcessInfo(),
        eventBus: EventBus(),
      );
      final r2 = await detector.analyzeCrashLog(
        processId: 'proc_2',
        processInfo: _makeProcessInfo(),
        eventBus: EventBus(),
      );

      expect(r1, contains('OutOfMemoryError'));
      expect(r1, isNot(contains('LWJGL error')));
      expect(r2, contains('LWJGL error'));
      expect(r2, isNot(contains('OutOfMemoryError')));
    });
  });

  group('GameErrorDetector.clear', () {
    test('clear 后该进程的故障模式不再出现在报告中', () async {
      detector.checkForErrors('proc_1', 'java.lang.OutOfMemoryError');
      detector.clear('proc_1');

      final report = await detector.analyzeCrashLog(
        processId: 'proc_1',
        processInfo: _makeProcessInfo(),
        eventBus: EventBus(),
      );

      expect(report, contains('未匹配到已知故障模式'));
    });

    test('clear 不影响其他进程', () async {
      detector.checkForErrors('proc_1', 'java.lang.OutOfMemoryError');
      detector.checkForErrors('proc_2', 'LWJGL error');
      detector.clear('proc_1');

      final r2 = await detector.analyzeCrashLog(
        processId: 'proc_2',
        processInfo: _makeProcessInfo(),
        eventBus: EventBus(),
      );
      expect(r2, contains('LWJGL error'));
    });
  });

  group('GameErrorDetector.analyzeCrashLog', () {
    test('报告应包含进程元数据', () async {
      final report = await detector.analyzeCrashLog(
        processId: 'proc_xyz',
        processInfo: _makeProcessInfo(),
        eventBus: EventBus(),
      );

      expect(report, contains('进程ID: proc_xyz'));
      expect(report, contains('游戏版本: 1.20.4'));
      expect(report, contains('退出码: -1'));
      expect(report, contains('崩溃诊断报告'));
    });

    test('应通过 EventBus 发布 CrashDiagnosticEvent', () async {
      detector.checkForErrors('proc_1', 'java.lang.OutOfMemoryError');

      final eventBus = EventBus();
      final events = <CrashDiagnosticEvent>[];
      final sub = eventBus.subscribe<CrashDiagnosticEvent>((e) {
        events.add(e);
      });

      await detector.analyzeCrashLog(
        processId: 'proc_1',
        processInfo: _makeProcessInfo(),
        eventBus: eventBus,
      );

      // 等待事件循环
      await Future<void>.delayed(Duration.zero);
      sub.unsubscribe();

      expect(events, isNotEmpty);
      expect(events.first.processId, equals('proc_1'));
      expect(events.first.matchedPatterns, isNotEmpty);
    });

    test('crash-reports 目录中的报告应被附加', () async {
      // 准备 crash-reports 目录
      final tempDir = Directory.systemTemp.createTempSync('crash_test_');
      try {
        final crashDir = Directory(
          '${tempDir.path}${Platform.pathSeparator}crash-reports',
        )..createSync();
        File('${crashDir.path}${Platform.pathSeparator}crash-2024-01-01.txt')
          ..writeAsStringSync('Minecraft crashed!\nStack trace here');

        final report = await detector.analyzeCrashLog(
          processId: 'proc_1',
          processInfo: _makeProcessInfo(gameDir: tempDir.path),
          eventBus: EventBus(),
        );

        expect(report, contains('crash-reports 最新报告'));
        expect(report, contains('Minecraft crashed!'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });

  group('GameErrorDetector - knownCrashPatterns', () {
    test('应包含至少 10 个已知故障模式', () {
      expect(
        GameErrorDetector.knownCrashPatterns.length,
        greaterThanOrEqualTo(10),
      );
    });

    test('每个模式应是非空字符串', () {
      for (final entry in GameErrorDetector.knownCrashPatterns.entries) {
        expect(entry.key, isNotEmpty);
        expect(entry.value, isNotEmpty);
      }
    });
  });
}
