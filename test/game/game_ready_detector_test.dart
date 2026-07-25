// GameReadyDetector 测试
//
// 验证从 GameLauncher 拆分出的就绪检测组件：
// 1. 命中关键字（render thread / glfw / setting user / lwjgl）应触发就绪
// 2. update processInfo.readyTime
// 3. 发布 GameReadyEvent 事件
// 4. 已就绪后再次检查不重复触发
// 5. onReady 回调被触发

import 'package:flutter_test/flutter_test.dart';
import 'package:bamclaunch/src/account/account.dart';
import 'package:bamclaunch/src/event/event.dart';
import 'package:bamclaunch/src/event/event_bus.dart';
import 'package:bamclaunch/src/game/launcher/game_ready_detector.dart';
import 'package:bamclaunch/src/game/launcher/models.dart';

GameProcessInfo _makeProcessInfo() {
  final account = Account(
    id: 'a1',
    username: 'Player123',
    type: AccountType.offline,
    createdAt: DateTime.now(),
    lastUsedAt: DateTime.now(),
  );
  final args = LaunchArguments(
    javaPath: '/java',
    gameVersion: '1.20.4',
    account: account,
    gameDirectory: '/mc',
    memory: 1024,
    jvmArguments: [],
    gameArguments: [],
  );
  return GameProcessInfo(
    processId: 'proc_1',
    arguments: args,
    status: GameProcessStatus.starting,
    startTime: DateTime.now(),
  );
}

void main() {
  late GameReadyDetector detector;

  setUp(() {
    detector = GameReadyDetector();
  });

  group('GameReadyDetector.checkGameReady', () {
    test('命中 render thread 应触发就绪', () {
      DateTime? capturedTime;
      detector.checkGameReady(
        processId: 'proc_1',
        line: '[Render thread/INFO]: Loading Minecraft',
        processInfo: _makeProcessInfo(),
        eventBus: EventBus(),
        onReady: (t) => capturedTime = t,
      );

      expect(capturedTime, isNotNull);
      final info = _makeProcessInfo();
      expect(info.readyTime, isNull); // 我们用的是局部 info
    });

    test('应更新 processInfo.readyTime', () {
      final info = _makeProcessInfo();
      expect(info.readyTime, isNull);

      detector.checkGameReady(
        processId: 'proc_1',
        line: 'GLFW initialized successfully',
        processInfo: info,
        eventBus: EventBus(),
        onReady: (_) {},
      );

      expect(info.readyTime, isNotNull);
    });

    test('命中 glfw（大小写不敏感）应触发', () {
      DateTime? capturedTime;
      detector.checkGameReady(
        processId: 'proc_1',
        line: 'GLFW error 65542 initializing...',
        processInfo: _makeProcessInfo(),
        eventBus: EventBus(),
        onReady: (t) => capturedTime = t,
      );

      expect(capturedTime, isNotNull);
    });

    test('命中 setting user 应触发', () {
      DateTime? capturedTime;
      detector.checkGameReady(
        processId: 'proc_1',
        line: 'Setting user: Player123',
        processInfo: _makeProcessInfo(),
        eventBus: EventBus(),
        onReady: (t) => capturedTime = t,
      );

      expect(capturedTime, isNotNull);
    });

    test('未命中关键字不应触发', () {
      DateTime? capturedTime;
      detector.checkGameReady(
        processId: 'proc_1',
        line: 'Loading library...',
        processInfo: _makeProcessInfo(),
        eventBus: EventBus(),
        onReady: (t) => capturedTime = t,
      );

      expect(capturedTime, isNull);
    });

    test('已就绪后再次检查不应重复触发', () {
      var callbackCount = 0;
      final info = _makeProcessInfo();

      // 第一次：触发
      detector.checkGameReady(
        processId: 'proc_1',
        line: 'Setting user: x',
        processInfo: info,
        eventBus: EventBus(),
        onReady: (_) => callbackCount++,
      );

      // 第二次：不触发
      detector.checkGameReady(
        processId: 'proc_1',
        line: 'LWJGL initialized',
        processInfo: info,
        eventBus: EventBus(),
        onReady: (_) => callbackCount++,
      );

      expect(callbackCount, equals(1));
    });

    test('应通过 EventBus 发布 GameReadyEvent', () async {
      final eventBus = EventBus();
      final events = <GameReadyEvent>[];
      final sub = eventBus.subscribe<GameReadyEvent>((e) {
        events.add(e);
      });

      detector.checkGameReady(
        processId: 'proc_xyz',
        line: 'Setting user: Player123',
        processInfo: _makeProcessInfo(),
        eventBus: eventBus,
        onReady: (_) {},
      );

      await Future<void>.delayed(Duration.zero);
      sub.unsubscribe();

      expect(events, hasLength(1));
      expect(events.first.processId, equals('proc_xyz'));
      expect(events.first.version, equals('1.20.4'));
      expect(events.first.username, equals('Player123'));
    });
  });

  group('GameReadyDetector.readyKeywords', () {
    test('应包含至少 4 个就绪关键字', () {
      expect(GameReadyDetector.readyKeywords.length, greaterThanOrEqualTo(4));
      expect(GameReadyDetector.readyKeywords, contains('render thread'));
      expect(GameReadyDetector.readyKeywords, contains('glfw'));
      expect(GameReadyDetector.readyKeywords, contains('setting user'));
      expect(GameReadyDetector.readyKeywords, contains('lwjgl'));
    });
  });
}
