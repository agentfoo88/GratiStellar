import '../../../../storage.dart';
import '../../data/repositories/gratitude_repository.dart';
import 'use_case.dart';

class RestoreGratitudeParams {
  final GratitudeStar star;
  final List<GratitudeStar> allStars;

  const RestoreGratitudeParams({
    required this.star,
    required this.allStars,
  });
}

class RestoreGratitudeUseCase extends UseCase<void, RestoreGratitudeParams> {
  final GratitudeRepository repository;

  RestoreGratitudeUseCase(this.repository);

  @override
  Future<void> call(RestoreGratitudeParams params) async {
    await repository.restoreGratitude(params.star, params.allStars);
  }
}