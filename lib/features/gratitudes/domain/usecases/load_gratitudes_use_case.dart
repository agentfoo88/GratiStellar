import 'package:shared_preferences/shared_preferences.dart';
import '../../../../storage.dart';
import '../../../../services/auth_service.dart';
import '../../data/repositories/gratitude_repository.dart';
import 'use_case.dart';

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
    print('💾 Loading gratitudes...');

    await _checkFirstRun();
    await _restoreAnonymousSessionIfNeeded();
    await _verifyDataOwnership();

    final stars = await repository.getGratitudes();
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
        await repository.clearAllData();
        await prefs.setBool('has_run_before', true);
        print('✅ First run setup complete');
      }
    } catch (e) {
      print('⚠️ Error checking first run: $e');
    }
  }

  Future<void> _restoreAnonymousSessionIfNeeded() async {
    try {
      if (authService.isSignedIn) {
        print('✓ User already signed in, skipping session restoration');
        return;
      }

      final savedUid = await authService.getSavedAnonymousUid();

      if (savedUid != null) {
        print('🔄 Found saved anonymous UID: $savedUid');
        await Future.delayed(Duration(milliseconds: 500));

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
    }
  }

  Future<void> _verifyDataOwnership() async {
    if (authService.isSignedIn) {
      final currentUid = authService.currentUser?.uid;
      final prefs = await SharedPreferences.getInstance();
      final localDataOwner = prefs.getString('local_data_owner_uid');

      if (localDataOwner != null && localDataOwner != currentUid) {
        print('⚠️ Local data belongs to different user. Clearing...');
        await repository.clearAllData();
        await prefs.setString('local_data_owner_uid', currentUid!);
      }

      if (localDataOwner == null && currentUid != null) {
        await prefs.setString('local_data_owner_uid', currentUid);
      }
    }
  }
}