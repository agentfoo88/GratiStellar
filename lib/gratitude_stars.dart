import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'camera_controller.dart';
import 'core/config/palette_preset_config.dart';
import 'storage.dart';

// ========================================
// STAR APPEARANCE CONFIGURATION
// ========================================
// Adjust these values to fine-tune star appearance
class StarConfig {
  // Glow Settings
  static const double glowSizeMin = 3.0;        // Minimum glow multiplier (x star size)
  static const double glowSizeMax = 6.0;        // Maximum glow multiplier (x star size)
  static const double glowInnerRatio = 0.25;     // Inner glow size ratio (0.0-1.0)

  // Spin Rate Settings
  static const double spinRateMin = 0.02;        // Minimum spin speed multiplier
  static const double spinRateMax = 1.25;        // Maximum spin speed multiplier

  // Twinkle Pulse Settings
  static const double pulseSpeedMin = 1.5;      // Minimum pulse speed
  static const double pulseSpeedMax = 2.5;      // Maximum pulse speed
  static const double pulseAxisVariation = 0.8; // How much axis speeds can vary (0.0-1.0)
  static const double pulseMinScaleMax = 0.0;   // Maximum minimum scale (0.0 = can disappear)

  // Twinkle Shape Settings
  static const double twinkleLength = 2.5;      // Twinkle ray length (x star size)
  static const double twinkleWidth = 1.2;       // Twinkle ray width
  static const double concaveDrama = 1.0;       // How dramatic the concave curve is (0.0-1.0)
  static const double twinkleOpacityMin = 0.25;  // Minimum twinkle opacity
  static const double twinkleOpacityMax = 0.60;  // Maximum twinkle opacity

  // Star Core Settings
  static const double coreSize = 0.1;          // Core size ratio (x star size)
  static const double coreBrightnessMin = 0.88; // Minimum core brightness
  static const double coreBrightnessMax = 1.0; // Maximum core brightness

  // Glow Opacity Settings
  static const double outerGlowOpacity = 0.05;  // Outer glow center opacity
  static const double innerGlowOpacity = 0.5;   // Inner glow center opacity
}

// ========================================
// STAR BIRTH ANIMATION CONFIGURATION
// ========================================
class StarBirthConfig {
  // Travel Animation
  static const double travelBaseSpeed = 350.0;      // pixels per second (was 800)
  static const int travelDurationMin = 2000;        // milliseconds (was 800)
  static const int travelDurationMax = 3000;        // milliseconds (was 2000)
  static const double travelPhaseEnd = 0.9;         // When travel ends (0.0-1.0)

  // Protostar Appearance (traveling star)
  static const double protostarGlowSize = 5.0;      // Glow size multiplier (was 6.0)
  static const double protostarCoreSize = 0.3;      // Core size multiplier (was 2.0)
  static const double protostarPointSize = 0.1;     // Bright point size (was 0.8)
  static const double protostarPulseSpeed = 2.0;    // Pulse frequency
  static const double protostarPulseMin = 0.2;      // Minimum pulse brightness
  static const double protostarPulseMax = 1.0;      // Maximum pulse brightness

// Protostar opacity
  static const double protostarOuterOpacity = 0.1;  // Outer glow opacity
  static const double protostarMidOpacity = 0.3;    // Mid glow opacity
  static const double protostarCoreOpacity = 0.7;   // Core opacity

// Burst Effect
  static const int burstRingCount = 3;              // Number of expanding rings (was 3)
  static const double burstRadiusMultiplier = 15.0; // Burst size (was 15.0)
  static const double burstOpacity = 0.6;           // Maximum burst opacity
  static const double burstRingDelay = 0.1;         // Delay between rings (was 0.15)
  static const double burstFlashSize = 8.0;        // Central flash size (was 8.0)

// Burst twinkle rays
  static const int burstTwinkleCount = 8;          // Number of rays shooting out
  static const double burstTwinkleLength = 15.0;    // Ray length (x star size)
  static const double burstTwinkleWidth = 1.5;      // Ray width
  static const double burstTwinkleOpacity = 0.9;    // Ray opacity

