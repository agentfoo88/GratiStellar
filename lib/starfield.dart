import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:math' show Random, pi, sin, cos;
import 'background.dart';

// Simple noise implementation to replace FastNoise
class SimpleNoise {
  double noise2D(double x, double y) {
    int xi = x.floor();
    int yi = y.floor();
    double xf = x - xi;
    double yf = y - yi;

    double a = _hash(xi, yi);
    double b = _hash(xi + 1, yi);
    double c = _hash(xi, yi + 1);
    double d = _hash(xi + 1, yi + 1);

    double i1 = _lerp(a, b, xf);
    double i2 = _lerp(c, d, xf);

    return _lerp(i1, i2, yf);
  }

  double _hash(int x, int y) {
    int h = x * 374761393 + y * 668265263;
    h = (h ^ (h >> 13)) * 1274126177;
    return ((h ^ (h >> 16)) & 0x7fffffff) / 2147483647.0;
  }

  double _lerp(double a, double b, double t) {
    return a + t * (b - a);
  }
}

// Configuration for Van Gogh background stars
class VanGoghConfig {
  // Star Generation
  static const int starCount = 12000;
  static const double parallaxFactor = 0.1;

  // Density-based generation (instead of fixed count)
  static const double starDensity = 0.00025;  // 12x less dense than background
  static const bool useDensityBasedCount = true;  // Toggle for density vs fixed count

  // Clustering - spiral galaxy pattern
  static const double clusterRadius = 0.4;
  static const int spiralArms = 3;
  static const double spiralTightness = 0.6;
  static const double spiralRandomness = 0.15;

  // Twinkling (adapted from gratitude stars but subtler)
  static const double pulseSpeedMin = 0.8;
  static const double pulseSpeedMax = 1.2;
  static const double pulseAxisVariation = 0.6;
  static const double twinkleOpacityMin = 0.05;
  static const double twinkleOpacityMax = 0.15;
  static const double twinkleFrequency = 0.3; // 30% of stars twinkle

  // Star appearance
  static const double starSizeMin = 0.8;
  static const double starSizeMax = 2.2;
  static const double brightnessMultiplier = 0.8;
}

// Individual Van Gogh background star
class VanGoghStar {
  final double worldX;
  final double worldY;
  final double size;
  final Color stellarColor;
  final double brightness;
  final DateTime createdAt;
  final double pulsePhase;
  final double spiralOffset;
  final bool shouldTwinkle;
  final double pulseSpeed;

  VanGoghStar({
    required this.worldX,
    required this.worldY,
    required this.size,
    required this.stellarColor,
    required this.brightness,
    required this.createdAt,
    required this.pulsePhase,
    required this.spiralOffset,
    required this.shouldTwinkle,
    required this.pulseSpeed,
  });
}

// Service to generate Van Gogh background stars using stellar colors
class VanGoghStarService {
  static List<VanGoghStar> generateVanGoghStars(Size screenSize) {
    // Get realistic stellar colors and properties from background service
    final backgroundStars = BackgroundService.generateStaticStars();
    final vanGoghStars = <VanGoghStar>[];
    final random = Random(42); // Consistent seed

    // Create clustered spiral galaxy pattern
    final centerX = 0.5;
    final centerY = 0.5;

    // Calculate star count based on screen size
    final calculatedStarCount = VanGoghConfig.useDensityBasedCount
        ? (screenSize.width * screenSize.height * VanGoghConfig.starDensity).round()
        : VanGoghConfig.starCount;
    final actualStarCount = math.min(calculatedStarCount, backgroundStars.length);

    for (int i = 0; i < actualStarCount; i++) {
      final backgroundStar = backgroundStars[i];

      // Generate spiral galaxy positioning
      final armIndex = i % VanGoghConfig.spiralArms;
      final armAngle = (armIndex / VanGoghConfig.spiralArms) * 2 * pi;

      // Distance from center with some randomness
      final normalizedDistance = (i / actualStarCount).clamp(0.0, 1.0);
      final baseRadius = normalizedDistance * VanGoghConfig.clusterRadius;
      final radiusVariation = (random.nextDouble() - 0.5) * VanGoghConfig.spiralRandomness;
      final radius = (baseRadius + radiusVariation).clamp(0.0, VanGoghConfig.clusterRadius);

      // Spiral arm angle with tightness
      final spiralAngle = armAngle + (normalizedDistance * VanGoghConfig.spiralTightness * 2 * pi);
      final angleVariation = (random.nextDouble() - 0.5) * VanGoghConfig.spiralRandomness;
      final finalAngle = spiralAngle + angleVariation;

      // Convert to world coordinates
      final worldX = (centerX + cos(finalAngle) * radius).clamp(0.05, 0.95);
      final worldY = (centerY + sin(finalAngle) * radius).clamp(0.05, 0.95);

      // Create realistic stellar color from background star
      final stellarColor = Colors.white.withValues(alpha: backgroundStar.brightness * VanGoghConfig.brightnessMultiplier);

      // Size variation
      final size = VanGoghConfig.starSizeMin +
          random.nextDouble() * (VanGoghConfig.starSizeMax - VanGoghConfig.starSizeMin);

      // Twinkling properties
      final shouldTwinkle = random.nextDouble() < VanGoghConfig.twinkleFrequency;
      final pulseSpeed = VanGoghConfig.pulseSpeedMin +
          random.nextDouble() * (VanGoghConfig.pulseSpeedMax - VanGoghConfig.pulseSpeedMin);

      vanGoghStars.add(VanGoghStar(
        worldX: worldX,
        worldY: worldY,
        size: size,
        stellarColor: stellarColor,
        brightness: backgroundStar.brightness * VanGoghConfig.brightnessMultiplier,
        createdAt: DateTime.now(),
        pulsePhase: random.nextDouble() * 2 * pi,
        spiralOffset: random.nextDouble() * 2 * pi,
        shouldTwinkle: shouldTwinkle,
        pulseSpeed: pulseSpeed,
      ));
    }

    return vanGoghStars;
  }
}

