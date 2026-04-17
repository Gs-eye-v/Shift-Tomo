import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

/// 復号化失敗時に投げられるカスタム例外
class DecryptionException implements Exception {
  final String message;
  DecryptionException(this.message);
  @override
  String toString() => 'DecryptionException: $message';
}

/// E2EE (エンドツーエンド暗号化) を担当するサービス
class EncryptionService {
  final String _password;

  EncryptionService({required String password}) : _password = password;

  /// パスワードから256ビットのAESキーを生成 (SHA-256)
  encrypt.Key _deriveKey() {
    final bytes = utf8.encode(_password);
    final digest = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }

  /// 文字列を暗号化
  /// [plainText] 暗号化対象の文字列
  /// 戻り値: "Base64(IV[16bytes] + Ciphertext)"
  String encryptData(String plainText) {
    final key = _deriveKey();
    // ランダムなIV (16バイト) を生成
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    
    // IVと暗号文を結合してBase64化
    final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combined.setAll(0, iv.bytes);
    combined.setAll(iv.bytes.length, encrypted.bytes);

    return base64.encode(combined);
  }

  /// 暗号化された文字列を復号
  /// [combinedBase64] "Base64(IV[16bytes] + Ciphertext)" 形式の文字列
  /// 戻り値: 復号された平文
  String decryptData(String combinedBase64) {
    try {
      final key = _deriveKey();
      final combined = base64.decode(combinedBase64);
      
      if (combined.length < 16) {
        throw DecryptionException('Invalid encrypted data: too short to contain IV');
      }

      // 先頭16バイトがIV
      final ivBytes = combined.sublist(0, 16);
      final ciphertextBytes = combined.sublist(16);
      
      final iv = encrypt.IV(ivBytes);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      
      return encrypter.decrypt(encrypt.Encrypted(ciphertextBytes), iv: iv);
    } catch (e) {
      throw DecryptionException('復号に失敗しました。パスワードが正しくない可能性があります。($e)');
    }
  }
}
