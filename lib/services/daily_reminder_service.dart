import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../storage.dart';
import '../core/utils/app_logger.dart';

class DailyReminderService extends ChangeNotifier {
  // Notification plugin instance
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Shared preferences instance
  SharedPreferences? _prefs;

  // State
  bool _isEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 21, minute: 0); // Default 9 PM
  bool _hasShownPrompt = false;
  bool _isInitialized = false;

  // SharedPreferences keys
  static const String _keyEnabled = 'reminder_enabled';
  static const String _keyHour = 'reminder_hour';
  static const String _keyMinute = 'reminder_minute';
  static const String _keyPromptShown = 'reminder_prompt_shown';
  static const String _keyLastChecked = 'reminder_last_checked';

  // Notification ID
  static const int _notificationId = 0;

  // Public getters
  bool get isEnabled => _isEnabled;
  TimeOfDay get reminderTime => _reminderTime;
  bool get hasShownPrompt => _hasShownPrompt;
  bool get isInitialized => _isInitialized;

  /// Initialize the service - call this once on app startup
  Future<void> initialize() async {
    try {
      AppLogger.info('🔔 Initializing DailyReminderService...');

      // Initialize timezone data
      tz.initializeTimeZones();

      // Set local timezone using IANA timezone name
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timeZoneInfo.identifier;
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        // Fallback to UTC if timezone not found
        AppLogger.warning('⚠️ Could not set timezone $timeZoneName, using UTC');
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      // Load SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      // Initialize notification settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@drawable/ic_notification');

      const DarwinInitializationSettings iOSSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const DarwinInitializationSettings macOSSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const LinuxInitializationSettings linuxSettings =
          LinuxInitializationSettings(defaultActionName: 'Open');

      const WindowsInitializationSettings windowsSettings =
          WindowsInitializationSettings(
        appName: 'GratiStellar',
        appUserModelId: 'com.example.gratistellar',
        guid: 'c8f8b5c0-5e2f-4f1a-9e0a-9d0f1e2a3b4c',
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iOSSettings,
        macOS: macOSSettings,
        linux: linuxSettings,
        windows: windowsSettings,
      );

      await _notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Create Android notification channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'daily_reminders',
        'Daily Reminders',
        description: 'Daily gratitude reminders',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Load saved preferences
      _isEnabled = _prefs!.getBool(_keyEnabled) ?? false;
      final savedHour = _prefs!.getInt(_keyHour) ?? 21;
      final savedMinute = _prefs!.getInt(_keyMinute) ?? 0;
      _reminderTime = TimeOfDay(hour: savedHour, minute: savedMinute);
      _hasShownPrompt = _prefs!.getBool(_keyPromptShown) ?? false;

      // Reschedule notification if enabled (since we removed recurring)
      if (_isEnabled) {
        final hasPermission = await checkPermissionStatus();
        if (hasPermission) {
          await scheduleReminder(_reminderTime);
          AppLogger.info('🔔 Rescheduled daily reminder at startup');
        } else {
          AppLogger.warning('⚠️ Reminders enabled but permission not granted - disabling');
          _isEnabled = false;
          await _prefs!.setBool(_keyEnabled, false);
        }
      }

      AppLogger.success(
          '✅ DailyReminderService initialized (enabled: $_isEnabled, time: ${_reminderTime.format24()})');
      
      // Mark initialization as complete
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      AppLogger.error('❌ Error initializing DailyReminderService: $e');
      // Even on error, mark as initialized to prevent infinite waiting
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Request notification permission (Android 13+ and iOS)
  Future<bool> requestPermission() async {
    try {
      AppLogger.info('🔔 Requesting notification permission...');

      // Check if already granted to avoid unnecessary dialogs
      final alreadyGranted = await checkPermissionStatus();
      if (alreadyGranted) {
        AppLogger.info('✅ Notification permission already granted');
        return true;
      }

      // Android
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? granted = await androidImplementation.requestNotificationsPermission();
        if (granted == true) {
          AppLogger.success('✅ Android notification permission granted');
          return true;
        } else {
          AppLogger.warning('⚠️ Android notification permission not granted');
          return false;
        }
      }

      // iOS/macOS
      final bool? iOSGranted = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: false,
            sound: true,
          );

      if (iOSGranted != null && iOSGranted) {
        AppLogger.success('✅ iOS notification permission granted');
        return true;
      }

      final bool? macOSGranted = await _notifications
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: false,
            sound: true,
          );

      if (macOSGranted != null && macOSGranted) {
        AppLogger.success('✅ macOS notification permission granted');
        return true;
      }

      // If we get here on a platform that doesn't need permission, assume granted
      AppLogger.info('ℹ️ No permission needed or already granted');
      return true;
    } catch (e) {
      AppLogger.error('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  /// Check if notifications are currently enabled (without requesting)
  Future<bool> checkPermissionStatus() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? enabled = await androidImplementation.areNotificationsEnabled();
        AppLogger.info('🔔 Notification permission status: $enabled');
        return enabled ?? false;
      }

      // iOS/macOS - assume granted if we got here (permission requested at init)
      return true;
    } catch (e) {
      AppLogger.error('❌ Error checking notification permission: $e');
      return false;
    }
  }

  /// Schedule a daily reminder at the specified time
  Future<void> scheduleReminder(TimeOfDay time) async {
    try {
      AppLogger.info('🔔 Scheduling daily reminder for ${time.format24()}...');

      // Verify permission before scheduling
      final hasPermission = await checkPermissionStatus();
      if (!hasPermission) {
        AppLogger.error('❌ Cannot schedule reminder: notification permission not granted');
        throw Exception('Notification permission not granted. Please enable notifications in Settings.');
      }

      // Cancel any existing notification
      await _notifications.cancel(id: _notificationId);

      // Calculate next notification time
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
        AppLogger.info('⏰ Time already passed today, scheduling for tomorrow');
      }

      // Schedule the notification
      await _notifications.zonedSchedule(
        id: _notificationId,
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminders',
            'Daily Reminders',
            channelDescription: 'Daily gratitude reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: 'Time for gratitude ✨',
        body: 'Take a moment to reflect on what you\'re grateful for today.',
      );

      // Save the new time
      _reminderTime = time;
      await _saveReminderTime(time);

      AppLogger.success(
          '✅ Daily reminder scheduled for ${time.format24()} (next: ${scheduledDate.toLocal()})');
      notifyListeners();
    } catch (e) {
      AppLogger.error('❌ Error scheduling reminder: $e');
      rethrow;
    }
  }

  /// Cancel the scheduled reminder
  Future<void> cancelReminder() async {
    try {
      AppLogger.info('🔔 Cancelling daily reminder...');
      await _notifications.cancel(id: _notificationId);
      AppLogger.success('✅ Daily reminder cancelled');
    } catch (e) {
      AppLogger.error('❌ Error cancelling reminder: $e');
    }
  }

  /// Reschedule reminder for tomorrow (called when user creates a gratitude)
  /// This prevents the reminder from firing today if already completed
  Future<void> rescheduleForTomorrow() async {
    if (!_isEnabled) return;

    // Verify permission before rescheduling
    final hasPermission = await checkPermissionStatus();
    if (!hasPermission) {
      AppLogger.warning('⚠️ Cannot reschedule: notification permission not granted');
      return;
    }

    try {
      AppLogger.info('🔔 Rescheduling reminder for tomorrow...');

      // Cancel today's pending notification
      await cancelReminder();

      // Calculate tomorrow at the same time
      final now = tz.TZDateTime.now(tz.local);
      final tomorrow = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        _reminderTime.hour,
        _reminderTime.minute,
      ).add(const Duration(days: 1));

      // Schedule the notification for tomorrow
      await _notifications.zonedSchedule(
        id: _notificationId,
        scheduledDate: tomorrow,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminders',
            'Daily Reminders',
            channelDescription: 'Daily gratitude reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: 'Time for gratitude ✨',
        body: 'Take a moment to reflect on what you\'re grateful for today.',
      );

      AppLogger.success(
          '✅ Reminder rescheduled for tomorrow at ${_reminderTime.format24()} (${tomorrow.toLocal()})');
    } catch (e) {
      AppLogger.error('❌ Error rescheduling reminder for tomorrow: $e');
    }
  }

  /// Enable or disable reminders
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _prefs?.setBool(_keyEnabled, enabled);
    AppLogger.info('🔔 Reminders ${enabled ? "enabled" : "disabled"}');
    notifyListeners();
  }

  /// Mark the first-time prompt as shown
  Future<void> markPromptShown() async {
    _hasShownPrompt = true;
    await _prefs?.setBool(_keyPromptShown, true);
    AppLogger.info('🔔 Reminder prompt marked as shown');
    notifyListeners();
  }

  /// Check if the user has created any gratitude today
  Future<bool> hasCreatedGratitudeToday() async {
    try {
      final stars = await StorageService.loadGratitudeStars();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      // Check if ANY non-deleted star was created today
      final createdToday = stars.any((star) =>
          !star.deleted &&
          star.createdAt.isAfter(today) &&
          star.createdAt.isBefore(tomorrow));

      AppLogger.info(
          '🔔 Has created gratitude today: $createdToday (checked ${stars.length} stars)');
      return createdToday;
    } catch (e) {
      AppLogger.error('❌ Error checking today\'s gratitudes: $e');
      return false; // Assume false on error
    }
  }

  /// Smart check: Should we send a notification?
  /// Only sends if enabled, hasn't checked today, and user hasn't created a star
  Future<void> checkAndNotify() async {
    try {
      AppLogger.info('🔔 Running smart notification check...');

      // 1. Check if enabled
      if (!_isEnabled) {
        AppLogger.info('ℹ️ Reminders not enabled, skipping');
        return;
      }

      // 2. Check if already checked today (avoid duplicate notifications)
      final lastChecked = await _getLastCheckedDate();
      final now = DateTime.now();
      if (lastChecked != null && _isSameDay(lastChecked, now)) {
        AppLogger.info('ℹ️ Already checked today, skipping');
        return;
      }

      // 3. Check if user created ANY star today
      final createdToday = await hasCreatedGratitudeToday();

      if (createdToday) {
        AppLogger.info('✅ User created gratitude today, skipping notification');
      } else {
        AppLogger.info(
            '📤 User has not created gratitude today, sending notification');
        await _sendNotification();
      }

      // 4. Mark as checked for today
      await _saveLastCheckedDate(now);
    } catch (e) {
      AppLogger.error('❌ Error in checkAndNotify: $e');
    }
  }

  /// Send the notification immediately (used by checkAndNotify)
  Future<void> _sendNotification() async {
    try {
      await _notifications.show(
        id: _notificationId,
        title: 'Time for gratitude ✨',
        body: 'Take a moment to reflect on what you\'re grateful for today.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminders',
            'Daily Reminders',
            channelDescription: 'Daily gratitude reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: true,
          ),
        ),
      );
      AppLogger.success('✅ Notification sent');
    } catch (e) {
      AppLogger.error('❌ Error sending notification: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    AppLogger.info('🔔 Notification tapped: ${response.payload}');
    // App will open automatically - no special deep linking needed
  }

  // Helper methods for SharedPreferences

  Future<void> _saveReminderTime(TimeOfDay time) async {
    await _prefs?.setInt(_keyHour, time.hour);
    await _prefs?.setInt(_keyMinute, time.minute);
  }

  Future<DateTime?> _getLastCheckedDate() async {
    final timestamp = _prefs?.getInt(_keyLastChecked);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  Future<void> _saveLastCheckedDate(DateTime date) async {
    await _prefs?.setInt(_keyLastChecked, date.millisecondsSinceEpoch);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

// Extension to format TimeOfDay as 24-hour string
extension TimeOfDayFormat on TimeOfDay {
  String format24() {
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
