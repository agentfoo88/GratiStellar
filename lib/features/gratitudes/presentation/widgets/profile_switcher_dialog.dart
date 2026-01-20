import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/user_profile_manager.dart';
import '../../../../services/user_scoped_storage.dart';
import '../../../../services/auth_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/accessibility/semantic_helper.dart';
import '../../../../features/gratitudes/presentation/state/galaxy_provider.dart';
import '../../../../features/gratitudes/presentation/state/gratitude_provider.dart';

/// Dialog for switching between anonymous profiles
class ProfileSwitcherDialog extends StatefulWidget {
  final AuthService authService;

  const ProfileSwitcherDialog({
    super.key,
    required this.authService,
  });

  @override
  State<ProfileSwitcherDialog> createState() => _ProfileSwitcherDialogState();

  static Future<void> show({
    required BuildContext context,
    required AuthService authService,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => ProfileSwitcherDialog(authService: authService),
    );
  }
}

class _ProfileSwitcherDialogState extends State<ProfileSwitcherDialog> {
  List<String> _userIds = [];
  String? _activeUserId;
  final Map<String, String> _displayNames = {};
  final Map<String, int> _starCounts = {};
  final Map<String, int> _galaxyCounts = {};
  bool _isLoading = true;
  bool _hasLoaded = false; // Track if we've already loaded

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load profiles after dependencies are available (context is ready)
    // Only load once
    if (!_hasLoaded) {
      _hasLoaded = true;
      _loadProfiles();
    }
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get default name from l10n - context is now available
      final l10n = AppLocalizations.of(context);
      final defaultName = l10n?.defaultUserName ?? 'Grateful User';
      
      final userProfileManager = Provider.of<UserProfileManager>(context, listen: false);
      _activeUserId = await userProfileManager.getOrCreateActiveUserId();
      
      AppLogger.data('🔍 Loading profiles - activeUserId: $_activeUserId');
      
      // Start with current user if anonymous (always show at least current user)
      _userIds = [];
      if (_activeUserId != null && _activeUserId!.startsWith('anonymous_')) {
        _userIds.add(_activeUserId!);
        AppLogger.data('📝 Added current user to list: $_activeUserId');
      }
      
      // Get all local user IDs (anonymous profiles only)
      final allUserIds = await UserScopedStorage.getLocalUserIds();
      AppLogger.data('🔍 Found ${allUserIds.length} tracked user IDs: ${allUserIds.join(", ")}');
      
      // Add tracked anonymous users (avoid duplicates)
      for (final userId in allUserIds) {
        if (userId.startsWith('anonymous_') && !_userIds.contains(userId)) {
          _userIds.add(userId);
        }
      }
      
      // Ensure current user is tracked for future loads
      if (_activeUserId != null && _activeUserId!.startsWith('anonymous_')) {
        await UserScopedStorage.trackUserHasData(_activeUserId!);
      }
      
      AppLogger.data('📋 Final profile list (${_userIds.length} profiles): ${_userIds.join(", ")}');
      
      // Load display names and counts for each profile
      for (final userId in _userIds) {
        // Get display name - use l10n default instead of hardcoded "Anonymous User"
        final displayName = await UserScopedStorage.getDisplayName(userId, defaultName: defaultName);
        _displayNames[userId] = displayName;
        
        // Load actual star and galaxy counts
        try {
          final stars = await UserScopedStorage.loadStars(userId);
          final galaxies = await UserScopedStorage.loadGalaxies(userId);
          _starCounts[userId] = stars.where((s) => !s.deleted).length;
          _galaxyCounts[userId] = galaxies.where((g) => !g.deleted).length;
          AppLogger.data('📊 Profile $userId: ${_starCounts[userId]} stars, ${_galaxyCounts[userId]} galaxies');
        } catch (e) {
          AppLogger.error('⚠️ Error loading counts for user $userId: $e');
          _starCounts[userId] = 0;
          _galaxyCounts[userId] = 0;
        }
      }
      
