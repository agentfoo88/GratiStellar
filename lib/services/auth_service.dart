import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Check if user has email (upgraded from anonymous)
  bool get hasEmailAccount =>
      _auth.currentUser != null &&
          !_auth.currentUser!.isAnonymous;

  // Sign in anonymously with display name
  Future<User?> signInAnonymously(String displayName) async {
    try {
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
        // Update display name
        await user.updateDisplayName(displayName);

        // Create user profile in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'displayName': displayName,
          'createdAt': FieldValue.serverTimestamp(),
          'isAnonymous': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  // Link anonymous account to email/password OR sign in if account exists
  Future<User?> linkEmailPassword(String email, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      // Check if already linked
      if (!user.isAnonymous) {
        throw Exception('Account is already linked to email');
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      try {
        // Try to link the credential
        final userCredential = await user.linkWithCredential(credential);

        // Update Firestore profile
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'displayName': userCredential.user!.displayName,
          'isAnonymous': false,
          'linkedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print('✅ Successfully linked anonymous account to email');
        return userCredential.user;

      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use' || e.code == 'credential-already-in-use') {
          // Email already exists - we need to merge data
          print('⚠️ Email already in use. Attempting to merge data...');

          // Save current anonymous user's data reference
          final anonymousUid = user.uid;
          final anonymousDisplayName = user.displayName;

          // Sign in with the existing email account
          final existingAccountCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          print('✅ Signed into existing account: ${existingAccountCredential.user!.uid}');

          // If anonymous user had a display name and existing account doesn't, transfer it
          if (anonymousDisplayName != null &&
              anonymousDisplayName.isNotEmpty &&
              existingAccountCredential.user!.displayName == null) {
            await existingAccountCredential.user!.updateDisplayName(anonymousDisplayName);
            await _firestore.collection('users').doc(existingAccountCredential.user!.uid).set({
              'displayName': anonymousDisplayName,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }

          // Update last seen
          await _firestore.collection('users').doc(existingAccountCredential.user!.uid).set({
            'lastSeen': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // Note: We'll merge the stars in the next step using FirestoreService
          // Store the old anonymous UID for data migration
          await _firestore.collection('users').doc(existingAccountCredential.user!.uid).set({
            'mergedFromAnonymous': anonymousUid,
            'mergedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          return existingAccountCredential.user;
        }
        rethrow;
      }
    } catch (e) {
      print('❌ Error linking email/password: $e');
      rethrow;
    }
  }

  // Sign in with email/password (for returning users)
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last seen
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return userCredential.user;
    } catch (e) {
      print('Error signing in with email: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user display name
  Future<String?> getDisplayName() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Try to get from Firebase Auth profile first
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName;
    }

    // Fallback to Firestore
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['displayName'] as String?;
    } catch (e) {
      print('Error getting display name: $e');
      return null;
    }
  }

  // Update display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      await user.updateDisplayName(displayName);
      await user.reload();

      // Also update in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Display name updated to: $displayName');
    } catch (e) {
      print('❌ Error updating display name: $e');
      rethrow;
    }
  }
}