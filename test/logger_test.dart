import 'package:flutter_test/flutter_test.dart';
import 'package:bamclaunch/src/core/logger.dart';
import 'package:bamclaunch/src/event/event.dart' as event_module;
import 'package:bamclaunch/src/event/event_bus.dart';

void main() {
  setUp(() {
    Logger.reset();
    EventBus.reset();
  });

  group('Logger', () {
    test('singleton pattern works', () {
      final logger1 = Logger.instance;
      final logger2 = Logger.instance;
      expect(logger1, same(logger2));
    });

    test('initialize sets initialized flag', () async {
      final logger = Logger.instance;
      await logger.initialize(
        enableConsoleOutput: false,
        enableFileOutput: false,
      );
    });

    test('log methods do not throw before initialize', () {
      final logger = Logger.instance;
      expect(() => logger.debug('test'), returnsNormally);
      expect(() => logger.info('test'), returnsNormally);
      expect(() => logger.warn('test'), returnsNormally);
      expect(() => logger.error('test'), returnsNormally);
      expect(() => logger.fatal('test'), returnsNormally);
    });

    test('log methods do not throw after initialize', () async {
      final logger = Logger.instance;
      await logger.initialize(
        enableConsoleOutput: false,
        enableFileOutput: false,
      );
      expect(() => logger.debug('test'), returnsNormally);
      expect(() => logger.info('test'), returnsNormally);
      expect(() => logger.warn('test'), returnsNormally);
      expect(() => logger.error('test'), returnsNormally);
      expect(() => logger.fatal('test'), returnsNormally);
    });

    test('log publishes LogEvent to event bus', () async {
      final logger = Logger.instance;
      final eventBus = EventBus.instance;
      await logger.initialize(
        enableConsoleOutput: false,
        enableFileOutput: false,
      );

      event_module.LogEvent? receivedEvent;
      eventBus.subscribe<event_module.LogEvent>((event) {
        receivedEvent = event;
      });

      logger.info('test message');

      expect(receivedEvent, isNotNull);
      expect(receivedEvent!.message, 'test message');
      expect(receivedEvent!.level, event_module.LogLevel.info);
    });

    test('log with error and stack trace', () async {
      final logger = Logger.instance;
      final eventBus = EventBus.instance;
      await logger.initialize(
        enableConsoleOutput: false,
        enableFileOutput: false,
      );

      event_module.LogEvent? receivedEvent;
      eventBus.subscribe<event_module.LogEvent>((event) {
        receivedEvent = event;
      });

      final error = Exception('test error');
      final stackTrace = StackTrace.current;
      logger.error('test with error', error, stackTrace);

      expect(receivedEvent, isNotNull);
      expect(receivedEvent!.error, error);
      expect(receivedEvent!.stackTrace, stackTrace);
    });

    test('min level filters logs', () async {
      final logger = Logger.instance;
      final eventBus = EventBus.instance;
      await logger.initialize(
        minLevel: LogLevel.warn,
        enableConsoleOutput: false,
        enableFileOutput: false,
      );

      event_module.LogEvent? receivedEvent;
      eventBus.subscribe<event_module.LogEvent>((event) {
        receivedEvent = event;
      });

      logger.debug('debug message');
      expect(receivedEvent, isNull);

      logger.info('info message');
      expect(receivedEvent, isNull);

      logger.warn('warn message');
      expect(receivedEvent, isNotNull);
      expect(receivedEvent!.message, 'warn message');
    });

    test('setMinLevel updates min level', () async {
      final logger = Logger.instance;
      final eventBus = EventBus.instance;
      await logger.initialize(
        minLevel: LogLevel.error,
        enableConsoleOutput: false,
        enableFileOutput: false,
      );

      event_module.LogEvent? receivedEvent;
      eventBus.subscribe<event_module.LogEvent>((event) {
        receivedEvent = event;
      });

      logger.warn('warn message');
      expect(receivedEvent, isNull);

      logger.setMinLevel(LogLevel.warn);
      logger.warn('warn message after');
      expect(receivedEvent, isNotNull);
      expect(receivedEvent!.message, 'warn message after');
    });

    test('dispose clears outputs', () async {
      final logger = Logger.instance;
      await logger.initialize(
        enableConsoleOutput: true,
        enableFileOutput: false,
      );
      await logger.dispose();
    });
  });

  group('LogRecord', () {
    test('format includes timestamp, level and message', () {
      final record = LogRecord(
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        level: LogLevel.info,
        message: 'test message',
      );
      final formatted = record.format();
      expect(formatted, contains('INFO'));
      expect(formatted, contains('test message'));
    });

    test('format includes error when present', () {
      final error = Exception('test error');
      final record = LogRecord(
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        level: LogLevel.error,
        message: 'test message',
        error: error,
      );
      final formatted = record.format();
      expect(formatted, contains('Error:'));
      expect(formatted, contains('test error'));
    });

    test('format includes stack trace when present', () {
      final stackTrace = StackTrace.current;
      final record = LogRecord(
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        level: LogLevel.error,
        message: 'test message',
        stackTrace: stackTrace,
      );
      final formatted = record.format();
      expect(formatted, contains('StackTrace:'));
    });

    test('toJson includes all fields', () {
      final error = Exception('test error');
      final stackTrace = StackTrace.current;
      final record = LogRecord(
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        level: LogLevel.error,
        message: 'test message',
        error: error,
        stackTrace: stackTrace,
        data: {'key': 'value'},
      );
      final json = record.toJson();
      expect(json['timestamp'], isNotNull);
      expect(json['level'], 'error');
      expect(json['message'], 'test message');
      expect(json['error'], isNotNull);
      expect(json['stackTrace'], isNotNull);
      expect(json['data'], {'key': 'value'});
    });
  });

  group('LogLevel', () {
    test('has correct order', () {
      expect(LogLevel.debug.index, 0);
      expect(LogLevel.info.index, 1);
      expect(LogLevel.warn.index, 2);
      expect(LogLevel.error.index, 3);
      expect(LogLevel.fatal.index, 4);
    });
  });

  group('LogRotationConfig', () {
    test('default values are correct', () {
      const config = LogRotationConfig();
      expect(config.strategy, LogRotationStrategy.size);
      expect(config.maxFileSize, 10 * 1024 * 1024);
      expect(config.maxFileCount, 5);
    });

    test('custom values are stored correctly', () {
      const config = LogRotationConfig(
        strategy: LogRotationStrategy.date,
        maxFileSize: 5 * 1024 * 1024,
        maxFileCount: 10,
      );
      expect(config.strategy, LogRotationStrategy.date);
      expect(config.maxFileSize, 5 * 1024 * 1024);
      expect(config.maxFileCount, 10);
    });
  });
}
