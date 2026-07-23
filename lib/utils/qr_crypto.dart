import 'dart:convert';
import 'package:encrypt/encrypt.dart';

/// Handles encryption/decryption of QR code data for secure ticket scanning.
///
/// Uses AES-256-CBC encryption with a shared key between booking and owner apps.
/// The QR code will show encrypted text instead of readable booking details.
class QrCrypto {
  QrCrypto._();

  // Shared encryption key (32 bytes for AES-256)
  // In production, this should be stored securely (e.g., in environment variables)
  static const String _keyString = 'TurfPro2026SecureKeyForQR12345678';

  // Initialization Vector (16 bytes for AES)
  static const String _ivString = 'TurfProIV2026!!';

  static Key get _key => Key.fromUtf8(_keyString);
  static IV get _iv => IV.fromUtf8(_ivString);

  /// Encrypts the QR code data string.
  /// 
  /// Returns a Base64-encoded encrypted string safe for QR code encoding.
  /// Example input: "abc123 | Ground: PowerPlay | Owner: owner123 | Ground ID: g456"
  /// Example output: "U2FsdGVkX1+..." (encrypted Base64 string)
  static String encryptQrData(String plainText) {
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypts the QR code data string.
  /// 
  /// Takes the Base64-encoded encrypted string and returns the original plain text.
  /// Returns null if decryption fails.
  static String? decryptQrData(String encryptedText) {
    try {
      final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
      final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
      return decrypted;
    } catch (e) {
      // Decryption failed - invalid data or wrong key
      return null;
    }
  }

  /// Checks if a string appears to be encrypted QR data.
  /// Encrypted data is typically a long Base64 string without spaces.
  static bool isEncryptedQr(String data) {
    // Encrypted data won't contain the old format separator ' | '
    if (data.contains(' | ')) return false;
    
    // Check if it looks like a valid Base64 string
    try {
      base64.decode(data);
      return data.length > 20; // Encrypted data is typically longer
    } catch (_) {
      return false;
    }
  }

  /// Extracts booking ID from decrypted QR data.
  /// 
  /// QR format: "$orderId | Ground: ${ground.name} | Owner: ${ownerId} | Ground ID: ${groundId}"
  static String? extractBookingId(String qrString) {
    // Try to extract booking ID from formatted QR string
    if (qrString.contains(' | ')) {
      final parts = qrString.split(' | ');
      if (parts.isNotEmpty) {
        final bookingId = parts[0].trim();
        // Validate it looks like a UUID or order ID
        if (bookingId.isNotEmpty && (bookingId.contains('-') || bookingId.startsWith('order_'))) {
          return bookingId;
        }
      }
    }
    
    // Fallback: if the raw string looks like a UUID directly
    if (qrString.contains('-') && qrString.length >= 30) {
      return qrString.trim();
    }
    
    return null;
  }

  /// Parses the full QR data into a structured map.
  /// 
  /// Returns a map with keys: bookingId, groundName, ownerId, groundId
  /// Returns null if parsing fails.
  static Map<String, String>? parseQrData(String qrString) {
    if (!qrString.contains(' | ')) return null;
    
    final parts = qrString.split(' | ');
    if (parts.length < 4) return null;
    
    final bookingId = parts[0].trim();
    
    // Parse "Ground: PowerPlay Arena"
    final groundName = parts[1].replaceFirst('Ground:', '').trim();
    
    // Parse "Owner: owner123"
    final ownerId = parts[2].replaceFirst('Owner:', '').trim();
    
    // Parse "Ground ID: g456"
    final groundId = parts[3].replaceFirst('Ground ID:', '').trim();
    
    if (bookingId.isEmpty || ownerId.isEmpty || groundId.isEmpty) {
      return null;
    }
    
    return {
      'bookingId': bookingId,
      'groundName': groundName,
      'ownerId': ownerId,
      'groundId': groundId,
    };
  }
}
