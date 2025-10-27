import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

// ========================================
// BACKGROUND CONFIGURATION
// ========================================
// Adjust these values to fine-tune background appearance and behavior
class BackgroundConfig {
  // Reference configuration for density calculation
  static const Size referenceScreenSize = Size(1920, 1080);
  static const int referenceStarCount = 2500;

// Calculate target density (stars per square pixel)
  static double get referenceDensity =>
      referenceStarCount / (referenceScreenSize.width * referenceScreenSize.height);

  // Star Generation Settings
  static const int starCount = 12500;                    // Total number of background stars
  static const double starSizeMin = 0.1;              // Minimum star size
  static const double starSizeMax = 1.25;              // Maximum star size
  static const double starBrightnessMin = 0.25;        // Minimum star brightness (0.0-1.0)
  static const double starBrightnessMax = 0.65;        // Maximum star brightness (0.0-1.0)

  // Star Distribution Settings
  static const bool useGaussianDistribution = false;   // Use Gaussian distribution vs uniform
  static const double gaussianCenterX = 0.5;          // Gaussian center X (0.0-1.0)
  static const double gaussianCenterY = 0.5;          // Gaussian center Y (0.0-1.0)
  static const double gaussianSpread = 0.9;           // Gaussian spread factor

  // Parallax Settings
  static const double parallaxStrength = 0.05;         // Parallax movement strength (0.0-1.0)
  static const bool enableParallax = true;            // Enable/disable parallax effect

  // Personalization Settings
  static const bool useMonthlyRotation = true;        // Rotate star field monthly
  static const bool useDailyVariation = false;        // Add daily variation to monthly rotation

  // Van Gogh Gradient Settings
  static const double gradientTopOpacity = 1.0;       // Top gradient color opacity
  static const double gradientMidOpacity = 1.0;       // Middle gradient color opacity
  static const double gradientBottomOpacity = 1.0;    // Bottom gradient color opacity
  static const bool enableCustomGradient = true;     // Use custom gradient colors

  // Custom Van Gogh Colors (used if enableCustomGradient = true)
//  static const Color customTopColor = Color(0xFF4A6FA5);     // Van Gogh blue
//  static const Color customMidTopColor = Color(0xFF166088);   // Darker blue
//  static const Color customMidBottomColor = Color(0xFF0B1426); // Deep navy
//  static const Color customBottomColor = Color(0xFF2C3E50);   // Dark blue-gray

  static const Color customTopColor = Color(0xFF2D1B69); // Deep purple-blue (top)
  static const Color customMidTopColor = Color(0xFF1E3A8A); // Rich blue
  static const Color customMidBottomColor = Color(0xFF1E40AF); // Slightly lighter blue
  static const Color customBottomColor = Color(0xFF3730A3); // Purple-blue (bottom)

  // Texture Overlay Settings
  static const bool enableBrushstrokeTexture = true;  // Enable brushstroke texture overlay
  static const bool enableCanvasTexture = true;       // Enable canvas texture overlay
  static const double brushstrokeOpacity = 0.2;       // Brushstroke texture opacity (0.0-1.0)
  static const double canvasTextureOpacity = 1.0;     // Canvas texture opacity (0.0-1.0)
  static const BlendMode brushstrokeBlendMode = BlendMode.overlay; // Brushstroke blend mode
  static const BlendMode canvasBlendMode = BlendMode.multiply;     // Canvas blend mode

  // Brushstroke Color Tinting
  static const Color brushstrokeTint = Color(0xFFFFE135); // Brushstroke tint color
  static const bool enableBrushstrokeTint = true;         // Enable brushstroke tinting

  // Performance Settings
  static const bool enableAntiAliasing = true;        // Enable anti-aliasing for stars
  static const bool enableTextureFiltering = true;    // Enable texture filtering

  // Animation Settings (for future use)
  static const bool enableStarTwinkling = false;      // Enable subtle star twinkling
  static const double twinkleSpeed = 1.0;             // Twinkling animation speed
  static const double twinkleIntensity = 0.1;         // Twinkling intensity (0.0-1.0)

  // Seasonal Variation Settings (for future use)
  static const bool enableSeasonalColors = false;     // Enable seasonal color variations
  static const double seasonalIntensity = 0.3;        // Seasonal color shift intensity
}

// Simplified background star (same structure as before but minimal)
class BackgroundStar {
  final double x;
  final double y;
  final double size;
  final double brightness;

  BackgroundStar(this.x, this.y, this.size, this.brightness);
}

// Enhanced background service with configurable generation
class BackgroundService {
  static ui.Image? _brushstrokeTexture;
  static ui.Image? _canvasTexture;

