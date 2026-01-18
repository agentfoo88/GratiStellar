import '../../../../storage.dart';
import '../../data/repositories/gratitude_repository.dart';
import 'use_case.dart';

class MoveGratitudeParams {
  final GratitudeStar star;
  final String targetGalaxyId;
  final List<GratitudeStar> allStars;

  const MoveGratitudeParams({
    required this.star,
    required this.targetGalaxyId,
    required this.allStars,
  });
}

class MoveGratitudeUseCase extends UseCase<List<GratitudeStar>, MoveGratitudeParams> {
  final GratitudeRepository repository;

  MoveGratitudeUseCase(this.repository);

  @override
  Future<List<GratitudeStar>> call(MoveGratitudeParams params) async {
    // Validation: Don't move to same galaxy
    if (params.star.galaxyId == params.targetGalaxyId) {
      throw StateError('Star is already in target galaxy');
    }

    // Create updated star with new galaxyId and updatedAt timestamp
    final movedStar = params.star.copyWith(
      galaxyId: params.targetGalaxyId,
      updatedAt: DateTime.now(),
    );

    // Update in repository
    await repository.updateGratitude(movedStar, params.allStars);

    // Return updated list
    final updatedStars = List<GratitudeStar>.from(params.allStars);
    final index = updatedStars.indexWhere((s) => s.id == params.star.id);
    if (index != -1) {
      updatedStars[index] = movedStar;
    }
    return updatedStars;
  }
}
