import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class BackupException implements Exception {
  final String message;
  const BackupException(this.message);
}

abstract final class BackupCrypto {
  // OWASP guidance for PBKDF2-HMAC-SHA256. Older backups decrypt with whatever
  // iteration count they stored, so raising this stays backward compatible.
  static const _iterations = 600000;
  static final _cipher = AesGcm.with256bits();

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  static Future<SecretKey> _deriveKey(
    String passphrase,
    List<int> salt,
    int iterations,
  ) {
    return Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    ).deriveKey(secretKey: SecretKey(utf8.encode(passphrase)), nonce: salt);
  }

  static Map<String, dynamic> _envelope(String fileContent) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(fileContent) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupException("Not a valid SSHub backup file.");
    }
    if (json['app'] != 'sshub') {
      throw const BackupException("Not a valid SSHub backup file.");
    }
    return json;
  }

  static bool isEncrypted(String fileContent) =>
      _envelope(fileContent)['encrypted'] == true;

  static Future<String> encrypt(
    String plainText,
    String passphrase,
    String version,
  ) async {
    final salt = _randomBytes(16);
    final key = await _deriveKey(passphrase, salt, _iterations);
    final box = await _cipher.encrypt(utf8.encode(plainText), secretKey: key);
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'sshub',
      'version': version,
      'encrypted': true,
      'kdf': {
        'algo': 'pbkdf2-hmac-sha256',
        'iterations': _iterations,
        'salt': base64Encode(salt),
      },
      'cipher': {
        'algo': 'aes-256-gcm',
        'nonce': base64Encode(box.nonce),
        'ciphertext': base64Encode(box.cipherText),
        'mac': base64Encode(box.mac.bytes),
      },
    });
  }

  static Future<String> decrypt(String fileContent, String passphrase) async {
    final json = _envelope(fileContent);
    if (json['kdf'] == null || json['cipher'] == null) {
      throw const BackupException("Not a valid SSHub backup file.");
    }
    final kdf = json['kdf'] as Map<String, dynamic>;
    final cipher = json['cipher'] as Map<String, dynamic>;
    final key = await _deriveKey(
      passphrase,
      base64Decode(kdf['salt'] as String),
      kdf['iterations'] as int,
    );
    final box = SecretBox(
      base64Decode(cipher['ciphertext'] as String),
      nonce: base64Decode(cipher['nonce'] as String),
      mac: Mac(base64Decode(cipher['mac'] as String)),
    );
    try {
      return utf8.decode(await _cipher.decrypt(box, secretKey: key));
    } on SecretBoxAuthenticationError {
      throw const BackupException("Wrong passphrase or corrupted file.");
    } catch (_) {
      throw const BackupException("Could not read backup file.");
    }
  }
}
