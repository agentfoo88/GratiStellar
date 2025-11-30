import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/accessibility/semantic_helper.dart';
import '../../core/config/app_config.dart';
import '../../core/config/constants.dart';
import '../../core/error/error_handler.dart';
import '../../core/error/error_context.dart';
import '../../core/utils/app_logger.dart';
import '../../font_scaling.dart';
import '../../l10n/app_localizations.dart';
import '../../services/url_launch_service.dart';
import 'name_collection_screen.dart';

/// Privacy and Terms of Service consent screen
///
/// Displays privacy practices and requires consent to both privacy policy
/// and terms of service via checkboxes before proceeding to name collection.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _privacyAccepted = false;
  bool _termsAccepted = false;
  String? _errorMessage;
  String? _failedUrl; // Track which URL failed for retry
  bool _isRetriable = false; // Track if error is retriable

  /// Open URL in external browser with comprehensive error handling
  Future<void> _openUrl(String url) async {
    // Clear previous errors
    setState(() {
      _errorMessage = null;
      _failedUrl = null;
      _isRetriable = false;
    });

    final l10n = AppLocalizations.of(context)!;

    try {
      await UrlLaunchService.launchUrlSafely(url);
    } catch (e, stack) {
      AppLogger.error('Failed to open URL: $url', 'CONSENT', e);

      if (!mounted) return;

      // Use ErrorHandler to map exception to user-friendly message
      final error = ErrorHandler.handle(
        e,
        stack,
        context: ErrorContext.url,
        l10n: l10n,
        metadata: {'url': url},
      );

      setState(() {
        _errorMessage = error.userMessage;
        _failedUrl = url;
        _isRetriable = error.isRetriable;
      });
    }
  }

  /// Retry opening the last failed URL
  Future<void> _retryOpenUrl() async {
    if (_failedUrl != null) {
      await _openUrl(_failedUrl!);
    }
  }

  /// Copy URL to clipboard as fallback
  Future<void> _copyUrlToClipboard(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.consentUrlCopied),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF4A6FA5),
      ),
    );

    // Clear error state
    setState(() {
      _errorMessage = null;
      _failedUrl = null;
      _isRetriable = false;
    });
  }

  /// Handle acceptance - navigate to name collection screen
  void _handleAccept() {
    if (!_canContinue) return;

    AppLogger.auth('Consent accepted, navigating to name collection...');

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NameCollectionScreen()),
    );
  }

  /// Build a bullet point for privacy practices
  Widget _buildBulletPoint(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '•  ',
          style: FontScaling.getBodyMedium(context).copyWith(
            color: const Color(0xFFFFE135),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: FontScaling.getBodyMedium(context),
          ),
        ),
      ],
    );
  }

  bool get _canContinue => _privacyAccepted && _termsAccepted;

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
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Center(
                      child: Text(
                        l10n.consentTitle,
                        style: FontScaling.getHeadingMedium(context).copyWith(
                          color: const Color(0xFFFFE135),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(
                      height: FontScaling.getResponsiveSpacing(context, 24) *
                          UIConstants.universalUIScale,
                    ),

                    // Privacy message container
                    Container(
                      padding: EdgeInsets.all(
                        FontScaling.getResponsiveSpacing(context, 16) *
                            UIConstants.universalUIScale,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.consentMessage,
                            style: FontScaling.getBodyMedium(context),
                          ),

                          SizedBox(
                            height:
                                FontScaling.getResponsiveSpacing(context, 16) *
                                    UIConstants.universalUIScale,
                          ),

                          // Bullet points
                          _buildBulletPoint(context, l10n.consentBullet1),
                          SizedBox(
                            height:
                                FontScaling.getResponsiveSpacing(context, 8) *
                                    UIConstants.universalUIScale,
                          ),
                          _buildBulletPoint(context, l10n.consentBullet2),
                          SizedBox(
                            height:
                                FontScaling.getResponsiveSpacing(context, 8) *
                                    UIConstants.universalUIScale,
                          ),
                          _buildBulletPoint(context, l10n.consentBullet3),
                        ],
                      ),
                    ),

                    SizedBox(
                      height: FontScaling.getResponsiveSpacing(context, 32) *
                          UIConstants.universalUIScale,
                    ),

                    // Privacy Policy checkbox
                    SemanticHelper.label(
                      label: l10n.consentPrivacyCheckbox,
                      isButton: false,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _privacyAccepted = !_privacyAccepted;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _privacyAccepted,
                                  onChanged: (value) {
                                    setState(() {
                                      _privacyAccepted = value ?? false;
                                    });
                                  },
                                  fillColor: WidgetStateProperty.resolveWith(
                                      (states) {
                                    if (states
                                        .contains(WidgetState.selected)) {
                                      return const Color(0xFFFFE135);
                                    }
                                    return Colors.white.withValues(alpha: 0.3);
                                  }),
                                  checkColor: const Color(0xFF1A2238),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      _openUrl(AppConfig.privacyPolicyUrl),
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: l10n.consentPrivacyPart1,
                                          style: FontScaling.getBodyMedium(
                                              context),
                                        ),
                                        TextSpan(
                                          text: l10n.consentPrivacyLink,
                                          style: FontScaling.getBodyMedium(
                                                  context)
                                              .copyWith(
                                            color: const Color(0xFFFFE135),
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      height: FontScaling.getResponsiveSpacing(context, 16) *
                          UIConstants.universalUIScale,
                    ),

                    // Terms of Service checkbox
                    SemanticHelper.label(
                      label: l10n.consentTermsCheckbox,
                      isButton: false,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _termsAccepted = !_termsAccepted;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _termsAccepted,
                                  onChanged: (value) {
                                    setState(() {
                                      _termsAccepted = value ?? false;
                                    });
                                  },
                                  fillColor: WidgetStateProperty.resolveWith(
                                      (states) {
                                    if (states
                                        .contains(WidgetState.selected)) {
                                      return const Color(0xFFFFE135);
                                    }
                                    return Colors.white.withValues(alpha: 0.3);
                                  }),
                                  checkColor: const Color(0xFF1A2238),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      _openUrl(AppConfig.termsOfServiceUrl),
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: l10n.consentTermsPart1,
                                          style: FontScaling.getBodyMedium(
                                              context),
                                        ),
                                        TextSpan(
                                          text: l10n.consentTermsLink,
                                          style: FontScaling.getBodyMedium(
                                                  context)
                                              .copyWith(
                                            color: const Color(0xFFFFE135),
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Enhanced error message with actions
                    if (_errorMessage != null) ...[
                      SizedBox(
                        height: FontScaling.getResponsiveSpacing(context, 16) *
                            UIConstants.universalUIScale,
                      ),
                      Container(
                        padding: EdgeInsets.all(
                          FontScaling.getResponsiveSpacing(context, 12) *
                              UIConstants.universalUIScale,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Error message
                            Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.withValues(alpha: 0.9),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: FontScaling.getBodySmall(context).copyWith(
                                      color: Colors.red.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Action buttons
                            if (_failedUrl != null) ...[
                              SizedBox(
                                height: FontScaling.getResponsiveSpacing(context, 12) *
                                    UIConstants.universalUIScale,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Copy URL button (always show as fallback)
                                  TextButton.icon(
                                    onPressed: () => _copyUrlToClipboard(_failedUrl!),
                                    icon: const Icon(Icons.copy, size: 16),
                                    label: Text(l10n.consentCopyUrlButton),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFFFFE135),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),

                                  // Retry button (only if retriable)
                                  if (_isRetriable) ...[
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: _retryOpenUrl,
                                      icon: const Icon(Icons.refresh, size: 16),
                                      label: Text(l10n.consentRetryButton),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFFFFE135),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    SizedBox(
                      height: FontScaling.getResponsiveSpacing(context, 32) *
                          UIConstants.universalUIScale,
                    ),

                    // Accept button
                    SemanticHelper.label(
                      label: l10n.consentAcceptButton,
                      hint: _canContinue
                          ? l10n.consentAcceptHint
                          : l10n.consentAcceptDisabledHint,
                      isButton: true,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _canContinue ? _handleAccept : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFE135),
                            disabledBackgroundColor:
                                Colors.grey.withValues(alpha: 0.3),
                            padding: EdgeInsets.symmetric(
                              vertical: FontScaling.getResponsiveSpacing(
                                      context, 16) *
                                  UIConstants.universalUIScale,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            minimumSize: const Size(0, 56),
                          ),
                          child: Text(
                            l10n.consentAcceptButton,
                            style: FontScaling.getButtonText(context).copyWith(
                              color: _canContinue
                                  ? const Color(0xFF1A2238)
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
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
      ),
    );
  }
}
