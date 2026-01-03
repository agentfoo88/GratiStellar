import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/accessibility/semantic_helper.dart';
import '../../core/config/app_colors.dart';
import '../../font_scaling.dart';
import '../../l10n/app_localizations.dart';

/// Display mode for the enhanced splash screen
enum SplashDisplayMode {
  /// Onboarding mode: auto-advance after 5 seconds
  onboarding,

  /// About mode: manual dismiss only
  about,
}

/// Enhanced splash screen with animations and dual-mode behavior
///
/// This screen serves two purposes:
/// 1. Initial onboarding splash - shows on first launch, auto-advances
/// 2. About screen - accessible from drawer, requires manual dismiss
///
/// Features rich animations including pulsing logo, floating particles,
/// and text shimmer effects.
class EnhancedSplashScreen extends StatefulWidget {
  final SplashDisplayMode displayMode;

  /// Callback called when splash completes (timer expires or tap)
  /// Required for onboarding mode; optional for about mode (which just pops)
  final VoidCallback? onComplete;

  const EnhancedSplashScreen({
    super.key,
    this.displayMode = SplashDisplayMode.onboarding,
    this.onComplete,
  });

  @override
  State<EnhancedSplashScreen> createState() => _EnhancedSplashScreenState();
}

class _EnhancedSplashScreenState extends State<EnhancedSplashScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _shimmerController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  // Particle positions (generated in initState)
  List<ParticleData> _particles = [];

  // Background stars (static, generated in initState)
  late final List<BackgroundStar> _backgroundStars;

  // Auto-advance timer (onboarding mode only)
  Timer? _autoAdvanceTimer;

  // Navigation flag to prevent double-navigation
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _backgroundStars = _generateBackgroundStars();
    _generateParticles();

    if (widget.displayMode == SplashDisplayMode.onboarding) {
      _startAutoAdvanceTimer();
    }
  }

  /// Set up all animation controllers and animations
  void _setupAnimations() {
    // Main fade-in (1 second, once)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Logo pulse (2 seconds, repeat)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Particle drift (30 seconds, repeat seamlessly)
    _particleController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    // Shimmer effect (3 seconds, repeat)
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    // Start fade-in
    _fadeController.forward();
  }

  /// Generate random particle positions and properties
  /// Generate background stars with deterministic seed for consistency
  List<BackgroundStar> _generateBackgroundStars() {
    final random = Random(42); // Deterministic seed
    return List.generate(40, (index) {
      return BackgroundStar(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 1.0 + random.nextDouble() * 1.5,  // 1.0-2.5px (increased from 0.5-1.5)
        opacity: 0.3 + random.nextDouble() * 0.4, // 0.3-0.7 (increased from 0.2-0.4)
      );
    });
  }

  void _generateParticles() {
    final random = Random();
    _particles = List.generate(10, (index) {
      return ParticleData(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 2 + random.nextDouble() * 3,
        speed: 0.3 + random.nextDouble() * 0.4,
        opacity: 0.3 + random.nextDouble() * 0.3,
      );
    });
  }

  /// Start auto-advance timer for onboarding mode
  void _startAutoAdvanceTimer() {
    _autoAdvanceTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      _completeSplash();
    });
  }

  /// Handle tap gesture
  void _handleTap() {
    if (_isNavigating) return;

    if (widget.displayMode == SplashDisplayMode.onboarding) {
      _autoAdvanceTimer?.cancel();
      _completeSplash();
    } else {
      // About mode - just pop
      _isNavigating = true;
      Navigator.of(context).pop();
    }
  }

  /// Complete the splash screen (called by timer or tap)
  void _completeSplash() {
    if (_isNavigating) return;
    _isNavigating = true;

    // Call the provided callback (required for onboarding mode)
    // For about mode, this is handled by _handleTap() which just pops
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _shimmerController.dispose();
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Background stars layer (static, decorative)
                SemanticHelper.decorative(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: BackgroundStarPainter(_backgroundStars),
                  ),
                ),

                // Floating particles layer (decorative)
                SemanticHelper.decorative(
                  child: _buildParticles(),
                ),

                // Main content
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildMainContent(l10n),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build floating particles layer
  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            progress: _particleController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  /// Build main content layout
  Widget _buildMainContent(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Pulsing logo
          ScaleTransition(
            scale: _pulseAnimation,
            child: SemanticHelper.label(
              label: l10n.appTitle,
              child: SvgPicture.asset(
                'assets/icon_star.svg',
                width: FontScaling.getResponsiveIconSize(context, 180),
                height: FontScaling.getResponsiveIconSize(context, 180),
                colorFilter: const ColorFilter.mode(
                  AppColors.primary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),

          SizedBox(height: FontScaling.getResponsiveSpacing(context, 32)),

          // App title with shimmer
          _buildShimmerText(
            l10n.appTitle,
            FontScaling.getAppTitle(context).copyWith(
              fontSize: FontScaling.getAppTitle(context).fontSize! * 2,
              fontWeight: FontScaling.boldWeight,
            ),
          ),

          SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),

          // Subtitle
          Text(
            l10n.appSubtitle,
            style: FontScaling.getSubtitle(context).copyWith(
              fontStyle: FontStyle.normal,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),

          // Divider
          Container(
            width: FontScaling.getResponsiveIconSize(context, 100),
            height: 1,
            color: Colors.white.withValues(alpha: 0.3),
          ),

          SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),

          // Tagline
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: FontScaling.getResponsiveSpacing(context, 40),
            ),
            child: Text(
              l10n.appTagline,
              style: FontScaling.getBodyMedium(context).copyWith(
                fontSize: FontScaling.getBodyMedium(context).fontSize! * 0.9,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const Spacer(flex: 1),

          // Version info
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final info = snapshot.data!;
              return Text(
                l10n.version(info.version, info.buildNumber),
                style: FontScaling.getCaption(context).copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              );
            },
          ),

          SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),

          // Mode-specific content
          if (widget.displayMode == SplashDisplayMode.about) ...[
            Text(
              l10n.createdBy('AgentFoo'),
              style: FontScaling.getCaption(context).copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 8)),
          ],

          // Hint text with pulsing opacity
          SemanticHelper.label(
            label: widget.displayMode == SplashDisplayMode.onboarding
                ? l10n.tapToContinue
                : l10n.tapToDismiss,
            isButton: true,
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.4 + (0.3 * _shimmerController.value),
                  child: Text(
                    widget.displayMode == SplashDisplayMode.onboarding
                        ? l10n.tapToContinue
                        : l10n.tapToDismiss,
                    style: FontScaling.getCaption(context).copyWith(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),

          SizedBox(height: FontScaling.getResponsiveSpacing(context, 32)),
        ],
      ),
    );
  }

  /// Build text with shimmer effect
  Widget _buildShimmerText(String text, TextStyle style) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                AppColors.primary,
                Color(0xFFFFFFFF),
                AppColors.primary,
              ],
              stops: [
                (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                _shimmerController.value,
                (_shimmerController.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: Text(
            text,
            style: style.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}

/// Data class for particle properties
class ParticleData {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  ParticleData({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

/// Data class for background star properties
class BackgroundStar {
  final double x;      // 0.0-1.0 normalized position
  final double y;      // 0.0-1.0 normalized position
  final double size;   // 0.5-1.5 pixel radius
  final double opacity; // 0.2-0.4 alpha

  const BackgroundStar({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
  });
}

/// Custom painter for rendering floating particles
class ParticlePainter extends CustomPainter {
  final List<ParticleData> particles;
  final double progress;

  ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = AppColors.primary.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;

      // Calculate drifting position (vertical scroll)
      final offsetY = ((progress * particle.speed) % 1.0) * size.height;
      final x = particle.x * size.width;
      final y = (particle.y * size.height + offsetY) % size.height;

      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

/// Custom painter for rendering static background stars
class BackgroundStarPainter extends CustomPainter {
  final List<BackgroundStar> stars;

  BackgroundStarPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: star.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(BackgroundStarPainter oldDelegate) => false; // Static
}
