import 'package:flutter/material.dart';
import 'dart:math' as math;

// Enhanced configuration for organic nebula shapes
class OrganicNebulaConfig {
  // Reference configuration
  static const Size referenceScreenSize = Size(1920, 1080);
  static const int referenceNebulaCount = 6;

  // Scale nebula count by screen area
  static const bool useScaledCount = true;

  // Nebula size as percentage of screen (instead of fixed pixels)
  static const double baseSizePercent = 0.13;  // 13% of screen width
  static const double sizeVariationPercent = 0.16;  // +/- 16% variation
  static const double nebulaOpacity = 0.05;

  // Organic shape parameters
  static const int shapeNodes = 12; // Points defining irregular boundary
  static const double shapeIrregularity = 3.0; // How irregular the shape is
  static const double edgeSoftness = 0.3; // How soft the edges are

  // Internal structure
  static const int internalClouds = 8; // Sub-clouds within each nebula
  static const double internalVariation = 0.6; // Color/brightness variation
  static const double tendrilLength = 0.7; // Length of wispy tendrils

  // Animation
  static const double driftSpeed = 0.01;
  static const double morphSpeed = 0.005; // Speed of shape morphing
  static const double internalMotion = 0.002; // Internal cloud movement

  // Enhanced color palettes with more variation
  static const List<List<Color>> nebulaPalettes = [
    // Blue-red nebula (like your image)
    [Color(0xFF1E3A8A), Color(0xFF3730A3), Color(0xFFDC2626), Color(0xFFEF4444), Colors.transparent],
    // Purple-pink nebula
    [Color(0xFF581C87), Color(0xFF7C3AED), Color(0xFFEC4899), Color(0xFFF472B6), Colors.transparent],
    // Orange-blue nebula
    [Color(0xFFEA580C), Color(0xFFFB923C), Color(0xFF1E40AF), Color(0xFF3B82F6), Colors.transparent],
    // Green-gold nebula
    [Color(0xFF166534), Color(0xFF22C55E), Color(0xFFEAB308), Color(0xFFFDE047), Colors.transparent],
  ];
}

// Complex nebula region with multiple internal structures
class OrganicNebulaRegion {
  final Offset basePosition;
  final double baseSize;
  final List<Color> colorPalette;
  final List<NebulaCloudlet> cloudlets; // Sub-structures
  final List<Offset> shapeNodes; // Irregular boundary points
  final double rotationOffset;
  final double morphOffset;

  OrganicNebulaRegion({
    required this.basePosition,
    required this.baseSize,
    required this.colorPalette,
    required this.cloudlets,
    required this.shapeNodes,
    required this.rotationOffset,
    required this.morphOffset,
  });
}

// Individual cloud structures within nebulae
class NebulaCloudlet {
  final Offset relativePosition;
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final double density; // Brightness/opacity multiplier
  final double driftPhase;

  NebulaCloudlet({
    required this.relativePosition,
    required this.size,
    required this.primaryColor,
    required this.secondaryColor,
    required this.density,
    required this.driftPhase,
  });
}

// Service to generate organic nebula structures
class OrganicNebulaService {
  static List<OrganicNebulaRegion> generateOrganicNebulae(Size screenSize) {
    final regions = <OrganicNebulaRegion>[];
    final random = math.Random(42);

    // Calculate nebula count based on screen size
    final screenArea = screenSize.width * screenSize.height;
    final referenceArea = OrganicNebulaConfig.referenceScreenSize.width *
        OrganicNebulaConfig.referenceScreenSize.height;
    final areaRatio = screenArea / referenceArea;

    final nebulaCount = OrganicNebulaConfig.useScaledCount
        ? (OrganicNebulaConfig.referenceNebulaCount * areaRatio).round().clamp(3, 6)
        : OrganicNebulaConfig.referenceNebulaCount;

    for (int i = 0; i < nebulaCount; i++) {
      final centerX = 0.5;  // Normalized center
      final centerY = 0.5;
      final maxRadius = 0.3;  // 30% of screen in normalized space

      // Use polar coordinates for better center clustering
      final angle = (i / nebulaCount) * 2 * math.pi + random.nextDouble() * 0.5;
      final distance = random.nextDouble() * maxRadius;

      final x = centerX + math.cos(angle) * distance;
      final y = centerY + math.sin(angle) * distance;

      // Variable size based on screen dimensions
      final baseSize = screenSize.width * OrganicNebulaConfig.baseSizePercent;
      final sizeVariation = screenSize.width * OrganicNebulaConfig.sizeVariationPercent;
      final size = baseSize + (random.nextDouble() - 0.5) * sizeVariation;

      // Random palette
      final paletteIndex = i % OrganicNebulaConfig.nebulaPalettes.length;
      final palette = OrganicNebulaConfig.nebulaPalettes[paletteIndex];

      // Generate irregular shape boundary
      final shapeNodes = _generateIrregularBoundary(random, size);

      // Generate internal cloud structures
      final cloudlets = _generateInternalCloudlets(random, palette, size, i);

      regions.add(OrganicNebulaRegion(
        basePosition: Offset(x, y),
        baseSize: size,
        colorPalette: palette,
        cloudlets: cloudlets,
        shapeNodes: shapeNodes,
        rotationOffset: random.nextDouble() * math.pi * 2,
        morphOffset: random.nextDouble() * math.pi * 2,
      ));
    }

    return regions;
  }

