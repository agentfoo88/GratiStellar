import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../services/daily_reminder_service.dart';
import '../font_scaling.dart';
import '../core/accessibility/semantic_helper.dart';
import '../l10n/app_localizations.dart';
import 'scrollable_dialog_content.dart';

class ReminderPromptBottomSheet extends StatefulWidget {
  const ReminderPromptBottomSheet({super.key});

  @override
  State<ReminderPromptBottomSheet> createState() =>
      _ReminderPromptBottomSheetState();
}

class _ReminderPromptBottomSheetState extends State<ReminderPromptBottomSheet> {
  bool _isProcessing = false;
  final TimeOfDay _selectedTime = const TimeOfDay(hour: 21, minute: 0);

  Future<void> _handleEnable() async {
    setState(() => _isProcessing = true);

    final reminderService = context.read<DailyReminderService>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    try {
      // Step 1: Request permission
      final granted = await reminderService.requestPermission();

      if (!granted) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(l10n.reminderPermissionDenied, style: FontScaling.getBodyMedium(context)),
          backgroundColor: AppTheme.error,
        ));
        setState(() => _isProcessing = false);
        return;
      }

      // Step 2: Show time picker
      if (!mounted) return;
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: _selectedTime,
        helpText: l10n.reminderTimePickerTitle,
      );

      if (selectedTime == null) {
        setState(() => _isProcessing = false);
        return; // User cancelled
      }

      // Step 3: Schedule reminder
      await reminderService.scheduleReminder(selectedTime);
      await reminderService.setEnabled(true);
      await reminderService.markPromptShown();

      if (!mounted) return;

      // Step 4: Show success toast
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.reminderEnabledSuccess,
                style: FontScaling.getBodyMedium(context),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ));

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Error enabling reminder: $e', style: FontScaling.getBodyMedium(context)),
        backgroundColor: AppTheme.error,
      ));
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleMaybeLater() async {
    final reminderService = context.read<DailyReminderService>();
    await reminderService.markPromptShown();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.5, // Cap at 50% max
        ),
        decoration: BoxDecoration(
          color: AppTheme.backgroundDark.withValues(alpha: 0.98),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 20)),
        child: ScrollableDialogContent(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          // Decorative icon
          SemanticHelper.decorative(
            child: Icon(
              Icons.celebration,
              color: AppTheme.primary,
              size: FontScaling.getResponsiveIconSize(context, 48),
            ),
          ),
          SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),

          // Heading
          Text(
            l10n.reminderPromptTitle,
            style: FontScaling.getModalTitle(context).copyWith(
              color: AppTheme.primary,
              fontSize:
                  FontScaling.getModalTitle(context).fontSize! * 1.0,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),

          // Body text
          Text(
            l10n.reminderPromptBody,
            style: FontScaling.getBodyMedium(context).copyWith(
              color: AppTheme.textSecondary,
              fontSize:
                  FontScaling.getBodyMedium(context).fontSize! * 1.0,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: FontScaling.getResponsiveSpacing(context, 8)),

          // Subtext
          Text(
            l10n.reminderPromptSubtext,
            style: FontScaling.getBodySmall(context).copyWith(
              color: AppTheme.textDisabled,
              fontSize:
                  FontScaling.getBodySmall(context).fontSize! * 1.0,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Maybe Later button
              SemanticHelper.label(
                label: l10n.maybeLaterButton,
                isButton: true,
                child: TextButton(
                  onPressed: _isProcessing ? null : _handleMaybeLater,
                  child: Text(
                    l10n.maybeLaterButton,
                    style: FontScaling.getButtonText(context).copyWith(
                      color: AppTheme.textTertiary,
                      fontSize:
                          FontScaling.getButtonText(context).fontSize! * 1.0,
                    ),
                  ),
                ),
              ),

              // Enable button
              SemanticHelper.label(
                label: l10n.enableReminderButton,
                hint: l10n.enableReminderHint,
                isButton: true,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handleEnable,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.backgroundDark,
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          FontScaling.getResponsiveSpacing(context, 24),
                      vertical: FontScaling.getResponsiveSpacing(context, 12),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        FontScaling.getResponsiveSpacing(context, 20),
                      ),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.backgroundDark,
                            ),
                          ),
                        )
                      : Text(
                          l10n.enableReminderButton,
                          style: FontScaling.getButtonText(context).copyWith(
                            color: AppTheme.backgroundDark,
                            fontWeight: FontWeight.w600,
                            fontSize: FontScaling.getButtonText(context)
                                    .fontSize! *
                                1.0,
                          ),
                        ),
                ),
              ),
            ],
          ),
            ],
          ),
        ),
      ),
    );
  }
}
