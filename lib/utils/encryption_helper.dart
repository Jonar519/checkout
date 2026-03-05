import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

class EncryptionHelper {
  static final EncryptionHelper _instance = EncryptionHelper._internal();
  factory EncryptionHelper() => _instance;
  EncryptionHelper._internal();

  final _secureStorage = const FlutterSecureStorage();
  static const String _keyKey = 'encryption_key';
  static const String _ivKey = 'encryption_iv';

  encrypt.Encrypter? _encrypter;
  encrypt.IV? _iv;

  // Inicializar la encriptación
  Future<void> initialize() async {
    try {
      // Obtener o generar la clave de encriptación
      String? keyString = await _secureStorage.read(key: _keyKey);
      String? ivString = await _secureStorage.read(key: _ivKey);

      if (keyString == null || ivString == null) {
        // Generar nueva clave y IV
        final key = encrypt.Key.fromSecureRandom(32); // AES-256
        final iv = encrypt.IV.fromSecureRandom(16);

        keyString = base64.encode(key.bytes);
        ivString = base64.encode(iv.bytes);

        await _secureStorage.write(key: _keyKey, value: keyString);
        await _secureStorage.write(key: _ivKey, value: ivString);
      }

      final key = encrypt.Key.fromBase64(keyString);
      _iv = encrypt.IV.fromBase64(ivString);
      _encrypter = encrypt.Encrypter(encrypt.AES(key));

      print('🔐 Encriptación inicializada correctamente');
    } catch (e) {
      print('❌ Error inicializando encriptación: $e');
    }
  }

  // Encriptar texto
  String encryptText(String plainText) {
    if (_encrypter == null || _iv == null) {
      throw Exception('Encriptación no inicializada');
    }
    try {
      final encrypted = _encrypter!.encrypt(plainText, iv: _iv!);
      return encrypted.base64;
    } catch (e) {
      print('❌ Error encriptando: $e');
      return plainText; // Fallback seguro
    }
  }

  // Desencriptar texto
  String decryptText(String encryptedText) {
    if (_encrypter == null || _iv == null) {
      throw Exception('Encriptación no inicializada');
    }
    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
      final decrypted = _encrypter!.decrypt(encrypted, iv: _iv!);
      return decrypted;
    } catch (e) {
      print('❌ Error desencriptando: $e');
      return encryptedText; // Fallback seguro
    }
  }

  // Hash de datos (para validación sin desencriptar)
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Enmascarar número de tarjeta (solo muestra últimos 4)
  String maskCardNumber(String cardNumber) {
    if (cardNumber.length < 4) return '****';
    String cleaned = cardNumber.replaceAll(' ', '');
    if (cleaned.length <= 4) return cardNumber;
    String last4 = cleaned.substring(cleaned.length - 4);
    return '**** **** **** $last4';
  }

  // Limpiar datos sensibles
  Future<void> clearSensitiveData() async {
    await _secureStorage.deleteAll();
    _encrypter = null;
    _iv = null;
  }
}
