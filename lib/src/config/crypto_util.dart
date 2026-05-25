import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

/// AES-256加密工具类
/// 提供AES-256-CBC加密和解密功能
class CryptoUtil {
  static const String _defaultPassword = 'bamclauncher_secret_key_2024';
  static const String _defaultSalt = 'bamclauncher_salt_2024';

  /// 从密码生成32字节密钥
  /// [password] 用户密码
  /// [salt] 可选的盐值，默认使用内置盐
  static encrypt.Key _generateKey(String password, {String? salt}) {
    final saltBytes = utf8.encode(salt ?? _defaultSalt);
    final passwordBytes = utf8.encode(password);

    final bytes = <int>[];
    bytes.addAll(passwordBytes);
    bytes.addAll(saltBytes);

    final hash = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(hash.bytes));
  }

  /// 生成随机IV
  static encrypt.IV _generateIV() {
    return encrypt.IV.fromSecureRandom(16);
  }

  /// AES-256-CBC加密
  /// [plaintext] 明文
  /// [password] 加密密码，默认使用内置密码
  /// [salt] 可选的盐值
  static String encryptString(
    String plaintext, {
    String? password,
    String? salt,
  }) {
    final key = _generateKey(password ?? _defaultPassword, salt: salt);
    final iv = _generateIV();

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );

    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// AES-256-CBC解密
  /// [ciphertext] 格式为 "IV:密文" 的Base64编码字符串
  /// [password] 解密密码，默认使用内置密码
  /// [salt] 可选的盐值
  static String? decryptString(
    String ciphertext, {
    String? password,
    String? salt,
  }) {
    try {
      final parts = ciphertext.split(':');
      if (parts.length != 2) return null;

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

      final key = _generateKey(password ?? _defaultPassword, salt: salt);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );

      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      return null;
    }
  }
}
