import '../../../../storage.dart';
import '../../data/repositories/gratitude_repository.dart';
import 'use_case.dart';

class GetDeletedGratitudesUseCase extends UseCase<List<GratitudeStar>, NoParams> {
  final GratitudeRepository repository;

  GetDeletedGratitudesUseCase(this.repository);

  @override
  Future<List<GratitudeStar>> call(NoParams params) async {
    return await repository.getDeletedGratitudes();
  }
}