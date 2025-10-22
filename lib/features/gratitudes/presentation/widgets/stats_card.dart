// lib/features/gratitudes/presentation/widgets/stats_card.dart

import 'package:flutter/material.dart';
import '../../../../core/config/constants.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../storage.dart';

/// Stats card widget displaying gratitude statistics
///
/// Shows total count, this week count, and today indicator
class StatsCardWidget extends StatelessWidget {
  final List<GratitudeStar> stars;

  const StatsCardWidget({
    super.key,
    required this.stars,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: FontScaling.getResponsiveSpacing(context, 20) * UIConstants.universalUIScale,
        vertical: FontScaling.getResponsiveSpacing(context, 12) * UIConstants.universalUIScale,
      ),
      decoration: BoxDecoration(
        color: Color(0xFF1A2238).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20 * UIConstants.universalUIScale),
        border: Border.all(
          color: Color(0xFFFFE135).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
              '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          color: Color(0xFFFFE135),
          size: FontScaling.getResponsiveIconSize(context, 20) * UIConstants.universalUIScale,
        ),
        SizedBox(height: FontScaling.getResponsiveSpacing(context, 4) * UIConstants.universalUIScale),
        Text(
          label,
          style: FontScaling.getStatsLabel(context).copyWith(
            fontSize: FontScaling.getStatsLabel(context).fontSize! * UIConstants.statsLabelTextScale,
          ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: FontScaling.getStatsNumber(context).copyWith(
              fontSize: FontScaling.getStatsNumber(context).fontSize! * UIConstants.universalUIScale,
            ),
          ),
      ],
    );
  }
}