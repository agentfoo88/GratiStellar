import 'package:flutter/material.dart';
import 'storage.dart';
import 'gratitude_stars.dart';
import 'font_scaling.dart';
import 'l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ListViewScreen extends StatefulWidget {
  final List<GratitudeStar> stars;
  final Function(GratitudeStar, VoidCallback) onStarTap;
  final Function(GratitudeStar) onJumpToStar;

  const ListViewScreen({
    super.key,
    required this.stars,
    required this.onStarTap,
    required this.onJumpToStar,
  });

  @override
  State<ListViewScreen> createState() => _ListViewScreenState();
}

class _ListViewScreenState extends State<ListViewScreen> {
  late List<GratitudeStar> _currentStars;
  String _sortMethod = 'newest';

  @override
  void initState() {
    super.initState();
    _currentStars = List<GratitudeStar>.from(widget.stars);
  }

  @override
  void didUpdateWidget(ListViewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stars != oldWidget.stars) {
      setState(() {
        _currentStars = List<GratitudeStar>.from(widget.stars);
      });
    }
  }

  void _refreshList() {
    setState(() {
      _currentStars = List<GratitudeStar>.from(widget.stars);
    });
  }

  List<GratitudeStar> _getSortedStars() {
    final stars = List<GratitudeStar>.from(_currentStars);

    switch (_sortMethod) {
      case 'newest':
        stars.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        stars.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'alpha_az':
        stars.sort((a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase()));
        break;
      case 'alpha_za':
        stars.sort((a, b) => b.text.toLowerCase().compareTo(a.text.toLowerCase()));
        break;
      case 'color':
        stars.sort((a, b) {
          // Sort by color index, then by creation date within same color
          final colorCompare = a.colorIndex.compareTo(b.colorIndex);
          if (colorCompare != 0) return colorCompare;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
    }

    return stars;
  }

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
      return DateFormat('yyyy/MMM/dd').format(date);
    }
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    final sortedStars = _getSortedStars();

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
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.sort,
                color: Color(0xFFFFE135),
                size: FontScaling.getResponsiveIconSize(context, 24),
              ),
              color: Color(0xFF1A2238).withValues(alpha: 0.98),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Color(0xFFFFE135).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              onSelected: (value) {
                setState(() {
                  _sortMethod = value;
                });
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'newest',
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        color: _sortMethod == 'newest' ? Color(0xFFFFE135) : Colors.white.withValues(alpha: 0.7),
                        size: FontScaling.getResponsiveIconSize(context, 20),
                      ),
                      SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.sortNewestFirst,
                        style: FontScaling.getBodySmall(context).copyWith(
                          color: _sortMethod == 'newest' ? Color(0xFFFFE135) : Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'oldest',
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        color: _sortMethod == 'oldest' ? Color(0xFFFFE135) : Colors.white.withValues(alpha: 0.7),
                        size: FontScaling.getResponsiveIconSize(context, 20),
                      ),
                      SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.sortOldestFirst,
                        style: FontScaling.getBodySmall(context).copyWith(
                          color: _sortMethod == 'oldest' ? Color(0xFFFFE135) : Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'alpha_az',
                  child: Row(
                    children: [
                      Icon(
                        Icons.sort_by_alpha,
                        color: _sortMethod == 'alpha_az' ? Color(0xFFFFE135) : Colors.white.withValues(alpha: 0.7),
                        size: FontScaling.getResponsiveIconSize(context, 20),
                      ),
                      SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.sortAlphabeticalAZ,
                        style: FontScaling.getBodySmall(context).copyWith(
                          color: _sortMethod == 'alpha_az' ? Color(0xFFFFE135) : Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'alpha_za',
                  child: Row(
                    children: [
                      Icon(
                        Icons.sort_by_alpha,
                        color: _sortMethod == 'alpha_za' ? Color(0xFFFFE135) : Colors.white.withValues(alpha: 0.7),
                        size: FontScaling.getResponsiveIconSize(context, 20),
                      ),
                      SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.sortAlphabeticalZA,
                        style: FontScaling.getBodySmall(context).copyWith(
                          color: _sortMethod == 'alpha_za' ? Color(0xFFFFE135) : Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'color',
                  child: Row(
                    children: [
                      Icon(
                        Icons.palette,
                        color: _sortMethod == 'color' ? Color(0xFFFFE135) : Colors.white.withValues(alpha: 0.7),
                        size: FontScaling.getResponsiveIconSize(context, 20),
                      ),
                      SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.sortByColor,
                        style: FontScaling.getBodySmall(context).copyWith(
                          color: _sortMethod == 'color' ? Color(0xFFFFE135) : Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
          SvgPicture.asset(
            'assets/icon_star.svg',
            width: FontScaling.getResponsiveIconSize(context, 64),
            height: FontScaling.getResponsiveIconSize(context, 64),
            colorFilter: ColorFilter.mode(Colors.white.withValues(alpha: 0.3), BlendMode.srcIn),
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
          color: star.color.withValues(alpha: 0.3),
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
            color: star.color.withValues(alpha: 0.2),
            border: Border.all(
              color: star.color,
              width: 2,
            ),
          ),
          child: SvgPicture.asset(
            'assets/icon_star.svg',
            width: FontScaling.getResponsiveIconSize(context, 20),
            height: FontScaling.getResponsiveIconSize(context, 20),
            colorFilter: ColorFilter.mode(star.color, BlendMode.srcIn),
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
        onTap: () => widget.onStarTap(star, _refreshList),
      ),
    );
  }
}