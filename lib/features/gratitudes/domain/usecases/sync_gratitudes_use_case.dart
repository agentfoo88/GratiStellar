import '../../../../storage.dart';
import '../../data/repositories/gratitude_repository.dart';
import 'use_case.dart';

class SyncGratitudesParams {
  final List<GratitudeStar> localStars;

  const SyncGratitudesParams({required this.localStars});
}

class SyncGratitudesResult {
  final List<GratitudeStar> mergedStars;
  final bool wasFirstSync;

  const SyncGratitudesResult({
    required this.mergedStars,
    required this.wasFirstSync,
  });
}

class SyncGratitudesUseCase extends UseCase<SyncGratitudesResult, SyncGratitudesParams> {
  final GratitudeRepository repository;

  SyncGratitudesUseCase(this.repository);

  @override
  Future<SyncGratitudesResult> call(SyncGratitudesParams params) async {
    final mergedStars = await repository.syncWithCloud(params.localStars);

    // Determine if it was first sync by checking if stars changed
    final wasFirstSync = mergedStars.length == params.localStars.length;

    return SyncGratitudesResult(
      mergedStars: mergedStars,
      wasFirstSync: wasFirstSync,
    );
  }
}