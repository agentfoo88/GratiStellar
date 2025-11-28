import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/config/app_config.dart';
import '../../font_scaling.dart';
import '../../l10n/app_localizations.dart';
import '../../services/onboarding_service.dart';
import 'age_gate_screen.dart';
import 'consent_screen.dart';

/// Splash screen shown on first app launch
///
/// Displays app branding with fade-in animation, then automatically
/// navigates to the appropriate screen after 1.5 seconds based on
/// onboarding status.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final OnboardingService _onboardingService = OnboardingService();

  @override
  void initState() {
    super.initState();

    // Set up fade-in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Start the fade-in animation
    _fadeController.forward();

    // Start the auto-navigation timer
    _startTimer();
  }

  /// Auto-navigate after splash duration
  void _startTimer() {
    Future.delayed(AppConfig.splashDuration, () {
      if (!mounted) return;
      _navigateNext();
    });
  }

  /// Determine next screen based on onboarding state
  Future<void> _navigateNext() async {
    final ageGatePassed = await _onboardingService.hasPassedAgeGate();

    if (!mounted) return;

    if (ageGatePassed) {
      // Age gate already passed, go to consent screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ConsentScreen()),
      );
    } else {
      // First time, show age gate
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AgeGateScreen()),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A6FA5),
              Color(0xFF166088),
              Color(0xFF0B1426),
              Color(0xFF2C3E50),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App icon
                  SvgPicture.asset(
                    'assets/icon_star.svg',
                    width: FontScaling.getResponsiveIconSize(context, 140),
                    height: FontScaling.getResponsiveIconSize(context, 140),
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFFFE135),
                      BlendMode.srcIn,
                    ),
                  ),

                  SizedBox(
                    height: FontScaling.getResponsiveSpacing(context, 32),
                  ),

                  // App title
                  Text(
                    l10n.appTitle,
                    style: FontScaling.getAppTitle(context),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(
                    height: FontScaling.getResponsiveSpacing(context, 12),
                  ),

                  // Subtitle
                  Text(
                    l10n.appSubtitle,
                    style: FontScaling.getSubtitle(context),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
