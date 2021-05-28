import 'dart:convert' as convert;
import 'package:encrypt/encrypt.dart';

class AesUtils {
  /**
   * 加密
   */
  static Encrypted encryptAes(String content, String aesKey,
      {AESMode aesMode = AESMode.cbc,IV iv}) {
    final _aesKey = Key.fromUtf8(aesKey);
    final _encrypter = Encrypter(AES(_aesKey, mode: aesMode));
    final _encrypted = _encrypter.encrypt(content,iv: iv);

    print(_encrypted.base64);
    return _encrypted;
  }

  /**
   * 解密
   */
  static String decryptAes(String content, String aesKey,
      {AESMode aesMode = AESMode.cbc,String iv}) {
    // AES
    final _aesKey = Key.fromUtf8(aesKey);
    final _iv = IV.fromUtf8(iv);
    final _encrypter = Encrypter(AES(_aesKey, mode: aesMode));
    final _decrypted = _encrypter.decrypt64(content, iv: _iv);

    return _decrypted.toString();
  }
}
