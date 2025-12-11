import 'package:flutter/material.dart';

import '../core/accessibility/semantic_helper.dart';
import '../core/error/error_context.dart';
import '../core/error/error_handler.dart';
import '../font_scaling.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';

/// Dialog for resetting user password via email
class PasswordResetDialog extends StatefulWidget {
  final AuthService authService;

  const PasswordResetDialog({
    super.key,
    required this.authService,
  });

  @override
  State<PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<PasswordResetDialog> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _handleReset() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = l10n.errorEmailPassword;
      });
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _errorMessage = l10n.errorValidEmail;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.sendPasswordResetEmail(email);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.passwordResetEmailSent,
                    style: FontScaling.getBodySmall(context).copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e, stack) {
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

    return AlertDialog(
      backgroundColor: Color(0xFF1A2238),
      title: Text(
        l10n.passwordResetTitle,
        style: FontScaling.getHeadingMedium(context).copyWith(
          color: Color(0xFFFFE135),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.passwordResetMessage,
              style: FontScaling.getBodyMedium(context).copyWith(
                color: Colors.white70,
              ),
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
            SemanticHelper.label(
              label: l10n.emailLabel,
              hint: l10n.emailHint,
              child: TextField(
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                style: FontScaling.getInputText(context),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.emailLabel,
                  labelStyle: FontScaling.getBodySmall(context),
                  hintText: l10n.emailHint,
                  hintStyle: FontScaling.getInputHint(context),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  prefixIcon: Icon(Icons.email, color: Color(0xFFFFE135)),
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
                onSubmitted: (_) => _handleReset(),
              ),
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
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
                    Icon(Icons.error_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            l10n.cancel,
            style: FontScaling.getButtonText(context).copyWith(
              color: Colors.white70,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleReset,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFFE135),
            foregroundColor: Color(0xFF1A2238),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A2238)),
                  ),
                )
              : Text(
                  l10n.sendResetEmail,
                  style: FontScaling.getButtonText(context).copyWith(
                    color: Color(0xFF1A2238),
                  ),
                ),
        ),
      ],
    );
  }
}

