import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../storage.dart';
import '../state/galaxy_provider.dart';

/// Dialog for recovering orphaned stars that belong to deleted galaxies
class OrphanRecoveryDialog extends StatefulWidget {
  const OrphanRecoveryDialog({super.key});

  /// Show the orphan recovery dialog
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const OrphanRecoveryDialog(),
    );
  }

  @override
  State<OrphanRecoveryDialog> createState() => _OrphanRecoveryDialogState();
}

class _OrphanRecoveryDialogState extends State<OrphanRecoveryDialog> {
  String? _selectedGalaxyId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-select the active galaxy
    final galaxyProvider = Provider.of<GalaxyProvider>(context, listen: false);
    final activeGalaxies = galaxyProvider.activeGalaxies;
    if (activeGalaxies.isNotEmpty) {
      _selectedGalaxyId = galaxyProvider.activeGalaxyId ?? activeGalaxies.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<GalaxyProvider>(
      builder: (context, galaxyProvider, child) {
        final orphanedStars = galaxyProvider.orphanedStars;
        final activeGalaxies = galaxyProvider.activeGalaxies;

        return Theme(
          data: Theme.of(context).copyWith(
            highlightColor: AppTheme.textPrimary.withValues(alpha: 0.1),
            splashColor: AppTheme.textPrimary.withValues(alpha: 0.05),
            hoverColor: AppTheme.textPrimary.withValues(alpha: 0.08),
            focusColor: AppTheme.textPrimary.withValues(alpha: 0.12),
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.textPrimary.withValues(alpha: 0.3),
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: AlertDialog(
            backgroundColor: AppTheme.backgroundDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: AppTheme.warning.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
          title: Semantics(
            header: true,
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.warning,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.orphanedStarsTitle,
                    style: FontScaling.getHeadingMedium(
                      context,
                      color: AppTheme.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  l10n.orphanedStarsDescription(orphanedStars.length),
                  style: FontScaling.getBodyMedium(context),
                ),
                const SizedBox(height: 16),

                // Star list (scrollable if more than 3 stars)
                SizedBox(
                  height: orphanedStars.length > 3 ? 150 : null,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundDarker,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: orphanedStars.length > 3
                        ? ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: orphanedStars.length,
                            itemBuilder: (context, index) {
                              final star = orphanedStars[index];
                              return _buildStarItem(context, star);
                            },
                          )
                        : Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: orphanedStars
                                  .map((star) => _buildStarItem(context, star))
                                  .toList(),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Galaxy dropdown (only if there are galaxies to move to)
                if (activeGalaxies.isNotEmpty) ...[
                  Text(
                    l10n.selectDestinationGalaxy,
                    style: FontScaling.getBodySmall(
                      context,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    label: l10n.selectDestinationGalaxy,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedGalaxyId,
                      focusColor: AppTheme.textPrimary.withValues(alpha: 0.12),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.backgroundDarker,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      dropdownColor: AppTheme.backgroundDark,
                      style: FontScaling.getBodyMedium(context),
                      items: activeGalaxies.map((g) {
                        return DropdownMenuItem(
                          value: g.id,
                          child: Text(g.name),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedGalaxyId = v),
                    ),
                  ),
                ],

                // Error message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: FontScaling.getBodySmall(
                      context,
                      color: AppTheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: _isLoading
              ? [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                ]
              : [
                  // Later button
                  Semantics(
                    button: true,
                    label: l10n.later,
                    child: TextButton(
                      onPressed: () => _handleLater(context),
                      child: Text(
                        l10n.later,
                        style: FontScaling.getButtonText(context),
                      ),
                    ),
                  ),
                  // Delete All button
                  Semantics(
                    button: true,
                    label: l10n.deleteAll,
                    child: TextButton(
                      onPressed: () => _showDeleteConfirmation(context),
                      child: Text(
                        l10n.deleteAll,
                        style: FontScaling.getButtonText(
                          context,
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  ),
                  // Recover button
                  if (activeGalaxies.isNotEmpty && _selectedGalaxyId != null)
                    Semantics(
                      button: true,
                      label: l10n.recoverStars,
                      child: TextButton(
                        onPressed: () => _handleRecover(context),
                        child: Text(
                          l10n.recoverStars,
                          style: FontScaling.getButtonText(
                            context,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
          ),
        );
      },
    );
  }

  Widget _buildStarItem(BuildContext context, GratitudeStar star) {
    final truncatedText = star.text.length > 50
        ? '${star.text.substring(0, 50)}...'
        : star.text;

    return Semantics(
      label: 'Star: ${star.text}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.star,
                color: star.color,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                truncatedText,
                style: FontScaling.getBodySmall(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLater(BuildContext context) {
    final galaxyProvider = Provider.of<GalaxyProvider>(context, listen: false);
    galaxyProvider.markOrphanRecoveryPromptShown();
    Navigator.of(context).pop();
  }

  Future<void> _handleRecover(BuildContext context) async {
    if (_selectedGalaxyId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final galaxyProvider = Provider.of<GalaxyProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final textStyle = FontScaling.getBodyMedium(context);

    try {
      final count = await galaxyProvider.recoverOrphanedStars(_selectedGalaxyId!);
      final galaxyName = galaxyProvider.activeGalaxies
          .firstWhere((g) => g.id == _selectedGalaxyId)
          .name;

      navigator.pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.orphansRecovered(count, galaxyName),
            style: textStyle,
          ),
          backgroundColor: AppTheme.backgroundDark,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final galaxyProvider = Provider.of<GalaxyProvider>(context, listen: false);
    final orphanCount = galaxyProvider.orphanedStars.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.backgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.error.withValues(alpha: 0.5)),
        ),
        title: Semantics(
          header: true,
          child: Text(
            l10n.confirmDeleteOrphans,
            style: FontScaling.getHeadingMedium(
              context,
              color: AppTheme.error,
            ),
          ),
        ),
        content: Text(
          l10n.confirmDeleteOrphansMessage(orphanCount),
          style: FontScaling.getBodyMedium(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.cancel,
              style: FontScaling.getButtonText(context),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.deletePermanently,
              style: FontScaling.getButtonText(context, color: AppTheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _handleDelete(context);
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final galaxyProvider = Provider.of<GalaxyProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final textStyle = FontScaling.getBodyMedium(context);

    try {
      final count = await galaxyProvider.deleteOrphanedStars();

      navigator.pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.orphansDeleted(count),
            style: textStyle,
          ),
          backgroundColor: AppTheme.backgroundDark,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }
}
