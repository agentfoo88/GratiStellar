import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/accessibility/semantic_helper.dart';
import '../../core/config/app_colors.dart';
import '../../font_scaling.dart';
import '../../l10n/app_localizations.dart';
import '../../models/holiday_greeting.dart';
import '../../services/holiday_greeting_service.dart';

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

  // Holiday greeting (if active)
  HolidayGreeting? _holidayGreeting;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _backgroundStars = _generateBackgroundStars();
    _generateParticles();
    
    // Get current holiday greeting (default to Northern Hemisphere)
    _holidayGreeting = HolidayGreetingService.instance.getCurrentGreeting();

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
            gradient: _getBackgroundGradient(),
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
            particleColor: _getParticleColor(),
          ),
          size: Size.infinite,
        );
      },
    );
  }

  /// Get background gradient based on holiday or default
  LinearGradient _getBackgroundGradient() {
    if (_holidayGreeting != null && _holidayGreeting!.style.gradient != null) {
      // Use holiday gradient if available
      final holidayGradient = _holidayGreeting!.style.gradient!;
      // Blend with base gradient for better integration
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(AppColors.gradientTop, holidayGradient.colors.first, 0.3) ?? holidayGradient.colors.first,
          Color.lerp(AppColors.gradientUpperMid, holidayGradient.colors.first, 0.2) ?? holidayGradient.colors.first,
          Color.lerp(AppColors.gradientLowerMid, holidayGradient.colors.last, 0.2) ?? holidayGradient.colors.last,
          Color.lerp(AppColors.gradientBottom, holidayGradient.colors.last, 0.3) ?? holidayGradient.colors.last,
        ],
      );
    }
    return AppColors.backgroundGradient;
  }

  /// Get logo color based on holiday or default
  Color _getLogoColor() {
    return _holidayGreeting?.style.accentColor ?? AppColors.primary;
  }

  /// Get particle color based on holiday or default
  Color _getParticleColor() {
    return _holidayGreeting?.style.accentColor ?? AppColors.primary;
  }

  /// Get localized holiday greeting text by key
  String _getHolidayGreetingText(AppLocalizations l10n, String key) {
    switch (key) {
      case 'greetingNewYear':
        return l10n.greetingNewYear;
      case 'greetingValentines':
        return l10n.greetingValentines;
      case 'greetingEaster':
        return l10n.greetingEaster;
      case 'greetingHalloween':
        return l10n.greetingHalloween;
      case 'greetingChristmas':
        return l10n.greetingChristmas;
      case 'greetingNewYearsEve':
        return l10n.greetingNewYearsEve;
      case 'greetingLunarNewYear':
        return l10n.greetingLunarNewYear;
      case 'greetingDiwali':
        return l10n.greetingDiwali;
      case 'greetingRamadan':
        return l10n.greetingRamadan;
      case 'greetingEidAlFitr':
        return l10n.greetingEidAlFitr;
      case 'greetingEidAlAdha':
        return l10n.greetingEidAlAdha;
      case 'greetingHanukkah':
        return l10n.greetingHanukkah;
      case 'greetingKwanzaa':
        return l10n.greetingKwanzaa;
      case 'greetingThanksgivingUS':
        return l10n.greetingThanksgivingUS;
      case 'greetingThanksgivingCA':
        return l10n.greetingThanksgivingCA;
      case 'greetingSpringEquinox':
        return l10n.greetingSpringEquinox;
      case 'greetingSummerSolstice':
        return l10n.greetingSummerSolstice;
      case 'greetingAutumnEquinox':
        return l10n.greetingAutumnEquinox;
      case 'greetingWinterSolstice':
        return l10n.greetingWinterSolstice;
      // Subtitles
      case 'greetingNewYearSubtitle':
        return l10n.greetingNewYearSubtitle;
      case 'greetingValentinesSubtitle':
        return l10n.greetingValentinesSubtitle;
      case 'greetingEasterSubtitle':
        return l10n.greetingEasterSubtitle;
      case 'greetingHalloweenSubtitle':
        return l10n.greetingHalloweenSubtitle;
      case 'greetingChristmasSubtitle':
        return l10n.greetingChristmasSubtitle;
      case 'greetingNewYearsEveSubtitle':
        return l10n.greetingNewYearsEveSubtitle;
      case 'greetingLunarNewYearSubtitle':
        return l10n.greetingLunarNewYearSubtitle;
      case 'greetingDiwaliSubtitle':
        return l10n.greetingDiwaliSubtitle;
      case 'greetingRamadanSubtitle':
        return l10n.greetingRamadanSubtitle;
      case 'greetingEidAlFitrSubtitle':
        return l10n.greetingEidAlFitrSubtitle;
      case 'greetingEidAlAdhaSubtitle':
        return l10n.greetingEidAlAdhaSubtitle;
      case 'greetingHanukkahSubtitle':
        return l10n.greetingHanukkahSubtitle;
      case 'greetingKwanzaaSubtitle':
        return l10n.greetingKwanzaaSubtitle;
      case 'greetingThanksgivingUSSubtitle':
        return l10n.greetingThanksgivingUSSubtitle;
      case 'greetingThanksgivingCASubtitle':
        return l10n.greetingThanksgivingCASubtitle;
      case 'greetingSpringEquinoxSubtitle':
        return l10n.greetingSpringEquinoxSubtitle;
      case 'greetingSummerSolsticeSubtitle':
        return l10n.greetingSummerSolsticeSubtitle;
      case 'greetingAutumnEquinoxSubtitle':
        return l10n.greetingAutumnEquinoxSubtitle;
      case 'greetingWinterSolsticeSubtitle':
        return l10n.greetingWinterSolsticeSubtitle;
      default:
        return '';
    }
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
                colorFilter: ColorFilter.mode(
                  _getLogoColor(),
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

          // Holiday greeting or subtitle
          if (_holidayGreeting != null) ...[
            // Holiday emoji icon
            Text(
              _holidayGreeting!.style.iconEmoji,
              style: TextStyle(
                fontSize: FontScaling.getResponsiveIconSize(context, 48),
              ),
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
            // Holiday greeting text
            _buildShimmerText(
              _getHolidayGreetingText(l10n, _holidayGreeting!.greetingKey),
              FontScaling.getSubtitle(context).copyWith(
                fontStyle: FontStyle.normal,
                color: _holidayGreeting!.style.accentColor,
                fontWeight: FontScaling.boldWeight,
              ),
            ),
            if (_holidayGreeting!.subtitleKey != null) ...[
              SizedBox(height: FontScaling.getResponsiveSpacing(context, 8)),
              Text(
                _getHolidayGreetingText(l10n, _holidayGreeting!.subtitleKey!),
                style: FontScaling.getSubtitle(context).copyWith(
                  fontStyle: FontStyle.normal,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ] else ...[
            // Default subtitle
            Text(
              l10n.appSubtitle,
              style: FontScaling.getSubtitle(context).copyWith(
                fontStyle: FontStyle.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),

          // Divider
          Container(
            width: FontScaling.getResponsiveIconSize(context, 100),
            height: 1,
            color: Colors.white.withValues(alpha: 0.3),
          ),

          SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),

          // Tagline (only show if no holiday greeting)
          if (_holidayGreeting == null)
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
              colors: [
                _getLogoColor(),
                Color(0xFFFFFFFF),
                _getLogoColor(),
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
  final Color particleColor;

  ParticlePainter({
    required this.particles,
    required this.progress,
    this.particleColor = AppColors.primary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particleColor.withValues(alpha: particle.opacity)
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
