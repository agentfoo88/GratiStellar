// lib/features/gratitudes/domain/usecases/delete_gratitude_use_case.dart

import '../../../../storage.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/firestore_service.dart';
import 'use_case.dart';

/// Parameters for deleting a gratitude
class DeleteGratitudeParams {
  final GratitudeStar star;
  final List<GratitudeStar> allStars;

  const DeleteGratitudeParams({
    required this.star,
    required this.allStars,
  });
}

/// Use case for deleting a gratitude star
///
/// Removes the star from local storage and syncs deletion to cloud if authenticated
class DeleteGratitudeUseCase extends UseCase<List<GratitudeStar>, DeleteGratitudeParams> {
  final FirestoreService firestoreService;
  final AuthService authService;

  DeleteGratitudeUseCase({
    required this.firestoreService,
    required this.authService,
  });

  @override
  Future<List<GratitudeStar>> call(DeleteGratitudeParams params) async {
    final updatedStars = List<GratitudeStar>.from(params.allStars);
    final starId = params.star.id;

    updatedStars.removeWhere((s) => s.id == starId);

    // ✅ Call statically
    await StorageService.saveGratitudeStars(updatedStars);

    if (authService.hasEmailAccount) {
      try {
        await firestoreService.deleteStar(starId);
      } catch (e) {
        print('⚠️ Failed to sync star deletion to cloud: $e');
      }
    }

    return updatedStars;
  }
}