import '../../../../storage.dart';
import '../../data/repositories/gratitude_repository.dart';
import 'use_case.dart';

class PurgeOldDeletedParams {
  final List<GratitudeStar> allStars;

  const PurgeOldDeletedParams(this.allStars);
}

class PurgeOldDeletedUseCase extends UseCase<List<GratitudeStar>, PurgeOldDeletedParams> {
  final GratitudeRepository repository;

  PurgeOldDeletedUseCase(this.repository);

  @override
  Future<List<GratitudeStar>> call(PurgeOldDeletedParams params) async {
    return await repository.purgeOldDeletedItems(params.allStars);
  }
}