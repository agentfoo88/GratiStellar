import 'package:flutter/foundation.dart';
import '../../../../galaxy_metadata.dart';
import '../../../gratitudes/data/repositories/galaxy_repository.dart';
import '../../../gratitudes/data/repositories/gratitude_repository.dart';
import 'gratitude_provider.dart';

/// Provider for galaxy state management
///
/// Manages all galaxy-related state and coordinates with repository
class GalaxyProvider extends ChangeNotifier {
  final GalaxyRepository _galaxyRepository;
  final GratitudeRepository _gratitudeRepository;

  late final GratitudeProvider _gratitudeProvider;

  List<GalaxyMetadata> _galaxies = [];
  String? _activeGalaxyId;
  final bool _isLoading = false;
  bool _isSwitching = false;

  GalaxyProvider({
    required GalaxyRepository galaxyRepository,
    required GratitudeRepository gratitudeRepository,
  })  : _galaxyRepository = galaxyRepository,
        _gratitudeRepository = gratitudeRepository;

  /// Set gratitude provider (called after construction)
  void setGratitudeProvider(GratitudeProvider gratitudeProvider) {
    _gratitudeProvider = gratitudeProvider;
  }

  // Getters
  List<GalaxyMetadata> get galaxies => _galaxies;
  String? get activeGalaxyId => _activeGalaxyId;
  bool get isLoading => _isLoading;
  bool get isSwitching => _isSwitching;

  /// Get active galaxy metadata
  GalaxyMetadata? get activeGalaxy {
    if (_activeGalaxyId == null) return null;
    try {
      return _galaxies.firstWhere((g) => g.id == _activeGalaxyId);
    } catch (e) {
      return null;
    }
  }

  /// Get non-deleted galaxies
  List<GalaxyMetadata> get activeGalaxies {
    return _galaxies.where((g) => !g.deleted).toList()
      ..sort((a, b) {
        // Sort by last viewed (most recent first)
        final aDate = a.lastViewedAt ?? a.createdAt;
        final bDate = b.lastViewedAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });
  }

  /// Get deleted galaxies
  List<GalaxyMetadata> get deletedGalaxies {
    return _galaxies.where((g) => g.deleted).toList()
      ..sort((a, b) => (b.deletedAt ?? b.createdAt).compareTo(a.deletedAt ?? a.createdAt));
  }

  /// Initialize - load galaxies and set active
  Future<void> initialize() async {
    try {
      await loadGalaxies();

      // Load the saved active galaxy ID from storage
      _activeGalaxyId = await _galaxyRepository.getActiveGalaxyId();
      print('📝 Loaded active galaxy from storage: $_activeGalaxyId');

      // If no active galaxy, create a default one
      if (_activeGalaxyId == null && _galaxies.isEmpty) {
        print('📝 No galaxies found, creating default galaxy');
        await createGalaxy(name: 'My First Galaxy', switchToNew: true);
      } else if (_activeGalaxyId == null && _galaxies.isNotEmpty) {
        // Set first galaxy as active
        print('📝 Setting first galaxy as active');
        _activeGalaxyId = _galaxies.first.id;
        await _galaxyRepository.setActiveGalaxy(_activeGalaxyId!);
        notifyListeners();
      }

      // Set the active galaxy filter in the gratitude repository
      if (_activeGalaxyId != null) {
        _gratitudeRepository.setActiveGalaxyId(_activeGalaxyId);
        print('🔧 Set gratitude repository filter to: $_activeGalaxyId');

        // Migrate existing stars to active galaxy (one-time migration)
        await _gratitudeRepository.migrateStarsToActiveGalaxy(_activeGalaxyId!);
      }

      print('✅ Galaxy system initialized, active: $_activeGalaxyId');
    } catch (e) {
      print('❌ Galaxy initialization failed: $e');
    }
  }

  /// Load all galaxies from repository
  Future<void> loadGalaxies() async {
    try {
      _galaxies = await _galaxyRepository.getGalaxies();
      notifyListeners();
    } catch (e) {
      print('⚠️ Error loading galaxies: $e');
      rethrow;
    }
  }

  /// Create a new galaxy
  Future<GalaxyMetadata> createGalaxy({
    required String name,
    bool switchToNew = true,
  }) async {
    try {
      final galaxy = await _galaxyRepository.createGalaxy(
        name: name,
        setAsActive: switchToNew,
      );

      // Reload galaxies
      await loadGalaxies();

      if (switchToNew) {
        // Use proper method to set active galaxy (updates repo, lastViewed, etc.)
        await setActiveGalaxy(galaxy.id);

        // Reload gratitudes to show stars from new galaxy
        try {
          await _gratitudeProvider.loadGratitudes();
        } catch (e) {
          print('⚠️ Failed to load gratitudes during switch: $e');
          // Continue anyway - don't block the switch
        }
      }

      notifyListeners();
      return galaxy;
    } catch (e) {
      print('⚠️ Error creating galaxy: $e');
      rethrow;
    }
  }

