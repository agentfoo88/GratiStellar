import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../font_scaling.dart';
import '../l10n/app_localizations.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name';
      });
      return;
    }

    if (name.length < 2) {
      setState(() {
        _errorMessage = 'Name must be at least 2 characters';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔵 Attempting anonymous sign-in with name: $name');
      final user = await _authService.signInAnonymously(name);
      print('🔵 Sign-in result: ${user?.uid ?? "null"}');

      if (user != null && mounted) {
        print('🔵 User signed in successfully, navigation should happen automatically');
        // Navigation will be handled by auth state listener in main.dart
      } else if (mounted) {
        print('🔴 Sign-in returned null user');
        setState(() {
          _errorMessage = 'Failed to create account. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('🔴 Sign-in exception: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
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
                FontScaling.getResponsiveSpacing(context, 24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App icon
                  SvgPicture.asset(
                    'assets/icon_star.svg',
                    width: FontScaling.getResponsiveIconSize(context, 120),
                    height: FontScaling.getResponsiveIconSize(context, 120),
                    colorFilter: ColorFilter.mode(
                      Color(0xFFFFE135),
                      BlendMode.srcIn,
                    ),
                  ),

                  SizedBox(height: FontScaling.getResponsiveSpacing(context, 32)),

                  // App title
                  Text(
                    AppLocalizations.of(context)!.appTitle,
                    style: FontScaling.getAppTitle(context),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),

                  // Subtitle
                  Text(
                    AppLocalizations.of(context)!.appSubtitle,
                    style: FontScaling.getSubtitle(context),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: FontScaling.getResponsiveSpacing(context, 48)),

                  // Welcome message
                  Container(
                    constraints: BoxConstraints(maxWidth: 400),
                    child: Column(
                      children: [
                        Text(
                          'Welcome! What should we call you?',
                          style: FontScaling.getBodyLarge(context),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),

                        // Name input
                        TextField(
                          controller: _nameController,
                          enabled: !_isLoading,
                          textAlign: TextAlign.center,
                          style: FontScaling.getInputText(context),
                          decoration: InputDecoration(
                            hintText: 'Enter your name',
                            hintStyle: FontScaling.getInputHint(context),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Color(0xFFFFE135).withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Color(0xFFFFE135).withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Color(0xFFFFE135),
                                width: 2,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _continue(),
                        ),

                        if (_errorMessage != null) ...[
                          SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
                          Text(
                            _errorMessage!,
                            style: FontScaling.getBodySmall(context).copyWith(
                              color: Colors.red.withValues(alpha: 0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],

                        SizedBox(height: FontScaling.getResponsiveSpacing(context, 32)),

                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _continue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFFE135),
                              padding: EdgeInsets.symmetric(
                                vertical: FontScaling.getResponsiveSpacing(context, 16),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
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
                              'Continue',
                              style: FontScaling.getButtonText(context).copyWith(
                                color: Color(0xFF1A2238),
                              ),
                            ),
                          ),
                        ),
                      ],
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