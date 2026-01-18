import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/error/error_context.dart';
import '../core/error/error_handler.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_logger.dart';
import '../features/gratitudes/data/datasources/galaxy_remote_data_source.dart';
import '../features/gratitudes/presentation/state/galaxy_provider.dart';
import '../features/gratitudes/presentation/state/gratitude_provider.dart';
import '../font_scaling.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/data_migration_service.dart';
import '../services/firestore_service.dart';
import '../services/user_profile_manager.dart';
import '../services/user_scoped_storage.dart';
import '../storage.dart';
import '../widgets/password_reset_dialog.dart';
import 'gratitude_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSignUp = false;

  @override
  void initState() {
    super.initState();
    _loadAnonymousName();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  /// Load anonymous user's name to pre-fill in sign-up form
  Future<void> _loadAnonymousName() async {
    if (_authService.hasEmailAccount) {
      return; // Don't load if already signed in
    }

    try {
      final userProfileManager = Provider.of<UserProfileManager>(context, listen: false);
      final userId = await userProfileManager.getOrCreateActiveUserId();
      if (userId.startsWith('anonymous_')) {
        final deviceId = userId.replaceFirst('anonymous_', '');
        final name = await UserScopedStorage.getAnonymousDisplayName(deviceId);
        if (name != null && mounted) {
          setState(() {
            _nameController.text = name;
          });
        }
      }
    } catch (e) {
      AppLogger.error('Error loading anonymous name: $e');
    }
  }

  /// Trigger cloud sync after sign-in
  /// Returns true if sync completed successfully, false if cancelled or failed
  Future<bool> _triggerCloudSync() async {
    final currentUser = _authService.currentUser;

    // #region agent log
    if (kDebugMode) {
      AppLogger.sync('🔄 DEBUG: _triggerCloudSync started - user=${currentUser?.uid}, isAnonymous=${currentUser?.isAnonymous}, hasEmailAccount=${_authService.hasEmailAccount}');
    }
    // #endregion

    final firestoreService = FirestoreService();
    final currentUserId = currentUser?.uid;

    if (currentUserId == null) {
      AppLogger.sync('⚠️ No user signed in, skipping sync');
      return false;
    }

    try {
      if (!mounted) {
        AppLogger.sync('⚠️ Widget not mounted, skipping sync');
        return false;
      }

      final galaxyProvider = context.read<GalaxyProvider>();

      // STEP 0: Check for anonymous data and prompt for migration BEFORE syncing
      final anonymousUserId = await _checkForAnonymousData();
      if (anonymousUserId != null && mounted) {
        AppLogger.auth('🔍 Found anonymous data from user: $anonymousUserId');
        final migrationChoice = await _showAnonymousDataMigrationDialog(anonymousUserId);
        
        if (migrationChoice == true) {
          // User chose to merge
          AppLogger.auth('🔀 User chose to merge anonymous data');
          try {
            final migrationService = DataMigrationService(
              firestoreService: firestoreService,
              galaxyRemoteDataSource: GalaxyRemoteDataSource(
                authService: _authService,
              ),
            );
            
            final result = await migrationService.migrateAnonymousToEmail(
              anonymousUserId,
              currentUserId,
            );
            
            AppLogger.success(
              '✅ Migration complete - merged: ${result.merged}, '
              'local: ${result.localStarsCount} stars/${result.localGalaxiesCount} galaxies, '
              'cloud: ${result.cloudStarsCount} stars/${result.cloudGalaxiesCount} galaxies',
            );
            
            // Reload galaxies after migration (they're now in email user's storage)
            await galaxyProvider.loadGalaxies();
            
            // Reload gratitudes after migration
            if (mounted) {
              final gratitudeProvider = context.read<GratitudeProvider>();
              await gratitudeProvider.loadGratitudes();
            }
          } catch (e, stack) {
            AppLogger.error('❌ Migration failed: $e');
            AppLogger.error('Stack trace: $stack');
            // Continue with sync even if migration fails
          }
        } else if (migrationChoice == false) {
          // User chose to delete
          AppLogger.auth('🗑️ User chose to delete anonymous data');
          try {
            await UserScopedStorage.clearUserData(anonymousUserId);
            AppLogger.success('✅ Deleted anonymous data for user: $anonymousUserId');
          } catch (e) {
            AppLogger.error('⚠️ Error deleting anonymous data: $e');
            // Continue with sync even if deletion fails
          }
        } else {
          // User cancelled - abort sign-in
          AppLogger.auth('❌ User cancelled migration, aborting sign-in');
          return false;
        }
      }

      // STEP 1: Check for empty default galaxies BEFORE syncing
      // Load local galaxies first to check for empty "My First Galaxy"
      await galaxyProvider.loadGalaxies();
      final localGalaxiesBeforeSync = galaxyProvider.galaxies;
      
      // Detect empty default galaxies
      final emptyDefaultGalaxies = localGalaxiesBeforeSync.where((galaxy) {
        return galaxy.name == kDefaultGalaxyName &&
               galaxy.starCount == 0 &&
               !galaxy.deleted;
      }).toList();
      
      // Check if cloud has galaxies with stars (before syncing)
      bool cloudHasRealGalaxies = false;
      if (emptyDefaultGalaxies.isNotEmpty) {
        try {
          final hasCloudData = await firestoreService.hasCloudData();
          if (hasCloudData) {
            // Load cloud galaxies directly from Firestore to check if they have stars
            // currentUserId is guaranteed to be non-null here (checked earlier)
            final cloudGalaxiesSnapshot = await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUserId)
                .collection('galaxyMetadata')
                .get();
            
            final cloudGalaxies = cloudGalaxiesSnapshot.docs
                .map((doc) => doc.data())
                .toList();
            
            // Check if any cloud galaxy has stars
            cloudHasRealGalaxies = cloudGalaxies.any((galaxyData) {
              final starCount = galaxyData['starCount'] as int? ?? 0;
              return starCount > 0;
            });
            
            AppLogger.sync('🔍 Checked cloud galaxies: ${cloudGalaxies.length} total, ${cloudGalaxies.where((g) => (g['starCount'] as int? ?? 0) > 0).length} with stars');
          }
        } catch (e) {
          AppLogger.sync('⚠️ Could not check cloud galaxies: $e');
          // Continue anyway - will handle during sync
        }
      }
      
      // Ask user if they want to delete empty default galaxies
      if (emptyDefaultGalaxies.isNotEmpty && cloudHasRealGalaxies && mounted) {
        final shouldDelete = await _askToDeleteEmptyGalaxies(emptyDefaultGalaxies);
        if (shouldDelete == true) {
          // Check if any empty galaxy is the active one
          final activeGalaxyId = galaxyProvider.activeGalaxyId;
          final deletingActiveGalaxy = emptyDefaultGalaxies.any((g) => g.id == activeGalaxyId);
          
          // Delete empty default galaxies
          for (final galaxy in emptyDefaultGalaxies) {
            try {
              await galaxyProvider.deleteGalaxy(galaxy.id);
              AppLogger.sync('🗑️ Deleted empty default galaxy: ${galaxy.name} (${galaxy.id})');
            } catch (e) {
              AppLogger.error('⚠️ Failed to delete empty galaxy ${galaxy.id}: $e');
            }
          }
          
          // Reload galaxies after deletion
          await galaxyProvider.loadGalaxies();
          
          // Ensure active galaxy is valid (not deleted)
          // The getActiveGalaxyId() method now validates this automatically,
          // but we need to ensure the provider's state is updated
          final currentActiveId = galaxyProvider.activeGalaxyId;
          if (currentActiveId != null) {
            // Check if current active galaxy still exists and is not deleted
            final activeGalaxies = galaxyProvider.activeGalaxies;
            final activeGalaxyExists = activeGalaxies.any((g) => g.id == currentActiveId);
            
            if (!activeGalaxyExists) {
              // Active galaxy was deleted, switch to first available galaxy
              if (activeGalaxies.isNotEmpty) {
                await galaxyProvider.switchGalaxy(activeGalaxies.first.id);
                AppLogger.sync('🔄 Active galaxy was deleted, switched to: ${activeGalaxies.first.id}');
              } else {
                AppLogger.sync('⚠️ No galaxies remaining after deletion');
              }
            }
          }
          
          if (deletingActiveGalaxy) {
            AppLogger.sync('🔄 Active galaxy was deleted, switched to: ${galaxyProvider.activeGalaxyId}');
          }
        }
      }

      // STEP 2: Sync galaxies FROM cloud first (so stars can reference correct galaxy IDs)
      AppLogger.sync('☁️ STEP 2: Syncing galaxies FROM cloud...');
      bool mergeDetected = false;
      try {
        // Check for merge scenario: if local galaxies exist AND cloud galaxies exist
        final localGalaxies = galaxyProvider.galaxies;
        final localGalaxiesCount = localGalaxies.length;
        final hasLocalGalaxies = localGalaxiesCount > 0;
        
        // Sync from cloud (will merge if local galaxies exist)
        await galaxyProvider.syncFromCloud();
        
        // Check if merge occurred (both local and cloud galaxies existed)
        final galaxiesAfterSync = galaxyProvider.galaxies;
        if (hasLocalGalaxies && galaxiesAfterSync.length > localGalaxiesCount) {
          mergeDetected = true;
          AppLogger.sync('🔀 Merge detected: local=$localGalaxiesCount, after sync=${galaxiesAfterSync.length}');
        }
        
        AppLogger.sync('✅ Galaxies synced from cloud');
      } catch (e) {
        AppLogger.sync('⚠️ Failed to sync galaxies from cloud: $e');
        // If cloud sync fails (e.g., no cloud data), load local galaxies
        if (galaxyProvider.galaxies.isEmpty) {
          AppLogger.sync('📋 Loading local galaxies...');
          await galaxyProvider.loadGalaxies();
        }
      }

      // STEP 3: Sync stars (now that galaxies are synced)
      AppLogger.sync('⭐ STEP 3: Syncing stars...');
      final mergedFromUid = await _checkForMergedAccount();

      if (mergedFromUid != null) {
        AppLogger.auth('🔀 Merging data from anonymous account: $mergedFromUid');
        await firestoreService.mergeStarsFromAnonymousAccount(mergedFromUid, []);
      } else {
        // Load stars FRESH from storage (using user-scoped storage)
        final localStars = await StorageService.loadGratitudeStars();

        AppLogger.sync('🔄 Syncing ${localStars.length} local stars');

        // Check if cloud has data
        final hasCloudData = await firestoreService.hasCloudData();

        if (hasCloudData) {
          AppLogger.sync('📥 Cloud has data, syncing...');
          // Don't just upload - sync to merge
          final mergedStars = await firestoreService.syncStars(localStars);
          
          // #region agent log
          if (kDebugMode) {
            final galaxyIdCounts = <String, int>{};
            for (final star in mergedStars) {
              galaxyIdCounts[star.galaxyId] = (galaxyIdCounts[star.galaxyId] ?? 0) + 1;
            }
            AppLogger.sync('💾 DEBUG: Saving merged stars after sync - total=${mergedStars.length}, by galaxy=${galaxyIdCounts.toString()}');
          }
          // #endregion

          await StorageService.saveGratitudeStars(mergedStars);
          AppLogger.sync('✅ Synced ${mergedStars.length} stars');
        } else {
          AppLogger.sync('📤 No cloud data, uploading local stars...');
          await firestoreService.uploadStars(localStars);
          AppLogger.sync('✅ Uploaded ${localStars.length} stars');
        }
      }

      // STEP 4: Sync galaxies TO cloud (upload any local-only galaxies)
      AppLogger.sync('☁️ STEP 4: Syncing galaxies TO cloud...');
      try {
        await galaxyProvider.syncToCloud();
        AppLogger.sync('✅ All galaxies synced to cloud');
      } catch (e, stack) {
        AppLogger.sync('⚠️ Failed to sync galaxies to cloud: $e');
        AppLogger.info('Stack trace: $stack');
        // Continue anyway - stars are safe
      }

      // STEP 5: Reconcile star counts
      AppLogger.sync('🔍 STEP 5: Reconciling star counts...');
      try {
        // Recalculate all star counts after sync
        // This will be done automatically by galaxyProvider after syncFromCloud
        // But we can trigger it explicitly by reloading galaxies
        await galaxyProvider.loadGalaxies();
        AppLogger.sync('✅ Star counts reconciled');
      } catch (e) {
        AppLogger.sync('⚠️ Failed to reconcile star counts: $e');
        // Non-critical, continue
      }

      // STEP 6: Show merge warning if merge detected
      if (mergeDetected && mounted) {
        _showMergeWarningDialog();
      }

      AppLogger.sync('✅ Cloud sync complete (migration → galaxies → stars → galaxies → reconcile)');
      
      // STEP 7: Reload gratitudes to refresh UI with synced stars
      if (mounted) {
        try {
          final gratitudeProvider = context.read<GratitudeProvider>();
          // #region agent log
          if (kDebugMode) {
            AppLogger.sync('🔄 DEBUG: Reloading gratitudes after sync - activeGalaxyId=${galaxyProvider.activeGalaxyId}');
          }
          // #endregion
          await gratitudeProvider.loadGratitudes(waitForSync: false);
          AppLogger.sync('✅ Gratitudes reloaded after sync');
        } catch (e, stack) {
          AppLogger.sync('⚠️ Failed to reload gratitudes after sync: $e');
          AppLogger.info('Stack trace: $stack');
          // Continue anyway - stars are saved, will load on next app launch
        }
      }
      
      return true;
    } catch (e) {
      AppLogger.sync('⚠️ Cloud sync failed: $e');
      // Don't show error to user - local data is still safe
      // Sync will retry on next app launch or galaxy switch
      return false;
    }
  }

  void _showMergeWarningDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.galaxiesMergedTitle),
        content: Text(l10n.galaxiesMergedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.closeButton),
          ),
        ],
      ),
    );
  }

  /// Ask user if they want to delete empty default galaxies
  /// Returns true if user wants to delete, false if they want to keep, null if cancelled
  Future<bool?> _askToDeleteEmptyGalaxies(List<dynamic> emptyGalaxies) async {
    if (!mounted || emptyGalaxies.isEmpty) return null;
    
    final l10n = AppLocalizations.of(context)!;
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_outline,
                color: Colors.orange.withValues(alpha: 0.8),
                size: FontScaling.getResponsiveIconSize(context, 48),
              ),
              SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
              Text(
                l10n.emptyGalaxyDetectedTitle,
                style: FontScaling.getHeadingMedium(context).copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
              Text(
                l10n.emptyGalaxyDetectedMessage,
                style: FontScaling.getBodySmall(context).copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      l10n.keepEmptyGalaxyButton,
                      style: FontScaling.getButtonText(context).copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(
                        horizontal: FontScaling.getResponsiveSpacing(context, 20),
                        vertical: FontScaling.getResponsiveSpacing(context, 12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      l10n.deleteEmptyGalaxyButton,
                      style: FontScaling.getButtonText(context).copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show dialog asking user what to do with anonymous data
  /// Returns true if merge, false if delete, null if cancelled
  Future<bool?> _showAnonymousDataMigrationDialog(String anonymousUserId) async {
    if (!mounted) return null;

    try {
      // Load data counts for display
      final stars = await UserScopedStorage.loadStars(anonymousUserId);
      final galaxies = await UserScopedStorage.loadGalaxies(anonymousUserId);
      final starsCount = stars.where((s) => !s.deleted).length;
      final galaxiesCount = galaxies.where((g) => !g.deleted).length;

      if (starsCount == 0 && galaxiesCount == 0) {
        // No data to migrate
        return null;
      }

      if (!mounted) return null;
      
      final l10n = AppLocalizations.of(context)!;

      return showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _AnonymousDataMigrationDialog(
          l10n: l10n,
          starsCount: starsCount,
          galaxiesCount: galaxiesCount,
        ),
      );
    } catch (e) {
      AppLogger.error('⚠️ Error showing migration dialog: $e');
      return null;
    }
  }

  Future<String?> _checkForMergedAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      return userDoc.data()?['mergedFromAnonymous'] as String?;
    } catch (e) {
      AppLogger.auth('⚠️ Error checking for merged account: $e');
      return null;
    }
  }

  /// Check for device-based anonymous data that needs migration
  /// Returns anonymous user ID with data, or null if none found or already migrated
  Future<String?> _checkForAnonymousData() async {
    try {
      final emailUser = _authService.currentUser;
      if (emailUser == null) return null;

      // Get all local user IDs
      final allUserIds = await UserScopedStorage.getLocalUserIds();
      
      // Filter for anonymous users
      final anonymousUserIds = allUserIds.where((id) => id.startsWith('anonymous_')).toList();
      
      if (anonymousUserIds.isEmpty) {
        AppLogger.auth('🔍 No anonymous profiles found');
        return null;
      }

      // Check each anonymous user for data and migration status
      final migrationService = DataMigrationService(
        firestoreService: FirestoreService(),
        galaxyRemoteDataSource: GalaxyRemoteDataSource(
          authService: _authService,
        ),
      );

      String? bestCandidate;
      int bestDataCount = 0;

      for (final anonymousUserId in anonymousUserIds) {
        // Check if already migrated
        final migratedTo = await migrationService.getMigratedTo(anonymousUserId);
        if (migratedTo != null) {
          AppLogger.auth('🔍 Anonymous user $anonymousUserId already migrated to $migratedTo');
          continue;
        }

        // Check if user has data
        final stars = await UserScopedStorage.loadStars(anonymousUserId);
        final galaxies = await UserScopedStorage.loadGalaxies(anonymousUserId);
        final activeStars = stars.where((s) => !s.deleted).length;
        final activeGalaxies = galaxies.where((g) => !g.deleted).length;
        final dataCount = activeStars + activeGalaxies;

        if (dataCount > 0) {
          AppLogger.auth('🔍 Found anonymous user $anonymousUserId with $activeStars stars, $activeGalaxies galaxies');
          // Prefer the one with most data
          if (dataCount > bestDataCount) {
            bestCandidate = anonymousUserId;
            bestDataCount = dataCount;
          }
        }
      }

      return bestCandidate;
    } catch (e) {
      AppLogger.error('⚠️ Error checking for anonymous data: $e');
      return null;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
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
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
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

    if (password.length < 6) {
      setState(() {
        _errorMessage = l10n.errorPasswordLength;
      });
      return;
    }

    if (_isSignUp && password != _passwordConfirmController.text) {
      setState(() {
        _errorMessage = l10n.errorPasswordsDoNotMatch;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        // Create new account with email and password
        AppLogger.auth('🆕 Creating new account');
        final user = await _authService.createAccountWithEmailPassword(email, password, name);

        if (user == null) {
          throw Exception('Failed to create account');
        }

        // Send verification email
        try {
          await _authService.sendEmailVerification();
          AppLogger.auth('✅ Verification email sent');
        } catch (e) {
          AppLogger.error('⚠️ Failed to send verification email: $e');
          // Don't fail sign-up if verification email fails
        }

        // Mark current user as local data owner
        await _setLocalDataOwner();

        // Show loading overlay during sync
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => PopScope(
              canPop: false,
              child: Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 24)),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A2238).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFE135)),
                      ),
                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                      Text(
                        'Syncing your data...',
                        style: FontScaling.getBodyMedium(context).copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Trigger sync BEFORE navigation - stars AND galaxies loaded fresh inside sync function
        final syncSuccess = await _triggerCloudSync();

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          
          if (!syncSuccess) {
            // Sync was cancelled or failed - sign out and show error
            await _authService.signOut();
            setState(() {
              _isLoading = false;
              _errorMessage = l10n.signInCancelled;
            });
            return;
          }
          
          // Navigate back to GratitudeScreen - use pushAndRemoveUntil to ensure clean navigation
          // This clears the navigation stack and ensures we're on the main screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => GratitudeScreen()),
            (route) => false, // Remove all previous routes
          );
          
          // Show success message after navigation
          Future.delayed(Duration(milliseconds: 300), () {
            if (mounted) {
              _showSuccessSnackBar(AppLocalizations.of(context)!.accountCreatedWithEmailVerification);
            }
          });
        }
      } else {
        // #region agent log
        if (kDebugMode) {
          AppLogger.auth('🔐 DEBUG: Starting signInWithEmail - email=$email');
        }
        // #endregion

        await _authService.signInWithEmail(email, password);

        // #region agent log
        if (kDebugMode) {
          final userAfterSignIn = _authService.currentUser;
          AppLogger.auth('🔐 DEBUG: After signInWithEmail - user=${userAfterSignIn?.uid}, isAnonymous=${userAfterSignIn?.isAnonymous}, email=${userAfterSignIn?.email}, hasEmailAccount=${_authService.hasEmailAccount}');
        }
        // #endregion

        // Mark current user as local data owner
        await _setLocalDataOwner();

        // Show loading overlay during sync
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => PopScope(
              canPop: false,
              child: Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 24)),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A2238).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFE135)),
                      ),
                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                      Text(
                        'Syncing your data...',
                        style: FontScaling.getBodyMedium(context).copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Trigger sync BEFORE navigation - stars AND galaxies loaded fresh inside sync function
        final syncSuccess = await _triggerCloudSync();

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          
          if (!syncSuccess) {
            // Sync was cancelled or failed - sign out and show error
            await _authService.signOut();
            setState(() {
              _isLoading = false;
              _errorMessage = l10n.signInCancelled;
            });
            return;
          }
          
          // Navigate back to GratitudeScreen - use pushAndRemoveUntil to ensure clean navigation
          // This clears the navigation stack and ensures we're on the main screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => GratitudeScreen()),
            (route) => false, // Remove all previous routes
          );
          
          // Show success message after navigation
          Future.delayed(Duration(milliseconds: 300), () {
            if (mounted) {
              _showSuccessSnackBar(l10n.signInSuccess);
            }
          });
        }
      }
    } catch (e, stack) {
      // Special handling for invalid-credential based on sign-up vs sign-in context
      String errorMessage;

      if (e is FirebaseAuthException && e.code == 'invalid-credential') {
        if (_isSignUp) {
          // During sign-up, invalid-credential usually means email already exists
          errorMessage = mounted && AppLocalizations.of(context) != null
              ? AppLocalizations.of(context)!.errorEmailInUse
              : 'This email is already registered. Try signing in instead.';
        } else {
          // During sign-in, be more specific about what might be wrong
          errorMessage = mounted && AppLocalizations.of(context) != null
              ? AppLocalizations.of(context)!.errorEmailOrPasswordIncorrect
              : 'Email or password incorrect. Double-check your credentials.';
        }
      } else {
        // Handle all other errors with ErrorHandler
        final error = ErrorHandler.handle(
          e,
          stack,
          context: ErrorContext.auth,
          l10n: mounted ? AppLocalizations.of(context) : null,
        );
        errorMessage = error.userMessage;
      }

      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Mark current user as owner of local data
  Future<void> _setLocalDataOwner() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('local_data_owner_uid', user.uid);
        AppLogger.success('✅ Set local data owner: ${user.uid}');
      }
    } catch (e) {
      AppLogger.error('⚠️ Error setting data owner: $e');
      // Non-critical, continue anyway
    }
  }

  void _showPasswordResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PasswordResetDialog(authService: _authService),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              Expanded(
                child: Center(
                  child: Scrollbar(
                    thumbVisibility: false,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(
                        FontScaling.getResponsiveSpacing(context, 24),
                      ),
                      child: Container(
                      constraints: BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isSignUp ? l10n.signUpTitle : l10n.signInTitle,
                            style: FontScaling.getHeadingLarge(context).copyWith(
                              color: Color(0xFFFFE135),
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: FontScaling.getResponsiveSpacing(context, 8)),

                          Text(
                            _isSignUp ? l10n.signUpSubtitle : l10n.signInSubtitle,
                            style: FontScaling.getBodyMedium(context).copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: FontScaling.getResponsiveSpacing(context, 32)),

                          // Name field (only for sign-up)
                          if (_isSignUp) ...[
                            TextField(
                              controller: _nameController,
                              enabled: !_isLoading,
                              textCapitalization: TextCapitalization.words,
                              style: FontScaling.getInputText(context),
                              decoration: InputDecoration(
                                labelText: l10n.nameInputLabel,
                                labelStyle: FontScaling.getBodySmall(context),
                                hintText: l10n.nameInputHint,
                                hintStyle: FontScaling.getInputHint(context),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
                                prefixIcon: Icon(Icons.person, color: Color(0xFFFFE135)),
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
                            ),
                            SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                          ],

                          TextField(
                            controller: _emailController,
                            enabled: !_isLoading,
                            keyboardType: TextInputType.emailAddress,
                            style: FontScaling.getInputText(context),
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
                          ),

                          SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),

                          TextField(
                            controller: _passwordController,
                            enabled: !_isLoading,
                            obscureText: true,
                            style: FontScaling.getInputText(context),
                            decoration: InputDecoration(
                              labelText: l10n.passwordLabel,
                              labelStyle: FontScaling.getBodySmall(context),
                              hintText: l10n.passwordHint,
                              hintStyle: FontScaling.getInputHint(context),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              prefixIcon: Icon(Icons.lock, color: Color(0xFFFFE135)),
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
                            onSubmitted: (_) => _handleSubmit(),
                          ),

                          // Password confirmation field (only for sign-up)
                          if (_isSignUp) ...[
                            SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                            TextField(
                              controller: _passwordConfirmController,
                              enabled: !_isLoading,
                              obscureText: true,
                              style: FontScaling.getInputText(context),
                              decoration: InputDecoration(
                                labelText: l10n.confirmPasswordLabel,
                                labelStyle: FontScaling.getBodySmall(context),
                                hintText: l10n.confirmPasswordHint,
                                hintStyle: FontScaling.getInputHint(context),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
                                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFFFE135)),
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
                              onSubmitted: (_) => _handleSubmit(),
                            ),
                          ],

                          // Forgot Password link
                          if (!_isSignUp) ...[
                            SizedBox(height: FontScaling.getResponsiveSpacing(context, 8)),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isLoading ? null : () => _showPasswordResetDialog(context),
                                child: Text(
                                  l10n.forgotPassword,
                                  style: FontScaling.getBodySmall(context).copyWith(
                                    color: Color(0xFFFFE135),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],

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

                          SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSubmit,
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
                                _isSignUp ? l10n.signUpButton : l10n.signInButton,
                                style: FontScaling.getButtonText(context).copyWith(
                                  color: Color(0xFF1A2238),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),

                          TextButton(
                            onPressed: _isLoading ? null : () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                                _errorMessage = null;
                                // Clear password confirmation when switching modes
                                _passwordConfirmController.clear();
                                // Reload anonymous name when switching to sign-up
                                if (_isSignUp) {
                                  _loadAnonymousName();
                                }
                              });
                            },
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: FontScaling.getBodySmall(context),
                                children: [
                                  TextSpan(
                                    text: _isSignUp
                                        ? '${l10n.alreadyHaveAccount}\n'
                                        : '${l10n.needToLinkAccount}\n',
                                    style: FontScaling.getBodySmall(context).copyWith(
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  TextSpan(
                                    text: _isSignUp ? l10n.signInToggle : l10n.signUpToggle,
                                    style: FontScaling.getBodySmall(context).copyWith(
                                      color: Color(0xFFFFE135),
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog for choosing what to do with anonymous data
class _AnonymousDataMigrationDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final int starsCount;
  final int galaxiesCount;

  const _AnonymousDataMigrationDialog({
    required this.l10n,
    required this.starsCount,
    required this.galaxiesCount,
  });

  @override
  State<_AnonymousDataMigrationDialog> createState() => _AnonymousDataMigrationDialogState();
}

class _AnonymousDataMigrationDialogState extends State<_AnonymousDataMigrationDialog> {
  bool? _selectedChoice;

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_circle_outlined,
              color: Color(0xFFFFE135).withValues(alpha: 0.8),
              size: FontScaling.getResponsiveIconSize(context, 48),
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
            Text(
              widget.l10n.anonymousDataDetectedTitle,
              style: FontScaling.getHeadingMedium(context).copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
            Text(
              widget.l10n.anonymousDataDetectedMessage(widget.starsCount, widget.galaxiesCount),
              style: FontScaling.getBodySmall(context).copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),
            // Radio buttons for merge/delete
            RadioGroup<bool>(
              groupValue: _selectedChoice,
              onChanged: (value) {
                setState(() {
                  _selectedChoice = value;
                });
              },
              child: Column(
                children: [
                  RadioListTile<bool>(
                    title: Text(
                      widget.l10n.mergeAnonymousDataButton,
                      style: FontScaling.getBodyMedium(context).copyWith(
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      widget.l10n.mergeAnonymousDataDescription,
                      style: FontScaling.getBodySmall(context).copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    value: true,
                    activeColor: AppTheme.primary,
                  ),
                  RadioListTile<bool>(
                    title: Text(
                      widget.l10n.deleteAnonymousDataButton,
                      style: FontScaling.getBodyMedium(context).copyWith(
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      widget.l10n.deleteAnonymousDataDescription,
                      style: FontScaling.getBodySmall(context).copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    value: false,
                    activeColor: AppTheme.primary,
                  ),
                ],
              ),
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text(
                    widget.l10n.cancel,
                    style: FontScaling.getButtonText(context).copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _selectedChoice == null
                      ? null
                      : () => Navigator.of(context).pop(_selectedChoice),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFE135),
                    padding: EdgeInsets.symmetric(
                      horizontal: FontScaling.getResponsiveSpacing(context, 20),
                      vertical: FontScaling.getResponsiveSpacing(context, 12),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    _selectedChoice == true
                        ? widget.l10n.mergeAnonymousDataButton
                        : _selectedChoice == false
                            ? widget.l10n.deleteAnonymousDataButton
                            : widget.l10n.cancel,
                    style: FontScaling.getButtonText(context).copyWith(
                      color: Color(0xFF1A2238),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}