  /// Switch to a different galaxy (with animation support)
  Future<void> switchGalaxy(String galaxyId, {
    Future<void> Function()? onFadeOut,
    Future<void> Function()? onFadeIn,
  }) async {
    if (_activeGalaxyId == galaxyId) {
      print('ℹ️ Already on galaxy $galaxyId');
      return;
    }

    _isSwitching = true;
    notifyListeners();

    try {
      // Step 1: Fade out animation callback
      if (onFadeOut != null) {
        await onFadeOut();
      }

      // Step 2: Switch galaxy in repository and update filter
      await _galaxyRepository.setActiveGalaxy(galaxyId);
      _activeGalaxyId = galaxyId;

      print('🔄 Galaxy switch: set active to $galaxyId');

      // Step 3: Reload galaxies to update lastViewedAt
      await loadGalaxies();

      // Step 4: Reload gratitudes with new galaxy filter
      print('🔄 Galaxy switch: reloading gratitudes for galaxy $galaxyId');
      await _gratitudeProvider.loadGratitudes();

      print('🔄 Galaxy switch: loaded ${_gratitudeProvider.gratitudeStars.length} stars');

      // Step 5: Fade in animation callback
      if (onFadeIn != null) {
        await onFadeIn();
      }

      print('✅ Switched to galaxy $galaxyId');
    } catch (e) {
      print('⚠️ Error switching galaxy: $e');
      rethrow;
    } finally {
      _isSwitching = false;
      notifyListeners();
    }
  }

  /// Set active galaxy without animation (for internal use)
  Future<void> setActiveGalaxy(String galaxyId) async {
    if (_activeGalaxyId == galaxyId) {
      print('ℹ️ Already on galaxy $galaxyId');
      return;
    }

    try {
      await _galaxyRepository.setActiveGalaxy(galaxyId);
      _activeGalaxyId = galaxyId;
      await loadGalaxies();

      // Reload gratitudes to show stars from new galaxy
      await _gratitudeProvider.loadGratitudes();

      notifyListeners();
      print('✅ Set active galaxy: $galaxyId');
    } catch (e) {
      print('⚠️ Error setting active galaxy: $e');
      rethrow;
    }
  }

  /// Rename a galaxy
  Future<void> renameGalaxy(String galaxyId, String newName) async {
    try {
      final index = _galaxies.indexWhere((g) => g.id == galaxyId);
      if (index == -1) {
        print('⚠️ Galaxy $galaxyId not found');
        return;
      }

      // Limit galaxy name length
      final truncatedName = newName.length > GalaxyMetadata.maxNameLength
          ? newName.substring(0, GalaxyMetadata.maxNameLength)
          : newName;

      final updatedGalaxy = _galaxies[index].copyWith(name: truncatedName);
      await _galaxyRepository.updateGalaxy(updatedGalaxy);
      await loadGalaxies();

      print('✅ Renamed galaxy to: $newName');
    } catch (e) {
      print('⚠️ Error renaming galaxy: $e');
      rethrow;
    }
  }

  /// Delete a galaxy (cascade delete stars)
  Future<void> deleteGalaxy(String galaxyId) async {
    try {
      await _galaxyRepository.deleteGalaxy(galaxyId);
      await loadGalaxies();

      // If we deleted the active galaxy, update active ID
      if (_activeGalaxyId == galaxyId) {
        _activeGalaxyId = await _galaxyRepository.getActiveGalaxyId();
        _gratitudeRepository.setActiveGalaxyId(_activeGalaxyId);
      }

      notifyListeners();
      print('✅ Deleted galaxy $galaxyId');
    } catch (e) {
      print('⚠️ Error deleting galaxy: $e');
      rethrow;
    }
  }

  /// Restore a deleted galaxy
  Future<void> restoreGalaxy(String galaxyId) async {
    try {
      await _galaxyRepository.restoreGalaxy(galaxyId);
      await loadGalaxies();
      notifyListeners();

      print('✅ Restored galaxy $galaxyId');
    } catch (e) {
      print('⚠️ Error restoring galaxy: $e');
      rethrow;
    }
  }

  /// Update star count for active galaxy
  Future<void> updateActiveGalaxyStarCount(int count) async {
    if (_activeGalaxyId == null) return;

    try {
      await _galaxyRepository.updateStarCount(_activeGalaxyId!, count);
      await loadGalaxies();
      notifyListeners();
    } catch (e) {
      print('⚠️ Error updating star count: $e');
    }
  }

  /// Sync galaxies from cloud
  Future<void> syncFromCloud() async {
    try {
      await _galaxyRepository.syncFromCloud();
      await loadGalaxies();

      // Update active galaxy
      _activeGalaxyId = await _galaxyRepository.getActiveGalaxyId();
      _gratitudeRepository.setActiveGalaxyId(_activeGalaxyId);

      notifyListeners();
    } catch (e) {
      print('⚠️ Error syncing galaxies from cloud: $e');
      rethrow;
    }
  }

  /// Sync galaxies to cloud
  Future<void> syncToCloud() async {
    try {
      await _galaxyRepository.syncToCloud();
    } catch (e) {
      print('⚠️ Error syncing galaxies to cloud: $e');
      rethrow;
    }
  }

  /// Clear all galaxy data (called on sign out)
  Future<void> clearAll() async {
    try {
      await _galaxyRepository.clearAll();
      _galaxies = [];
      _activeGalaxyId = null;
      notifyListeners();
    } catch (e) {
      print('⚠️ Error clearing galaxy data: $e');
    }
  }
}