  static List<Offset> _generateIrregularBoundary(math.Random random, double size) {
    final nodes = <Offset>[];

    for (int i = 0; i < OrganicNebulaConfig.shapeNodes; i++) {
      final angle = (i / OrganicNebulaConfig.shapeNodes) * 2 * math.pi;

      // Base radius with irregular variation
      final baseRadius = size * 0.5;
      final irregularity = (random.nextDouble() - 0.5) * OrganicNebulaConfig.shapeIrregularity;
      final radius = baseRadius * (1.0 + irregularity);

      nodes.add(Offset(
        math.cos(angle) * radius,
        math.sin(angle) * radius,
      ));
    }

    return nodes;
  }

  static List<NebulaCloudlet> _generateInternalCloudlets(
      math.Random random, List<Color> palette, double nebulaSize, int nebulaIndex) {
    final cloudlets = <NebulaCloudlet>[];
    final cloudletRandom = math.Random(nebulaIndex * 54321);

    for (int j = 0; j < OrganicNebulaConfig.internalClouds; j++) {
      // Position within nebula bounds
      final angle = cloudletRandom.nextDouble() * 2 * math.pi;
      final distance = _gaussianRandom(cloudletRandom) * nebulaSize * 0.3;

      final position = Offset(
        math.cos(angle) * distance,
        math.sin(angle) * distance,
      );

      // Variable size based on distance from center
      final distanceFactor = distance / (nebulaSize * 0.3);
      final size = nebulaSize * (0.3 - distanceFactor * 0.2) * (0.8 + cloudletRandom.nextDouble() * 0.4);

      // Color variation within palette
      final primaryIndex = cloudletRandom.nextInt(palette.length - 1);
      final secondaryIndex = (primaryIndex + 1 + cloudletRandom.nextInt(2)) % (palette.length - 1);

      cloudlets.add(NebulaCloudlet(
        relativePosition: position,
        size: math.max(50.0, math.min(size, nebulaSize * 0.4)),
        primaryColor: palette[primaryIndex],
        secondaryColor: palette[secondaryIndex],
        density: 0.6 + cloudletRandom.nextDouble() * 0.4,
        driftPhase: cloudletRandom.nextDouble() * math.pi * 2,
      ));
    }

    return cloudlets;
  }

  static double _gaussianRandom(math.Random random) {
    final u1 = random.nextDouble();
    final u2 = random.nextDouble();
    return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2) * 0.4;
  }
}

// Widget that renders organic nebulae using custom painting
class OrganicNebulaWidget extends StatelessWidget {
  final List<OrganicNebulaRegion> regions;
  final double animationValue;
  final double? cameraOffsetX;
  final double? cameraOffsetY;

  const OrganicNebulaWidget({
    super.key,
    required this.regions,
    required this.animationValue,
    this.cameraOffsetX,
    this.cameraOffsetY,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: OrganicNebulaPainter(
        regions: regions,
        animationValue: animationValue,
        cameraOffsetX: cameraOffsetX ?? 0.0,
        cameraOffsetY: cameraOffsetY ?? 0.0,
      ),
      size: Size.infinite,
    );
  }
}

// Custom painter for organic nebula shapes
class OrganicNebulaPainter extends CustomPainter {
  final List<OrganicNebulaRegion> regions;
  final double animationValue;
  final double cameraOffsetX;
  final double cameraOffsetY;

