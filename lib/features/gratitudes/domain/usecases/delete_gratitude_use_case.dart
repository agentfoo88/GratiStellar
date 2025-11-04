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
    // Soft delete: mark as deleted with timestamp
    final deletedStar = params.star.copyWith(
      deleted: true,
      deletedAt: DateTime.now(),
    );

    await repository.deleteGratitude(deletedStar, params.allStars);

    // Return updated list with soft-deleted star
    final updatedStars = List<GratitudeStar>.from(params.allStars);
    final index = updatedStars.indexWhere((s) => s.id == params.star.id);
    if (index != -1) {
      updatedStars[index] = deletedStar;
    }
    return updatedStars;
  }
}