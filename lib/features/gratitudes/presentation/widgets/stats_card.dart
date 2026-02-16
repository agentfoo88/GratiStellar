import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../storage.dart';
import '../state/galaxy_provider.dart';

/// Stats card widget displaying gratitude statistics
///
/// Shows galaxy name, total count, this week count, and today indicator
class StatsCardWidget extends StatelessWidget {
  final List<GratitudeStar> stars;

  const StatsCardWidget({
    super.key,
    required this.stars,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate max width based on screen size (leave margins on sides)
    final screenWidth = MediaQuery.of(context).size.width;
    final maxCardWidth = screenWidth * 0.9;

    return Consumer<GalaxyProvider>(
      builder: (context, galaxyProvider, _) {
        final galaxyName = galaxyProvider.activeGalaxy?.name ?? 'All Stars';

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxCardWidth),
            child: IntrinsicWidth(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: FontScaling.getResponsiveSpacing(context, 20) * UIConstants.universalUIScale,
                  vertical: FontScaling.getResponsiveSpacing(context, 12) * UIConstants.universalUIScale,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundDark.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20 * UIConstants.universalUIScale),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Galaxy name at the top
                    _buildGalaxyName(context, galaxyName),

                    SizedBox(height: FontScaling.getResponsiveSpacing(context, 8) * UIConstants.universalUIScale),

                    // Horizontal divider
                    Container(
                      height: 1,
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),

                    SizedBox(height: FontScaling.getResponsiveSpacing(context, 8) * UIConstants.universalUIScale),

                    // Stats row - wrapped in FittedBox to scale down if needed
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatItem(
                            context,
                            Icons.star,
                            AppLocalizations.of(context)!.statsTotal,
                            StorageService.getTotalStars(stars).toString(),
                          ),
                          SizedBox(width: FontScaling.getResponsiveSpacing(context, 20) * UIConstants.universalUIScale),
                          _buildStatItem(
                            context,
                            Icons.trending_up,
                            AppLocalizations.of(context)!.statsThisWeek,
                            StorageService.getThisWeekStars(stars).toString(),
                          ),
                          SizedBox(width: FontScaling.getResponsiveSpacing(context, 20) * UIConstants.universalUIScale),
                          _buildStatItem(
                            context,
                            StorageService.getAddedToday(stars) ? Icons.check_circle : Icons.radio_button_unchecked,
                            AppLocalizations.of(context)!.statsToday,
                            StorageService.getTodayStars(stars).toString(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ExcludeSemantics(
          child: Icon(
            icon,
            color: AppTheme.primary,
            size: FontScaling.getResponsiveIconSize(context, 20) * UIConstants.universalUIScale,
          ),
        ),
        SizedBox(height: FontScaling.getResponsiveSpacing(context, 4) * UIConstants.universalUIScale),
        Text(
          label,
          style: FontScaling.getStatsLabel(context).copyWith(
            fontSize: FontScaling.getStatsLabel(context).fontSize! * UIConstants.statsLabelTextScale,
          ),
        ),
        if (value.isNotEmpty) ...[
          SizedBox(height: FontScaling.getResponsiveSpacing(context, 2) * UIConstants.universalUIScale),
          Text(
            value,
            style: FontScaling.getStatsNumber(context).copyWith(
              fontSize: FontScaling.getStatsNumber(context).fontSize! * UIConstants.universalUIScale,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGalaxyName(BuildContext context, String galaxyName) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ExcludeSemantics(
          child: Icon(
            Icons.brightness_2,
            color: AppTheme.primary,
            size: FontScaling.getResponsiveIconSize(context, 18) * UIConstants.universalUIScale,
          ),
        ),
        SizedBox(width: FontScaling.getResponsiveSpacing(context, 8) * UIConstants.universalUIScale),
        Flexible(
          child: Text(
            galaxyName,
            style: FontScaling.getStatsLabel(context).copyWith(
              fontSize: FontScaling.getStatsLabel(context).fontSize! * UIConstants.universalUIScale,
              fontWeight: FontScaling.mediumWeight,
              color: AppTheme.primary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}