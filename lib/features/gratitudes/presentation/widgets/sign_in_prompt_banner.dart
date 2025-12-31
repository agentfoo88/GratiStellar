import 'package:flutter/material.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth_service.dart';
import '../../../../screens/sign_in_screen.dart';
import '../../../../core/accessibility/semantic_helper.dart';
import '../state/gratitude_provider.dart';

/// Banner widget that prompts anonymous users to sign in after creating stars
/// 
/// Shows a non-intrusive banner at the top of the screen when:
/// - User is anonymous (not signed in with email)
/// - User has created N stars (default: 3)
/// - User hasn't dismissed the prompt
class SignInPromptBanner extends StatefulWidget {
  final GratitudeProvider gratitudeProvider;
  final AuthService authService;

  const SignInPromptBanner({
    super.key,
    required this.gratitudeProvider,
    required this.authService,
  });

  @override
  State<SignInPromptBanner> createState() => _SignInPromptBannerState();
}

class _SignInPromptBannerState extends State<SignInPromptBanner> {
  bool _shouldShow = false;

  @override
  void initState() {
    super.initState();
    _checkShouldShow();
  }

  Future<void> _checkShouldShow() async {
    if (widget.authService.hasEmailAccount) {
      if (mounted) {
        setState(() => _shouldShow = false);
      }
      return;
    }
    final shouldShow = await widget.gratitudeProvider.shouldShowSignInPrompt();
    if (mounted) {
      setState(() => _shouldShow = shouldShow);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hide if user is signed in with email
    if (widget.authService.hasEmailAccount) {
      return const SizedBox.shrink();
    }

    if (!_shouldShow) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;

    return SemanticHelper.label(
      label: l10n.signInPromptMessage,
      hint: 'Banner prompting anonymous users to sign in',
      child: Container(
        width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: FontScaling.getResponsiveSpacing(context, 16),
        vertical: FontScaling.getResponsiveSpacing(context, 12),
      ),
      decoration: BoxDecoration(
        color: Color(0xFFFFE135).withValues(alpha: 0.15),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFFFE135).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Cloud icon
          Icon(
            Icons.cloud_upload,
            color: Color(0xFFFFE135),
            size: FontScaling.getResponsiveIconSize(context, 24),
          ),
          SizedBox(width: FontScaling.getResponsiveSpacing(context, 12)),
          // Message
          Expanded(
            child: Text(
              l10n.signInPromptMessage,
              style: FontScaling.getBodySmall(context).copyWith(
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
          // Sign In button
          SemanticHelper.label(
            label: l10n.signInPromptButton,
            hint: 'Navigate to sign in screen',
            isButton: true,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignInScreen()),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: FontScaling.getResponsiveSpacing(context, 12),
                  vertical: FontScaling.getResponsiveSpacing(context, 8),
                ),
                backgroundColor: Color(0xFFFFE135),
                foregroundColor: Color(0xFF1A2238),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                l10n.signInPromptButton,
                style: FontScaling.getBodySmall(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2238),
                ),
              ),
            ),
          ),
          SizedBox(width: FontScaling.getResponsiveSpacing(context, 4)),
          // Dismiss button
          SemanticHelper.label(
            label: l10n.signInPromptDismiss,
            hint: 'Dismiss sign in prompt',
            isButton: true,
            child: IconButton(
              onPressed: () async {
                await widget.gratitudeProvider.dismissSignInPrompt();
                _checkShouldShow(); // Update state to hide banner
              },
              icon: Icon(
                Icons.close,
                color: Colors.white.withValues(alpha: 0.7),
                size: FontScaling.getResponsiveIconSize(context, 20),
              ),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              tooltip: l10n.signInPromptDismiss,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
