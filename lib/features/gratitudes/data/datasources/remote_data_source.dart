// lib/features/gratitudes/data/datasources/remote_data_source.dart

import '../../../../storage.dart';
import '../../../../services/firestore_service.dart';

/// Remote data source - handles all cloud storage operations
///
/// Wraps FirestoreService to provide a clean interface
class RemoteDataSource {
  final FirestoreService _firestoreService;

  RemoteDataSource(this._firestoreService);

  /// Check if cloud has any data
  Future<bool> hasCloudData() async {
    return await _firestoreService.hasCloudData();
  }

  /// Sync local stars with cloud (delta sync)
  Future<List<GratitudeStar>> syncStars(List<GratitudeStar> localStars) async {
    return await _firestoreService.syncStars(localStars);
  }

  /// Download all stars for a specific galaxy (bypasses delta sync)
  Future<List<GratitudeStar>> downloadStarsForGalaxy(String galaxyId) async {
    return await _firestoreService.downloadStarsForGalaxy(galaxyId);
  }

  /// Upload stars to cloud (first sync)
  Future<void> uploadStars(List<GratitudeStar> stars) async {
    await _firestoreService.uploadStars(stars);
  }

  /// Delete a star from cloud
  Future<void> deleteStar(String starId) async {
    await _firestoreService.deleteStar(starId);
  }

  /// Add a star to cloud
  Future<void> addStar(GratitudeStar star) async {
    await _firestoreService.addStar(star);
  }

  /// Update a star in cloud
  Future<void> updateStar(GratitudeStar star) async {
    await _firestoreService.updateStar(star);
  }
}