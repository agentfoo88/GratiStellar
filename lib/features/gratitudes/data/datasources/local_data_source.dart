// lib/features/gratitudes/data/datasources/local_data_source.dart

import '../../../../storage.dart';
import '../../../../services/user_scoped_storage.dart';
import '../../../../services/user_profile_manager.dart';

/// Local data source - handles all local storage operations
///
/// Uses user-scoped storage when UserProfileManager is provided,
/// falls back to global storage for backward compatibility.
class LocalDataSource {
  final UserProfileManager? _userProfileManager;

  LocalDataSource({UserProfileManager? userProfileManager})
      : _userProfileManager = userProfileManager;

  /// Load all gratitude stars from local storage
  Future<List<GratitudeStar>> loadStars() async {
    if (_userProfileManager != null) {
      // Use user-scoped storage
      final userId = await _userProfileManager.getOrCreateActiveUserId();
      return await UserScopedStorage.loadStars(userId);
    } else {
      // Fallback to global storage (backward compatibility)
      return await StorageService.loadGratitudeStars();
    }
  }

  /// Save gratitude stars to local storage
  Future<void> saveStars(List<GratitudeStar> stars) async {
    if (_userProfileManager != null) {
      // Use user-scoped storage
      final userId = await _userProfileManager.getOrCreateActiveUserId();
      await UserScopedStorage.saveStars(userId, stars);
      await UserScopedStorage.trackUserHasData(userId);
    } else {
      // Fallback to global storage (backward compatibility)
      await StorageService.saveGratitudeStars(stars);
    }
  }

  /// Clear all local data for current user
  ///
  /// [userId] - Optional user ID to clear data for. If not provided,
  /// will attempt to get the current user ID (which may fail after sign-out).
  Future<void> clearAll({String? userId}) async {
    if (_userProfileManager != null) {
      // Get user ID if not provided
      final targetUserId = userId ?? await _userProfileManager.getOrCreateActiveUserId();
      await UserScopedStorage.clearUserData(targetUserId);
      await UserScopedStorage.untrackUser(targetUserId);
    } else {
      // Fallback: clear all data (backward compatibility)
      await StorageService.clearAllData();
    }
  }

  /// Check if local data exists
  Future<bool> hasLocalData() async {
    final stars = await loadStars();
    return stars.isNotEmpty;
  }

  /// Load only non-deleted gratitude stars
  Future<List<GratitudeStar>> loadActiveStars() async {
    final allStars = await loadStars();
    return allStars.where((star) => !star.deleted).toList();
  }

  /// Load only deleted gratitude stars
  Future<List<GratitudeStar>> loadDeletedStars() async {
    final allStars = await loadStars();
    return allStars.where((star) => star.deleted).toList();
  }
}