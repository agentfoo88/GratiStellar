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

  // Link anonymous account to email/password
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

      final userCredential = await user.linkWithCredential(credential);

      // Update Firestore profile
      await _firestore.collection('users').doc(user.uid).update({
        'email': email,
        'isAnonymous': false,
        'linkedAt': FieldValue.serverTimestamp(),
      });

      return userCredential.user;
    } catch (e) {
      print('Error linking email/password: $e');
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
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastSeen': FieldValue.serverTimestamp(),
        });
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
    final user = _auth.currentUser;
    if (user == null) return;

    await user.updateDisplayName(displayName);
    await _firestore.collection('users').doc(user.uid).update({
      'displayName': displayName,
    });
  }
}