import '../../../../storage.dart';
import '../../data/repositories/gratitude_repository.dart';
import 'use_case.dart';

class DeleteGratitudeParams {
  final GratitudeStar star;
  final List<GratitudeStar> allStars;

  const DeleteGratitudeParams({
    required this.star,
    required this.allStars,
  });
}

class DeleteGratitudeUseCase extends UseCase<List<GratitudeStar>, DeleteGratitudeParams> {
  final GratitudeRepository repository;

  DeleteGratitudeUseCase(this.repository);

  @override
  Future<List<GratitudeStar>> call(DeleteGratitudeParams params) async {
    await repository.deleteGratitude(params.star.id, params.allStars);

    // Return updated list
    final updatedStars = List<GratitudeStar>.from(params.allStars);
    updatedStars.removeWhere((s) => s.id == params.star.id);
    return updatedStars;
  }
}