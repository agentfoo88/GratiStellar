import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../storage.dart';
import '../../../gratitudes/presentation/state/galaxy_provider.dart';
import '../../../gratitudes/presentation/state/gratitude_provider.dart';
import '../../data/repositories/backup_repository.dart';
import '../../domain/usecases/export_backup_use_case.dart';

/// Dialog for exporting backup
class BackupDialog extends StatefulWidget {
  const BackupDialog({super.key});

  @override
  State<BackupDialog> createState() => _BackupDialogState();
}

class _BackupDialogState extends State<BackupDialog> {
  bool _isExporting = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _exportBackup() async {
    setState(() {
      _isExporting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final gratitudeProvider = context.read<GratitudeProvider>();
      final galaxyProvider = context.read<GalaxyProvider>();

      // Get current data
      final stars = gratitudeProvider.gratitudeStars;
      final galaxies = galaxyProvider.galaxies;
      final fontScale = await StorageService.getFontScale();

      // Create use case and execute
      final repository = BackupRepository();
      final useCase = ExportBackupUseCase(repository);

      final result = await useCase.execute(
        stars: stars,
        galaxies: galaxies,
        fontScale: fontScale,
      );

      if (result.success && result.filePath != null) {
        // Share the backup file
        await useCase.shareBackupFile(
          result.filePath!,
          'gratistellar_backup.gratistellar',
        );

        setState(() {
          _successMessage = 'Backup created successfully!\n${result.backup?.getSummary()}';
          _isExporting = false;
        });

        // Auto-close after showing success
        await Future.delayed(Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Failed to create backup';
          _isExporting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AlertDialog(
      backgroundColor: Color(0xFF1A2238),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Color(0xFFFFE135).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      title: Row(
        children: [
          Icon(
            Icons.backup,
            color: Color(0xFFFFE135),
            size: 28,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.exportBackup,
              style: FontScaling.getHeadingMedium(context).copyWith(
                color: Color(0xFFFFE135),
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isExporting) ...[
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFFFFE135)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      l10n.creatingBackup,
                      style: FontScaling.getBodyMedium(context),
                    ),
                  ],
                ),
              ),
            ] else if (_successMessage != null) ...[
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                _successMessage!,
                style: FontScaling.getBodyMedium(context).copyWith(
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
            ] else if (_errorMessage != null) ...[
              Icon(
                Icons.error,
                color: Colors.red,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: FontScaling.getBodyMedium(context).copyWith(
                  color: Colors.red,
                ),
              ),
            ] else ...[
              Text(
                l10n.exportBackupDescription,
                style: FontScaling.getBodyMedium(context),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFFFE135).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(0xFFFFE135).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFFFFE135),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          l10n.backupWhatsIncluded,
                          style: FontScaling.getBodySmall(context).copyWith(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFE135),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    _buildInfoItem(l10n.backupIncludesGratitudes),
                    _buildInfoItem(l10n.backupIncludesGalaxies),
                    _buildInfoItem(l10n.backupIncludesPreferences),
                    _buildInfoItem(l10n.backupEncrypted),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isExporting && _successMessage == null) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l10n.cancelButton,
              style: FontScaling.getBodyMedium(context),
            ),
          ),
          ElevatedButton(
            onPressed: _exportBackup,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFFE135),
              foregroundColor: Color(0xFF1A2238),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.createBackup,
              style: FontScaling.getBodyMedium(context).copyWith(
                color: Color(0xFF1A2238),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        if (_errorMessage != null) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l10n.closeButton,
              style: FontScaling.getBodyMedium(context),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
              _exportBackup();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFFE135),
              foregroundColor: Color(0xFF1A2238),
            ),
            child: Text(
              l10n.retry,
              style: FontScaling.getBodyMedium(context).copyWith(
                color: Color(0xFF1A2238),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 28, top: 4),
      child: Row(
        children: [
          Icon(
            Icons.check,
            color: Color(0xFFFFE135),
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            text,
            style: FontScaling.getBodySmall(context),
          ),
        ],
      ),
    );
  }
}

