import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../storage.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's stars collection reference
  CollectionReference? get _starsCollection {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection('stars');
  }

  // Upload all local stars to Firestore (batch operation)
  Future<void> uploadStars(List<GratitudeStar> stars) async {
    if (_starsCollection == null) {
      throw Exception('No user signed in');
    }

    print('📤 Uploading ${stars.length} stars to Firestore...');

    // Firestore batch limit is 500 operations
    const batchSize = 500;

    for (var i = 0; i < stars.length; i += batchSize) {
      final batch = _firestore.batch();
      final end = (i + batchSize < stars.length) ? i + batchSize : stars.length;
      final batchStars = stars.sublist(i, end);

      for (final star in batchStars) {
        final docRef = _starsCollection!.doc(star.id);
        batch.set(docRef, star.toJson());
      }

      await batch.commit();
      print('📤 Uploaded batch ${i ~/ batchSize + 1} (${batchStars.length} stars)');
    }

    print('✅ All stars uploaded successfully');
  }

  // Download all stars from Firestore
  Future<List<GratitudeStar>> downloadStars() async {
    if (_starsCollection == null) {
      throw Exception('No user signed in');
    }

    print('📥 Downloading stars from Firestore...');

    final snapshot = await _starsCollection!.get();
    final stars = snapshot.docs
        .map((doc) => GratitudeStar.fromJson(doc.data() as Map<String, dynamic>))
        .toList();

    print('✅ Downloaded ${stars.length} stars');
    return stars;
  }

  // Sync: merge local and cloud data
  Future<List<GratitudeStar>> syncStars(List<GratitudeStar> localStars) async {
    if (_starsCollection == null) {
      throw Exception('No user signed in');
    }

    print('🔄 Syncing stars...');

    // Download cloud stars
    final cloudStars = await downloadStars();

    // Create map for efficient lookup
    final cloudStarsMap = {for (var star in cloudStars) star.id: star};
    final localStarsMap = {for (var star in localStars) star.id: star};

    // Merge logic: newest timestamp wins
    final mergedStars = <GratitudeStar>[];
    final allIds = {...localStarsMap.keys, ...cloudStarsMap.keys};

    for (final id in allIds) {
      final localStar = localStarsMap[id];
      final cloudStar = cloudStarsMap[id];

      if (localStar == null) {
        // Only in cloud
        mergedStars.add(cloudStar!);
      } else if (cloudStar == null) {
        // Only local - upload it
        mergedStars.add(localStar);
      } else {
        // In both - keep newer one
        final localNewer = localStar.createdAt.isAfter(cloudStar.createdAt);
        mergedStars.add(localNewer ? localStar : cloudStar);
      }
    }

    // Upload merged results back to cloud
    await uploadStars(mergedStars);

    print('✅ Sync complete. Total stars: ${mergedStars.length}');
    return mergedStars;
  }

  // Add a single star to Firestore
  Future<void> addStar(GratitudeStar star) async {
    if (_starsCollection == null) return;

    await _starsCollection!.doc(star.id).set(star.toJson());
    print('➕ Star added to Firestore: ${star.id}');
  }

  // Update a star in Firestore
  Future<void> updateStar(GratitudeStar star) async {
    if (_starsCollection == null) return;

    await _starsCollection!.doc(star.id).update(star.toJson());
    print('✏️ Star updated in Firestore: ${star.id}');
  }

  // Delete a star from Firestore
  Future<void> deleteStar(String starId) async {
    if (_starsCollection == null) return;

    await _starsCollection!.doc(starId).delete();
    print('🗑️ Star deleted from Firestore: $starId');
  }

  // Update user's last sync timestamp
  Future<void> updateLastSync() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).update({
      'lastSync': FieldValue.serverTimestamp(),
    });
  }
}