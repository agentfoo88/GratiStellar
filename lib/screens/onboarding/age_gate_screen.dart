import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/accessibility/semantic_helper.dart';
import '../../core/config/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../font_scaling.dart';
import '../../l10n/app_localizations.dart';
import '../../services/onboarding_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_profile_manager.dart';
import '../../services/user_profile_migration_service.dart';
import '../../core/utils/app_logger.dart';
import 'consent_screen.dart';

/// Age gate screen for COPPA compliance
///
/// Verifies that users are 13+ years old before allowing them to proceed.
/// Users under 13 are shown an exit dialog and the app closes.
/// 
/// Checks both local state and Firebase profile for age gate status.
class AgeGateScreen extends StatefulWidget {
  const AgeGateScreen({super.key});

  @override
  State<AgeGateScreen> createState() => _AgeGateScreenState();
}

class _AgeGateScreenState extends State<AgeGateScreen> {
  bool _isChecking = true;
  bool _shouldShow = true;

  @override
  void initState() {
    super.initState();
    _checkAgeGateStatus();
  }

  /// Check age gate status from both local and Firebase
  Future<void> _checkAgeGateStatus() async {
    try {
      final authService = AuthService();
      
      // Get UserProfileManager from context
      final userProfileManager = Provider.of<UserProfileManager>(context, listen: false);
      final userId = await userProfileManager.getOrCreateActiveUserId();
      final onboardingService = OnboardingService(userProfileManager: userProfileManager);
      
      // Check local state first (user-scoped)
      final localAgeGatePassed = await onboardingService.hasPassedAgeGate(userId);
      
      // If user is signed in, check Firebase profile
      if (authService.isSignedIn && authService.hasEmailAccount) {
        final userId = authService.currentUser?.uid;
        if (userId != null) {
          // Sync and migrate profile from Firebase
          final migrationService = UserProfileMigrationService();
          final migrationResult = await migrationService.loadAndMigrateProfile(userId);
          
          if (migrationResult != null) {
            // Use profile data from migration result to avoid redundant read
            final profileData = migrationResult.profileData;
            final firebaseAgeGatePassed = profileData?['ageGatePassed'] as bool? ?? false;
            
            // If Firebase says age gate passed, skip this screen
            if (firebaseAgeGatePassed) {
              AppLogger.data('✅ Age gate already passed in Firebase, skipping screen');
              if (!mounted) return;
              // Mark locally as well (user-scoped)
              await onboardingService.markAgeGatePassed(userId);
              if (!mounted) return;
              // Capture navigator after async gap
              final navigator = Navigator.of(context);
              navigator.pushReplacement(
                MaterialPageRoute(builder: (context) => const ConsentScreen()),
              );
              return;
            }
          }
        }
      }
      
      // If local age gate passed, skip this screen
      if (localAgeGatePassed) {
        AppLogger.data('✅ Age gate already passed locally, skipping screen');
        if (!mounted) return;
        // Capture navigator after async gap
        final navigator = Navigator.of(context);
        navigator.pushReplacement(
          MaterialPageRoute(builder: (context) => const ConsentScreen()),
        );
        return;
      }
      
      // Show age gate screen
      if (mounted) {
        setState(() {
          _isChecking = false;
          _shouldShow = true;
        });
      }
    } catch (e) {
      AppLogger.error('❌ Error checking age gate status: $e');
      // On error, show the screen (safer to show than skip)
      if (mounted) {
        setState(() {
          _isChecking = false;
          _shouldShow = true;
        });
      }
    }
  }