      AppLogger.data('✅ Loaded ${_userIds.length} profiles successfully');
    } catch (e, stackTrace) {
      AppLogger.error('⚠️ Error loading profiles: $e');
      AppLogger.error('Stack trace: $stackTrace');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _switchProfile(String userId) async {
    if (!mounted) return;
    
    try {
      final userProfileManager = Provider.of<UserProfileManager>(context, listen: false);
      await userProfileManager.switchUser(userId);
      
      if (!mounted) return;
      
      // Reload data for the new profile
      final galaxyProvider = Provider.of<GalaxyProvider>(context, listen: false);
      final gratitudeProvider = Provider.of<GratitudeProvider>(context, listen: false);
      
      // Reset initialization flag so galaxy system reinitializes for new user
      galaxyProvider.resetInitialization();
      
      // Load galaxies and initialize (sets active galaxy)
      await galaxyProvider.initialize();
      await gratitudeProvider.loadGratitudes();
      
      // Update active user ID in this dialog
      if (mounted) {
        setState(() {
          _activeUserId = userId;
        });
      }
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Switched to ${_displayNames[userId] ?? "profile"}',
              style: FontScaling.getBodyMedium(context),
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('⚠️ Error switching profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to switch profile',
              style: FontScaling.getBodyMedium(context),
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _createNewProfile() async {
    if (!mounted) return;
    
    try {
      final userProfileManager = Provider.of<UserProfileManager>(context, listen: false);
      final newUserId = await userProfileManager.createAnonymousProfile();
      
      AppLogger.data('✨ Created new profile: $newUserId');
      
      if (!mounted) return;
      
      // Switch to new profile first (before reloading list)
      await userProfileManager.switchUser(newUserId);
      
      if (!mounted) return;
      
      // Reload data for the new profile
      final galaxyProvider = Provider.of<GalaxyProvider>(context, listen: false);
      final gratitudeProvider = Provider.of<GratitudeProvider>(context, listen: false);
      
      // Reset initialization flag so galaxy system reinitializes for new user
      galaxyProvider.resetInitialization();
      
      // Initialize galaxy system (sets active galaxy)
      await galaxyProvider.initialize();
      await gratitudeProvider.loadGratitudes();
      
      // Reload profiles list to show the new one
      await _loadProfiles();
      
      // Update active user ID and refresh UI
      if (mounted) {
        setState(() {
          _activeUserId = newUserId;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Created new profile',
              style: FontScaling.getBodyMedium(context),
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('⚠️ Error creating new profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to create profile',
              style: FontScaling.getBodyMedium(context),
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteProfile(String userId) async {
    if (userId == _activeUserId) {
      // Can't delete active profile
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot delete active profile',
              style: FontScaling.getBodyMedium(context),
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundDark,
        title: Text(
          l10n.deleteProfile,
          style: FontScaling.getHeadingMedium(context).copyWith(
            color: AppTheme.primary,
          ),
        ),
        content: Text(
          l10n.deleteProfileConfirm,
          style: FontScaling.getBodyMedium(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l10n.cancelButton,
              style: FontScaling.getButtonText(context),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.deleteProfile,
              style: FontScaling.getButtonText(context).copyWith(
                color: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await UserScopedStorage.clearUserData(userId);
        await _loadProfiles();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profile deleted',
                style: FontScaling.getBodyMedium(context),
              ),
            ),
          );
        }
      } catch (e) {
        AppLogger.error('⚠️ Error deleting profile: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to delete profile',
                style: FontScaling.getBodyMedium(context),
              ),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: AppTheme.backgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(
          color: AppTheme.primary,
          width: 2,
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                l10n.switchProfileTitle,
                style: FontScaling.getHeadingMedium(context).copyWith(
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              // Loading indicator
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                )
              else if (_userIds.isEmpty)
                // Empty state
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No profiles found',
                    style: FontScaling.getBodyMedium(context),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                // Profile list
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _userIds.length,
                  itemBuilder: (context, index) {
                    final userId = _userIds[index];
                    final defaultName = l10n.defaultUserName;
                    final displayName = _displayNames[userId] ?? defaultName;
                    final isActive = userId == _activeUserId;

                    return InkWell(
                      onTap: !isActive ? () => _switchProfile(userId) : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Card(
                        color: isActive
                            ? AppTheme.overlayLight
                            : Colors.white.withValues(alpha: 0.05),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: FontScaling.getBodyMedium(context).copyWith(
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isActive)
                                Text(
                                  l10n.currentProfile,
                                  style: FontScaling.getBodySmall(context).copyWith(
                                    color: AppTheme.primary,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            '${_starCounts[userId] ?? 0} ${l10n.profileStars}, ${_galaxyCounts[userId] ?? 0} ${l10n.profileGalaxies}',
                            style: FontScaling.getBodySmall(context),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isActive)
                                IconButton(
                                  icon: const Icon(Icons.swap_horiz),
                                  color: AppTheme.primary,
                                  onPressed: () => _switchProfile(userId),
                                  tooltip: l10n.switchProfile,
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: AppTheme.error,
                                onPressed: () => _deleteProfile(userId),
                                tooltip: l10n.deleteProfile,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 16),

              // Create new profile button
              SemanticHelper.label(
                label: l10n.createNewProfile,
                hint: l10n.createNewProfile,
                isButton: true,
                child: ElevatedButton(
                  onPressed: _createNewProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    l10n.createNewProfile,
                    style: FontScaling.getButtonText(context).copyWith(
                      color: AppTheme.textOnPrimary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Close button
              SemanticHelper.label(
                label: l10n.closeButton,
                hint: l10n.closeButton,
                isButton: true,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    l10n.closeButton,
                    style: FontScaling.getButtonText(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

