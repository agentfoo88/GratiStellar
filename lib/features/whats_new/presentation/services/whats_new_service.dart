import 'package:flutter/material.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../storage.dart';
import '../../data/release_notes_data.dart';

/// Service for managing What's New feature state
///
/// Handles tracking whether the user has seen the latest release notes
/// and whether to auto-show the modal on first launch after update.
class WhatsNewService extends ChangeNotifier {
  bool _isInitialized = false;
  bool _hasUnseenUpdates = false;
  bool _shouldAutoShow = false;
  int? _lastSeenBuild;

  /// Whether there are unseen updates (for badge indicator)
  bool get hasUnseenUpdates => _hasUnseenUpdates;

  /// Whether the modal should auto-show (first launch after update)
  bool get shouldAutoShow => _shouldAutoShow;

  /// Whether the service has been initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the service - compare current vs last seen build
  Future<void> initialize() async {
    try {
      AppLogger.info('📰 Initializing WhatsNewService...');

      _lastSeenBuild = await StorageService.getLastSeenWhatsNewBuild();
      final currentBuild = ReleaseNotesData.currentBuildNumber;

      AppLogger.info(
        '📰 Last seen build: $_lastSeenBuild, current build: $currentBuild',
      );

      if (_lastSeenBuild == null) {
        // First install - no auto-show, but mark current build as seen
        // This prevents showing "what's new" to new users
        _hasUnseenUpdates = false;
        _shouldAutoShow = false;
        await StorageService.saveLastSeenWhatsNewBuild(currentBuild);
        AppLogger.info('📰 First install detected - marking current build as seen');
      } else if (_lastSeenBuild! < currentBuild) {
        // Update detected - show badge and auto-show modal
        _hasUnseenUpdates = true;
        _shouldAutoShow = true;
        AppLogger.info('📰 Update detected - will show What\'s New');
      } else {
        // User is up to date
        _hasUnseenUpdates = false;
        _shouldAutoShow = false;
        AppLogger.info('📰 User is up to date');
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      AppLogger.error('❌ Error initializing WhatsNewService: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Mark updates as seen - update stored build number and remove badge
  Future<void> markAsSeen() async {
    if (!_hasUnseenUpdates && !_shouldAutoShow) {
      return;
    }

    AppLogger.info('📰 Marking What\'s New as seen');

    _hasUnseenUpdates = false;
    _shouldAutoShow = false;
    notifyListeners();

    final currentBuild = ReleaseNotesData.currentBuildNumber;
    await StorageService.saveLastSeenWhatsNewBuild(currentBuild);
  }

  /// Clear auto-show flag (prevents re-showing on same session)
  void clearAutoShow() {
    if (!_shouldAutoShow) {
      return;
    }

    AppLogger.info('📰 Clearing auto-show flag');
    _shouldAutoShow = false;
    notifyListeners();
  }
}
