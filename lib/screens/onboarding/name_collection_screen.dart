import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/accessibility/semantic_helper.dart';
import '../../core/config/app_config.dart';
import '../../core/config/constants.dart';
import '../../core/error/error_context.dart';
import '../../core/error/error_handler.dart';
import '../../core/utils/app_logger.dart';
import '../../font_scaling.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/onboarding_service.dart';
import '../gratitude_screen.dart';

/// Name collection screen - single source of truth for account creation
///
/// Collects user's name and creates anonymous Firebase account with that name.
/// This is the ONLY place in the app where anonymous accounts are created.
class NameCollectionScreen extends StatefulWidget {
  const NameCollectionScreen({super.key});

  @override
  State<NameCollectionScreen> createState() => _NameCollectionScreenState();
}

class _NameCollectionScreenState extends State<NameCollectionScreen> {
  final TextEditingController _nameController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OnboardingService _onboardingService = OnboardingService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Create anonymous account with user's name - single source of truth
  Future<void> _handleCreateAccount() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final l10n = AppLocalizations.of(context)!;

    try {
      AppLogger.auth('Creating anonymous account with name: $name');

      // Step 1: Create anonymous Firebase account with user's name
      final user = await _authService.signInAnonymously(name);

      if (user == null) {
        throw Exception('Failed to create account');
      }

      AppLogger.auth('Anonymous account created: ${user.uid}');

      // Step 2: Save consent to Firestore with retry
      await ErrorHandler.withRetry(
        operation: () => _firestore.collection('users').doc(user.uid).set({
          'consentVersion': AppConfig.consentVersion,
          'consentDate': FieldValue.serverTimestamp(),
          'privacyAccepted': true,
          'termsAccepted': true,
          'onboardingCompletedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
        context: ErrorContext.auth,
        l10n: l10n,
      );

      AppLogger.data('Consent saved to Firestore');

      // Step 3: Mark onboarding as complete
      await _onboardingService.markOnboardingComplete();

      AppLogger.success('✅ Onboarding completed successfully for $name');

      // Step 4: Navigate to main app
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GratitudeScreen()),
      );
    } catch (e, stack) {
      AppLogger.error('Account creation error: $e');

      final error = ErrorHandler.handle(
        e,
        stack,
        context: ErrorContext.auth,
        l10n: l10n,
      );

      if (mounted) {
        setState(() {
          _errorMessage = error.userMessage;
          _isLoading = false;
        });
      }
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
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Welcome icon
                    Icon(
                      Icons.person_outline,
                      size: FontScaling.getResponsiveIconSize(context, 80) *
                          UIConstants.universalUIScale,
                      color: const Color(0xFFFFE135),
                    ),

                    SizedBox(
                      height: FontScaling.getResponsiveSpacing(context, 32) *
                          UIConstants.universalUIScale,
                    ),

                    // Title
                    Text(
                      l10n.nameCollectionTitle,
                      style: FontScaling.getHeadingMedium(context),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(
                      height: FontScaling.getResponsiveSpacing(context, 12) *
                          UIConstants.universalUIScale,
                    ),

                    // Subtitle
                    Text(
                      l10n.nameCollectionSubtitle,
                      style: FontScaling.getBodyMedium(context).copyWith(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(
                      height: FontScaling.getResponsiveSpacing(context, 48) *
                          UIConstants.universalUIScale,
                    ),

                    // Name input field
                    SemanticHelper.label(
                      label: l10n.nameCollectionLabel,
                      hint: l10n.nameCollectionHint,
                      child: TextField(
                        controller: _nameController,
                        enabled: !_isLoading,
                        textAlign: TextAlign.center,
                        style: FontScaling.getInputText(context),
                        decoration: InputDecoration(
                          hintText: l10n.nameCollectionPlaceholder,
                          hintStyle: FontScaling.getInputHint(context),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: const Color(0xFFFFE135).withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFE135),
                              width: 2,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _handleCreateAccount(),
                      ),
                    ),

                    // Error message
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
                        child: Text(
                          _errorMessage!,
                          style: FontScaling.getBodySmall(context).copyWith(
                            color: Colors.red.withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    SizedBox(
                      height: FontScaling.getResponsiveSpacing(context, 32) *
                          UIConstants.universalUIScale,
                    ),

                    // Continue button
                    SemanticHelper.label(
                      label: l10n.nameCollectionButton,
                      hint: l10n.nameCollectionButtonHint,
                      isButton: true,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleCreateAccount,
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
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF1A2238),
                                    ),
                                  ),
                                )
                              : Text(
                                  l10n.nameCollectionButton,
                                  style:
                                      FontScaling.getButtonText(context).copyWith(
                                    color: const Color(0xFF1A2238),
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
