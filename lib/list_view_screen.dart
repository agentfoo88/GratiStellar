import 'package:flutter/material.dart';
import 'storage.dart';
import 'gratitude_stars.dart';
import 'font_scaling.dart';
import 'l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class ListViewScreen extends StatelessWidget {
  final List<GratitudeStar> stars;
  final Function(GratitudeStar) onStarTap;
  final Function(GratitudeStar) onJumpToStar;

  const ListViewScreen({
    super.key,
    required this.stars,
    required this.onStarTap,
    required this.onJumpToStar,
  });

  String _formatDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return AppLocalizations.of(context)!.todayLabel;
    } else if (difference.inDays == 1) {
      return AppLocalizations.of(context)!.yesterdayLabel;
    } else if (difference.inDays <= 7) {
      return AppLocalizations.of(context)!.daysAgoLabel(difference.inDays);
    } else {
      // Format as YYYY/MMM/DD
      return DateFormat('yyyy/MMM/dd').format(date);
    }
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    // Sort stars by creation date (newest first)
    final sortedStars = List<GratitudeStar>.from(stars)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: Color(0xFF1A2238),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A2238),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: FontScaling.getResponsiveIconSize(context, 24),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context)!.listViewTitle,
          style: FontScaling.getHeadingMedium(context).copyWith(
            color: Color(0xFFFFE135),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            color: Color(0xFFFFE135).withValues(alpha: 0.3),
            height: 1,
          ),
        ),
      ),
      body: sortedStars.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: FontScaling.getResponsiveSpacing(context, 16),
          vertical: FontScaling.getResponsiveSpacing(context, 16),
        ),
        itemCount: sortedStars.length,
        itemBuilder: (context, index) {
          final star = sortedStars[index];
          return _buildListItem(context, star);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            color: Colors.white.withValues(alpha: 0.3),
            size: FontScaling.getResponsiveIconSize(context, 64),
          ),
          SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),
          Text(
            AppLocalizations.of(context)!.emptyStateTitle,
            style: FontScaling.getEmptyStateTitle(context),
          ),
          SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
          Text(
            AppLocalizations.of(context)!.emptyStateSubtitle,
            style: FontScaling.getEmptyStateSubtitle(context),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, GratitudeStar star) {
    return Container(
      margin: EdgeInsets.only(
        bottom: FontScaling.getResponsiveSpacing(context, 12),
      ),
      decoration: BoxDecoration(
        color: Color(0xFF0A0B1E).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: StarColors.getColor(star.colorIndex).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: FontScaling.getResponsiveSpacing(context, 16),
          vertical: FontScaling.getResponsiveSpacing(context, 8),
        ),
        leading: Container(
          width: FontScaling.getResponsiveIconSize(context, 40),
          height: FontScaling.getResponsiveIconSize(context, 40),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: StarColors.getColor(star.colorIndex).withValues(alpha: 0.2),
            border: Border.all(
              color: StarColors.getColor(star.colorIndex),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.auto_awesome,
            color: StarColors.getColor(star.colorIndex),
            size: FontScaling.getResponsiveIconSize(context, 20),
          ),
        ),
        title: Text(
          _truncateText(star.text, 80),
          style: FontScaling.getBodySmall(context).copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(
            top: FontScaling.getResponsiveSpacing(context, 4),
          ),
          child: Text(
            _formatDate(context, star.createdAt),
            style: FontScaling.getCaption(context).copyWith(
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.white.withValues(alpha: 0.5),
          size: FontScaling.getResponsiveIconSize(context, 24),
        ),
        onTap: () => onStarTap(star),
      ),
    );
  }
}