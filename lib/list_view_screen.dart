import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'core/accessibility/semantic_helper.dart';
import 'core/theme/app_theme.dart';
import 'features/gratitudes/presentation/state/gratitude_provider.dart';
import 'features/gratitudes/presentation/widgets/galaxy_picker_bottom_sheet.dart';
import 'font_scaling.dart';
import 'l10n/app_localizations.dart';
import 'storage.dart';

class ListViewScreen extends StatefulWidget {
  final Function(GratitudeStar) onStarTap;
  final Function(GratitudeStar) onJumpToStar;

  const ListViewScreen({
    super.key,
    required this.onStarTap,
    required this.onJumpToStar,
  });

  @override
  State<ListViewScreen> createState() => _ListViewScreenState();
}

class _ListViewScreenState extends State<ListViewScreen> {
  String _sortMethod = 'newest';
  bool _isSelectionMode = false;
  final Set<String> _selectedStarIds = {};

  List<GratitudeStar> _getSortedStars(List<GratitudeStar> stars) {
    final sortedStars = List<GratitudeStar>.from(stars);

    switch (_sortMethod) {
      case 'newest':
        sortedStars.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        sortedStars.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'alpha_az':
        sortedStars.sort((a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase()));
        break;
      case 'alpha_za':
        sortedStars.sort((a, b) => b.text.toLowerCase().compareTo(a.text.toLowerCase()));
        break;
      case 'color':
        sortedStars.sort((a, b) {
          // Sort by color index, then by creation date within same color
          final colorCompare = a.colorPresetIndex.compareTo(b.colorPresetIndex);
          if (colorCompare != 0) return colorCompare;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
      case 'by_month':
      case 'by_year':
        sortedStars.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
        break;
    }

    return sortedStars;
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
      // Locale-aware date format (display only - does not affect database storage)
      return DateFormat.yMMMd().format(date);
    }
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GratitudeProvider>(
      builder: (context, provider, child) {
        final stars = provider.gratitudeStars;
        final sortedStars = _getSortedStars(stars);

        return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.textPrimary,
            size: FontScaling.getResponsiveIconSize(context, 24),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isSelectionMode && _selectedStarIds.isNotEmpty
              ? AppLocalizations.of(context)!.selectedCount(_selectedStarIds.length)
              : AppLocalizations.of(context)!.listViewTitle,
          style: FontScaling.getHeadingMedium(context).copyWith(
            color: AppTheme.primary,
          ),
        ),
        actions: [
          if (_isSelectionMode) ...[
            // Select All / Deselect All button
            SemanticHelper.label(
              label: _selectedStarIds.length == _getSortedStars(stars).length
                  ? AppLocalizations.of(context)!.deselectAll
                  : AppLocalizations.of(context)!.selectAll,
              hint: _selectedStarIds.length == _getSortedStars(stars).length
                  ? AppLocalizations.of(context)!.deselectAllStars
                  : AppLocalizations.of(context)!.selectAllStars,
              isButton: true,
              child: IconButton(
                icon: Icon(
                  _selectedStarIds.length == _getSortedStars(stars).length
                      ? Icons.deselect
                      : Icons.select_all,
                  color: AppTheme.primary,
                  size: FontScaling.getResponsiveIconSize(context, 24),
                ),
                onPressed: () {
                  setState(() {
                    if (_selectedStarIds.length == _getSortedStars(stars).length) {
                      _selectedStarIds.clear();
                    } else {
                      _selectedStarIds.addAll(_getSortedStars(stars).map((s) => s.id));
                    }
                  });
                },
                tooltip: _selectedStarIds.length == _getSortedStars(stars).length
                    ? AppLocalizations.of(context)!.deselectAll
                    : AppLocalizations.of(context)!.selectAll,
              ),
            ),
            // Cancel selection mode
            SemanticHelper.label(
              label: AppLocalizations.of(context)!.cancelSelection,
              hint: 'Exit selection mode',
              isButton: true,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: AppTheme.textPrimary,
                  size: FontScaling.getResponsiveIconSize(context, 24),
                ),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedStarIds.clear();
                  });
                },
                tooltip: AppLocalizations.of(context)!.cancelSelection,
              ),
            ),
          ] else ...[
            // Enter selection mode button
            SemanticHelper.label(
              label: AppLocalizations.of(context)!.selectMode,
              hint: 'Enter selection mode to select multiple stars',
              isButton: true,
              child: IconButton(
                icon: Icon(
                  Icons.check_box_outline_blank,
                  color: AppTheme.primary,
                  size: FontScaling.getResponsiveIconSize(context, 24),
                ),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = true;
                  });
                },
                tooltip: AppLocalizations.of(context)!.selectMode,
              ),
            ),
            // Sort menu
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: PopupMenuButton<String>(
                icon: Icon(
                  Icons.sort,
                  color: AppTheme.primary,
                  size: FontScaling.getResponsiveIconSize(context, 24),
                ),
                color: AppTheme.backgroundDark.withValues(alpha: 0.98),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: AppTheme.borderSubtle,
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
                    child: Container(
                      decoration: _sortMethod == 'newest'
                          ? BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            )
                          : null,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            // WCAG FIX: Dark icon on yellow background (14:1 contrast)
                            color: _sortMethod == 'newest'
                                ? AppTheme.textOnLight
                                : AppTheme.textSecondary,
                            size: FontScaling.getResponsiveIconSize(context, 20),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.sortNewestFirst,
                              style: FontScaling.getBodySmall(context).copyWith(
                                // WCAG FIX: Dark text on yellow background (14:1 contrast)
                                color: _sortMethod == 'newest'
                                    ? AppTheme.textOnLight
                                    : AppTheme.textPrimary.withValues(alpha: 0.9),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'oldest',
                    child: Container(
                      decoration: _sortMethod == 'oldest'
                          ? BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            )
                          : null,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            color: _sortMethod == 'oldest'
                                ? AppTheme.textOnLight
                                : AppTheme.textSecondary,
                            size: FontScaling.getResponsiveIconSize(context, 20),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.sortOldestFirst,
                              style: FontScaling.getBodySmall(context).copyWith(
                                color: _sortMethod == 'oldest'
                                    ? AppTheme.textOnLight
                                    : AppTheme.textPrimary.withValues(alpha: 0.9),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'by_month',
                    child: Container(
                      decoration: _sortMethod == 'by_month'
                          ? BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            )
                          : null,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            color: _sortMethod == 'by_month'
                                ? AppTheme.textOnLight
                                : AppTheme.textSecondary,
                            size: FontScaling.getResponsiveIconSize(context, 20),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.sortByMonth,
                              style: FontScaling.getBodySmall(context).copyWith(
                                color: _sortMethod == 'by_month'
                                    ? AppTheme.textOnLight
                                    : AppTheme.textPrimary.withValues(alpha: 0.9),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'by_year',
                    child: Container(
                      decoration: _sortMethod == 'by_year'
                          ? BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            )
                          : null,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: _sortMethod == 'by_year'
                                ? AppTheme.textOnLight
                                : AppTheme.textSecondary,
                            size: FontScaling.getResponsiveIconSize(context, 20),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.sortByYear,
                              style: FontScaling.getBodySmall(context).copyWith(
                                color: _sortMethod == 'by_year'
                                    ? AppTheme.textOnLight
                                    : AppTheme.textPrimary.withValues(alpha: 0.9),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'alpha_az',
                    child: Container(
                      decoration: _sortMethod == 'alpha_az'
                          ? BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            )
                          : null,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sort_by_alpha,
                            color: _sortMethod == 'alpha_az'
                                ? AppTheme.textOnLight
                                : AppTheme.textSecondary,
                            size: FontScaling.getResponsiveIconSize(context, 20),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.sortAlphabeticalAZ,
                              style: FontScaling.getBodySmall(context).copyWith(
                                color: _sortMethod == 'alpha_az'
                                    ? AppTheme.textOnLight
                                    : AppTheme.textPrimary.withValues(alpha: 0.9),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'alpha_za',
                    child: Container(
                      decoration: _sortMethod == 'alpha_za'
                          ? BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            )
                          : null,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sort_by_alpha,
                            color: _sortMethod == 'alpha_za'
                                ? AppTheme.textOnLight
                                : AppTheme.textSecondary,
                            size: FontScaling.getResponsiveIconSize(context, 20),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.sortAlphabeticalZA,
                              style: FontScaling.getBodySmall(context).copyWith(
                                color: _sortMethod == 'alpha_za'
                                    ? AppTheme.textOnLight
                                    : AppTheme.textPrimary.withValues(alpha: 0.9),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'color',
                    child: Container(
                      decoration: _sortMethod == 'color'
                          ? BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            )
                          : null,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.palette,
                            color: _sortMethod == 'color'
                                ? AppTheme.textOnLight
                                : AppTheme.textSecondary,
                            size: FontScaling.getResponsiveIconSize(context, 20),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.sortByColor,
                              style: FontScaling.getBodySmall(context).copyWith(
                                color: _sortMethod == 'color'
                                    ? AppTheme.textOnLight
                                    : AppTheme.textPrimary.withValues(alpha: 0.9),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ],
          ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            color: AppTheme.borderSubtle,
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          // Action buttons when items are selected
          if (_isSelectionMode && _selectedStarIds.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: FontScaling.getResponsiveSpacing(context, 16),
                vertical: FontScaling.getResponsiveSpacing(context, 8),
              ),
              decoration: BoxDecoration(
                color: Color(0xFF0A0B1E).withValues(alpha: 0.8),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Move button
                  SemanticHelper.label(
                    label: AppLocalizations.of(context)!.moveSelected,
                    hint: 'Move ${_selectedStarIds.length} selected star(s)',
                    isButton: true,
                    child: ElevatedButton.icon(
                      onPressed: () => _moveSelectedStars(context, provider),
                      icon: Icon(
                        Icons.drive_file_move_outline,
                        color: AppTheme.textPrimary,
                        size: FontScaling.getResponsiveIconSize(context, 20),
                      ),
                      label: Text(
                        AppLocalizations.of(context)!.moveSelected,
                        style: FontScaling.getBodySmall(context).copyWith(
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.8),
                        foregroundColor: AppTheme.textOnLight,
                        padding: EdgeInsets.symmetric(
                          horizontal: FontScaling.getResponsiveSpacing(context, 16),
                          vertical: FontScaling.getResponsiveSpacing(context, 12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: FontScaling.getResponsiveSpacing(context, 12)),
                  // Delete button
                  SemanticHelper.label(
                    label: AppLocalizations.of(context)!.deleteSelected,
                    hint: 'Delete ${_selectedStarIds.length} selected star(s)',
                    isButton: true,
                    child: ElevatedButton.icon(
                      onPressed: () => _deleteSelectedStars(context, provider),
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppTheme.textPrimary,
                        size: FontScaling.getResponsiveIconSize(context, 20),
                      ),
                      label: Text(
                        AppLocalizations.of(context)!.deleteSelected,
                        style: FontScaling.getBodySmall(context).copyWith(
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error.withValues(alpha: 0.8),
                        padding: EdgeInsets.symmetric(
                          horizontal: FontScaling.getResponsiveSpacing(context, 16),
                          vertical: FontScaling.getResponsiveSpacing(context, 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // List content
          Expanded(
            child: sortedStars.isEmpty
                ? _buildEmptyState(context)
                : (_sortMethod == 'by_month' || _sortMethod == 'by_year')
                    ? _buildGroupedList(sortedStars)
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
          ),
        ],
      ),
        );
      },
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
            colorFilter: ColorFilter.mode(AppTheme.textPrimary.withValues(alpha: 0.3), BlendMode.srcIn),
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
    final isSelected = _selectedStarIds.contains(star.id);
    
    return Container(
      margin: EdgeInsets.only(
        bottom: FontScaling.getResponsiveSpacing(context, 12),
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primary.withValues(alpha: 0.1)
            : Color(0xFF0A0B1E).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppTheme.primary
              : star.color.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: FontScaling.getResponsiveSpacing(context, 16),
          vertical: FontScaling.getResponsiveSpacing(context, 8),
        ),
        leading: _isSelectionMode
            ? SemanticHelper.label(
                label: isSelected
                    ? 'Selected: ${_truncateText(star.text, 50)}'
                    : 'Not selected: ${_truncateText(star.text, 50)}',
                hint: isSelected ? 'Tap to deselect this star' : 'Tap to select this star',
                isToggle: true,
                toggleValue: isSelected,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedStarIds.add(star.id);
                      } else {
                        _selectedStarIds.remove(star.id);
                      }
                      // Exit selection mode if nothing selected
                      if (_selectedStarIds.isEmpty) {
                        _isSelectionMode = false;
                      }
                    });
                  },
                  activeColor: AppTheme.primary,
                  checkColor: AppTheme.textOnLight,
                ),
              )
            : Container(
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
            color: AppTheme.textPrimary.withValues(alpha: 0.9),
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
              color: AppTheme.textPrimary.withValues(alpha: 0.5),
            ),
          ),
        ),
        trailing: _isSelectionMode
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Move button
                  IconButton(
                    icon: Icon(
                      Icons.drive_file_move,
                      color: AppTheme.primary.withValues(alpha: 0.8),
                      size: FontScaling.getResponsiveIconSize(context, 20),
                    ),
                    onPressed: () => _showMoveDialog(context, star),
                    tooltip: AppLocalizations.of(context)!.moveStar,
                  ),
                  // Chevron
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.textPrimary.withValues(alpha: 0.5),
                    size: FontScaling.getResponsiveIconSize(context, 24),
                  ),
                ],
              ),
        onTap: _isSelectionMode
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedStarIds.remove(star.id);
                    if (_selectedStarIds.isEmpty) {
                      _isSelectionMode = false;
                    }
                  } else {
                    _selectedStarIds.add(star.id);
                  }
                });
              }
            : () => widget.onStarTap(star),
      ),
    );
  }

  Widget _buildGroupedList(List<GratitudeStar> stars) {
    String? lastGroup;
    final List<Widget> widgets = [];

    for (final star in stars) {
      String currentGroup;

      if (_sortMethod == 'by_month') {
        final month = star.createdAt;
        currentGroup = '${_getMonthName(month.month)} ${month.year}';
      } else {
        currentGroup = '${star.createdAt.year}';
      }

      if (currentGroup != lastGroup) {
        widgets.add(
          Padding(
            padding: EdgeInsets.fromLTRB(
              FontScaling.getResponsiveSpacing(context, 16),
              widgets.isEmpty ? FontScaling.getResponsiveSpacing(context, 16) : FontScaling.getResponsiveSpacing(context, 24),
              FontScaling.getResponsiveSpacing(context, 16),
              FontScaling.getResponsiveSpacing(context, 8),
            ),
            child: Text(
              currentGroup,
              style: FontScaling.getHeadingSmall(context).copyWith(
                color: AppTheme.primary,
              ),
            ),
          ),
        );
        lastGroup = currentGroup;
      }

      widgets.add(_buildListItem(context, star));
    }

    return Column(
      children: [
        // Action buttons when items are selected (for grouped list)
        if (_isSelectionMode && _selectedStarIds.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: FontScaling.getResponsiveSpacing(context, 16),
              vertical: FontScaling.getResponsiveSpacing(context, 8),
            ),
            decoration: BoxDecoration(
              color: Color(0xFF0A0B1E).withValues(alpha: 0.8),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Move button
                ElevatedButton.icon(
                  onPressed: () => _moveSelectedStars(context, Provider.of<GratitudeProvider>(context, listen: false)),
                  icon: Icon(
                    Icons.drive_file_move_outline,
                    color: AppTheme.textPrimary,
                    size: FontScaling.getResponsiveIconSize(context, 20),
                  ),
                  label: Text(
                    AppLocalizations.of(context)!.moveSelected,
                    style: FontScaling.getBodySmall(context).copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.8),
                    foregroundColor: AppTheme.textOnLight,
                    padding: EdgeInsets.symmetric(
                      horizontal: FontScaling.getResponsiveSpacing(context, 16),
                      vertical: FontScaling.getResponsiveSpacing(context, 12),
                    ),
                  ),
                ),
                SizedBox(width: FontScaling.getResponsiveSpacing(context, 12)),
                // Delete button
                ElevatedButton.icon(
                  onPressed: () => _deleteSelectedStars(context, Provider.of<GratitudeProvider>(context, listen: false)),
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppTheme.textPrimary,
                    size: FontScaling.getResponsiveIconSize(context, 20),
                  ),
                  label: Text(
                    AppLocalizations.of(context)!.deleteSelected,
                    style: FontScaling.getBodySmall(context).copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error.withValues(alpha: 0.8),
                    padding: EdgeInsets.symmetric(
                      horizontal: FontScaling.getResponsiveSpacing(context, 16),
                      vertical: FontScaling.getResponsiveSpacing(context, 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(bottom: FontScaling.getResponsiveSpacing(context, 16)),
            children: widgets,
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    // Use Flutter's built-in localization
    final date = DateTime(2025, month);
    return DateFormat.MMMM().format(date);
  }

  Future<void> _deleteSelectedStars(BuildContext context, GratitudeProvider provider) async {
    if (_selectedStarIds.isEmpty) return;

    // Capture context-dependent objects before async gap
    final l10n = AppLocalizations.of(context)!;
    final count = _selectedStarIds.length;
    final messenger = ScaffoldMessenger.of(context);
    final textStyle = FontScaling.getBodySmall(context);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.backgroundDark,
        title: Text(
          l10n.deleteSelected,
          style: FontScaling.getHeadingMedium(dialogContext).copyWith(
            color: AppTheme.error,
          ),
        ),
        content: Text(
          l10n.deleteSelectedStars(count),
          style: FontScaling.getBodyMedium(dialogContext).copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.cancelButton,
              style: FontScaling.getButtonText(dialogContext).copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: AppTheme.textPrimary,
            ),
            child: Text(
              l10n.deleteButton,
              style: FontScaling.getButtonText(dialogContext).copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Delete selected stars
    try {
      final starsToDelete = provider.gratitudeStars
          .where((star) => _selectedStarIds.contains(star.id))
          .toList();

      for (final star in starsToDelete) {
        await provider.deleteGratitude(star);
      }

      if (mounted) {
        setState(() {
          _selectedStarIds.clear();
          _isSelectionMode = false;
        });

        if (messenger.mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                l10n.starsDeleted(count),
                style: textStyle.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              backgroundColor: AppTheme.backgroundDark,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && messenger.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting stars: $e',
              style: textStyle.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
                backgroundColor: AppTheme.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _moveSelectedStars(BuildContext context, GratitudeProvider provider) async {
    if (_selectedStarIds.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final textStyle = FontScaling.getBodySmall(context);

    // Store the IDs for batch move
    final idsToMove = _selectedStarIds.toList();

    // Get the first selected star to determine current galaxy
    final firstStar = provider.gratitudeStars
        .firstWhere((star) => _selectedStarIds.contains(star.id));

    await GalaxyPickerBottomSheet.show(
      context: context,
      currentGalaxyId: firstStar.galaxyId,
      onGalaxySelected: (targetGalaxyId, targetGalaxyName) async {
        try {
          // Use batch move - single operation, single reload
          final movedCount = await provider.moveGratitudes(idsToMove, targetGalaxyId);

          if (mounted) {
            setState(() {
              _selectedStarIds.clear();
              _isSelectionMode = false;
            });

            if (messenger.mounted && movedCount > 0) {
              messenger.showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.textPrimary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.starsMovedSuccess(movedCount, targetGalaxyName),
                          style: textStyle.copyWith(color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppTheme.backgroundDark,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        } catch (e) {
          if (mounted && messenger.mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  l10n.starMoveFailed(e.toString()),
                  style: textStyle.copyWith(color: AppTheme.textPrimary),
                ),
                backgroundColor: AppTheme.error,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _showMoveDialog(BuildContext context, GratitudeStar star) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final provider = Provider.of<GratitudeProvider>(context, listen: false);
    final textStyle = FontScaling.getBodySmall(context);

    await GalaxyPickerBottomSheet.show(
      context: context,
      currentGalaxyId: star.galaxyId,
      onGalaxySelected: (targetGalaxyId, targetGalaxyName) async {
        try {
          await provider.moveGratitude(star, targetGalaxyId);

          if (mounted && messenger.mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.textPrimary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.starMovedSuccess(targetGalaxyName),
                        style: textStyle.copyWith(color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.backgroundDark,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (mounted && messenger.mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  l10n.starMoveFailed(e.toString()),
                  style: textStyle.copyWith(color: AppTheme.textPrimary),
                ),
                backgroundColor: AppTheme.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
    );
  }
}