  /// Handle age confirmation
  void _handleAgeConfirmation(BuildContext context, bool is13OrOlder) async {
    final l10n = AppLocalizations.of(context)!;

    if (is13OrOlder) {
      // User is 13+, save and proceed to consent screen
      final userProfileManager = Provider.of<UserProfileManager>(context, listen: false);
      final userId = await userProfileManager.getOrCreateActiveUserId();
      final onboardingService = OnboardingService(userProfileManager: userProfileManager);
      await onboardingService.markAgeGatePassed(userId);
      
      // OPTIMIZATION: Use batched profile update instead of direct write
      final authService = AuthService();
      if (authService.isSignedIn && authService.hasEmailAccount) {
        final userId = authService.currentUser?.uid;
        if (userId != null) {
          try {
            authService.scheduleProfileUpdate(userId, {
              'ageGatePassed': true,
            });
            AppLogger.success('✅ Age gate passed scheduled for batched update');
          } catch (e) {
            AppLogger.error('⚠️ Error scheduling age gate update: $e');
            // Continue anyway - local state is saved
          }
        }
      }

      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ConsentScreen()),
      );
    } else {
      // User is under 13, show exit dialog
      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.backgroundDark,
          title: Text(
            l10n.ageGateUnder13Title,
            style: FontScaling.getHeadingMedium(context).copyWith(
              color: AppTheme.primary,
            ),
          ),
          content: Text(
            l10n.ageGateUnder13Message,
            style: FontScaling.getBodyMedium(context).copyWith(
              color: AppTheme.textPrimary, // Explicit white for better contrast on dark background
            ),
          ),
          actions: [
            SemanticHelper.label(
              label: l10n.exitButton,
              hint: l10n.exitButton,
              isButton: true,
              child: TextButton(
                onPressed: () {
                  SystemNavigator.pop(); // Exit the app
                },
                child: Text(
                  l10n.exitButton,
                  style: FontScaling.getButtonText(context).copyWith(
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Show loading while checking status
    if (_isChecking) {
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
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
        ),
      );
    }

    // Don't show if we determined we shouldn't
    if (!_shouldShow) {
      return const SizedBox.shrink();
    }

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
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                FontScaling.getResponsiveSpacing(context, 24) *
                    UIConstants.universalUIScale,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Icon(
                    Icons.cake_outlined,
                    size: FontScaling.getResponsiveIconSize(context, 80) *
                        UIConstants.universalUIScale,
                    color: AppTheme.primary,
                  ),

                  SizedBox(
                    height: FontScaling.getResponsiveSpacing(context, 32) *
                        UIConstants.universalUIScale,
                  ),

                  // Question
                  Text(
                    l10n.ageGateQuestion,
                    style: FontScaling.getHeadingMedium(context),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(
                    height: FontScaling.getResponsiveSpacing(context, 48) *
                        UIConstants.universalUIScale,
                  ),

                  // Yes button (13+)
                  SemanticHelper.label(
                    label: l10n.ageGateYesButton,
                    hint: l10n.ageGateYesHint,
                    isButton: true,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _handleAgeConfirmation(context, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: EdgeInsets.symmetric(
                            vertical:
                                FontScaling.getResponsiveSpacing(context, 16) *
                                    UIConstants.universalUIScale,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          minimumSize: const Size(0, 56), // Accessibility
                        ),
                        child: Text(
                          l10n.ageGateYesButton,
                          style: FontScaling.getButtonText(context).copyWith(
                            color: AppTheme.textOnLight,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                    height: FontScaling.getResponsiveSpacing(context, 16) *
                        UIConstants.universalUIScale,
                  ),

                  // No button (under 13)
                  SemanticHelper.label(
                    label: l10n.ageGateNoButton,
                    hint: l10n.ageGateNoHint,
                    isButton: true,
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _handleAgeConfirmation(context, false);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppTheme.primary.withValues(alpha: 0.5),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical:
                                FontScaling.getResponsiveSpacing(context, 16) *
                                    UIConstants.universalUIScale,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          minimumSize: const Size(0, 56), // Accessibility
                        ),
                        child: Text(
                          l10n.ageGateNoButton,
                          style: FontScaling.getButtonText(context),
                        ),
                      ),
                    ),
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