  // Load texture assets
  static Future<void> loadTextures() async {
    if (BackgroundConfig.enableBrushstrokeTexture) {
      try {
        _brushstrokeTexture = await _loadImageAsset('assets/textures/brushstrokes.png');
      } catch (e) {
        // Brushstroke texture not available
      }
    }

    if (BackgroundConfig.enableCanvasTexture) {
      try {
        _canvasTexture = await _loadImageAsset('assets/textures/canvas_texture.png');
      } catch (e) {
        // Canvas texture not available
      }
    }
  }

  static Future<ui.Image> _loadImageAsset(String path) async {
    final ByteData data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  // Configurable star generation with multiple distribution options
  static List<BackgroundStar> generateStaticStars([Size? screenSize]) {
    final size = screenSize ?? const Size(1920, 1080);

    // Calculate star count for this screen size at consistent density
    final screenArea = size.width * size.height;
    final calculatedStarCount = (screenArea * BackgroundConfig.referenceDensity).round();

// Use calculated count
    final starCount = calculatedStarCount;

    final now = DateTime.now();

    // Create personalized seed based on configuration
    int userSeed = now.day + now.month * 31;

    if (BackgroundConfig.useMonthlyRotation) {
      userSeed = now.month + now.year * 12;

      if (BackgroundConfig.useDailyVariation) {
        userSeed += now.day;
      }
    }

    final staticRandom = math.Random(userSeed);
    final stars = <BackgroundStar>[];

    for (int i = 0; i < starCount; i++) {
      double x, y;

      if (BackgroundConfig.useGaussianDistribution) {
        // Gaussian distribution around configurable center
        x = _gaussianRandom(staticRandom, BackgroundConfig.gaussianCenterX, BackgroundConfig.gaussianSpread);
        y = _gaussianRandom(staticRandom, BackgroundConfig.gaussianCenterY, BackgroundConfig.gaussianSpread);

        // Clamp to screen bounds
        x = x.clamp(0.0, 1.0);
        y = y.clamp(0.0, 1.0);
      } else {
        // Uniform distribution across screen (0.0 to 1.0)
        x = staticRandom.nextDouble();
        y = staticRandom.nextDouble();
      }

      final starSize = BackgroundConfig.starSizeMin +
          staticRandom.nextDouble() * (BackgroundConfig.starSizeMax - BackgroundConfig.starSizeMin);

      final brightness = BackgroundConfig.starBrightnessMin +
          staticRandom.nextDouble() * (BackgroundConfig.starBrightnessMax - BackgroundConfig.starBrightnessMin);

      stars.add(BackgroundStar(x, y, starSize, brightness));
    }

    return stars;
  }

  // Helper method for Gaussian distribution
  static double _gaussianRandom(math.Random random, double center, double spread) {
    // Box-Muller transform for Gaussian distribution
    final u1 = random.nextDouble();
    final u2 = random.nextDouble();
    final z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
    return center + z * spread;
  }

  // Configurable gradient generation
  static List<Paint> generateBackgroundGradients() {
    final gradients = <Paint>[];

    List<Color> gradientColors;

    if (BackgroundConfig.enableCustomGradient) {
      gradientColors = [
        BackgroundConfig.customTopColor.withValues(alpha: BackgroundConfig.gradientTopOpacity),
        BackgroundConfig.customMidTopColor.withValues(alpha: BackgroundConfig.gradientMidOpacity),
        BackgroundConfig.customMidBottomColor.withValues(alpha: BackgroundConfig.gradientMidOpacity),
        BackgroundConfig.customBottomColor.withValues(alpha: BackgroundConfig.gradientBottomOpacity),
      ];
    } else {
      // Default Van Gogh colors with configurable opacity
      gradientColors = [
        Color(0xFF4A6FA5).withValues(alpha: BackgroundConfig.gradientTopOpacity),
        Color(0xFF166088).withValues(alpha: BackgroundConfig.gradientMidOpacity),
        Color(0xFF0B1426).withValues(alpha: BackgroundConfig.gradientMidOpacity),
        Color(0xFF2C3E50).withValues(alpha: BackgroundConfig.gradientBottomOpacity),
      ];
    }

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: gradientColors,
      stops: [0.0, 0.3, 0.7, 1.0],
    );

    gradients.add(Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, 1000, 1000)));
    return gradients;
  }
}

// Enhanced painter with configurable rendering
class StaticBackgroundPainter extends CustomPainter {
  final List<BackgroundStar> stars;
  final double parallaxOffsetX;
  final double parallaxOffsetY;

  StaticBackgroundPainter(
      this.stars, {
        this.parallaxOffsetX = 0.0,
        this.parallaxOffsetY = 0.0,
      });

