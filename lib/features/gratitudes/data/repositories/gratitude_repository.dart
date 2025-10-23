// lib/features/gratitudes/data/repositories/gratitude_repository.dart

import '../../../../storage.dart';
import '../../../../services/auth_service.dart';
import '../datasources/local_data_source.dart';
import '../datasources/remote_data_source.dart';

/// Repository for gratitude data operations
///
/// Single source of truth for all gratitude data.
/// Coordinates between local and remote data sources.
class GratitudeRepository {
  final LocalDataSource _localDataSource;
  final RemoteDataSource _remoteDataSource;
  final AuthService _authService;

  GratitudeRepository({
    required LocalDataSource localDataSource,
    required RemoteDataSource remoteDataSource,
    required AuthService authService,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _authService = authService;

  /// Get all gratitudes from local storage
  Future<List<GratitudeStar>> getGratitudes() async {
    return await _localDataSource.loadStars();
  }

  /// Save gratitudes to local storage
  Future<void> saveGratitudes(List<GratitudeStar> stars) async {
    await _localDataSource.saveStars(stars);
  }

  /// Add a new gratitude (local + cloud if authenticated)
  Future<void> addGratitude(GratitudeStar star, List<GratitudeStar> allStars) async {
    final updatedStars = [...allStars, star];
    await _localDataSource.saveStars(updatedStars);

    // Sync to cloud if authenticated
    if (_authService.hasEmailAccount) {
      try {
        await _remoteDataSource.addStar(star);
      } catch (e) {
        print('⚠️ Failed to sync new star to cloud: $e');
        // Don't rethrow - local save succeeded
      }
    }
  }

  /// Update an existing gratitude (local + cloud if authenticated)
  Future<void> updateGratitude(GratitudeStar star, List<GratitudeStar> allStars) async {
    final updatedStars = List<GratitudeStar>.from(allStars);
    final index = updatedStars.indexWhere((s) => s.id == star.id);

    if (index != -1) {
      updatedStars[index] = star;
      await _localDataSource.saveStars(updatedStars);

      // Sync to cloud if authenticated
      if (_authService.hasEmailAccount) {
        try {
          await _remoteDataSource.updateStar(star);
        } catch (e) {
          print('⚠️ Failed to sync star update to cloud: $e');
        }
      }
    }
  }

  /// Delete a gratitude (local + cloud if authenticated)
  Future<void> deleteGratitude(String starId, List<GratitudeStar> allStars) async {
    final updatedStars = List<GratitudeStar>.from(allStars);
    updatedStars.removeWhere((s) => s.id == starId);
    await _localDataSource.saveStars(updatedStars);

    // Sync deletion to cloud if authenticated
    if (_authService.hasEmailAccount) {
      try {
        await _remoteDataSource.deleteStar(starId);
      } catch (e) {
        print('⚠️ Failed to sync star deletion to cloud: $e');
      }
    }
  }

  /// Sync with cloud - merge local and remote data
  Future<List<GratitudeStar>> syncWithCloud(List<GratitudeStar> localStars) async {
    print('🔄 Starting cloud sync...');

    final hasCloudData = await _remoteDataSource.hasCloudData();

    if (hasCloudData) {
      // Delta sync - merge changes
      print('📥 Cloud data exists, syncing...');
      final mergedStars = await _remoteDataSource.syncStars(localStars);
      await _localDataSource.saveStars(mergedStars);
      print('✅ Sync complete! Total stars: ${mergedStars.length}');
      return mergedStars;
    } else {
      // First sync - upload local to cloud
      print('📤 No cloud data, uploading local stars...');
      await _remoteDataSource.uploadStars(localStars);
      print('✅ Local stars uploaded to cloud');
      return localStars;
    }
  }

  /// Clear all local data
  Future<void> clearAllData() async {
    await _localDataSource.clearAll();
  }
}