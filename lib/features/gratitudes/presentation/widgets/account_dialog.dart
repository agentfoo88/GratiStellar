import 'package:flutter/material.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth_service.dart';
import '../../../../screens/sign_in_screen.dart';

/// Account dialog widget for displaying and editing user account information
class AccountDialog extends StatelessWidget {
  final AuthService authService;
  final VoidCallback? onSignOut;
  final VoidCallback? onSignIn;

  const AccountDialog({
    super.key,
    required this.authService,
    this.onSignOut,
    this.onSignIn,
  });

  static void show({
    required BuildContext context,
    required AuthService authService,
    VoidCallback? onSignOut,
    VoidCallback? onSignIn,
  }) {
    showDialog(
      context: context,
      builder: (context) => AccountDialog(
        authService: authService,
        onSignOut: onSignOut,
        onSignIn: onSignIn,
      ),
    );
  }

  void _handleSignOut(BuildContext context) {
    Navigator.pop(context); // Close account dialog
    onSignOut?.call();
  }

  void _handleSignIn(BuildContext context) {
    Navigator.pop(context); // Close account dialog
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignInScreen()),
    );
    onSignIn?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayNameController = TextEditingController(
      text: authService.currentUser?.displayName ?? l10n.defaultUserName,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: 500, minWidth: 300),
        padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 24)),
        decoration: BoxDecoration(
          color: Color(0xFF1A2238).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Color(0xFFFFE135).withValues(alpha: 0.3),
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
                Icons.account_circle,
                color: Color(0xFFFFE135),
                size: FontScaling.getResponsiveIconSize(context, 48),
              ),
              SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
              // Title
              Text(
                l10n.accountTitle,
                style: FontScaling.getModalTitle(context),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
              // Content
              StatefulBuilder(
        builder: (context, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Account Name and Icon
              Container(
                padding: EdgeInsets.all(
                  FontScaling.getResponsiveSpacing(context, 16),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Avatar placeholder (for future)
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFFFFE135).withValues(alpha: 0.2),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Color(0xFFFFE135),
                      ),
                    ),
                    SizedBox(
                      height: FontScaling.getResponsiveSpacing(context, 12),
                    ),

                    // Display name field
                    TextField(
                      controller: displayNameController,
                      textCapitalization: TextCapitalization.sentences,
                      style: FontScaling.getInputText(context),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: l10n.displayNameLabel,
                        labelStyle: FontScaling.getBodySmall(context),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color(0xFFFFE135).withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color(0xFFFFE135).withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color(0xFFFFE135),
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      height: FontScaling.getResponsiveSpacing(context, 12),
                    ),

                    // Update button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final newName = displayNameController.text.trim();
                          if (newName.isNotEmpty &&
                              newName != authService.currentUser?.displayName) {
                            await authService.updateDisplayName(newName);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          l10n.displayNameUpdated,
                                          style: FontScaling.getBodySmall(
                                            context,
                                          ).copyWith(color: Colors.white),
                                          overflow: TextOverflow.ellipsis,
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
                                  duration: Duration(seconds: 2),
                                ),
                              );

                              // Refresh the UI
                              setDialogState(() {});
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFE135),
                          padding: EdgeInsets.symmetric(
                            vertical: FontScaling.getResponsiveSpacing(
                              context,
                              12,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          l10n.updateButton,
                          style: FontScaling.getButtonText(
                            context,
                          ).copyWith(color: Color(0xFF1A2238)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),

              // Email (read-only)
              Container(
                padding: EdgeInsets.all(
                  FontScaling.getResponsiveSpacing(context, 12),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.email,
                      color: Color(0xFFFFE135),
                      size: FontScaling.getResponsiveIconSize(context, 20),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authService.currentUser?.email ?? '',
                        style: FontScaling.getBodySmall(
                          context,
                        ).copyWith(color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Show "Sign in with Email" for anonymous users
                  if (!authService.hasEmailAccount)
                    TextButton(
                      onPressed: () => _handleSignIn(context),
                      child: Text(
                        l10n.signInWithEmailMenuItem,
                        style: FontScaling.getButtonText(context).copyWith(
                          color: Color(0xFFFFE135),
                        ),
                      ),
                    ),
                  // Show "Sign Out" for email users
                  if (authService.hasEmailAccount)
                    TextButton(
                      onPressed: () => _handleSignOut(context),
                      child: Text(
                        l10n.signOutButton,
                        style: FontScaling.getButtonText(context).copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFE135),
                      foregroundColor: Color(0xFF1A2238),
                      padding: EdgeInsets.symmetric(
                        horizontal: FontScaling.getResponsiveSpacing(context, 16),
                        vertical: FontScaling.getResponsiveSpacing(context, 12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      l10n.closeButton,
                      style: FontScaling.getButtonText(context).copyWith(
                        color: Color(0xFF1A2238),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
            ],
          ),
        ),
      ),
    );
  }
}

