import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../galaxy_metadata.dart';
import '../state/galaxy_provider.dart';

class GalaxyPickerBottomSheet extends StatelessWidget {
  final String currentGalaxyId;
  final Function(String galaxyId, String galaxyName) onGalaxySelected;

  const GalaxyPickerBottomSheet({
    super.key,
    required this.currentGalaxyId,
    required this.onGalaxySelected,
  });

  static Future<void> show({
    required BuildContext context,
    required String currentGalaxyId,
    required Function(String galaxyId, String galaxyName) onGalaxySelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GalaxyPickerBottomSheet(
        currentGalaxyId: currentGalaxyId,
        onGalaxySelected: onGalaxySelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;

    return Consumer<GalaxyProvider>(
      builder: (context, galaxyProvider, child) {
        // Filter out current galaxy and deleted galaxies
        final availableGalaxies = galaxyProvider.activeGalaxies
            .where((g) => g.id != currentGalaxyId)
            .toList();

        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.6,
            ),
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark.withValues(alpha: 0.98),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 20)),
                  child: Column(
                    children: [
                      Icon(
                        Icons.drive_file_move,
                        color: AppTheme.primary,
                        size: FontScaling.getResponsiveIconSize(context, 32),
                      ),
                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
                      Text(
                        l10n.selectTargetGalaxy,
                        style: FontScaling.getHeadingMedium(context).copyWith(
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(color: AppTheme.borderSubtle, height: 1),

                // Galaxy list
                Flexible(
                  child: availableGalaxies.isEmpty
                      ? _buildEmptyState(context, l10n)
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: availableGalaxies.length,
                          itemBuilder: (context, index) {
                            final galaxy = availableGalaxies[index];
                            return _buildGalaxyItem(context, galaxy, l10n);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGalaxyItem(
    BuildContext context,
    GalaxyMetadata galaxy,
    AppLocalizations l10n,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onGalaxySelected(galaxy.id, galaxy.name);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: FontScaling.getResponsiveSpacing(context, 20),
          vertical: FontScaling.getResponsiveSpacing(context, 16),
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppTheme.borderSubtle,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.stars,
              color: AppTheme.primary,
              size: FontScaling.getResponsiveIconSize(context, 24),
            ),
            SizedBox(width: FontScaling.getResponsiveSpacing(context, 16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    galaxy.name,
                    style: FontScaling.getBodyLarge(context).copyWith(
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: FontScaling.getResponsiveSpacing(context, 4)),
                  Text(
                    l10n.galaxyStarCount(galaxy.starCount),
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
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_off,
              size: FontScaling.getResponsiveIconSize(context, 48),
              color: AppTheme.textDisabled,
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
            Text(
              l10n.noOtherGalaxies,
              style: FontScaling.getBodyMedium(context).copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
