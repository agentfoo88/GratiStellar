import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../font_scaling.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';

class ChangePasswordDialog extends StatefulWidget {
  final AuthService authService;

  const ChangePasswordDialog({
    super.key,
    required this.authService,
  });

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    final l10n = AppLocalizations.of(context)!;
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validation
    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = l10n.errorAllFieldsRequired;
      });
      return;
    }

    if (newPassword.length < 6) {
      setState(() {
        _errorMessage = l10n.errorPasswordLength;
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _errorMessage = l10n.errorPasswordsDoNotMatch;
      });
      return;
    }

    if (currentPassword == newPassword) {
      setState(() {
        _errorMessage = l10n.errorSamePassword;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return success

        // Show success message on parent screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.passwordChangedSuccess,
                    style: FontScaling.getBodySmall(context).copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'wrong-password') {
        errorMessage = l10n.errorCurrentPasswordIncorrect;
      } else {
        errorMessage = l10n.errorPasswordChangeFailed;
      }

      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = l10n.errorPasswordChangeFailed;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !_isLoading,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 24)),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2238).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFFE135).withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Icon(
                Icons.lock_reset,
                color: const Color(0xFFFFE135),
                size: FontScaling.getResponsiveIconSize(context, 48),
              ),
              SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),

              // Title
              Text(
                l10n.changePasswordTitle,
                style: FontScaling.getHeadingMedium(context).copyWith(
                  color: AppTheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),

              // Current password field
              TextField(
                controller: _currentPasswordController,
                enabled: !_isLoading,
                obscureText: !_showCurrentPassword,
                style: FontScaling.getInputText(context),
                decoration: InputDecoration(
                  labelText: l10n.currentPasswordLabel,
                  labelStyle: FontScaling.getBodySmall(context),
                  hintText: l10n.currentPasswordHint,
                  hintStyle: FontScaling.getInputHint(context),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFFFFE135)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showCurrentPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    onPressed: () {
                      setState(() {
                        _showCurrentPassword = !_showCurrentPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: const Color(0xFFFFE135).withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
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
              ),
              SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),

              // New password field
              TextField(
                controller: _newPasswordController,
                enabled: !_isLoading,
                obscureText: !_showNewPassword,
                style: FontScaling.getInputText(context),
                decoration: InputDecoration(
                  labelText: l10n.newPasswordLabel,
                  labelStyle: FontScaling.getBodySmall(context),
                  hintText: l10n.newPasswordHint,
                  hintStyle: FontScaling.getInputHint(context),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFFFE135)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showNewPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    onPressed: () {
                      setState(() {
                        _showNewPassword = !_showNewPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: const Color(0xFFFFE135).withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
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
              ),
              SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),

              // Confirm new password field
              TextField(
                controller: _confirmPasswordController,
                enabled: !_isLoading,
                obscureText: !_showConfirmPassword,
                style: FontScaling.getInputText(context),
                decoration: InputDecoration(
                  labelText: l10n.confirmPasswordLabel,
                  labelStyle: FontScaling.getBodySmall(context),
                  hintText: l10n.confirmPasswordHint,
                  hintStyle: FontScaling.getInputHint(context),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFFFE135)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    onPressed: () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: const Color(0xFFFFE135).withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
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
                onSubmitted: (_) => _handleChangePassword(),
              ),

              // Error message
              if (_errorMessage != null) ...[
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                Container(
                  padding: EdgeInsets.all(
                    FontScaling.getResponsiveSpacing(context, 12),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: FontScaling.getBodySmall(context).copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      l10n.cancel,
                      style: FontScaling.getButtonText(context).copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleChangePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE135),
                      padding: EdgeInsets.symmetric(
                        horizontal: FontScaling.getResponsiveSpacing(context, 24),
                        vertical: FontScaling.getResponsiveSpacing(context, 16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF1A2238),
                              ),
                            ),
                          )
                        : Text(
                            l10n.changePasswordButton,
                            style: FontScaling.getButtonText(context).copyWith(
                              color: const Color(0xFF1A2238),
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
