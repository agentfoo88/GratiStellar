import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/utils/app_logger.dart';

/// Triggers the platform in-app review prompt when conditions are met:
/// - Enough app launches (main screen visits)
/// - Enough days since first launch
/// - Cooldown since last request
class InAppReviewService {
  InAppReviewService._();
  static final InAppReviewService instance = InAppReviewService._();

  static const String _keyFirstLaunchTimeMs = 'review_first_launch_time_ms';
  static const String _keyLaunchCount = 'review_launch_count';
  static const String _keyLastRequestTimeMs = 'review_last_request_time_ms';

  final InAppReview _inAppReview = InAppReview.instance;

  /// Call when the user has reached the main gratitude screen (after onboarding).
  /// Increments launch count and may request a store review if conditions are met.
  Future<void> maybeRequestReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // First time: record first launch time
      final firstLaunchMs = prefs.getInt(_keyFirstLaunchTimeMs);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (firstLaunchMs == null) {
        await prefs.setInt(_keyFirstLaunchTimeMs, nowMs);
      }
      final firstLaunch = firstLaunchMs ?? nowMs;

      // Increment launch count
      final count = (prefs.getInt(_keyLaunchCount) ?? 0) + 1;
      await prefs.setInt(_keyLaunchCount, count);

      final daysSinceFirst = (nowMs - firstLaunch) / (1000 * 60 * 60 * 24);
      final lastRequestMs = prefs.getInt(_keyLastRequestTimeMs);
      final daysSinceLastRequest = lastRequestMs != null
          ? (nowMs - lastRequestMs) / (1000 * 60 * 60 * 24)
          : double.infinity;

      final minLaunches = AppConfig.reviewMinLaunchCount;
      final minDays = AppConfig.reviewMinDaysSinceFirstLaunch.toDouble();
      final cooldownDays = AppConfig.reviewCooldownDays.toDouble();

      if (count < minLaunches ||
          daysSinceFirst < minDays ||
          daysSinceLastRequest < cooldownDays) {
        return;
      }

      if (!await _inAppReview.isAvailable()) {
        AppLogger.info('In-app review not available on this device');
        return;
      }

      await prefs.setInt(_keyLastRequestTimeMs, nowMs);
      await _inAppReview.requestReview();
      AppLogger.info('In-app review requested');
    } catch (e, st) {
      AppLogger.error('InAppReviewService error: $e');
      AppLogger.info('Stack: $st');
    }
  }
}