  // Color Transition
  static const double colorTransitionStart = 0.3;   // When color fade begins (0.0-1.0)
  static const double coloredGlowSize = 4.0;        // Colored glow radius
  static const double coloredCoreSize = 0.5;        // Colored core radius
}

// Expanded Van Gogh inspired color palette with more variety
class StarColors {
  static const List<Color> palette = [
    Color(0xFFFFF200), // Bright Van Gogh yellow
    Color(0xFF00BFFF), // Bright sky blue
    Color(0xFF6A5ACD), // Slate blue
    Color(0xFFFFD700), // Gold
    Color(0xFFDA70D6), // Orchid
    Color(0xFFFF69B4), // Hot pink
    Color(0xFF00CED1), // Dark turquoise
    Color(0xFFFFA500), // Orange
    Color(0xFF32CD32), // Lime green
    Color(0xFFFF6347), // Tomato red
    Color(0xFF8A2BE2), // Blue violet
    Color(0xFFDC143C), // Crimson
    Color(0xFF00FA9A), // Medium spring green
    Color(0xFFFF1493), // Deep pink
    Color(0xFF1E90FF), // Dodger blue
    Color(0xFFFFB347), // Peach
  ];

  static Color getColor(int index) => palette[index % palette.length];
}

// Universe size management based on star count
class UniverseManager {
  static double calculateUniverseSize(int starCount) {
    return 1.0 + (starCount / 200).floor() * 1.0;
  }

  static Offset getUniverseCenter(double universeSize) {
    return Offset(universeSize / 2, universeSize / 2);
  }

  static double getClusterRadius(double universeSize) {
    // Scale the cluster radius proportionally (30% of universe)
    return universeSize * 0.3;
  }
}

// Hit testing utility for normalized coordinates
class StarHitTester {
  static GratitudeStar? findStarAtScreenPosition(
      Offset screenPosition,
      List<GratitudeStar> stars,
      Size screenSize,
      {
        Offset cameraPosition = Offset.zero,
        double cameraScale = 1.0,
      }
      ) {
    // Convert screen position to world coordinates using camera transform
    final adjustedScreenPos = screenPosition - cameraPosition;
    final worldPosition = adjustedScreenPos / cameraScale;

    // Convert to normalized world coordinates
    final normalizedX = worldPosition.dx / screenSize.width;
    final normalizedY = worldPosition.dy / screenSize.height;

    // Find closest star within tap radius
    const double tapRadiusWorld = 0.03; // 3% of screen width

    GratitudeStar? closestStar;
    double closestDistance = double.infinity;

    for (final star in stars) {
      final distance = _calculateWorldDistance(
        normalizedX,
        normalizedY,
        star.worldX,
        star.worldY,
      );

      if (distance <= tapRadiusWorld && distance < closestDistance) {
        closestStar = star;
        closestDistance = distance;
      }
    }

    return closestStar;
  }

  static double _calculateWorldDistance(double x1, double y1, double x2, double y2) {
    final dx = x1 - x2;
    final dy = y1 - y2;
    return math.sqrt(dx * dx + dy * dy);
  }
}

// Service for managing gratitude star creation and rendering
class GratitudeStarService {

  // Generate 10 irregular glow patterns
  static List<Paint> generateGlowPatterns() {
    final patterns = <Paint>[];

    for (int i = 0; i < 10; i++) {
      final patternRandom = math.Random(i + 100);
      final stops = <double>[];
      final colors = <Color>[];

      // Create irregular gradient stops for more visible glow
      stops.add(0.0);
      colors.add(Colors.white.withValues(alpha: 0.8)); // Much more visible center

      stops.add(0.3);
      colors.add(Colors.white.withValues(alpha: 0.4)); // Visible mid-range

      for (int j = 1; j < 4; j++) {
        stops.add(0.5 + (j / 4.0) * 0.4 + patternRandom.nextDouble() * 0.1);
        colors.add(Colors.white.withValues(alpha: 0.3 - j * 0.06)); // More visible gradation
      }

      stops.add(1.0);
      colors.add(Colors.white.withValues(alpha: 0.0));

      final gradient = RadialGradient(
        stops: stops,
        colors: colors,
        center: Alignment(
          patternRandom.nextDouble() * 0.4 - 0.2,
          patternRandom.nextDouble() * 0.4 - 0.2,
        ),
      );

      patterns.add(Paint()..shader = gradient.createShader(Rect.fromCircle(center: Offset.zero, radius: 100)));
    }

    return patterns;
  }

