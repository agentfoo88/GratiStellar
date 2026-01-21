import 'dart:async';
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

  // Cache for user profile data to avoid redundant reads
  Map<String, dynamic>? _cachedProfileData;
  String? _cachedProfileUserId;
  DateTime? _cachedProfileTimestamp;
  static const Duration _profileCacheExpiry = Duration(minutes: 5);

  // Debouncing for profile updates to batch multiple updates together
  Timer? _profileUpdateTimer;
  final Map<String, dynamic> _pendingProfileUpdates = {};
  static const Duration _profileUpdateDebounce = Duration(seconds: 2);

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

        // Update last seen (batched with other profile updates)
        scheduleProfileUpdate(refreshedUser!.uid, {
          'lastSeen': FieldValue.serverTimestamp(),
        });

        // Read profile once, then migrate with existing data (avoids double-read)
        final doc = await _firestore.collection('users').doc(refreshedUser.uid).get();
        final profileData = doc.data();

        // Migrate user profile (add missing fields) using already-read data
        final migrationResult = await _migrationService.migrateUserProfile(
          userId: refreshedUser.uid,
          profileData: profileData,
        );
        if (migrationResult?.profileData != null) {
          _cachedProfileData = migrationResult!.profileData;
          _cachedProfileUserId = refreshedUser.uid;
          _cachedProfileTimestamp = DateTime.now();
        }

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

      // Flush any pending profile updates before signing out
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _flushPendingProfileUpdates(userId);
      }

      // Clear profile cache on sign out
      _cachedProfileData = null;
      _cachedProfileUserId = null;
      _cachedProfileTimestamp = null;

      // Cancel any pending profile updates
      _profileUpdateTimer?.cancel();
      _profileUpdateTimer = null;
      _pendingProfileUpdates.clear();

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

      // Check cache first to avoid redundant reads
      if (_cachedProfileData != null &&
          _cachedProfileUserId == user.uid &&
          _cachedProfileTimestamp != null &&
          DateTime.now().difference(_cachedProfileTimestamp!) < _profileCacheExpiry) {
        final cachedDisplayName = _cachedProfileData!['displayName'] as String?;
        if (cachedDisplayName != null && cachedDisplayName.isNotEmpty) {
          return cachedDisplayName;
        }
      }

      // Fallback to Firestore if cache miss or expired
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        final profileData = doc.data();
        
        // Cache the profile data
        _cachedProfileData = profileData;
        _cachedProfileUserId = user.uid;
        _cachedProfileTimestamp = DateTime.now();
        
        // Migrate profile if needed (ensures fields are up to date)
        final migrationResult = await _migrationService.migrateUserProfile(
          userId: user.uid,
          profileData: profileData,
        );
        
        // Update cache with migrated data if available
        if (migrationResult?.profileData != null) {
          _cachedProfileData = migrationResult!.profileData;
        }
        
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
      final profileData = {
        'email': email,
        'displayName': displayName ?? email,
        'isAnonymous': false,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('users').doc(user.uid).set(
        profileData,
        SetOptions(merge: true),
      );

      // Migrate user profile with already-created data (avoids redundant read)
      final migrationResult = await _migrationService.migrateUserProfile(
        userId: user.uid,
        profileData: profileData,
      );
      if (migrationResult?.profileData != null) {
        _cachedProfileData = migrationResult!.profileData;
        _cachedProfileUserId = user.uid;
        _cachedProfileTimestamp = DateTime.now();
      } else {
        // Cache the initial profile data if migration didn't return data
        _cachedProfileData = profileData;
        _cachedProfileUserId = user.uid;
        _cachedProfileTimestamp = DateTime.now();
      }

      AppLogger.auth('✅ Account created successfully: ${user.uid}');
      return user;
    } catch (e) {
      AppLogger.auth('❌ Error creating account: $e');
      rethrow;
    }
  }

  /// Schedule a profile update with debouncing to batch multiple updates
  void scheduleProfileUpdate(String userId, Map<String, dynamic> updates) {
    // Merge updates into pending map
    _pendingProfileUpdates.addAll(updates);

    // Cancel existing timer
    _profileUpdateTimer?.cancel();

    // Schedule new update
    _profileUpdateTimer = Timer(_profileUpdateDebounce, () async {
      if (_pendingProfileUpdates.isEmpty) return;

      try {
        final updatesToApply = Map<String, dynamic>.from(_pendingProfileUpdates);
        _pendingProfileUpdates.clear();

        await _firestore.collection('users').doc(userId).set(
          updatesToApply,
          SetOptions(merge: true),
        );

        AppLogger.data('✅ Batched profile update applied');
      } catch (e) {
        AppLogger.error('❌ Error applying batched profile update: $e');
        // Retry individual updates if batch fails
        final failedUpdates = Map<String, dynamic>.from(_pendingProfileUpdates);
        _pendingProfileUpdates.clear();
        for (final entry in failedUpdates.entries) {
          try {
            await _firestore.collection('users').doc(userId).set(
              {entry.key: entry.value},
              SetOptions(merge: true),
            );
          } catch (e2) {
            AppLogger.error('❌ Error applying individual profile update ${entry.key}: $e2');
          }
        }
      }
    });
  }

  /// Force immediate application of pending profile updates (called on sign out or critical operations)
  Future<void> _flushPendingProfileUpdates(String userId) async {
    _profileUpdateTimer?.cancel();
    _profileUpdateTimer = null;

    if (_pendingProfileUpdates.isEmpty) return;

    try {
      final updatesToApply = Map<String, dynamic>.from(_pendingProfileUpdates);
      _pendingProfileUpdates.clear();

      await _firestore.collection('users').doc(userId).set(
        updatesToApply,
        SetOptions(merge: true),
      );

      AppLogger.data('✅ Flushed pending profile updates');
    } catch (e) {
      AppLogger.error('❌ Error flushing pending profile updates: $e');
      _pendingProfileUpdates.clear();
    }
  }
}