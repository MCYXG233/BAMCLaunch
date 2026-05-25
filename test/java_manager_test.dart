import 'package:flutter_test/flutter_test.dart';
import 'package:bamclaunch/src/game/java/models.dart';

void main() {
  group('JavaVersion Tests', () {
    test('parseMajorVersion should parse 1.x format correctly', () {
      expect(JavaVersion.parseMajorVersion('1.8.0_301'), equals(8));
      expect(JavaVersion.parseMajorVersion('1.7.0_80'), equals(7));
      expect(JavaVersion.parseMajorVersion('1.6.0_45'), equals(6));
    });

    test('parseMajorVersion should parse new format correctly', () {
      expect(JavaVersion.parseMajorVersion('11.0.12'), equals(11));
      expect(JavaVersion.parseMajorVersion('17.0.4'), equals(17));
      expect(JavaVersion.parseMajorVersion('21'), equals(21));
      expect(JavaVersion.parseMajorVersion('22.0.1'), equals(22));
    });

    test('parseMajorVersion should handle quoted strings', () {
      expect(JavaVersion.parseMajorVersion('"17.0.4"'), equals(17));
      expect(JavaVersion.parseMajorVersion("'11.0.12'"), equals(11));
    });

    test('parseMajorVersion should handle invalid versions', () {
      expect(JavaVersion.parseMajorVersion(''), equals(0));
      expect(JavaVersion.parseMajorVersion('invalid'), equals(0));
      expect(JavaVersion.parseMajorVersion('x.y.z'), equals(0));
    });

    test('isCompatible should return true for compatible versions', () {
      expect(JavaVersion.isCompatible(8), isTrue);
      expect(JavaVersion.isCompatible(11), isTrue);
      expect(JavaVersion.isCompatible(17), isTrue);
      expect(JavaVersion.isCompatible(21), isTrue);
    });

    test('isCompatible should return false for incompatible versions', () {
      expect(JavaVersion.isCompatible(7), isFalse);
      expect(JavaVersion.isCompatible(9), isFalse);
      expect(JavaVersion.isCompatible(12), isFalse);
      expect(JavaVersion.isCompatible(16), isFalse);
      expect(JavaVersion.isCompatible(22), isFalse);
    });

    test('isRecommended should return true for recommended versions', () {
      expect(JavaVersion.isRecommended(8), isTrue);
      expect(JavaVersion.isRecommended(11), isTrue);
      expect(JavaVersion.isRecommended(17), isTrue);
      expect(JavaVersion.isRecommended(21), isTrue);
      expect(JavaVersion.isRecommended(12), isTrue); // Between 8-21
      expect(JavaVersion.isRecommended(20), isTrue); // Between 8-21
    });

    test('isRecommended should return false for non-recommended versions', () {
      expect(JavaVersion.isRecommended(7), isFalse);
      expect(JavaVersion.isRecommended(22), isFalse);
    });

    test('getCompatibilityDescription should return correct descriptions', () {
      expect(JavaVersion.getCompatibilityDescription(0), equals('未知版本'));
      expect(JavaVersion.getCompatibilityDescription(8), equals('完全兼容'));
      expect(JavaVersion.getCompatibilityDescription(11), equals('完全兼容'));
      expect(JavaVersion.getCompatibilityDescription(17), equals('完全兼容'));
      expect(JavaVersion.getCompatibilityDescription(21), equals('完全兼容'));
      expect(JavaVersion.getCompatibilityDescription(7), equals('版本过低'));
      expect(JavaVersion.getCompatibilityDescription(22), equals('可能不兼容'));
    });
  });

  group('JavaInstallation Tests', () {
    test('JavaInstallation should create correctly', () {
      final installation = JavaInstallation(
        path: '/usr/bin/java',
        version: '17.0.4',
        majorVersion: 17,
        is64Bit: true,
        vendor: 'Oracle',
      );

      expect(installation.path, equals('/usr/bin/java'));
      expect(installation.version, equals('17.0.4'));
      expect(installation.majorVersion, equals(17));
      expect(installation.is64Bit, isTrue);
      expect(installation.vendor, equals('Oracle'));
    });

    test('JavaInstallation should handle null vendor', () {
      final installation = JavaInstallation(
        path: '/usr/bin/java',
        version: '11.0.12',
        majorVersion: 11,
        is64Bit: true,
      );

      expect(installation.vendor, isNull);
    });

    test('copyWith should create new instance with updated values', () {
      final original = JavaInstallation(
        path: '/usr/bin/java',
        version: '17.0.4',
        majorVersion: 17,
        is64Bit: true,
        vendor: 'Oracle',
      );

      final updated = original.copyWith(version: '17.0.5', vendor: 'OpenJDK');

      expect(updated.path, equals(original.path));
      expect(updated.version, equals('17.0.5'));
      expect(updated.majorVersion, equals(original.majorVersion));
      expect(updated.is64Bit, equals(original.is64Bit));
      expect(updated.vendor, equals('OpenJDK'));
      expect(updated, isNot(same(original)));
    });

    test('equality should work correctly', () {
      final installation1 = JavaInstallation(
        path: '/usr/bin/java',
        version: '17.0.4',
        majorVersion: 17,
        is64Bit: true,
        vendor: 'Oracle',
      );

      final installation2 = JavaInstallation(
        path: '/usr/bin/java',
        version: '17.0.4',
        majorVersion: 17,
        is64Bit: true,
        vendor: 'Oracle',
      );

      final installation3 = JavaInstallation(
        path: '/usr/local/bin/java',
        version: '11.0.12',
        majorVersion: 11,
        is64Bit: false,
        vendor: 'OpenJDK',
      );

      expect(installation1, equals(installation2));
      expect(installation1.hashCode, equals(installation2.hashCode));
      expect(installation1, isNot(equals(installation3)));
    });

    test('toString should return correct string', () {
      final installation = JavaInstallation(
        path: '/usr/bin/java',
        version: '17.0.4',
        majorVersion: 17,
        is64Bit: true,
        vendor: 'Oracle',
      );

      final string = installation.toString();
      expect(string, contains('/usr/bin/java'));
      expect(string, contains('17.0.4'));
      expect(string, contains('17'));
      expect(string, contains('true'));
      expect(string, contains('Oracle'));
    });
  });
}
