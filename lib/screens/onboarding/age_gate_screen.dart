import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/accessibility/semantic_helper.dart';
import '../../core/config/constants.dart';
import '../../font_scaling.dart';
import '../../l10n/app_localizations.dart';
import '../../services/onboarding_service.dart';
import 'consent_screen.dart';

/// Age gate screen for COPPA compliance
///
/// Verifies that users are 13+ years old before allowing them to proceed.
/// Users under 13 are shown an exit dialog and the app closes.
class AgeGateScreen extends StatelessWidget {
  const AgeGateScreen({super.key});

  /// Handle age confirmation
  void _handleAgeConfirmation(BuildContext context, bool is13OrOlder) async {
    final l10n = AppLocalizations.of(context)!;

    if (is13OrOlder) {
      // User is 13+, save and proceed to consent screen
      final onboardingService = OnboardingService();
      await onboardingService.markAgeGatePassed();

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
          backgroundColor: const Color(0xFF1A2238),
          title: Text(
            l10n.ageGateUnder13Title,
            style: FontScaling.getHeadingMedium(context).copyWith(
              color: const Color(0xFFFFE135),
            ),
          ),
          content: Text(
            l10n.ageGateUnder13Message,
            style: FontScaling.getBodyMedium(context),
          ),
          actions: [
            TextButton(
              onPressed: () {
                SystemNavigator.pop(); // Exit the app
              },
              child: Text(
                l10n.exitButton,
                style: FontScaling.getButtonText(context).copyWith(
                  color: const Color(0xFFFFE135),
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
                    color: const Color(0xFFFFE135),
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
                        onPressed: () => _handleAgeConfirmation(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFE135),
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
                            color: const Color(0xFF1A2238),
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
                        onPressed: () =>
                            _handleAgeConfirmation(context, false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: const Color(0xFFFFE135).withValues(alpha: 0.5),
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
