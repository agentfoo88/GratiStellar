/// Input validation and sanitization for security
class InputValidator {
  // Maximum safe lengths
  static const int maxGratitudeLength = 500;
  static const int maxEmailLength = 254;
  static const int maxHexLength = 7;

  /// Sanitize gratitude text input
  /// Removes dangerous characters, normalizes whitespace
  static String sanitizeGratitudeText(String input) {
    if (input.isEmpty) return input;

    String sanitized = input;

    // Normalize unicode
    sanitized = sanitized.replaceAll(RegExp(r'\p{C}', unicode: true), '');

    // Remove zero-width characters (can be used for obfuscation)
    sanitized = sanitized.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');

    // Normalize whitespace (but preserve newlines for multiline input)
    sanitized = sanitized.replaceAll(RegExp(r'[ \t]+'), ' ');
    sanitized = sanitized.replaceAll(RegExp(r'\n\n+'), '\n\n'); // Max 2 consecutive newlines

    // Trim leading/trailing whitespace
    sanitized = sanitized.trim();

    // Enforce length limit
    if (sanitized.length > maxGratitudeLength) {
      sanitized = sanitized.substring(0, maxGratitudeLength);
    }

    return sanitized;
  }

  /// Validate hex color input
  static String? sanitizeHexColor(String input) {
    if (input.isEmpty) return null;

    // Remove any non-hex characters
    String hex = input.replaceAll(RegExp(r'[^0-9A-Fa-f#]'), '');

    // Ensure # prefix
    if (!hex.startsWith('#')) {
      hex = '#$hex';
    }

    // Validate length
    if (hex.length != 7) return null;

    // Validate format
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex)) return null;

    return hex.toUpperCase();
  }

  /// Validate RGB value (0-255)
  static int? sanitizeRGBValue(String input) {
    if (input.isEmpty) return null;

    final value = int.tryParse(input);
    if (value == null) return null;

    return value.clamp(0, 255);
  }

  /// Check if text contains potentially dangerous patterns
  static bool hasDangerousContent(String input) {
    // Check for script injection attempts
    if (RegExp(r'<script', caseSensitive: false).hasMatch(input)) return true;
    if (RegExp(r'javascript:', caseSensitive: false).hasMatch(input)) return true;
    if (RegExp(r'on\w+\s*=', caseSensitive: false).hasMatch(input)) return true;

    return false;
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    if (email.length > maxEmailLength) return false;

    return RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    ).hasMatch(email);
  }
}