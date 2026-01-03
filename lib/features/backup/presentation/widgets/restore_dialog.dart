import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/error_context.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../storage.dart';
import '../../../../widgets/scrollable_dialog_content.dart';
import '../../../gratitudes/presentation/state/galaxy_provider.dart';
import '../../../gratitudes/presentation/state/gratitude_provider.dart';
import '../../data/repositories/backup_repository.dart';
import '../../domain/usecases/import_backup_use_case.dart';
import '../../domain/usecases/validate_backup_use_case.dart';

/// Dialog for importing/restoring backup
class RestoreDialog extends StatefulWidget {
  const RestoreDialog({super.key});

  @override
  State<RestoreDialog> createState() => _RestoreDialogState();
}

class _RestoreDialogState extends State<RestoreDialog> {
  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;
  String? _selectedFilePath;
  BackupData? _validatedBackup;
  MergeStrategy _selectedStrategy = MergeStrategy.mergeKeepNewer;

  Future<void> _pickFile() async {
    try {
      // Use FileType.any because custom extensions are not reliably supported
      // on all platforms (especially Android). We'll validate the extension ourselves.
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Select GratiStellar Backup File',
        allowMultiple: false,
        withData: false,
        withReadStream: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;

        // Warn if extension is wrong, but still try to validate file content
        // This allows users to rename files without breaking import
        final hasCorrectExtension = filePath.toLowerCase().endsWith('.gratistellar');
        if (!hasCorrectExtension) {
          AppLogger.warning('⚠️ Selected file does not have .gratistellar extension: $filePath');
          // Continue anyway - we'll validate the file content
        }
        
        setState(() {
          _selectedFilePath = filePath;
          _errorMessage = null;
          _validatedBackup = null;
        });

        await _validateFile();
      }
    } catch (e, stack) {
      // Handle file picker errors with ErrorHandler
      final error = ErrorHandler.handle(
        e,
        stack,
        context: ErrorContext.backup,
        l10n: mounted ? AppLocalizations.of(context) : null,
      );

      setState(() {
        _errorMessage = error.userMessage;
      });
    }
  }

  Future<void> _validateFile() async {
    if (_selectedFilePath == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final repository = BackupRepository();
      final useCase = ValidateBackupUseCase(repository);

      final result = await useCase.execute(_selectedFilePath!);

      setState(() {
        if (result.isValid) {
          _validatedBackup = result.backup;
        } else {
          _errorMessage = result.errorMessage ?? 'Invalid backup file';
          _selectedFilePath = null;
        }
        _isProcessing = false;
      });
    } catch (e, stack) {
      // Handle validation errors with ErrorHandler
      final error = ErrorHandler.handle(
        e,
        stack,
        context: ErrorContext.backup,
        l10n: mounted ? AppLocalizations.of(context) : null,
      );

      setState(() {
        _errorMessage = error.userMessage;
        _selectedFilePath = null;
        _isProcessing = false;
      });
    }
  }

  Future<void> _importBackup() async {
    if (_selectedFilePath == null || _validatedBackup == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final gratitudeProvider = context.read<GratitudeProvider>();
      final galaxyProvider = context.read<GalaxyProvider>();

      // Get current data
      final currentStars = gratitudeProvider.gratitudeStars;
      final currentGalaxies = galaxyProvider.galaxies;
      final currentFontScale = await StorageService.getFontScale();
      final currentPalettePreset = await StorageService.getSelectedPalettePreset();
      final currentPreferences = {
        'fontScale': currentFontScale,
        'selectedPalettePreset': currentPalettePreset,
      };

      // Import backup
      final repository = BackupRepository();
      final useCase = ImportBackupUseCase(repository);

      final result = await useCase.execute(
        filePath: _selectedFilePath!,
        currentStars: currentStars,
        currentGalaxies: currentGalaxies,
        currentPreferences: currentPreferences,
        strategy: _selectedStrategy,
      );

      if (result.success) {
        // CRITICAL: Restore galaxies FIRST, then stars
        // This ensures the active galaxy is set before stars are filtered
        AppLogger.data('🔄 Step 1: Restoring galaxies...');
        await galaxyProvider.restoreFromBackup(
          result.mergedGalaxies!,
          backupActiveGalaxyId: result.backup?.activeGalaxyId,
        );
        
        AppLogger.data('🔄 Step 2: Restoring stars...');
        await gratitudeProvider.restoreFromBackup(result.mergedStars!);
        
        // Apply preferences
        if (result.mergedPreferences!.containsKey('fontScale')) {
          await StorageService.saveFontScale(
            result.mergedPreferences!['fontScale'] as double,
          );
        }
        if (result.mergedPreferences!.containsKey('selectedPalettePreset')) {
          await StorageService.saveSelectedPalettePreset(
            result.mergedPreferences!['selectedPalettePreset'] as String,
          );
        }

        // Note: Both providers already call notifyListeners() in their restoreFromBackup methods
        // No need to call it again here

        setState(() {
          _successMessage = 'Backup restored successfully!\n${result.backup?.getSummary()}';
          _isProcessing = false;
        });

        // Auto-close and refresh
        await Future.delayed(Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Failed to import backup';
          _isProcessing = false;
        });
      }
    } catch (e, stack) {
      // Handle import errors with ErrorHandler
      final error = ErrorHandler.handle(
        e,
        stack,
        context: ErrorContext.backup,
        l10n: mounted ? AppLocalizations.of(context) : null,
      );

      setState(() {
        _errorMessage = error.userMessage;
        _isProcessing = false;
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
            Icons.restore,
            color: Color(0xFFFFE135),
            size: 28,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.restoreBackup,
              style: FontScaling.getHeadingMedium(context).copyWith(
                color: Color(0xFFFFE135),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: ScrollableDialogContent(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isProcessing) ...[
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFFFFE135)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _validatedBackup == null ? l10n.validatingBackup : l10n.restoringBackup,
                      style: FontScaling.getBodyMedium(context),
                    ),
                  ],
                ),
              ),
            ] else if (_successMessage != null) ...[
              Center(
                child: Column(
                  children: [
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
                  ],
                ),
              ),
            ] else ...[
              Text(
                l10n.restoreBackupDescription,
                style: FontScaling.getBodyMedium(context),
              ),
              SizedBox(height: 16),

              // File picker button
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: Icon(Icons.folder_open, color: Color(0xFFFFE135)),
                label: Text(
                  _selectedFilePath == null ? l10n.selectBackupFile : l10n.changeFile,
                  style: FontScaling.getBodyMedium(context),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(0xFFFFE135),
                  side: BorderSide(color: Color(0xFFFFE135)),
                  padding: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: FontScaling.getBodySmall(context).copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_validatedBackup != null) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            l10n.validBackup,
                            style: FontScaling.getBodySmall(context).copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        _validatedBackup!.getSummary(),
                        style: FontScaling.getBodySmall(context),
                      ),
                      SizedBox(height: 4),
                      Text(
                        l10n.backupCreated(_formatDate(_validatedBackup!.createdAt)),
                        style: FontScaling.getCaption(context),
                      ),
                      Text(
                        l10n.backupAppVersion(_validatedBackup!.appVersion),
                        style: FontScaling.getCaption(context),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),
                Text(
                  l10n.restoreStrategy,
                  style: FontScaling.getBodySmall(context).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),

                RadioGroup<MergeStrategy>(
                  groupValue: _selectedStrategy,
                  onChanged: (value) {
                    setState(() {
                      _selectedStrategy = value!;
                    });
                  },
                  child: Column(
                    children: [
                      RadioListTile<MergeStrategy>(
                        value: MergeStrategy.mergeKeepNewer,
                        title: Text(
                          l10n.restoreStrategyMerge,
                          style: FontScaling.getBodySmall(context),
                        ),
                        subtitle: Text(
                          l10n.restoreStrategyMergeDescription,
                          style: FontScaling.getCaption(context),
                        ),
                        activeColor: Color(0xFFFFE135),
                      ),

                      RadioListTile<MergeStrategy>(
                        value: MergeStrategy.replaceAll,
                        title: Text(
                          l10n.restoreStrategyReplace,
                          style: FontScaling.getBodySmall(context),
                        ),
                        subtitle: Text(
                          l10n.restoreStrategyReplaceDescription,
                          style: FontScaling.getCaption(context).copyWith(
                            color: Colors.orange,
                          ),
                        ),
                        activeColor: Colors.orange,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        if (!_isProcessing && _successMessage == null) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l10n.cancelButton,
              style: FontScaling.getBodyMedium(context),
            ),
          ),
          if (_validatedBackup != null)
            ElevatedButton(
              onPressed: _importBackup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFE135),
                foregroundColor: Color(0xFF1A2238),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.restore,
                style: FontScaling.getBodyMedium(context).copyWith(
                  color: Color(0xFF1A2238),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

