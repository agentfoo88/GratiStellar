import '../../../../storage.dart';
import '../../data/repositories/gratitude_repository.dart';
import 'use_case.dart';

class GetDeletedGratitudesResult {
  final List<GratitudeStar> stars;
  final int count;

  const GetDeletedGratitudesResult({
    required this.stars,
    required this.count,
  });
}

class GetDeletedGratitudesUseCase extends UseCase<GetDeletedGratitudesResult, NoParams> {
  final GratitudeRepository repository;

  GetDeletedGratitudesUseCase(this.repository);

  @override
  Future<GetDeletedGratitudesResult> call(NoParams params) async {
    final stars = await repository.getDeletedGratitudes();
    return GetDeletedGratitudesResult(
      stars: stars,
      count: stars.length,
    );
  }
}