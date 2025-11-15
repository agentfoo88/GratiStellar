import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../galaxy_metadata.dart';
import '../../../../services/auth_service.dart';

/// Remote data source for galaxy metadata operations
class GalaxyRemoteDataSource {
  final FirebaseFirestore _firestore;
  final AuthService _authService;

  GalaxyRemoteDataSource({
    FirebaseFirestore? firestore,
    required AuthService authService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authService = authService;

  /// Get reference to user's galaxy collection
  CollectionReference? _getGalaxyCollection() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection('galaxyMetadata');
  }

  /// Load all galaxy metadata from Firestore
  Future<List<GalaxyMetadata>> loadGalaxies() async {
    try {
      final collection = _getGalaxyCollection();
      if (collection == null) {
        print('⚠️ No user authenticated, cannot load galaxies from Firestore');
        return [];
      }

      final snapshot = await collection.get();
      return snapshot.docs
          .map((doc) => GalaxyMetadata.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('⚠️ Error loading galaxies from Firestore: $e');
      rethrow;
    }
  }

  /// Save a single galaxy to Firestore
  Future<void> saveGalaxy(GalaxyMetadata galaxy) async {
    try {
      final collection = _getGalaxyCollection();
      if (collection == null) {
        print('⚠️ No user authenticated, cannot save galaxy to Firestore');
        return;
      }

      await collection.doc(galaxy.id).set(galaxy.toJson());
      print('☁️ Saved galaxy ${galaxy.name} to Firestore');
    } catch (e) {
      print('⚠️ Error saving galaxy to Firestore: $e');
      rethrow;
    }
  }

  /// Update a single galaxy in Firestore
  Future<void> updateGalaxy(GalaxyMetadata galaxy) async {
    try {
      final collection = _getGalaxyCollection();
      if (collection == null) {
        print('⚠️ No user authenticated, cannot update galaxy in Firestore');
        return;
      }

      await collection.doc(galaxy.id).update(galaxy.toJson());
      print('☁️ Updated galaxy ${galaxy.name} in Firestore');
    } catch (e) {
      print('⚠️ Error updating galaxy in Firestore: $e');
      rethrow;
    }
  }

  /// Delete a galaxy from Firestore (soft delete)
  Future<void> deleteGalaxy(String galaxyId) async {
    try {
      final collection = _getGalaxyCollection();
      if (collection == null) {
        print('⚠️ No user authenticated, cannot delete galaxy from Firestore');
        return;
      }

      await collection.doc(galaxyId).update({
        'deleted': true,
        'deletedAt': DateTime.now().millisecondsSinceEpoch,
      });
      print('☁️ Soft deleted galaxy $galaxyId in Firestore');
    } catch (e) {
      print('⚠️ Error deleting galaxy from Firestore: $e');
      rethrow;
    }
  }

  /// Get active galaxy ID from Firestore user settings
  Future<String?> getActiveGalaxyId() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      return data?['activeGalaxyId'] as String?;
    } catch (e) {
      print('⚠️ Error getting active galaxy ID from Firestore: $e');
      return null;
    }
  }

  /// Set active galaxy ID in Firestore user settings
  Future<void> setActiveGalaxyId(String galaxyId) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        print('⚠️ No user authenticated, cannot set active galaxy in Firestore');
        return;
      }

      await _firestore.collection('users').doc(userId).set(
        {'activeGalaxyId': galaxyId},
        SetOptions(merge: true),
      );
      print('☁️ Set active galaxy $galaxyId in Firestore');
    } catch (e) {
      print('⚠️ Error setting active galaxy ID in Firestore: $e');
      rethrow;
    }
  }
}