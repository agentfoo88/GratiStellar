// lib/features/gratitudes/domain/usecases/load_gratitudes_use_case.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../../../../storage.dart';
import '../../../../services/auth_service.dart';
import 'use_case.dart';

/// Result of loading gratitudes
class LoadGratitudesResult {
  final List<GratitudeStar> stars;
  final bool shouldSyncWithCloud;

  const LoadGratitudesResult({
    required this.stars,
    required this.shouldSyncWithCloud,
  });
}

/// Use case for loading gratitudes from storage
///
/// Handles:
/// - First-run detection and data cleanup
/// - Anonymous session restoration
/// - Data ownership verification
/// - Loading from local storage
/// - Determining if cloud sync is needed
class LoadGratitudesUseCase extends UseCase<LoadGratitudesResult, NoParams> {
  final AuthService authService;

  LoadGratitudesUseCase({
    required this.authService,
  });

  @override
  Future<LoadGratitudesResult> call(NoParams params) async {
    print('💾 Loading gratitudes...');

    await _checkFirstRun();
    await _restoreAnonymousSessionIfNeeded();
    await _verifyDataOwnership();

    // ✅ Call statically
    final stars = await StorageService.loadGratitudeStars();
    print('🎯 Loaded ${stars.length} gratitude stars');

    final shouldSync = authService.hasEmailAccount;
    if (shouldSync) {
      print('🔄 User has email account, cloud sync needed');
    }

    return LoadGratitudesResult(
      stars: stars,
      shouldSyncWithCloud: shouldSync,
    );
  }

  Future<void> _checkFirstRun() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRunBefore = prefs.getBool('has_run_before') ?? false;

      if (!hasRunBefore) {
        print('🆕 First run detected - clearing any stale data');
        await StorageService.clearAllData();
        await prefs.setBool('has_run_before', true);
        print('✅ First run setup complete');
      }
    } catch (e) {
      print('⚠️ Error checking first run: $e');
      // Non-critical, continue anyway
    }
  }

  Future<void> _restoreAnonymousSessionIfNeeded() async {
    try {
      // Only restore if not currently signed in
      if (authService.isSignedIn) {
        print('✓ User already signed in, skipping session restoration');
        return;
      }

      // Check if we have a saved anonymous UID
      final savedUid = await authService.getSavedAnonymousUid();

      if (savedUid != null) {
        print('🔄 Found saved anonymous UID: $savedUid');

        // Firebase will auto-restore anonymous sessions if valid
        await Future.delayed(Duration(milliseconds: 500));

        // Check if session was restored
        if (authService.isSignedIn && authService.currentUser?.uid == savedUid) {
          print('✅ Anonymous session restored successfully');
        } else {
          print('⚠️ Saved session expired or invalid');
        }
      } else {
        print('ℹ️ No saved anonymous UID found');
      }
    } catch (e) {
      print('⚠️ Error restoring anonymous session: $e');
      // Continue normally - user will create new session
    }
  }

  Future<void> _verifyDataOwnership() async {
    // Safety check: If signed in, verify local data belongs to current user
    if (authService.isSignedIn) {
      final currentUid = authService.currentUser?.uid;
      final prefs = await SharedPreferences.getInstance();
      final localDataOwner = prefs.getString('local_data_owner_uid');

      if (localDataOwner != null && localDataOwner != currentUid) {
        // Local data belongs to different user - clear ALL data!
        print('⚠️ Local data belongs to different user. Clearing...');
        await StorageService.clearAllData();
        await prefs.setString('local_data_owner_uid', currentUid!);
      }

      // Store current user as owner if not set
      if (localDataOwner == null && currentUid != null) {
        await prefs.setString('local_data_owner_uid', currentUid);
      }
    }
  }
}