import '../../../../storage.dart';
import '../../data/repositories/gratitude_repository.dart';
import 'use_case.dart';

class UpdateGratitudeParams {
  final GratitudeStar updatedStar;
  final List<GratitudeStar> allStars;

  const UpdateGratitudeParams({
    required this.updatedStar,
    required this.allStars,
  });
}

class UpdateGratitudeUseCase extends UseCase<List<GratitudeStar>, UpdateGratitudeParams> {
  final GratitudeRepository repository;

  UpdateGratitudeUseCase(this.repository);

  @override
  Future<List<GratitudeStar>> call(UpdateGratitudeParams params) async {
    await repository.updateGratitude(params.updatedStar, params.allStars);

    // Return updated list
    final updatedStars = List<GratitudeStar>.from(params.allStars);
    final index = updatedStars.indexWhere((s) => s.id == params.updatedStar.id);
    if (index != -1) {
      updatedStars[index] = params.updatedStar;
    }
    return updatedStars;
  }
}