class StarfieldWidget extends StatefulWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final double intensity;
  final bool useVanGoghMode;

  const StarfieldWidget({
    super.key,
    this.primaryColor = const Color(0xFF4A90E2),
    this.secondaryColor = const Color(0xFFE94B3C),
    this.backgroundColor = const Color(0xFF0A0B1E),
    this.intensity = 0.7,
    this.useVanGoghMode = false,
  });

  @override
  State<StarfieldWidget> createState() => _StarfieldWidgetState();
}

class _StarfieldWidgetState extends State<StarfieldWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(minutes: 5),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            widget.backgroundColor.withValues(alpha: 0.8),
            widget.backgroundColor,
            Colors.black,
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _rotationAnimation,
          _pulseAnimation,
          _shimmerAnimation,
        ]),
        builder: (context, child) {
          return CustomPaint(
            painter: widget.useVanGoghMode
                ? VanGoghBackgroundPainter(
              primaryColor: widget.primaryColor,
              secondaryColor: widget.secondaryColor,
              animationValue: _shimmerAnimation.value,
              intensity: widget.intensity,
            )
                : null,
            foregroundPainter: StarfieldPainter(
              primaryColor: widget.primaryColor,
              secondaryColor: widget.secondaryColor,
              rotationValue: _rotationAnimation.value,
              pulseValue: _pulseAnimation.value,
              shimmerValue: _shimmerAnimation.value,
              intensity: widget.intensity,
              useVanGoghMode: widget.useVanGoghMode,
            ),
            child: Container(),
          );
        },
      ),
    );
  }
}

class VanGoghBackgroundPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final double animationValue;
  final double intensity;
  final SimpleNoise noise = SimpleNoise();

  VanGoghBackgroundPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.animationValue,
    required this.intensity,
  });

  void _paintOrganicNebulae(Canvas canvas, Size size) {
    final paint = Paint()
      ..blendMode = BlendMode.screen
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    for (int i = 0; i < 8; i++) {
      final center = Offset(
        size.width * (0.2 + 0.6 * (i / 8)),
        size.height * (0.3 + 0.4 * sin(i + animationValue * 2)),
      );

      final noiseValue = noise.noise2D(
        center.dx * 0.005 + animationValue,
        center.dy * 0.005,
      );

      final radius = 80 + 40 * noiseValue * intensity;
      final opacity = 0.1 + 0.15 * intensity * (0.5 + 0.5 * sin(animationValue * 3 + i));

      paint.shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: opacity),
          secondaryColor.withValues(alpha: opacity * 0.7),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintOrganicNebulae(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class StarfieldPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final double rotationValue;
  final double pulseValue;
  final double shimmerValue;
  final double intensity;
  final bool useVanGoghMode;
  final Random random = Random(42);
  final SimpleNoise noise = SimpleNoise();

  StarfieldPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.rotationValue,
    required this.pulseValue,
    required this.shimmerValue,
    required this.intensity,
    required this.useVanGoghMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (useVanGoghMode) {
      _paintVanGoghStarfield(canvas, size);
    } else {
      _paintClassicStarfield(canvas, size);
    }
  }

  void _paintClassicStarfield(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Background stars
    _drawBackgroundStars(canvas, size, 400);

    // Midground stars with shimmer
    _drawMidgroundStars(canvas, size, 150);

    // Foreground constellation
    _drawForegroundConstellation(canvas, size, center);

    // Central radiant star
    _drawCentralStar(canvas, size, center);
  }

  void _paintVanGoghStarfield(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Van Gogh style swirling background
    _drawSwirlingBackground(canvas, size);

    // Impressionistic star clusters
    _drawImpressionisticStars(canvas, size, 200);

    // Brushstroke-style constellation
    _drawBrushstrokeConstellation(canvas, size, center);

    // Van Gogh central star with radiating energy
    _drawVanGoghCentralStar(canvas, size, center);
  }

  void _drawBackgroundStars(Canvas canvas, Size size, int count) {
    final paint = Paint()
      ..color = primaryColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 0.5 + random.nextDouble() * 1.5;

      final twinkle = sin(shimmerValue * 6 + i * 0.1) * 0.3 + 0.7;
      paint.color = primaryColor.withValues(alpha: 0.4 * twinkle * intensity);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  void _drawMidgroundStars(Canvas canvas, Size size, int count) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    for (int i = 0; i < count; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 1 + random.nextDouble() * 2;

      final pulse = sin(shimmerValue * 4 + i * 0.2) * 0.5 + 0.5;
      final color = Color.lerp(primaryColor, secondaryColor, pulse)!;
      paint.color = color.withValues(alpha: 0.8 * intensity);

      canvas.drawCircle(Offset(x, y), radius * pulseValue, paint);

      // Add sparkle effect
      if (random.nextDouble() < 0.3) {
        _drawSparkle(canvas, Offset(x, y), radius * 2, color);
      }
    }
  }

  void _drawForegroundConstellation(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..color = primaryColor.withValues(alpha: 0.9)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);

    // Create constellation pattern
    final points = <Offset>[];
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4) + rotationValue * 0.5;
      final distance = 80 + 40 * sin(shimmerValue * 2 + i);
      final point = Offset(
        center.dx + cos(angle) * distance,
        center.dy + sin(angle) * distance,
      );
      points.add(point);

      // Draw constellation stars
      final starPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.95 * intensity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(point, 2 * pulseValue, starPaint);
    }

    // Connect constellation points
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        path.moveTo(points[i].dx, points[i].dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    path.close();

    paint.color = primaryColor.withValues(alpha: 0.3 * intensity);
    canvas.drawPath(path, paint);
  }

  void _drawCentralStar(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Multi-layered central star
    final layers = [
      {'radius': 25.0, 'opacity': 0.3, 'color': secondaryColor},
      {'radius': 15.0, 'opacity': 0.6, 'color': primaryColor},
      {'radius': 8.0, 'opacity': 0.9, 'color': Colors.white},
    ];

    for (final layer in layers) {
      paint.shader = RadialGradient(
        colors: [
          (layer['color'] as Color).withValues(alpha: (layer['opacity'] as double) * intensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: center,
        radius: (layer['radius'] as double) * pulseValue,
      ));

      canvas.drawCircle(center, (layer['radius'] as double) * pulseValue, paint);
    }

    // Central bright core
    paint.shader = null;
    paint.color = Colors.white.withValues(alpha: 0.95 * intensity);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    canvas.drawCircle(center, 3 * pulseValue, paint);
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sparkleSize = size * pulseValue;

    // Draw cross sparkle
    canvas.drawLine(
      Offset(center.dx - sparkleSize, center.dy),
      Offset(center.dx + sparkleSize, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - sparkleSize),
      Offset(center.dx, center.dy + sparkleSize),
      paint,
    );
  }

  void _drawSwirlingBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (int i = 0; i < 20; i++) {
      final path = Path();
      final startX = size.width * (i / 20);
      final startY = size.height * 0.5;

      path.moveTo(startX, startY);

      for (double t = 0; t <= 1; t += 0.1) {
        final x = startX + t * size.width * 0.1;
        final y = startY + 50 * sin(t * pi * 4 + rotationValue * 2 + i * 0.5) *
            noise.noise2D(x * 0.01, t + shimmerValue);
        path.lineTo(x, y);
      }

      final opacity = 0.1 + 0.1 * sin(shimmerValue * 2 + i * 0.3);
      paint.color = Color.lerp(primaryColor, secondaryColor, i / 20)!
          .withValues(alpha: opacity);

      canvas.drawPath(path, paint);
    }
  }

  void _drawImpressionisticStars(Canvas canvas, Size size, int count) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (int i = 0; i < count; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      final noiseValue = noise.noise2D(x * 0.01 + shimmerValue, y * 0.01);
      final radius = 2 + 3 * noiseValue * intensity;

      final hue = (i * 137.5) % 360; // Golden angle for natural distribution
      final color = HSVColor.fromAHSV(
        0.7 * intensity,
        hue,
        0.6 + 0.4 * noiseValue,
        0.8 + 0.2 * sin(shimmerValue * 3 + i * 0.1),
      ).toColor();

      paint.color = color;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  void _drawBrushstrokeConstellation(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    for (int i = 0; i < 6; i++) {
      final angle = (i * pi / 3) + rotationValue * 0.3;
      final distance = 60 + 30 * sin(shimmerValue * 1.5 + i);

      final start = center;
      final end = Offset(
        center.dx + cos(angle) * distance,
        center.dy + sin(angle) * distance,
      );

      paint.shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          primaryColor.withValues(alpha: 0.8 * intensity),
          secondaryColor.withValues(alpha: 0.6 * intensity),
        ],
      ).createShader(Rect.fromPoints(start, end));

      canvas.drawLine(start, end, paint);

      // Draw brushstroke star at end
      paint.shader = null;
      paint.style = PaintingStyle.fill;
      paint.color = Colors.white.withValues(alpha: 0.9 * intensity);
      canvas.drawCircle(end, 4 * pulseValue, paint);
      paint.style = PaintingStyle.stroke;
    }
  }

  void _drawVanGoghCentralStar(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // Radiating energy lines
    for (int i = 0; i < 24; i++) {
      final angle = (i * pi / 12) + rotationValue;
      final length = 40 + 20 * sin(shimmerValue * 4 + i * 0.2);

      final start = Offset(
        center.dx + cos(angle) * 10,
        center.dy + sin(angle) * 10,
      );
      final end = Offset(
        center.dx + cos(angle) * length,
        center.dy + sin(angle) * length,
      );

      paint.strokeWidth = 2.0 + sin(shimmerValue * 6 + i * 0.3);
      paint.color = Color.lerp(
        primaryColor,
        secondaryColor,
        (sin(shimmerValue * 2 + i * 0.5) + 1) / 2,
      )!.withValues(alpha: 0.7);

      canvas.drawLine(start, end, paint);
    }

    // Central core with Van Gogh swirl
    final corePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.9),
          secondaryColor.withValues(alpha: 0.7),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 15));

    canvas.drawCircle(center, 12 * pulseValue, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// New Van Gogh Midground Painter using realistic stellar colors and twinkling
class VanGoghMidgroundPainter extends CustomPainter {
  final List<VanGoghStar> stars;
  final double cameraOffsetX;
  final double cameraOffsetY;
  final double cameraScale;

  VanGoghMidgroundPainter(
      this.stars, {
        this.cameraOffsetX = 0.0,
        this.cameraOffsetY = 0.0,
        this.cameraScale = 1.0,
      });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final now = DateTime.now();

    for (final star in stars) {
      // Convert world coordinates to screen coordinates
      final screenX = star.worldX * size.width;
      final screenY = star.worldY * size.height;
      final position = Offset(screenX, screenY);

      // Independent timing for each star
      final timeSinceCreation = now.difference(star.createdAt).inMilliseconds / 1000.0;

      // Base star rendering using realistic stellar color
      paint.color = star.stellarColor;
      canvas.drawCircle(position, star.size, paint);

      // Add subtle twinkling for selected stars
      if (star.shouldTwinkle) {
        final pulseTime = (timeSinceCreation * star.pulseSpeed + star.pulsePhase) % (2 * pi);
        final twinkleBrightness = _createSharpPulse(pulseTime);

        final twinkleOpacity = VanGoghConfig.twinkleOpacityMin +
            twinkleBrightness * (VanGoghConfig.twinkleOpacityMax - VanGoghConfig.twinkleOpacityMin);

        paint.color = star.stellarColor.withValues(alpha: twinkleOpacity);
        canvas.drawCircle(position, star.size * 1.2, paint);
      }
    }
  }

  // Copied from gratitude stars but adapted for background subtlety
  double _createSharpPulse(double t) {
    final normalizedT = t % (2 * pi);

    // Quick pulse over first 60% of cycle, then pause
    if (normalizedT < pi * 1.2) {
      // Sharp rise and fall using smoothstep for rapid but smooth animation
      final progress = normalizedT / (pi * 1.2);
      final smoothProgress = progress * progress * (3.0 - 2.0 * progress); // Smoothstep
      return sin(smoothProgress * pi);
    } else {
      // Pause at minimum for remaining 40% of cycle
      return 0.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}