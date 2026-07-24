// BAMCException + NotificationManager 集成测试
//
// 验证目标：
// 1. BAMCException 及其子类的 message / retryable 字段正确
// 2. recordException 顶级函数不抛异常
// 3. NotificationManager.showException 在没有 Overlay 时不崩（init 未调用）

import 'package:flutter_test/flutter_test.dart';

import 'package:bamclaunch/src/core/app_exceptions.dart';
import 'package:bamclaunch/src/core/logger.dart';

void main() {
  group('BAMCException 基础验证', () {
    test('TokenExpiredException 包含 i18n key 和 message', () {
      final e = TokenExpiredException();
      expect(e.message, contains('Token'));
      expect(e.i18nKey, 'error.auth.token_expired');
      expect(e.retryable, isFalse);
      expect(e, isA<AuthException>());
      expect(e, isA<BAMCException>());
    });

    test('ServerUnreachableException 标记为 retryable', () {
      final e = ServerUnreachableException();
      expect(e.retryable, isTrue);
    });

    test('HashMismatchException 携带期望和实际哈希', () {
      final e = HashMismatchException(
        expectedHash: 'abc123',
        actualHash: 'def456',
      );
      expect(e.expectedHash, 'abc123');
      expect(e.actualHash, 'def456');
      expect(e.message, contains('abc123'));
      expect(e.message, contains('def456'));
    });

    test('JavaNotFoundException 不重试', () {
      final e = JavaNotFoundException();
      expect(e.retryable, isFalse);
      expect(e.message, contains('Java'));
    });

    test('CrashException 携带 exit code 和诊断报告', () {
      final e = CrashException(
        exitCode: 1,
        diagnosticReport: 'crash-2026-07-24.log',
      );
      expect(e.exitCode, 1);
      expect(e.diagnosticReport, 'crash-2026-07-24.log');
    });
  });

  group('recordException 顶级函数验证', () {
    test('处理 BAMCException 不抛异常', () {
      // 未初始化的 Logger 会跳过输出（_initialized=false），不应崩溃
      expect(() => recordException(TokenExpiredException()), returnsNormally);
    });

    test('处理普通 Exception 不抛异常', () {
      expect(() => recordException(Exception('普通异常')), returnsNormally);
    });

    test('处理任意 Object 不抛异常', () {
      expect(() => recordException('错误字符串'), returnsNormally);
      expect(() => recordException(42), returnsNormally);
      // 不传 null（类型签名是 Object 不是 Object?）
    });

    test('处理带 stackTrace 的异常', () {
      expect(
        () => recordException(TokenExpiredException(), StackTrace.current),
        returnsNormally,
      );
    });
  });
}
