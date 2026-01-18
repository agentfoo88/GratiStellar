import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../storage.dart';
import '../core/services/firebase_initializer.dart';
import '../core/utils/app_logger.dart';
import 'user_profile_migration_service.dart';

class AuthService {
  // Lazy-initialize Firebase services to handle cases where Firebase isn't ready yet
  FirebaseAuth? _authInstance;
  FirebaseFirestore? _firestoreInstance;

  /// Get FirebaseAuth instance, ensuring Firebase is initialized first
  FirebaseAuth get _auth {
    if (_authInstance == null) {
      if (!FirebaseInitializer.instance.isInitialized) {
        throw StateError(
          'Firebase not initialized. Cannot access authentication services. '
          'The app may be running in offline mode.'
        );
      }
      _authInstance = FirebaseAuth.instance;
    }
    return _authInstance!;
  }

  /// Get FirebaseFirestore instance, ensuring Firebase is initialized first
  FirebaseFirestore get _firestore {
    if (_firestoreInstance == null) {
      if (!FirebaseInitializer.instance.isInitialized) {
        throw StateError(
          'Firebase not initialized. Cannot access Firestore services. '
          'The app may be running in offline mode.'
        );
      }
      _firestoreInstance = FirebaseFirestore.instance;
    }
    return _firestoreInstance!;
  }

  final UserProfileMigrationService _migrationService = UserProfileMigrationService();

  // Get current user (returns null if Firebase not initialized)
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (e) {
      AppLogger.warning('⚠️ Cannot access currentUser: Firebase not initialized');
      return null;
    }
  }

  // Get current user stream
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (e) {
      AppLogger.warning('⚠️ Cannot access authStateChanges: Firebase not initialized');
      // Return a stream that emits null
      return Stream.value(null);
    }
  }

  // Check if user is signed in
  bool get isSignedIn {
    try {
      return _auth.currentUser != null;
    } catch (e) {
      AppLogger.warning('⚠️ Cannot check isSignedIn: Firebase not initialized');
      return false;
    }
  }

  // Check if user has email (upgraded from anonymous)
  bool get hasEmailAccount {
    try {
      final user = _auth.currentUser;
      return user != null && !user.isAnonymous;
    } catch (e) {
      AppLogger.warning('⚠️ Cannot check hasEmailAccount: Firebase not initialized');
      return false;
    }
  }

  // Sign in with email/password (for returning users)
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      // #region agent log
      if (kDebugMode) {
        AppLogger.auth('🔐 DEBUG: signInWithEmail called - email=$email');
      }
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
        if (kDebugMode) {
          AppLogger.auth('🔐 DEBUG: signInWithEmail completed - user=${refreshedUser?.uid}, isAnonymous=${refreshedUser?.isAnonymous}, email=${refreshedUser?.email}');
        }
        // #endregion

        // Update last seen
        await _firestore.collection('users').doc(refreshedUser!.uid).set({
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Migrate user profile (add missing fields)
        await _migrationService.loadAndMigrateProfile(refreshedUser.uid);

        return refreshedUser;
      }

      return user;
    } catch (e) {
      // #region agent log
      if (kDebugMode) {
        AppLogger.error('🔐 DEBUG: signInWithEmail failed - error=$e');
      }
      // #endregion
      AppLogger.auth('Error signing in with email: $e');
      rethrow;
    }
  }

  // Sign out - clear all local user data for privacy
  Future<void> signOut({bool keepData = false}) async {
    try {
      if (!keepData) {
        // Clear local data BEFORE signing out
        // This prevents next user from seeing previous user's data
        await _clearLocalUserData();
      }

      // Sign out from Firebase
      await _auth.signOut();

      AppLogger.auth('✅ Signed out${keepData ? ' (data preserved)' : ' and cleared local data'}');
    } catch (e) {
      AppLogger.auth('⚠️ Error during sign out: $e');
      // Still attempt sign out even if clear fails
      await _auth.signOut();
    }
  }

  // Sign out and keep local data (for anonymous users)
  Future<void> signOutKeepData() async {
    return signOut(keepData: true);
  }

  // Sign out and clear all data (default behavior)
  Future<void> signOutClearData() async {
    return signOut(keepData: false);
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
  Future<String?> getDisplayName({String? defaultName}) async {
    final user = _auth.currentUser;
    
    // If signed in with email, get from Firebase
    if (user != null && !user.isAnonymous) {
      // Try to get from Firebase Auth profile first
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        return user.displayName;
      }

      // Fallback to Firestore
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        final profileData = doc.data();
        
        // Migrate profile if needed (ensures fields are up to date)
        await _migrationService.migrateUserProfile(
          userId: user.uid,
          profileData: profileData,
        );
        
        return profileData?['displayName'] as String?;
      } catch (e) {
        AppLogger.error('Error getting display name: $e');
        return defaultName;
      }
    }
    
    // For anonymous users, get from local storage
    // This requires UserProfileManager to get the device ID
    // Return defaultName here - caller should use UserScopedStorage.getDisplayName() directly
    return defaultName;
  }

  // Update display name
  // For anonymous users, this should be handled via UserScopedStorage
  // This method only works for authenticated users
  Future<void> updateDisplayName(String displayName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      // For anonymous users, don't update Firebase - use UserScopedStorage instead
      if (user.isAnonymous) {
        throw Exception('Cannot update display name for anonymous users via AuthService. Use UserScopedStorage.setAnonymousDisplayName() instead.');
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

  /// Change password for current user (requires reauthentication)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      if (user.isAnonymous) {
        throw Exception('Cannot change password for anonymous users');
      }

      final email = user.email;
      if (email == null) {
        throw Exception('User email not found');
      }

      // Reauthenticate user (required by Firebase for sensitive operations)
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      AppLogger.auth('✅ User reauthenticated successfully');

      // Update password
      await user.updatePassword(newPassword);
      await user.reload();

      // Update timestamp in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'passwordChangedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.success('✅ Password changed successfully');
    } catch (e) {
      AppLogger.error('❌ Error changing password: $e');
      rethrow;
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }
      await user.sendEmailVerification();
      AppLogger.auth('✅ Verification email sent to: ${user.email}');
    } catch (e) {
      AppLogger.auth('❌ Error sending verification email: $e');
      rethrow;
    }
  }

  // Check if email is verified
  bool get isEmailVerified {
    final user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  // Create new account with email and password (for sign-up)
  Future<User?> createAccountWithEmailPassword(String email, String password, String? displayName) async {
    try {
      AppLogger.auth('🔐 Creating new account with email: $email');
      
      // Create user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to create user account');
      }

      // Set display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
        await user.reload();
      }

      // Create Firestore profile
      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'displayName': displayName ?? email,
        'isAnonymous': false,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Migrate user profile (add missing fields)
      await _migrationService.loadAndMigrateProfile(user.uid);

      AppLogger.auth('✅ Account created successfully: ${user.uid}');
      return user;
    } catch (e) {
      AppLogger.auth('❌ Error creating account: $e');
      rethrow;
    }
  }
}