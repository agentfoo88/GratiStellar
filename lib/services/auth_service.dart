import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/app_logger.dart';

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
  bool get hasEmailAccount {
    final user = _auth.currentUser;
    final result = user != null && !user.isAnonymous;
    // #region agent log
    AppLogger.auth('🔐 DEBUG: hasEmailAccount check - user=${user?.uid}, isAnonymous=${user?.isAnonymous}, result=$result');
    // #endregion
    return result;
  }

  // Sign in anonymously with display name
  Future<User?> signInAnonymously(String displayName) async {
    try {
      AppLogger.auth('🔵 Step 1: Starting Firebase anonymous sign-in...');
      final userCredential = await _auth.signInAnonymously();
      AppLogger.auth('🔵 Step 2: Firebase sign-in completed');

      final user = userCredential.user;
      AppLogger.info('🔵 Step 3: Got user: ${user?.uid ?? "null"}');

      if (user != null) {
        AppLogger.info('🔵 Step 4: Saving anonymous UID to SharedPreferences...');
        await _saveAnonymousUid(user.uid);
        AppLogger.success('🔵 Step 5: UID saved successfully');

        AppLogger.info('🔵 Step 6: Updating display name...');
        await user.updateDisplayName(displayName);
        AppLogger.info('🔵 Step 7: Display name updated');

        AppLogger.data('🔵 Step 8: Creating user profile in Firestore...');
        await _firestore.collection('users').doc(user.uid).set({
          'displayName': displayName,
          'createdAt': FieldValue.serverTimestamp(),
          'isAnonymous': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
        AppLogger.data('🔵 Step 9: Firestore profile created');
      }

      AppLogger.info('🔵 Step 10: Returning user');
      return user;
    } catch (e) {
      AppLogger.auth('🔴 Error signing in anonymously: $e');
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

        // Reload user to ensure auth state is fresh
        await userCredential.user!.reload();
        final refreshedUser = _auth.currentUser;

        // Update Firestore profile
        await _firestore.collection('users').doc(refreshedUser!.uid).set({
          'email': email,
          'displayName': refreshedUser.displayName,
          'isAnonymous': false,
          'linkedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Clear anonymous UID since account is now linked to email
        await _clearAnonymousUid();

        AppLogger.auth('✅ Successfully linked anonymous account to email');
        return refreshedUser;

      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use' || e.code == 'credential-already-in-use') {
          // Email already exists - we need to merge data
          AppLogger.auth('⚠️ Email already in use. Attempting to merge data...');

          // Save current anonymous user's data reference
          final anonymousUid = user.uid;
          final anonymousDisplayName = user.displayName;

          // Sign in with the existing email account
          final existingAccountCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          AppLogger.auth('✅ Signed into existing account: ${existingAccountCredential.user!.uid}');

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

          // Clear anonymous UID since we're now signed into email account
          await _clearAnonymousUid();

          return existingAccountCredential.user;
        }
        rethrow;
      }
    } catch (e) {
      AppLogger.auth('❌ Error linking email/password: $e');
      rethrow;
    }
  }

  // Sign in with email/password (for returning users)
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      // #region agent log
      AppLogger.auth('🔐 DEBUG: signInWithEmail called - email=$email');
      // #endregion

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      // Reload user to ensure auth state is fresh
      if (user != null) {
        await user.reload();
        final refreshedUser = _auth.currentUser;

        // #region agent log
        AppLogger.auth('🔐 DEBUG: signInWithEmail completed - user=${refreshedUser?.uid}, isAnonymous=${refreshedUser?.isAnonymous}, email=${refreshedUser?.email}');
        // #endregion

        // Update last seen
        await _firestore.collection('users').doc(refreshedUser!.uid).set({
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return refreshedUser;
      }

      return user;
    } catch (e) {
      // #region agent log
      AppLogger.error('🔐 DEBUG: signInWithEmail failed - error=$e');
      // #endregion
      AppLogger.auth('Error signing in with email: $e');
      rethrow;
    }
  }

  // Sign out - clear all local user data for privacy
  Future<void> signOut() async {
    try {
      // Clear local data BEFORE signing out
      // This prevents next user from seeing previous user's data
      await _clearLocalUserData();

      // Sign out from Firebase
      await _auth.signOut();

      AppLogger.auth('✅ Signed out and cleared local data');
    } catch (e) {
      AppLogger.auth('⚠️ Error during sign out: $e');
      // Still attempt sign out even if clear fails
      await _auth.signOut();
    }
  }

// Helper method to clear all local user data
  Future<void> _clearLocalUserData() async {
    try {
      // Use StorageService's centralized clear method
      await StorageService.clearAllData();

      AppLogger.data('🗑️ Cleared all local user data');
    } catch (e) {
      AppLogger.error('⚠️ Error clearing local data: $e');
      rethrow;
    }
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
      AppLogger.error('Error getting display name: $e');
      return null;
    }
  }

  // Save anonymous UID to SharedPreferences
  Future<void> _saveAnonymousUid(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('anonymous_uid', uid);
      AppLogger.data('💾 Saved anonymous UID: $uid');
    } catch (e) {
      AppLogger.error('⚠️ Error saving anonymous UID: $e');
    }
  }

  // Get saved anonymous UID
  Future<String?> getSavedAnonymousUid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('anonymous_uid');
    } catch (e) {
      AppLogger.error('⚠️ Error getting saved anonymous UID: $e');
      return null;
    }
  }

  // Clear saved anonymous UID
  Future<void> _clearAnonymousUid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('anonymous_uid');
      AppLogger.data('🗑️ Cleared saved anonymous UID');
    } catch (e) {
      AppLogger.error('⚠️ Error clearing anonymous UID: $e');
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

      AppLogger.success('✅ Display name updated to: $displayName');
    } catch (e) {
      AppLogger.error('❌ Error updating display name: $e');
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      AppLogger.auth('✅ Password reset email sent to: $email');
    } catch (e) {
      AppLogger.auth('❌ Error sending password reset email: $e');
      rethrow;
    }
  }
}