  @override
  void paint(Canvas canvas, Size size) {
    // Configure anti-aliasing
    //if (BackgroundConfig.enableAntiAliasing) {
      //canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height), doAntiAlias: true);
    //}

    // Paint configurable Van Gogh gradient
    List<Color> gradientColors;

    if (BackgroundConfig.enableCustomGradient) {
      gradientColors = [
        BackgroundConfig.customTopColor.withValues(alpha: BackgroundConfig.gradientTopOpacity),
        BackgroundConfig.customMidTopColor.withValues(alpha: BackgroundConfig.gradientMidOpacity),
        BackgroundConfig.customMidBottomColor.withValues(alpha: BackgroundConfig.gradientMidOpacity),
        BackgroundConfig.customBottomColor.withValues(alpha: BackgroundConfig.gradientBottomOpacity),
      ];
    } else {
      gradientColors = [
        Color(0xFF4A6FA5).withValues(alpha: BackgroundConfig.gradientTopOpacity),
        Color(0xFF166088).withValues(alpha: BackgroundConfig.gradientMidOpacity),
        Color(0xFF0B1426).withValues(alpha: BackgroundConfig.gradientMidOpacity),
        Color(0xFF2C3E50).withValues(alpha: BackgroundConfig.gradientBottomOpacity),
      ];
    }

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: gradientColors,
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Apply configurable texture overlays
    if (BackgroundConfig.enableBrushstrokeTexture) {
      _paintBrushstrokeTexture(canvas, size);
    }

    if (BackgroundConfig.enableCanvasTexture) {
      _paintCanvasTexture(canvas, size);
    }

    // Paint configurable stars with optional parallax
    paint.shader = null;

    for (final star in stars) {
      double starX = star.x * size.width;
      double starY = star.y * size.height;

      // Apply configurable parallax offset
      if (BackgroundConfig.enableParallax) {
        starX += parallaxOffsetX * BackgroundConfig.parallaxStrength;
        starY += parallaxOffsetY * BackgroundConfig.parallaxStrength;
      }

      paint.color = Colors.white.withValues(alpha: star.brightness);

      if (BackgroundConfig.enableAntiAliasing) {
        paint.isAntiAlias = true;
      }

      canvas.drawCircle(
        Offset(starX, starY),
        star.size,
        paint,
      );
    }
  }

  void _paintBrushstrokeTexture(Canvas canvas, Size size) {
    if (BackgroundService._brushstrokeTexture != null) {
      final paint = Paint()
        ..blendMode = BackgroundConfig.brushstrokeBlendMode;

      if (BackgroundConfig.enableBrushstrokeTint) {
        paint.colorFilter = ColorFilter.mode(
          BackgroundConfig.brushstrokeTint.withValues(alpha: BackgroundConfig.brushstrokeOpacity),
          BlendMode.modulate,
        );
      } else {
        paint.colorFilter = ColorFilter.mode(
          Colors.white.withValues(alpha: BackgroundConfig.brushstrokeOpacity),
          BlendMode.modulate,
        );
      }

      if (BackgroundConfig.enableTextureFiltering) {
        paint.filterQuality = FilterQuality.medium;
      }

      final texture = BackgroundService._brushstrokeTexture!;
      final textureWidth = texture.width.toDouble();
      final textureHeight = texture.height.toDouble();

      // Tile the brushstroke texture across the screen
      for (double x = 0; x < size.width; x += textureWidth) {
        for (double y = 0; y < size.height; y += textureHeight) {
          canvas.drawImageRect(
            texture,
            Rect.fromLTWH(0, 0, textureWidth, textureHeight),
            Rect.fromLTWH(x, y,
                math.min(textureWidth, size.width - x),
                math.min(textureHeight, size.height - y)),
            paint,
          );
        }
      }
    }
  }

  void _paintCanvasTexture(Canvas canvas, Size size) {
    if (BackgroundService._canvasTexture != null) {
      final paint = Paint()
        ..blendMode = BackgroundConfig.canvasBlendMode
        ..colorFilter = ColorFilter.mode(
          Colors.white.withValues(alpha: BackgroundConfig.canvasTextureOpacity),
          BlendMode.modulate,
        );

      if (BackgroundConfig.enableTextureFiltering) {
        paint.filterQuality = FilterQuality.medium;
      }

      final texture = BackgroundService._canvasTexture!;
      final textureWidth = texture.width.toDouble();
      final textureHeight = texture.height.toDouble();

      // Tile the canvas texture across the screen
      for (double x = 0; x < size.width; x += textureWidth) {
        for (double y = 0; y < size.height; y += textureHeight) {
          canvas.drawImageRect(
            texture,
            Rect.fromLTWH(0, 0, textureWidth, textureHeight),
            Rect.fromLTWH(x, y,
                math.min(textureWidth, size.width - x),
                math.min(textureHeight, size.height - y)),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}