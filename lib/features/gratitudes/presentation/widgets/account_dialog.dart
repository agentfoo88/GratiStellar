import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/user_profile_manager.dart';
import '../../../../services/user_scoped_storage.dart';
import '../../../../screens/sign_in_screen.dart';
import '../../../../widgets/scrollable_dialog_content.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/accessibility/semantic_helper.dart';
import 'profile_switcher_dialog.dart';

/// Account dialog widget for displaying and editing user account information
class AccountDialog extends StatefulWidget {
  final AuthService authService;
  final VoidCallback? onSignOut;
  final VoidCallback? onSignIn;

  const AccountDialog({
    super.key,
    required this.authService,
    this.onSignOut,
    this.onSignIn,
  });

  @override
  State<AccountDialog> createState() => _AccountDialogState();

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
}

class _AccountDialogState extends State<AccountDialog> {
  late TextEditingController _displayNameController;
  bool _isLoadingName = false; // Start as false so field is enabled immediately
  bool _hasInitialized = false;
  bool _isSaving = false; // Prevent reload while saving
  String? _lastUserId; // Track last user ID to detect changes

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set initial text after inherited widgets are available (only once, and not while saving)
    if (!_hasInitialized && !_isSaving) {
      _hasInitialized = true;
      final l10n = AppLocalizations.of(context)!;
      _displayNameController.text = l10n.defaultUserName;
      _loadDisplayName();
    } else {
      // Check if user has changed (e.g., profile switch)
      _checkForUserChange();
    }
  }

  /// Check if the active user has changed and reload if needed
  Future<void> _checkForUserChange() async {
    if (widget.authService.hasEmailAccount) {
      // Email users don't change via profile switching
      return;
    }
    
    try {
      final userProfileManager = Provider.of<UserProfileManager>(context, listen: false);
      final currentUserId = await userProfileManager.getOrCreateActiveUserId();
      
      // If user ID changed, reload display name
      if (_lastUserId != null && _lastUserId != currentUserId) {
        AppLogger.data('🔄 User changed from $_lastUserId to $currentUserId, reloading display name');
        _lastUserId = currentUserId;
        await _loadDisplayName();
      } else {
        // First time, just track it
        _lastUserId ??= currentUserId;
      }
    } catch (e) {
      AppLogger.error('⚠️ Error checking for user change: $e');
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _loadDisplayName() async {
    try {
      final l10n = AppLocalizations.of(context)!;
      String displayName = l10n.defaultUserName;
      
      if (widget.authService.hasEmailAccount) {
        // For email users, get from Firebase
        final name = await widget.authService.getDisplayName(defaultName: l10n.defaultUserName);
        displayName = name ?? l10n.defaultUserName;
      } else {
        // For anonymous users, get from local storage
        final userProfileManager = Provider.of<UserProfileManager>(context, listen: false);
        final userId = await userProfileManager.getOrCreateActiveUserId();
        
        // Track current user ID
        _lastUserId = userId;
        
        // Use helper method to get display name (handles both Firebase UID and device-based IDs)
        displayName = await UserScopedStorage.getDisplayName(userId, defaultName: l10n.defaultUserName);
        AppLogger.data('📖 Loaded display name: $displayName for userId: $userId');
      }
      
      if (mounted) {
        setState(() {
          _displayNameController.text = displayName;
          _isLoadingName = false; // Always set to false, even on error
        });
      }
    } catch (e) {
      // On error, still enable the field with default name
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _displayNameController.text = l10n.defaultUserName;
          _isLoadingName = false; // Enable field even if loading failed
        });
      }
    }
  }

  void _handleSignOut(BuildContext context) {
    Navigator.pop(context); // Close account dialog
    widget.onSignOut?.call();
  }

  void _handleSignIn(BuildContext context) {
    Navigator.pop(context); // Close account dialog
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignInScreen()),
    );
    widget.onSignIn?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
        child: ScrollableDialogContent(
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
              Column(
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
                          controller: _displayNameController,
                          enabled: !_isLoadingName, // Enable once name is loaded
                          readOnly: false,
                          textCapitalization: TextCapitalization.sentences,
                          style: FontScaling.getInputText(context),
                          textAlign: TextAlign.center,
                          onTap: () {
                            // Select all text when field is tapped
                            _displayNameController.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: _displayNameController.text.length,
                            );
                          },
                          decoration: InputDecoration(
                            labelText: l10n.displayNameLabel,
                            labelStyle: FontScaling.getBodySmall(context),
                            hintText: l10n.displayNameLabel,
                            hintStyle: FontScaling.getInputHint(context),
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
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
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
                            final newName = _displayNameController.text.trim();
                            if (newName.isEmpty) {
                              // Use root Navigator context to ensure SnackBar appears on top of dialog
                              final rootContext = Navigator.of(context, rootNavigator: true).context;
                              ScaffoldMessenger.of(rootContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.errorNameRequired,
                                    style: FontScaling.getBodySmall(context).copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: EdgeInsets.all(16),
                                ),
                              );
                              return;
                            }
                          
                          try {
                            // Set saving flag to prevent reload
                            setState(() {
                              _isSaving = true;
                            });

                            if (widget.authService.hasEmailAccount) {
                              // For email users, update via AuthService
                              await widget.authService.updateDisplayName(newName);
                            } else {
                              // For anonymous users, update in local storage
                              final userProfileManager = Provider.of<UserProfileManager>(context, listen: false);
                              final userId = await userProfileManager.getOrCreateActiveUserId();
                              AppLogger.data('💾 Saving display name for userId: $userId');
                              
                              // Get device ID (handles both Firebase UID and device-based IDs)
                              String? deviceId = await UserScopedStorage.getDeviceIdFromUserId(userId);
                              
                              // If no device ID found (shouldn't happen, but handle gracefully)
                              if (deviceId == null) {
                                // Create device ID for this Firebase anonymous user
                                final prefs = await SharedPreferences.getInstance();
                                final timestamp = DateTime.now().millisecondsSinceEpoch;
                                final random = DateTime.now().microsecondsSinceEpoch % 1000000;
                                deviceId = 'device_${timestamp}_$random';
                                await prefs.setString('device_id', deviceId);
                                AppLogger.data('💾 Created new device ID: $deviceId');
                              }
                              
                              await UserScopedStorage.setAnonymousDisplayName(deviceId, newName);
                              AppLogger.success('✅ Display name saved: $newName');
                              
                              // Verify it was saved
                              final savedName = await UserScopedStorage.getAnonymousDisplayName(deviceId);
                              AppLogger.data('💾 Verified saved name: $savedName');
                              
                              if (savedName != newName) {
                                AppLogger.error('⚠️ Name mismatch! Expected: $newName, Got: $savedName');
                              }
                            }

                            // Update controller text to reflect saved value
                            if (context.mounted) {
                              setState(() {
                                _displayNameController.text = newName;
                                _isSaving = false;
                              });
                            }

                            if (context.mounted) {
                              // Use root Navigator context to ensure SnackBar appears on top of dialog
                              final rootContext = Navigator.of(context, rootNavigator: true).context;
                              ScaffoldMessenger.of(rootContext).showSnackBar(
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
                            }
                          } catch (e) {
                            AppLogger.error('❌ Error updating display name: $e');
                            if (context.mounted) {
                              // Use root Navigator context to ensure SnackBar appears on top of dialog
                              final rootContext = Navigator.of(context, rootNavigator: true).context;
                              ScaffoldMessenger.of(rootContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.errorNameUpdateFailed,
                                    style: FontScaling.getBodySmall(context).copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: EdgeInsets.all(16),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFE135),
                          padding: EdgeInsets.symmetric(
                            vertical: FontScaling.getResponsiveSpacing(
                                    context, 16) *
                                UIConstants.universalUIScale,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          l10n.updateButton,
                          style: FontScaling.getButtonText(context).copyWith(
                            color: Color(0xFF1A2238),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                  ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                // Account info
                if (widget.authService.hasEmailAccount)
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
                            widget.authService.currentUser?.email ?? '',
                            style: FontScaling.getBodySmall(
                              context,
                            ).copyWith(color: Colors.white.withValues(alpha: 0.7)),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Profile switching section (only for anonymous users)
                if (!widget.authService.hasEmailAccount) ...[
                  SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                  SemanticHelper.label(
                    label: l10n.switchProfile,
                    hint: l10n.switchProfile,
                    isButton: true,
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // Show profile switcher and wait for it to close
                          await ProfileSwitcherDialog.show(
                            context: context,
                            authService: widget.authService,
                          );
                          // Reload display name after profile switch
                          if (mounted) {
                            await _checkForUserChange();
                          }
                        },
                        icon: Icon(
                          Icons.swap_horiz,
                          color: Color(0xFFFFE135),
                        ),
                        label: Text(
                          l10n.switchProfile,
                          style: FontScaling.getButtonText(context),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Color(0xFFFFE135).withValues(alpha: 0.5),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: FontScaling.getResponsiveSpacing(context, 16),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Show "Sign in with Email" for anonymous users
                    if (!widget.authService.hasEmailAccount)
                    TextButton(
                      onPressed: () => _handleSignIn(context),
                      child: Text(
                        l10n.signInWithEmailMenuItem,
                        style: FontScaling.getButtonText(context).copyWith(
                          color: Color(0xFFFFE135),
                        ),
                      ),
                    ),
                  // Always show "Sign Out"
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
                      padding: EdgeInsets.symmetric(
                        vertical: FontScaling.getResponsiveSpacing(context, 16),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

