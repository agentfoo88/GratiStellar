import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/user_scoped_storage.dart';
import '../core/utils/app_logger.dart';

/// Manages user profiles and tracks the active user
/// 
/// Supports multiple local users simultaneously and provides
/// methods to switch between users and create anonymous profiles.
class UserProfileManager extends ChangeNotifier {
  static const String _activeUserIdKey = 'active_user_id';
  
  String? _activeUserId;
  final AuthService _authService;

  UserProfileManager({
    required AuthService authService,
  }) : _authService = authService {
    _initialize();
  }

  /// Get current active user ID
  String? get activeUserId => _activeUserId;

  /// Initialize active user from storage or auth service
  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString(_activeUserIdKey);
      
      // If user is signed in with email, use their Firebase UID
      if (_authService.isSignedIn && _authService.hasEmailAccount) {
        final currentUser = _authService.currentUser;
        if (currentUser != null) {
          _activeUserId = currentUser.uid;
          if (_activeUserId != savedUserId) {
            await prefs.setString(_activeUserIdKey, _activeUserId!);
          }
        }
      } else if (savedUserId != null) {
        // Use saved user ID (for anonymous users with device-based IDs)
        _activeUserId = savedUserId;
      }
      
      AppLogger.data('👤 Initialized active user: ${_activeUserId ?? 'anonymous'}');
    } catch (e) {
      AppLogger.error('⚠️ Error initializing user profile manager: $e');
    }
  }

  /// Get or create active user ID
  /// 
  /// Returns the current user's ID if signed in, or creates/returns anonymous profile ID
  /// Never returns null - always creates an anonymous profile if needed
  /// 
  /// For anonymous users: Uses device ID (not Firebase UID) to support device-based profiles
  /// For email users: Uses Firebase UID
  Future<String> getOrCreateActiveUserId() async {
    // If user is signed in with email, use their Firebase UID
    if (_authService.hasEmailAccount) {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        _activeUserId = currentUser.uid;
        
        // Save to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_activeUserIdKey, _activeUserId!);
        
        AppLogger.data('👤 Active user (email): $_activeUserId');
        return _activeUserId!;
      }
    }
    
    // Anonymous user or not signed in - use device-based ID
    // Check if we have a saved anonymous profile
    if (_activeUserId == null) {
      final prefs = await SharedPreferences.getInstance();
      _activeUserId = prefs.getString(_activeUserIdKey);
      
      // If saved ID exists but doesn't start with 'anonymous_', it's invalid - clear it
      if (_activeUserId != null && !_activeUserId!.startsWith('anonymous_')) {
        AppLogger.warning('⚠️ Invalid saved user ID format, clearing: $_activeUserId');
        _activeUserId = null;
        await prefs.remove(_activeUserIdKey);
      }
      
      // Migrate old format (anonymous_device_123) to new format (anonymous_device_123_timestamp)
      if (_activeUserId != null && _activeUserId!.startsWith('anonymous_')) {
        final parts = _activeUserId!.split('_');
        // Old format: anonymous_device_123 (3 parts)
        // New format: anonymous_device_123_timestamp (4+ parts)
        if (parts.length == 3) {
          AppLogger.data('📦 Migrating old anonymous user ID format: $_activeUserId');
          // Keep the old ID but create a new one with timestamp
          // This preserves data while transitioning to new format
          _activeUserId = null;
          await prefs.remove(_activeUserIdKey);
        }
      }
    }
    
    // If still null, create anonymous profile
    _activeUserId ??= await createAnonymousProfile();
    
    // At this point, _activeUserId is guaranteed to be non-null and device-based
    return _activeUserId!;
  }

  /// Create an anonymous profile
  /// 
  /// Returns the anonymous user ID (device-specific with timestamp for uniqueness)
  /// Format: anonymous_device_123_1704123456 (device_id + timestamp)
  Future<String> createAnonymousProfile() async {
    // For anonymous users, we'll use a device-specific ID with timestamp
    // This allows multiple anonymous profiles on the same device
    final prefs = await SharedPreferences.getInstance();
    
    // Get or create persistent device ID (never cleared)
    String deviceId = prefs.getString('device_id') ?? '';
    if (deviceId.isEmpty) {
      // Generate device ID if not exists (persistent per device)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = DateTime.now().microsecondsSinceEpoch % 1000000;
      deviceId = 'device_${timestamp}_$random';
      await prefs.setString('device_id', deviceId);
      AppLogger.data('📱 Created persistent device ID: $deviceId');
    }
    
    // Generate unique user ID with timestamp suffix
    final userTimestamp = DateTime.now().millisecondsSinceEpoch;
    final anonymousUserId = 'anonymous_${deviceId}_$userTimestamp';
    
    _activeUserId = anonymousUserId;
    await prefs.setString(_activeUserIdKey, anonymousUserId);
    
    // Track that this user has data
    await UserScopedStorage.trackUserHasData(anonymousUserId);
    
    AppLogger.data('👤 Created anonymous profile: $anonymousUserId');
    notifyListeners();
    
    return anonymousUserId;
  }

  /// Switch to a different user
  /// 
  /// [userId] - The user ID to switch to (null for anonymous)
  Future<void> switchUser(String? userId) async {
    _activeUserId = userId;
    
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) {
      await prefs.setString(_activeUserIdKey, userId);
    } else {
      await prefs.remove(_activeUserIdKey);
    }
    
    AppLogger.data('👤 Switched to user: ${userId ?? 'anonymous'}');
    notifyListeners();
  }

  /// Get list of user IDs that have local data
  Future<List<String>> getLocalUserIds() async {
    return await UserScopedStorage.getLocalUserIds();
  }
}

