import 'package:bamclaunch/src/core/index.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bamclaunch/src/event/event_bus.dart';
import 'package:bamclaunch/src/event/event.dart';

void main() {
  group('EventBus Tests', () {
    setUp(() {
      EventBus.reset();
    });

    test('subscribe and publish event', () {
      final eventBus = EventBus();
      final receivedEvents = <LogEvent>[];

      final subscription = eventBus.subscribe<LogEvent>((event) {
        receivedEvents.add(event);
      });

      final event = LogEvent(level: LogLevel.info, message: 'Test message');
      eventBus.publish(event);

      expect(receivedEvents.length, 1);
      expect(receivedEvents.first.message, 'Test message');
      expect(receivedEvents.first.level, LogLevel.info);

      subscription.unsubscribe();
    });

    test('unsubscribe stops receiving events', () {
      final eventBus = EventBus();
      var receivedCount = 0;

      final subscription = eventBus.subscribe<LogEvent>((event) {
        receivedCount++;
      });

      eventBus.publish(LogEvent(level: LogLevel.info, message: 'Test 1'));
      expect(receivedCount, 1);

      subscription.unsubscribe();

      eventBus.publish(LogEvent(level: LogLevel.info, message: 'Test 2'));
      expect(receivedCount, 1);
    });

    test('multiple subscribers receive events', () {
      final eventBus = EventBus();
      var count1 = 0;
      var count2 = 0;

      final sub1 = eventBus.subscribe<LogEvent>((event) {
        count1++;
      });

      final sub2 = eventBus.subscribe<LogEvent>((event) {
        count2++;
      });

      eventBus.publish(LogEvent(level: LogLevel.info, message: 'Test'));

      expect(count1, 1);
      expect(count2, 1);

      sub1.unsubscribe();
      sub2.unsubscribe();
    });

    test('different event types are handled separately', () {
      final eventBus = EventBus();
      var logCount = 0;
      var taskCount = 0;

      final logSub = eventBus.subscribe<LogEvent>((event) {
        logCount++;
      });

      final taskSub = eventBus.subscribe<TaskStartedEvent>((event) {
        taskCount++;
      });

      eventBus.publish(LogEvent(level: LogLevel.info, message: 'Test'));
      expect(logCount, 1);
      expect(taskCount, 0);

      eventBus.publish(TaskStartedEvent(taskId: '123'));
      expect(logCount, 1);
      expect(taskCount, 1);

      logSub.unsubscribe();
      taskSub.unsubscribe();
    });

    test('subscriberCount returns correct count', () {
      final eventBus = EventBus();
      expect(eventBus.subscriberCount(LogEvent), 0);
      expect(eventBus.subscriberCount(), 0);

      final sub1 = eventBus.subscribe<LogEvent>((event) {});
      final sub2 = eventBus.subscribe<LogEvent>((event) {});

      expect(eventBus.subscriberCount(LogEvent), 2);
      expect(eventBus.subscriberCount(), 2);

      sub1.unsubscribe();
      expect(eventBus.subscriberCount(LogEvent), 1);
      expect(eventBus.subscriberCount(), 1);

      sub2.unsubscribe();
      expect(eventBus.subscriberCount(LogEvent), 0);
      expect(eventBus.subscriberCount(), 0);
    });

    test('EventBus is singleton', () {
      final bus1 = EventBus();
      final bus2 = EventBus();
      final bus3 = EventBus.instance;

      expect(identical(bus1, bus2), true);
      expect(identical(bus1, bus3), true);
    });
  });
}
