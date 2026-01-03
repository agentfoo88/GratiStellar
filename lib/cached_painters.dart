import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'background.dart';
import 'starfield.dart';

// ========================================
// CACHED LAYER PAINTERS
// ========================================

/// Painter that uses cached background image instead of drawing stars
/// Supports season-based gradients when season tracking is enabled
class CachedBackgroundPainter extends CustomPainter {
  final ui.Image? cachedImage;  // Changed from Image to ui.Image
  final List<Color>? seasonGradientColors; // Optional season gradient colors (5 stops)

  CachedBackgroundPainter(this.cachedImage, {this.seasonGradientColors});

  @override
  void paint(Canvas canvas, Size size) {
    // #region agent log
    _writeDebugLog('cached_painters.dart:19', 'CachedBackgroundPainter.paint() called', {
      'hasCachedImage': cachedImage != null,
      'hasSeasonGradient': seasonGradientColors != null,
      'seasonGradientLength': seasonGradientColors?.length ?? 0,
      'size': '${size.width}x${size.height}',
    }, 'A');
    // #endregion

    // ALWAYS draw cached image first (contains gradient + background stars)
    if (cachedImage != null) {
      // #region agent log
      _writeDebugLog('cached_painters.dart:28', 'Drawing cached background image', {
        'imageSize': '${cachedImage!.width}x${cachedImage!.height}',
        'hasSeasonGradient': seasonGradientColors != null,
      }, 'A');
      // #endregion
      final paint = Paint()..filterQuality = FilterQuality.medium;
      canvas.drawImageRect(
        cachedImage!,
        Rect.fromLTWH(0, 0, cachedImage!.width.toDouble(), cachedImage!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        paint,
      );
    } else {
      // Fallback: solid gradient if cache not ready
      // #region agent log
      _writeDebugLog('cached_painters.dart:40', 'No cached image - using fallback gradient', {}, 'A');
      // #endregion
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          BackgroundConfig.customTopColor,
          BackgroundConfig.customMidTopColor,
          BackgroundConfig.customMidBottomColor,
          BackgroundConfig.customBottomColor,
        ],
      );
      final paint = Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    }

    // THEN overlay season gradient using blend mode that preserves star brightness
    if (seasonGradientColors != null && seasonGradientColors!.length == 4) {
      // #region agent log
      _writeDebugLog('cached_painters.dart:58', 'Overlaying season gradient with color blend', {
        'blendMode': 'color',
        'opacity': 0.33,
      }, 'B');
      // #endregion
      // Use BlendMode.color to preserve luminance (brightness) of stars
      // This tints the gradient while keeping stars visible
      final seasonGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: seasonGradientColors!,
        stops: const [0.0, 0.3, 0.7, 1.0], // 4 stops: top, 30%, 70%, bottom
      );
      final seasonPaint = Paint()
        ..shader = seasonGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..color = Colors.white.withValues(alpha: 0.33) // Reduced opacity
        ..blendMode = BlendMode.color; // Preserves brightness/luminance
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), seasonPaint);
    }
  }

  /// Write debug log to file (for debug mode instrumentation)
  void _writeDebugLog(String location, String message, Map<String, dynamic> data, String hypothesisId) {
    try {
      final logFile = File('.cursor/debug.log');
      logFile.parent.createSync(recursive: true);
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final logEntry = {
        'id': 'log_${timestamp}_$hypothesisId',
        'timestamp': timestamp,
        'location': location,
        'message': message,
        'data': data,
        'sessionId': 'debug-session',
        'runId': 'test-stars',
        'hypothesisId': hypothesisId,
      };
      final jsonLine = jsonEncode(logEntry);
      logFile.writeAsStringSync(
        '${logFile.existsSync() ? logFile.readAsStringSync() : ""}$jsonLine\n',
        mode: FileMode.append,
      );
    } catch (e) {
      // Silently fail - don't break app if logging fails
    }
  }

  @override
  bool shouldRepaint(covariant CachedBackgroundPainter oldDelegate) {
    // Repaint if season gradient colors changed
    return seasonGradientColors != oldDelegate.seasonGradientColors;
  }
}

/// Painter for cached Van Gogh base + animated twinklers
class CachedVanGoghPainter extends CustomPainter {
  final ui.Image? cachedBaseImage;  // Changed from Image to ui.Image
  final List<VanGoghStar> animatedStars;

  CachedVanGoghPainter(this.cachedBaseImage, this.animatedStars);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw cached base layer (90 static stars)
    if (cachedBaseImage != null) {
      final paint = Paint()..filterQuality = FilterQuality.medium;
      canvas.drawImageRect(
        cachedBaseImage!,
        Rect.fromLTWH(0, 0, cachedBaseImage!.width.toDouble(), cachedBaseImage!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        paint,
      );
    }

    // Draw animated stars (12 twinklers) - using actual properties
    final paint = Paint();
    final now = DateTime.now();

    for (final star in animatedStars) {
      // Convert world coordinates to screen coordinates
      final screenX = star.worldX * size.width;
      final screenY = star.worldY * size.height;

      paint.color = star.stellarColor;
      canvas.drawCircle(Offset(screenX, screenY), star.size, paint);

      // Add twinkling if enabled
      if (star.shouldTwinkle) {
        final timeSinceCreation = now.difference(star.createdAt).inMilliseconds / 1000.0;
        final pulseTime = (timeSinceCreation * star.pulseSpeed + star.pulsePhase) % (2 * 3.14159);
        // Simple twinkle effect
        final twinkle = 0.5 + 0.5 * (pulseTime / (2 * 3.14159));
        paint.color = star.stellarColor.withValues(alpha: twinkle);
        canvas.drawCircle(Offset(screenX, screenY), star.size * 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; // Animated stars change
}

/// Painter for cached nebula with simple opacity animation
class CachedNebulaPainter extends CustomPainter {
  final ui.Image? cachedImage;  // Changed from Image to ui.Image
  final double animationValue;

  CachedNebulaPainter(this.cachedImage, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (cachedImage != null) {
      // Gentle opacity pulse: 0.8 to 1.0
      final opacity = 0.8 + (0.2 * animationValue);
      final paint = Paint()
        ..filterQuality = FilterQuality.medium
        ..color = Colors.white.withValues(alpha: opacity);

      canvas.drawImageRect(
        cachedImage!,
        Rect.fromLTWH(0, 0, cachedImage!.width.toDouble(), cachedImage!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; // Animation changes
}

/// Painter for pre-made nebula asset image
class AssetNebulaPainter extends CustomPainter {
  final ui.Image? image;
  final double animationValue;

  AssetNebulaPainter(this.image, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;

    // Buffer scale to prevent edges showing during parallax (1.3 = 30% buffer)
    final double bufferScale = 1.3;

    // Calculate aspect ratios
    final imageAspect = image!.width / image!.height;
    final screenAspect = size.width / size.height;

    // Scale to cover screen while maintaining aspect ratio + buffer
    double drawWidth, drawHeight;
    if (imageAspect > screenAspect) {
      // Image is wider - fit to height
      drawHeight = size.height * bufferScale;
      drawWidth = drawHeight * imageAspect;
    } else {
      // Image is taller - fit to width
      drawWidth = size.width * bufferScale;
      drawHeight = drawWidth / imageAspect;
    }

    // Center the image
    final left = (size.width - drawWidth) / 2;
    final top = (size.height - drawHeight) / 2;

    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..blendMode = BlendMode.screen
      ..color = Colors.white.withValues(alpha: 0.22);

    canvas.drawImageRect(
      image!,
      Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()),
      Rect.fromLTWH(left, top, drawWidth, drawHeight),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}