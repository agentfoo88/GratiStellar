import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../services/daily_reminder_service.dart';
import '../../../../widgets/reminder_prompt_bottom_sheet.dart';

/// Controller for managing reminder prompt logic
class ReminderController {
  final BuildContext context;
  final bool Function() mounted;

  ReminderController({
    required this.context,
    required this.mounted,
  });

  /// Check and show reminder prompt if conditions are met
  Future<void> checkAndShowReminderPrompt() async {
    if (!mounted()) return;

    // Capture service and navigator before async operations
    final reminderService = Provider.of<DailyReminderService>(context, listen: false);
    final navigator = Navigator.of(context);

    if (!reminderService.isInitialized) {
      AppLogger.info('🔔 Reminder service not initialized, waiting...');
      // Poll for initialization with timeout (max 1 second)
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted()) return;
        // Use navigator.context after async gap - safe because we check mounted() and navigator.mounted
        // ignore: use_build_context_synchronously
        final service = Provider.of<DailyReminderService>(navigator.context, listen: false);
        if (service.isInitialized) {
          AppLogger.info(
            '🔔 Reminder service initialized after ${(i + 1) * 100}ms',
          );
          break;
        }
      }
    }

    if (!mounted()) return;

    // Read fresh state after potential initialization wait
    // Use navigator.context after async gap - safe because we check mounted() and navigator.mounted
    // ignore: use_build_context_synchronously
    final freshService = Provider.of<DailyReminderService>(navigator.context, listen: false);

    // Defensive check: Don't show if already shown OR if reminder is already enabled
    if (freshService.hasShownPrompt) {
      AppLogger.info('🔔 Reminder prompt already shown, skipping');
      return;
    }

    if (freshService.isEnabled) {
      AppLogger.info('🔔 Reminders already enabled, skipping prompt');
      return;
    }

    AppLogger.info(
      '🔔 Reminder prompt conditions met (not shown: ${!freshService.hasShownPrompt}, not enabled: ${!freshService.isEnabled}), waiting 2s...',
    );

    // Wait 2 seconds after birth animation completes
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted()) return;

    // Check again after delay with fresh state (user might have enabled during wait)
    // Use navigator.context after async gap - safe because we check mounted() and navigator.mounted
    // ignore: use_build_context_synchronously
    final finalService = Provider.of<DailyReminderService>(navigator.context, listen: false);

    if (finalService.hasShownPrompt) {
      AppLogger.info('🔔 Reminder prompt was shown during wait, skipping');
      return;
    }

    if (finalService.isEnabled) {
      AppLogger.info('🔔 Reminders were enabled during wait, skipping prompt');
      return;
    }

    // Final defensive check before showing
    if (!finalService.isInitialized) {
      AppLogger.warning(
        '⚠️ Reminder service still not initialized, skipping prompt to avoid race condition',
      );
      return;
    }

    AppLogger.info('🔔 Showing reminder prompt bottom sheet');

    // Show bottom sheet - use navigator context after async gap
    if (!mounted()) return;
    if (!navigator.mounted) return;
    showModalBottomSheet(
      context: navigator.context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const ReminderPromptBottomSheet(),
    );
  }
}

