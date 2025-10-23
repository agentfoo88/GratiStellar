// lib/features/gratitudes/data/datasources/local_data_source.dart

import '../../../../storage.dart';

/// Local data source - handles all local storage operations
///
/// Wraps StorageService to provide a clean interface
class LocalDataSource {
  /// Load all gratitude stars from local storage
  Future<List<GratitudeStar>> loadStars() async {
    return await StorageService.loadGratitudeStars();
  }

  /// Save gratitude stars to local storage
  Future<void> saveStars(List<GratitudeStar> stars) async {
    await StorageService.saveGratitudeStars(stars);
  }

  /// Clear all local data
  Future<void> clearAll() async {
    await StorageService.clearAllData();
  }

  /// Check if local data exists
  Future<bool> hasLocalData() async {
    final stars = await loadStars();
    return stars.isNotEmpty;
  }
}