  OrganicNebulaPainter({
    required this.regions,
    required this.animationValue,
    required this.cameraOffsetX,
    required this.cameraOffsetY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final continuousTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    for (final region in regions) {
      _paintOrganicNebula(canvas, region, continuousTime, size);
    }
  }

  void _paintOrganicNebula(Canvas canvas, OrganicNebulaRegion region, double time, Size screenSize) {
    // Calculate position and gentle drift
    final driftPhase = time * OrganicNebulaConfig.driftSpeed + region.rotationOffset;
    final drift = Offset(
      math.cos(driftPhase) * 20.0,
      math.sin(driftPhase * 0.8) * 15.0,
    );

    // Convert normalized position to screen pixels
    final pixelPosition = Offset(
      region.basePosition.dx * screenSize.width,
      region.basePosition.dy * screenSize.height,
    );
    final position = pixelPosition + drift;

    // Calculate rotation
    final rotation = time * OrganicNebulaConfig.driftSpeed * 0.5 + region.rotationOffset;

    // Paint internal cloudlets with layered complexity
    for (final cloudlet in region.cloudlets) {
      _paintCloudlet(canvas, cloudlet, time, region.baseSize, position, rotation);
    }

    // Paint soft irregular boundary
    _paintIrregularBoundary(canvas, region, time, position, rotation);
  }

  void _paintCloudlet(Canvas canvas, NebulaCloudlet cloudlet, double time, double nebulaSize, Offset nebulaPosition, double nebulaRotation) {
    // Animate internal movement
    final motionPhase = time * OrganicNebulaConfig.internalMotion + cloudlet.driftPhase;
    final motion = Offset(
      math.cos(motionPhase) * 5.0,
      math.sin(motionPhase * 1.3) * 3.0,
    );

    // Apply nebula rotation to cloudlet position
    final rotatedCloudletPos = _rotatePoint(cloudlet.relativePosition, nebulaRotation);
    final position = nebulaPosition + rotatedCloudletPos + motion;

    // Multiple overlapping gradients for complexity
    _paintMultiLayerGradient(canvas, position, cloudlet);
  }

  void _paintMultiLayerGradient(Canvas canvas, Offset position, NebulaCloudlet cloudlet) {
    final paint = Paint()..blendMode = BlendMode.screen;

    // Layer 1: Outer diffuse glow
    final outerGradient = RadialGradient(
      colors: [
        cloudlet.secondaryColor.withValues(alpha: 0.05 * cloudlet.density),
        cloudlet.secondaryColor.withValues(alpha: 0.02 * cloudlet.density),
        Colors.transparent,
      ],
      stops: [0.0, 0.6, 1.0],
    );

    paint.shader = outerGradient.createShader(
        Rect.fromCircle(center: position, radius: cloudlet.size * 1.2)
    );
    canvas.drawCircle(position, cloudlet.size * 1.2, paint);

    // Layer 2: Mid-range color mixing
    final midGradient = RadialGradient(
      colors: [
        Color.lerp(cloudlet.primaryColor, cloudlet.secondaryColor, 0.3)!.withValues(alpha: 0.15 * cloudlet.density),
        cloudlet.primaryColor.withValues(alpha: 0.08 * cloudlet.density),
        Colors.transparent,
      ],
      stops: [0.0, 0.5, 1.0],
    );

    paint.shader = midGradient.createShader(
        Rect.fromCircle(center: position, radius: cloudlet.size * 0.8)
    );
    canvas.drawCircle(position, cloudlet.size * 0.8, paint);

    // Layer 3: Bright inner core
    final innerGradient = RadialGradient(
      colors: [
        cloudlet.primaryColor.withValues(alpha: 0.25 * cloudlet.density),
        cloudlet.primaryColor.withValues(alpha: 0.1 * cloudlet.density),
        Colors.transparent,
      ],
      stops: [0.0, 0.3, 1.0],
    );

    paint.shader = innerGradient.createShader(
        Rect.fromCircle(center: position, radius: cloudlet.size * 0.4)
    );
    canvas.drawCircle(position, cloudlet.size * 0.4, paint);
  }

  void _paintIrregularBoundary(Canvas canvas, OrganicNebulaRegion region, double time, Offset nebulaPosition, double nebulaRotation) {
    // Create soft boundary effect with morphing shape
    final morphPhase = time * OrganicNebulaConfig.morphSpeed + region.morphOffset;

    // Paint soft edge gradients at boundary points
    for (int i = 0; i < region.shapeNodes.length; i++) {
      final node = region.shapeNodes[i];

      // Slight morphing animation
      final morphOffset = Offset(
        math.cos(morphPhase + i * 0.5) * 10.0,
        math.sin(morphPhase + i * 0.7) * 8.0,
      );

      // Apply nebula rotation and position to boundary nodes
      final rotatedNode = _rotatePoint(node + morphOffset, nebulaRotation);
      final animatedNode = nebulaPosition + rotatedNode;

      // Soft edge gradient
      final edgeGradient = RadialGradient(
        colors: [
          region.colorPalette[0].withValues(alpha: 0.1),
          region.colorPalette[1].withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: [0.0, 0.4, 1.0],
      );

      final paint = Paint()
        ..shader = edgeGradient.createShader(
            Rect.fromCircle(center: animatedNode, radius: 60.0)
        )
        ..blendMode = BlendMode.screen;

      canvas.drawCircle(animatedNode, 60.0, paint);
    }
  }

  // Helper method to rotate a point around the origin
  Offset _rotatePoint(Offset point, double rotation) {
    final cos = math.cos(rotation);
    final sin = math.sin(rotation);
    return Offset(
      point.dx * cos - point.dy * sin,
      point.dx * sin + point.dy * cos,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}