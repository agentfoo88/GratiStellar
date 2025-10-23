// lib/features/gratitudes/domain/usecases/sync_gratitudes_use_case.dart

import '../../../../storage.dart';
import '../../../../services/firestore_service.dart';
import 'use_case.dart';

/// Parameters for syncing gratitudes
class SyncGratitudesParams {
  final List<GratitudeStar> localStars;

  const SyncGratitudesParams({required this.localStars});
}

/// Result of sync operation
class SyncGratitudesResult {
  final List<GratitudeStar> mergedStars;
  final bool wasFirstSync; // true if uploading to empty cloud

  const SyncGratitudesResult({
    required this.mergedStars,
    required this.wasFirstSync,
  });
}

/// Use case for syncing gratitudes with cloud
///
/// Handles two scenarios:
/// 1. First sync: Upload all local stars to empty cloud
/// 2. Delta sync: Merge local and cloud changes intelligently
///
/// Uses delta sync strategy:
/// - Downloads only stars modified since last sync
/// - Uploads only local changes
/// - Keeps the newest version when conflicts occur
class SyncGratitudesUseCase extends UseCase<SyncGratitudesResult, SyncGratitudesParams> {
  final FirestoreService firestoreService;

  SyncGratitudesUseCase({
    required this.firestoreService,
  });

  @override
  Future<SyncGratitudesResult> call(SyncGratitudesParams params) async {
    print('🔄 Starting cloud sync...');

    final hasCloudData = await firestoreService.hasCloudData();

    if (hasCloudData) {
      print('📥 Cloud data exists, syncing...');
      final mergedStars = await firestoreService.syncStars(params.localStars);

      // ✅ Call statically
      await StorageService.saveGratitudeStars(mergedStars);

      print('✅ Sync complete! Total stars: ${mergedStars.length}');

      return SyncGratitudesResult(
        mergedStars: mergedStars,
        wasFirstSync: false,
      );
    } else {
      print('📤 No cloud data, uploading local stars...');
      await firestoreService.uploadStars(params.localStars);
      print('✅ Local stars uploaded to cloud');

      return SyncGratitudesResult(
        mergedStars: params.localStars,
        wasFirstSync: true,
      );
    }
  }
}