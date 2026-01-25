import 'package:flutter/material.dart';

import '../core/accessibility/semantic_helper.dart';
import '../core/theme/app_theme.dart';
import '../font_scaling.dart';
import '../l10n/app_localizations.dart';
import '../features/backup/presentation/widgets/backup_dialog.dart';
import '../features/backup/presentation/widgets/restore_dialog.dart';

/// Combined dialog for Backup & Restore operations
class BackupRestoreDialog extends StatelessWidget {
  const BackupRestoreDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: AppTheme.primaryDark,
      title: Text(
        l10n.backupRestoreTitle,
        style: FontScaling.getHeadingMedium(context).copyWith(
          color: AppTheme.primary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Export Backup option
            SemanticHelper.label(
              label: l10n.exportBackup,
              hint: l10n.exportBackupSubtitle,
              isButton: true,
              child: InkWell(
                onTap: () async {
                  Navigator.of(context).pop(); // Close this dialog
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final textStyle = FontScaling.getBodyMedium(context);
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => const BackupDialog(),
                  );

                  if (result == true && context.mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.backupCreatedSimple, style: textStyle),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(
                    FontScaling.getResponsiveSpacing(context, 16),
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.textPrimary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.backup,
                        color: AppTheme.primary,
                        size: FontScaling.getResponsiveIconSize(context, 28),
                      ),
                      SizedBox(width: FontScaling.getResponsiveSpacing(context, 16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.exportBackup,
                              style: FontScaling.getBodyLarge(context).copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontScaling.mediumWeight,
                              ),
                            ),
                            SizedBox(height: FontScaling.getResponsiveSpacing(context, 4)),
                            Text(
                              l10n.exportBackupSubtitle,
                              style: FontScaling.getCaption(context).copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppTheme.textTertiary,
                        size: FontScaling.getResponsiveIconSize(context, 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),

            // Restore Backup option
            SemanticHelper.label(
              label: l10n.restoreBackup,
              hint: l10n.restoreBackupSubtitle,
              isButton: true,
              child: InkWell(
                onTap: () async {
                  Navigator.of(context).pop(); // Close this dialog
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final textStyle = FontScaling.getBodyMedium(context);
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => const RestoreDialog(),
                  );

                  if (result == true && context.mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.backupRestoredSimple, style: textStyle),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(
                    FontScaling.getResponsiveSpacing(context, 16),
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.textPrimary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.restore,
                        color: AppTheme.primary,
                        size: FontScaling.getResponsiveIconSize(context, 28),
                      ),
                      SizedBox(width: FontScaling.getResponsiveSpacing(context, 16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.restoreBackup,
                              style: FontScaling.getBodyLarge(context).copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontScaling.mediumWeight,
                              ),
                            ),
                            SizedBox(height: FontScaling.getResponsiveSpacing(context, 4)),
                            Text(
                              l10n.restoreBackupSubtitle,
                              style: FontScaling.getCaption(context).copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppTheme.textTertiary,
                        size: FontScaling.getResponsiveIconSize(context, 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.closeButton,
            style: FontScaling.getButtonText(context).copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

