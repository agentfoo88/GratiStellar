import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/sync_status_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';

/// Banner widget showing sync status with tap-to-retry functionality
/// 
/// Displays at the top of the screen when sync is pending, syncing, error, or offline.
/// Only shows when user is signed in with email account.
/// Allows user to tap to manually retry sync.
class SyncStatusBanner extends StatelessWidget {
  final SyncStatusService syncStatusService;
  final AuthService authService;
  final VoidCallback? onRetry;

  const SyncStatusBanner({
    super.key,
    required this.syncStatusService,
    required this.authService,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // Hide if user is not signed in with email account (no sync needed)
    if (!authService.hasEmailAccount) {
      return const SizedBox.shrink();
    }

    // Hide when fully synced
    if (syncStatusService.status == SyncStatus.synced) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final status = syncStatusService.status;
    final isTappable = status == SyncStatus.pending || 
                       status == SyncStatus.error || 
                       status == SyncStatus.offline;

    return Semantics(
      label: _getStatusMessage(status, l10n),
      button: isTappable,
      hint: isTappable ? l10n?.retrySync : null,
      child: GestureDetector(
        onTap: isTappable ? () {
          AppLogger.sync('👆 User tapped sync status banner to retry');
          onRetry?.call();
        } : null,
        child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: FontScaling.getResponsiveSpacing(context, 16),
          vertical: FontScaling.getResponsiveSpacing(context, 12),
        ),
        decoration: BoxDecoration(
          color: _getStatusColor(status),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _getStatusIcon(status),
            SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
            Flexible(
              child: Text(
                _getStatusMessage(status, l10n),
                style: FontScaling.getBodySmall(context).copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontScaling.mediumWeight,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (isTappable) ...[
              SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
              Icon(
                Icons.touch_app,
                color: AppTheme.textPrimary,
                size: FontScaling.getResponsiveIconSize(context, 18),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Color _getStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.pending:
        return AppTheme.warning;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.offline:
        return Colors.grey.shade700;
      case SyncStatus.error:
        return AppTheme.error;
      case SyncStatus.synced:
        return Colors.transparent; // Shouldn't show
    }
  }

  Widget _getStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.pending:
        return const Icon(
          Icons.cloud_upload_outlined,
          color: AppTheme.textPrimary,
          size: 20,
        );
      case SyncStatus.syncing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textPrimary),
          ),
        );
      case SyncStatus.offline:
        return const Icon(
          Icons.cloud_off_outlined,
          color: AppTheme.textPrimary,
          size: 20,
        );
      case SyncStatus.error:
        return const Icon(
          Icons.error_outline,
          color: AppTheme.textPrimary,
          size: 20,
        );
      case SyncStatus.synced:
        return const SizedBox.shrink();
    }
  }

  String _getStatusMessage(SyncStatus status, AppLocalizations? l10n) {
    switch (status) {
      case SyncStatus.pending:
        return l10n?.syncStatusPendingTap ?? 'Changes pending sync - Tap to sync now';
      case SyncStatus.syncing:
        return l10n?.syncStatusSyncingMessage ?? 'Syncing...';
      case SyncStatus.offline:
        return l10n?.syncStatusOfflineMessage ?? 'Offline - will sync when connected';
      case SyncStatus.error:
        return l10n?.syncStatusErrorTap ?? 'Sync failed - tap to retry';
      case SyncStatus.synced:
        return ''; // Shouldn't show
    }
  }
}