  // Create a new gratitude star with normalized coordinates and smart positioning
  static Future<GratitudeStar> createStar(
      String text,
      Size screenSize,
      math.Random random,
      List<GratitudeStar> existingStars, {
        required String galaxyId,
        int? colorPresetIndex,
        Color? customColor,
        String? inspirationPrompt,
      }) async {
    // Calculate current universe size based on star count
    final universeSize = UniverseManager.calculateUniverseSize(existingStars.length);
    final universeCenter = UniverseManager.getUniverseCenter(universeSize);
    final maxRadius = UniverseManager.getClusterRadius(universeSize);

    double worldX, worldY;
    int attempts = 0;
    const maxAttempts = 30;
    const minDistance = 0.075; // Minimum distance in world space (50% larger than 0.05)

    do {
      // Use Gaussian distribution to cluster around center
      final angle = random.nextDouble() * 2 * math.pi;
      final radius = random.nextGaussian() * maxRadius * 0.5;

      worldX = universeCenter.dx + math.cos(angle) * radius;
      worldY = universeCenter.dy + math.sin(angle) * radius;

      // Soft clamp to keep stars within reasonable bounds (5% margin)
      final margin = universeSize * 0.05;
      worldX = worldX.clamp(margin, universeSize - margin);
      worldY = worldY.clamp(margin, universeSize - margin);

      attempts++;

      // Check if this position overlaps with existing stars
      bool hasOverlap = false;
      for (final existingStar in existingStars) {
        final distance = math.sqrt(
            math.pow(worldX - existingStar.worldX, 2) +
                math.pow(worldY - existingStar.worldY, 2)
        );
        if (distance < minDistance) {
          hasOverlap = true;
          break;
        }
      }

      if (!hasOverlap) break;

    } while (attempts < maxAttempts);

    // --- Calculate animation properties once at creation ---
    final spinDirection = random.nextBool() ? 1.0 : -1.0;
    final spinRate = StarConfig.spinRateMin + random.nextDouble() * (StarConfig.spinRateMax - StarConfig.spinRateMin);
    final pulseSpeedH = StarConfig.pulseSpeedMin + random.nextDouble() * (StarConfig.pulseSpeedMax - StarConfig.pulseSpeedMin);
    final pulseSpeedV = StarConfig.pulseSpeedMin + random.nextDouble() * (StarConfig.pulseSpeedMax - StarConfig.pulseSpeedMin);
    final pulsePhaseH = random.nextDouble() * 2 * math.pi;
    final pulsePhaseV = random.nextDouble() * 2 * math.pi;
    final pulseMinScaleH = random.nextDouble() * StarConfig.pulseMinScaleMax;
    final pulseMinScaleV = random.nextDouble() * StarConfig.pulseMinScaleMax;
    // --- End animation property calculations ---

    // Get random color from selected palette preset if no color specified
    int? finalColorPresetIndex = colorPresetIndex;
    Color? finalCustomColor = customColor;
    
    if (finalColorPresetIndex == null && finalCustomColor == null) {
      // Use selected palette preset for random color
      try {
        final presetId = await StorageService.getSelectedPalettePreset();
        final preset = PalettePresetConfig.getPresetById(presetId);
        if (preset != null && preset.colors.isNotEmpty) {
          // Pick random color from preset
          final randomColor = preset.colors[random.nextInt(preset.colors.length)];
          // Check if this color exists in StarColors.palette
          final starColorsIndex = StarColors.palette.indexOf(randomColor);
          if (starColorsIndex >= 0) {
            finalColorPresetIndex = starColorsIndex;
          } else {
            // Use as custom color if not in StarColors.palette
            finalCustomColor = randomColor;
          }
        } else {
          // Fallback to StarColors.palette
          finalColorPresetIndex = random.nextInt(StarColors.palette.length);
        }
      } catch (e) {
        // Fallback to StarColors.palette on error
        finalColorPresetIndex = random.nextInt(StarColors.palette.length);
      }
    }

    return GratitudeStar(
      text: text,
      worldX: worldX,
      worldY: worldY,
      colorPresetIndex: finalColorPresetIndex ?? 0, // Default to first color if null
      customColor: finalCustomColor,
      size: 18.0 + random.nextDouble() * 9.0,  // Base size 18.0 (50% larger than 12.0)
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      galaxyId: galaxyId,
      glowPatternIndex: random.nextInt(10),
      // Pass the newly calculated animation properties
      spinDirection: spinDirection,
      spinRate: spinRate,
      pulseSpeedH: pulseSpeedH,
      pulseSpeedV: pulseSpeedV,
      pulsePhaseH: pulsePhaseH,
      pulsePhaseV: pulsePhaseV,
      pulseMinScaleH: pulseMinScaleH,
      pulseMinScaleV: pulseMinScaleV,
      // Pass the inspiration prompt that inspired this gratitude
      inspirationPrompt: inspirationPrompt,
    );
  }
}

