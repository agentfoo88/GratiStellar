// lib/features/gratitudes/domain/usecases/update_gratitude_use_case.dart

import '../../../../storage.dart';
import 'use_case.dart';

/// Parameters for updating a gratitude
class UpdateGratitudeParams {
  final GratitudeStar updatedStar;
  final List<GratitudeStar> allStars;

  const UpdateGratitudeParams({
    required this.updatedStar,
    required this.allStars,
  });
}

/// Use case for updating an existing gratitude star
///
/// Updates the star in the list and saves to storage
class UpdateGratitudeUseCase extends UseCase<List<GratitudeStar>, UpdateGratitudeParams> {

  UpdateGratitudeUseCase();

  @override
  Future<List<GratitudeStar>> call(UpdateGratitudeParams params) async {
    final updatedStars = List<GratitudeStar>.from(params.allStars);

    final index = updatedStars.indexWhere((s) => s.id == params.updatedStar.id);
    if (index != -1) {
      updatedStars[index] = params.updatedStar;

      // ✅ Call statically
      await StorageService.saveGratitudeStars(updatedStars);
    }

    return updatedStars;
  }
}