import 'package:shared_preferences/shared_preferences.dart';
import '../../../../storage.dart';
import '../../../../services/auth_service.dart';
import '../../data/repositories/gratitude_repository.dart';
import 'use_case.dart';
import '../../../../core/utils/app_logger.dart';

class LoadGratitudesResult {
  final List<GratitudeStar> stars;
  final bool shouldSyncWithCloud;

  const LoadGratitudesResult({
    required this.stars,
    required this.shouldSyncWithCloud,
  });
}

class LoadGratitudesUseCase extends UseCase<LoadGratitudesResult, NoParams> {
  final GratitudeRepository repository;
  final AuthService authService;

  LoadGratitudesUseCase({
    required this.repository,
    required this.authService,
  });

  @override
  Future<LoadGratitudesResult> call(NoParams params) async {
    AppLogger.data('💾 Loading gratitudes...');

    await _checkFirstRun();
    await _restoreAnonymousSessionIfNeeded();
    await _verifyDataOwnership();

    final stars = await repository.getGratitudes();
    AppLogger.data('🎯 Loaded ${stars.length} gratitude stars');

    final shouldSync = authService.hasEmailAccount;
    if (shouldSync) {
      AppLogger.auth('🔄 User has email account, cloud sync needed');
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
        AppLogger.data('🆕 First run detected - clearing any stale data');
        await repository.clearAllData();
        await prefs.setBool('has_run_before', true);
        AppLogger.success('✅ First run setup complete');
      }
    } catch (e) {
      AppLogger.error('⚠️ Error checking first run: $e');
    }
  }

  Future<void> _restoreAnonymousSessionIfNeeded() async {
    try {
      if (authService.isSignedIn) {
        AppLogger.auth('✓ User already signed in, skipping session restoration');
        return;
      }

      final savedUid = await authService.getSavedAnonymousUid();

      if (savedUid != null) {
        AppLogger.data('🔄 Found saved anonymous UID: $savedUid');
        await Future.delayed(Duration(milliseconds: 500));

        if (authService.isSignedIn && authService.currentUser?.uid == savedUid) {
          AppLogger.success('✅ Anonymous session restored successfully');
        } else {
          AppLogger.warning('⚠️ Saved session expired or invalid');
        }
      } else {
        AppLogger.data('ℹ️ No saved anonymous UID found');
      }
    } catch (e) {
      AppLogger.error('⚠️ Error restoring anonymous session: $e');
    }
  }

  Future<void> _verifyDataOwnership() async {
    if (authService.isSignedIn) {
      final currentUid = authService.currentUser?.uid;
      final prefs = await SharedPreferences.getInstance();
      final localDataOwner = prefs.getString('local_data_owner_uid');

      if (localDataOwner != null && localDataOwner != currentUid) {
        AppLogger.warning('⚠️ Local data belongs to different user. Clearing...');
        await repository.clearAllData();
        await prefs.setString('local_data_owner_uid', currentUid!);
      }

      if (localDataOwner == null && currentUid != null) {
        await prefs.setString('local_data_owner_uid', currentUid);
      }
    }
  }
}