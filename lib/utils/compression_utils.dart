import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';

class CompressionUtils {
  // Minimum text length to compress (shorter text isn't worth the overhead)
  static const int minCompressionLength = 500;

  // Compress text using gzip
  static String? compressText(String text) {
    if (text.length < minCompressionLength) {
      return null; // Don't compress short text
    }

    try {
      // Convert string to bytes
      final bytes = utf8.encode(text);

      // Compress using gzip
      final compressed = GZipEncoder().encode(bytes);

      if (compressed == null) {
        return null;
      }

      // Encode to base64 for storage
      final base64Compressed = base64.encode(compressed);

      // Only use compression if it actually saves space
      if (base64Compressed.length < text.length) {
        return base64Compressed;
      }

      return null; // Compression didn't help
    } catch (e) {
      print('⚠️ Compression error: $e');
      return null;
    }
  }

  // Decompress text
  static String decompressText(String compressedText) {
    try {
      // Decode from base64
      final compressed = base64.decode(compressedText);

      // Decompress using gzip
      final decompressed = GZipDecoder().decodeBytes(compressed);

      // Convert bytes back to string
      return utf8.decode(decompressed);
    } catch (e) {
      print('⚠️ Decompression error: $e');
      // Return original if decompression fails (backward compatibility)
      return compressedText;
    }
  }

  // Check if text is compressed (base64 encoded gzip has specific pattern)
  static bool isCompressed(String text) {
    if (text.length < 10) return false;

    try {
      // Try to decode as base64
      final decoded = base64.decode(text);

      // Check for gzip magic number (1f 8b)
      return decoded.length >= 2 &&
          decoded[0] == 0x1f &&
          decoded[1] == 0x8b;
    } catch (e) {
      return false;
    }
  }
}