// Interactive starfield canvas for gratitude stars
class StarfieldCanvas extends StatelessWidget {
  final List<GratitudeStar> stars;
  final AnimationController animationController;
  final List<Paint> glowPatterns;

  const StarfieldCanvas({
    super.key,
    required this.stars,
    required this.animationController,
    required this.glowPatterns,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: GratitudeStarPainter(stars, animationController.value, glowPatterns),
          size: Size.infinite,
        );
      },
    );
  }
}

// Optimized painter for gratitude stars with normalized coordinates
class GratitudeStarPainter extends CustomPainter {
  final List<GratitudeStar> stars;
  final double animationValue;
  final List<Paint> glowPatterns;

  GratitudeStarPainter(this.stars, this.animationValue, this.glowPatterns);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (int i = 0; i < stars.length; i++) {
      final star = stars[i];

      // Convert normalized world coordinates to screen coordinates
      final screenX = star.worldX * size.width;
      final screenY = star.worldY * size.height;

      // Viewport culling - skip stars outside visible area (with 200px margin)
      const cullingMargin = 200.0;
      if (screenX < -cullingMargin || screenX > size.width + cullingMargin ||
          screenY < -cullingMargin || screenY > size.height + cullingMargin) {
        continue;
      }

      final screenPosition = Offset(screenX, screenY);
      final spinDirection = star.spinDirection; // Use pre-calculated value
      final spinRate = star.spinRate;           // Use pre-calculated value

      // Use star creation time to ensure continuous rotation even for old stars
      final timeSinceCreation = DateTime.now().difference(star.createdAt).inMilliseconds / 1000.0;
      final rotation = (timeSinceCreation * spinRate * spinDirection) % (2 * math.pi);

      final brightness = 0.7 + math.sin(animationValue * 2 * math.pi + i * 0.5) * 0.3;

      // Layer 1: Dual overlaid glows - scaled to star size
      final glowColor = star.color;

      // Scale glow to star size with configurable variation
      final glowMultiplier = StarConfig.glowSizeMin + (star.id.hashCode % 1000 / 1000.0) * (StarConfig.glowSizeMax - StarConfig.glowSizeMin); // Derived from star ID for consistent variation

      // Outer glow - softer and more diffuse, scaled to star
      final outerGlowRadius = star.size * glowMultiplier;
      final outerGradient = RadialGradient(
        colors: [
          glowColor.withValues(alpha: StarConfig.outerGlowOpacity),
          glowColor.withValues(alpha: StarConfig.outerGlowOpacity * 0.5),
          glowColor.withValues(alpha: 0.0),
        ],
        stops: [0.0, 0.6, 1.0],
      );
      paint.shader = outerGradient.createShader(
          Rect.fromCircle(center: screenPosition, radius: outerGlowRadius)
      );
      canvas.drawCircle(screenPosition, outerGlowRadius, paint);

      // Inner glow - brighter and more focused, scaled to star
      final innerGlowRadius = star.size * (glowMultiplier * StarConfig.glowInnerRatio);
      final innerGradient = RadialGradient(
        colors: [
          glowColor.withValues(alpha: StarConfig.innerGlowOpacity),
          glowColor.withValues(alpha: StarConfig.innerGlowOpacity * 0.5),
          glowColor.withValues(alpha: 0.0),
        ],
        stops: [0.0, 0.5, 1.0],
      );
      paint.shader = innerGradient.createShader(
          Rect.fromCircle(center: screenPosition, radius: innerGlowRadius)
      );
      canvas.drawCircle(screenPosition, innerGlowRadius, paint);

      // Reset shader for solid colors
      paint.shader = null;

      // Layer 2: Pointy spinning twinkles with configurable organic pulsing
      // Create varied speeds and patterns per star using config values
      final horizontalSpeed = star.pulseSpeedH; // Use pre-calculated value
      final verticalSpeed = star.pulseSpeedV; // Use pre-calculated value

      final hPhaseOffset = star.pulsePhaseH; // Use pre-calculated value
      final vPhaseOffset = star.pulsePhaseV; // Use pre-calculated value

      final hMinScale = star.pulseMinScaleH; // Use pre-calculated value
      final vMinScale = star.pulseMinScaleV; // Use pre-calculated value
      final pulseTimeH = (timeSinceCreation * horizontalSpeed + hPhaseOffset) % (2 * math.pi);
      final pulseTimeV = (timeSinceCreation * verticalSpeed + vPhaseOffset) % (2 * math.pi);

      final horizontalPulse = _createSharpPulse(pulseTimeH);
      final verticalPulse = _createSharpPulse(pulseTimeV);

      final horizontalScale = hMinScale + horizontalPulse * (1.0 - hMinScale);
      final verticalScale = vMinScale + verticalPulse * (1.0 - vMinScale);

      final cos = math.cos(rotation);
      final sin = math.sin(rotation);

      // Create pointy twinkles using config values
      final twinkleLength = star.size * StarConfig.twinkleLength;
      final twinkleOpacity = (StarConfig.twinkleOpacityMin + brightness * (StarConfig.twinkleOpacityMax - StarConfig.twinkleOpacityMin)).clamp(StarConfig.twinkleOpacityMin, StarConfig.twinkleOpacityMax);

      // Horizontal twinkle line (pointy)
      final hLength = twinkleLength * horizontalScale;
      _drawCurvedTwinkle(
        canvas,
        screenPosition,
        Offset(screenPosition.dx - hLength * cos, screenPosition.dy - hLength * sin),
        Offset(screenPosition.dx + hLength * cos, screenPosition.dy + hLength * sin),
        glowColor.withValues(alpha: twinkleOpacity),
      );

      // Vertical twinkle line (pointy)
      final vLength = twinkleLength * verticalScale;
      _drawCurvedTwinkle(
        canvas,
        screenPosition,
        Offset(screenPosition.dx - vLength * sin, screenPosition.dy + vLength * cos),
        Offset(screenPosition.dx + vLength * sin, screenPosition.dy - vLength * cos),
        glowColor.withValues(alpha: twinkleOpacity),
      );

      // Layer 3: Pure white core center - configurable size
      paint.color = Colors.white.withValues(alpha: brightness.clamp(StarConfig.coreBrightnessMin, StarConfig.coreBrightnessMax));
      canvas.drawCircle(screenPosition, star.size * StarConfig.coreSize, paint);
    }
  }

  // Creates a sharp pulse animation with pauses (0.0 to 1.0)
  double _createSharpPulse(double t) {
    final normalizedT = t % (2 * math.pi);

    // Quick pulse over first 60% of cycle, then pause
    if (normalizedT < math.pi * 1.2) {
      // Sharp rise and fall using smoothstep for rapid but smooth animation
      final progress = normalizedT / (math.pi * 1.2);
      final smoothProgress = progress * progress * (3.0 - 2.0 * progress); // Smoothstep
      return math.sin(smoothProgress * math.pi);
    } else {
      // Pause at minimum for remaining 40% of cycle
      return 0.0;
    }
  }

  // Helper method to draw curved pointed twinkles with configurable drama
  void _drawCurvedTwinkle(Canvas canvas, Offset center, Offset end1, Offset end2, Color color) {
    final path = Path();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Calculate direction and perpendicular vectors
    final direction = end2 - end1;
    final length = math.sqrt(direction.dx * direction.dx + direction.dy * direction.dy);
    final unitDirection = Offset(direction.dx / length, direction.dy / length);
    final perpendicular = Offset(-unitDirection.dy, unitDirection.dx);

    // Create configurable concave curves
    final maxWidth = StarConfig.twinkleWidth;

    // Create diamond-like concave shape with configurable drama
    path.moveTo(end1.dx, end1.dy); // Point 1

    // Configurable concave control points
    final quarterPoint1 = Offset(
      end1.dx + (center.dx - end1.dx) * 0.25,
      end1.dy + (center.dy - end1.dy) * 0.25,
    );
    final quarterPoint2 = Offset(
      center.dx + (end2.dx - center.dx) * 0.25,
      center.dy + (end2.dy - center.dy) * 0.25,
    );

    // Use configurable concave drama
    final control1 = Offset(
      quarterPoint1.dx + (center.dx - quarterPoint1.dx) * StarConfig.concaveDrama + perpendicular.dx * maxWidth,
      quarterPoint1.dy + (center.dy - quarterPoint1.dy) * StarConfig.concaveDrama + perpendicular.dy * maxWidth,
    );
    final control2 = Offset(
      quarterPoint2.dx + (center.dx - quarterPoint2.dx) * StarConfig.concaveDrama + perpendicular.dx * maxWidth,
      quarterPoint2.dy + (center.dy - quarterPoint2.dy) * StarConfig.concaveDrama + perpendicular.dy * maxWidth,
    );

    // First edge (configurable concave)
    path.quadraticBezierTo(control1.dx, control1.dy, center.dx + perpendicular.dx * maxWidth, center.dy + perpendicular.dy * maxWidth);
    path.quadraticBezierTo(control2.dx, control2.dy, end2.dx, end2.dy);

    // Second edge (configurable concave) - mirror the curve
    final control3 = Offset(
      quarterPoint2.dx + (center.dx - quarterPoint2.dx) * StarConfig.concaveDrama - perpendicular.dx * maxWidth,
      quarterPoint2.dy + (center.dy - quarterPoint2.dy) * StarConfig.concaveDrama - perpendicular.dy * maxWidth,
    );
    final control4 = Offset(
      quarterPoint1.dx + (center.dx - quarterPoint1.dx) * StarConfig.concaveDrama - perpendicular.dx * maxWidth,
      quarterPoint1.dy + (center.dy - quarterPoint1.dy) * StarConfig.concaveDrama - perpendicular.dy * maxWidth,
    );

    path.quadraticBezierTo(control3.dx, control3.dy, center.dx - perpendicular.dx * maxWidth, center.dy - perpendicular.dy * maxWidth);
    path.quadraticBezierTo(control4.dx, control4.dy, end1.dx, end1.dy);

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
// Widget for animating star birth
class AnimatedStarBirth extends StatelessWidget {
  final GratitudeStar star;
  final Animation<double> animation;
  final CameraController cameraController;
  final Size screenSize;

  const AnimatedStarBirth({
    super.key,
    required this.star,
    required this.animation,
    required this.cameraController,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: StarBirthPainter(
        star: star,
        progress: animation.value,
        cameraController: cameraController,
        screenSize: screenSize,
      ),
      size: Size.infinite,
    );
  }
}

// Painter for star birth animation
class StarBirthPainter extends CustomPainter {
  final GratitudeStar star;
  final double progress;
  final CameraController cameraController;
  final Size screenSize;

  StarBirthPainter({
    required this.star,
    required this.progress,
    required this.cameraController,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Work in world coordinates - Transform wrapper handles camera conversion
    // Start position: bottom-center in world space
    final startWorld = Offset(size.width / 2, size.height);

    // End position: star's world position in pixels
    final endWorld = Offset(star.worldX * size.width, star.worldY * size.height);

    final travelProgress = (progress / StarBirthConfig.travelPhaseEnd).clamp(0.0, 1.0);
    final currentWorld = Offset.lerp(startWorld, endWorld, travelProgress)!;

    if (progress < StarBirthConfig.travelPhaseEnd) {
      _paintTravelingStar(canvas, currentWorld);
    } else {
      final burstProgress = (progress - StarBirthConfig.travelPhaseEnd) / (1.0 - StarBirthConfig.travelPhaseEnd);
      _paintBurstEffect(canvas, endWorld, burstProgress);
    }
  }

  void _paintTravelingStar(Canvas canvas, Offset position) {
    final paint = Paint();

    // Multi-frequency organic pulsing
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final pulse1 = math.sin(time * StarBirthConfig.protostarPulseSpeed);
    final pulse2 = math.sin(time * StarBirthConfig.protostarPulseSpeed * 0.7 + 1.3);
    final pulse3 = math.sin(time * StarBirthConfig.protostarPulseSpeed * 1.3 + 2.7);
    final organicPulse = StarBirthConfig.protostarPulseMin +
        ((pulse1 + pulse2 * 0.5 + pulse3 * 0.3) / 2.8) *
            (StarBirthConfig.protostarPulseMax - StarBirthConfig.protostarPulseMin);

    // Outer glow - matches gratitude star style with irregular falloff
    final outerGlowRadius = star.size * StarBirthConfig.protostarGlowSize * organicPulse;
    final outerGradient = RadialGradient(
      colors: [
        Colors.white.withValues(alpha: StarBirthConfig.protostarOuterOpacity * organicPulse),
        Colors.white.withValues(alpha: StarBirthConfig.protostarOuterOpacity * 0.5 * organicPulse),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: [0.0, 0.6, 1.0],
    );

    paint.shader = outerGradient.createShader(
        Rect.fromCircle(center: position, radius: outerGlowRadius)
    );
    canvas.drawCircle(position, outerGlowRadius, paint);

    // Inner glow - tighter and brighter, matches gratitude star inner glow
    final innerGlowRadius = star.size * (StarBirthConfig.protostarGlowSize * 0.25) * organicPulse;
    final innerGradient = RadialGradient(
      colors: [
        Colors.white.withValues(alpha: StarBirthConfig.protostarMidOpacity * organicPulse),
        Colors.white.withValues(alpha: StarBirthConfig.protostarMidOpacity * 0.5 * organicPulse),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: [0.0, 0.5, 1.0],
    );

    paint.shader = innerGradient.createShader(
        Rect.fromCircle(center: position, radius: innerGlowRadius)
    );
    canvas.drawCircle(position, innerGlowRadius, paint);

    // Core with secondary pulse
    paint.shader = null;
    final corePulse = 0.85 + pulse2 * 0.15;
    paint.color = Colors.white.withValues(alpha: StarBirthConfig.protostarCoreOpacity * corePulse);
    canvas.drawCircle(position, star.size * StarBirthConfig.protostarCoreSize * organicPulse, paint);

    // Bright center point
    paint.color = Colors.white;
    canvas.drawCircle(position, star.size * StarBirthConfig.protostarPointSize, paint);
  }

  void _paintBurstEffect(Canvas canvas, Offset position, double burstProgress) {
    final paint = Paint();

    // Ease out the burst expansion
    final easedProgress = 1.0 - math.pow(1.0 - burstProgress, 3.0);

    // Expanding burst wave
    final burstRadius = star.size * StarBirthConfig.burstRadiusMultiplier * easedProgress;
    final burstOpacity = (1.0 - easedProgress) * StarBirthConfig.burstOpacity;

// Multiple expanding rings with soft, fuzzy edges
    for (int ring = 0; ring < StarBirthConfig.burstRingCount; ring++) {
      final ringDelay = ring * StarBirthConfig.burstRingDelay;
      final ringProgress = (easedProgress - ringDelay).clamp(0.0, 1.0);
      final ringRadius = burstRadius * ringProgress;

      final ringGradient = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: burstOpacity * (1.0 - ringProgress) * 0.6),
          Colors.white.withValues(alpha: burstOpacity * (1.0 - ringProgress) * 0.3),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: [0.0, 0.5, 1.0],
      );

      paint.shader = ringGradient.createShader(
          Rect.fromCircle(center: position, radius: ringRadius)
      );

      // Add fuzzy blur to match gratitude stars
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, star.size * 0.8);

      canvas.drawCircle(position, ringRadius, paint);
    }

// Clear mask filter for subsequent drawing
    paint.maskFilter = null;

    // Twinkle rays shooting outward (only in first half of burst)
    if (burstProgress < 0.5) {
      paint.shader = null;
      final rayProgress = burstProgress / 0.5;
      final rayLength = star.size * StarBirthConfig.burstTwinkleLength * rayProgress;
      final rayOpacity = StarBirthConfig.burstTwinkleOpacity * (1.0 - rayProgress);

      for (int i = 0; i < StarBirthConfig.burstTwinkleCount; i++) {
        final angle = (i / StarBirthConfig.burstTwinkleCount) * 2 * math.pi;
        final endPoint = Offset(
          position.dx + math.cos(angle) * rayLength,
          position.dy + math.sin(angle) * rayLength,
        );

        // Draw ray as gradient line
        final rayGradient = LinearGradient(
          begin: Alignment.center,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withValues(alpha: rayOpacity),
            Colors.white.withValues(alpha: 0.0),
          ],
        );

        paint.shader = rayGradient.createShader(
            Rect.fromPoints(position, endPoint)
        );
        paint.strokeWidth = StarBirthConfig.burstTwinkleWidth;
        paint.strokeCap = StrokeCap.round;
        canvas.drawLine(position, endPoint, paint);
      }
    }

// Flash of light at burst center with soft edges
    paint.shader = null;
    paint.style = PaintingStyle.fill;
    paint.maskFilter = MaskFilter.blur(BlurStyle.normal, star.size * 1.2);
    final flashOpacity = (1.0 - burstProgress) * 0.9;
    paint.color = Colors.white.withValues(alpha: flashOpacity);
    canvas.drawCircle(position, star.size * StarBirthConfig.burstFlashSize * (1.0 - easedProgress), paint);

// Clear mask filter
    paint.maskFilter = null;

    // Transition to colored star
    if (burstProgress > StarBirthConfig.colorTransitionStart) {
      final colorProgress = (burstProgress - StarBirthConfig.colorTransitionStart) /
          (1.0 - StarBirthConfig.colorTransitionStart);
      final starColor = StarColors.getColor(star.colorPresetIndex);

      // Colored glow emerging
      final coloredGlowRadius = star.size * StarBirthConfig.coloredGlowSize;
      final coloredGradient = RadialGradient(
        colors: [
          Color.lerp(Colors.white, starColor, colorProgress)!.withValues(alpha: 0.4 * colorProgress),
          Color.lerp(Colors.white, starColor, colorProgress)!.withValues(alpha: 0.2 * colorProgress),
          Colors.transparent,
        ],
        stops: [0.0, 0.6, 1.0],
      );

      paint.shader = coloredGradient.createShader(
          Rect.fromCircle(center: position, radius: coloredGlowRadius)
      );
      canvas.drawCircle(position, coloredGlowRadius, paint);

      // Core appearing
      paint.shader = null;
      paint.color = Color.lerp(Colors.white, starColor, colorProgress)!.withValues(alpha: 0.8 * colorProgress);
      canvas.drawCircle(position, star.size * StarBirthConfig.coloredCoreSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}