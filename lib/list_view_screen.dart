import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'storage.dart';
import 'font_scaling.dart';
import 'l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'features/gratitudes/presentation/state/gratitude_provider.dart';
import 'core/accessibility/semantic_helper.dart';

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
      return DateFormat('yyyy/MMM/dd').format(date);
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
          _isSelectionMode && _selectedStarIds.isNotEmpty
              ? AppLocalizations.of(context)!.selectedCount(_selectedStarIds.length)
              : AppLocalizations.of(context)!.listViewTitle,
          style: FontScaling.getHeadingMedium(context).copyWith(
            color: Color(0xFFFFE135),
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
                  ? 'Deselect all stars'
                  : 'Select all stars',
              isButton: true,
              child: IconButton(
                icon: Icon(
                  _selectedStarIds.length == _getSortedStars(stars).length
                      ? Icons.deselect
                      : Icons.select_all,
                  color: Color(0xFFFFE135),
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
                  color: Colors.white,
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
                  color: Color(0xFFFFE135),
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
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.sortNewestFirst,
                          style: FontScaling.getBodySmall(context).copyWith(
                            color: _sortMethod == 'newest' ? Color(0xFFFFE135) : Colors.white.withValues(alpha: 0.9),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.sortOldestFirst,
                          style: FontScaling.getBodySmall(context).copyWith(
                            color: _sortMethod == 'oldest' ? Color(0xFFFFE135) : Colors.white.withValues(alpha: 0.9),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  ),
                  PopupMenuItem(
                    value: 'by_month',
                    child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        color: _sortMethod == 'by_month' ? Color(0xFFFFE135) : Colors.white.withValues(alpha: 0.7),
                        size: FontScaling.getResponsiveIconSize(context, 20),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.sortByMonth,
                          style: FontScaling.getBodySmall(context).copyWith(
                            color: _sortMethod == 'by_month' ? Color(0xFFFFE135) : Colors.white.withValues(alpha: 0.9),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  ),
                  PopupMenuItem(
                    value: 'by_year',
                    child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: _sortMethod == 'by_year' ? Color(0xFFFFE135) : Colors.white.withValues(alpha: 0.7),
                        size: FontScaling.getResponsiveIconSize(context, 20),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.sortByYear,
                          style: FontScaling.getBodySmall(context).copyWith(
                            color: _sortMethod == 'by_year' ? Color(0xFFFFE135) : Colors.white.withValues(alpha: 0.9),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],  // ← ADD THIS ] bracket
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
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.sortAlphabeticalAZ,
                          style: FontScaling.getBodySmall(context).copyWith(
                            color: _sortMethod == 'alpha_az' ? Color(0xFFFFE135) : Colors.white.withValues(alpha: 0.9),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.sortAlphabeticalZA,
                          style: FontScaling.getBodySmall(context).copyWith(
                            color: _sortMethod == 'alpha_za' ? Color(0xFFFFE135) : Colors.white.withValues(alpha: 0.9),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.sortByColor,
                          style: FontScaling.getBodySmall(context).copyWith(
                            color: _sortMethod == 'color' ? Color(0xFFFFE135) : Colors.white.withValues(alpha: 0.9),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
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
            color: Color(0xFFFFE135).withValues(alpha: 0.3),
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
                    color: Color(0xFFFFE135).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: SemanticHelper.label(
                      label: AppLocalizations.of(context)!.deleteSelected,
                      hint: 'Delete ${_selectedStarIds.length} selected star(s)',
                      isButton: true,
                      child: ElevatedButton.icon(
                        onPressed: () => _deleteSelectedStars(context, provider),
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: FontScaling.getResponsiveIconSize(context, 20),
                        ),
                        label: Text(
                          AppLocalizations.of(context)!.deleteSelected,
                          style: FontScaling.getBodySmall(context).copyWith(
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.8),
                          padding: EdgeInsets.symmetric(
                            vertical: FontScaling.getResponsiveSpacing(context, 12),
                          ),
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
    final isSelected = _selectedStarIds.contains(star.id);
    
    return Container(
      margin: EdgeInsets.only(
        bottom: FontScaling.getResponsiveSpacing(context, 12),
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? Color(0xFFFFE135).withValues(alpha: 0.1)
            : Color(0xFF0A0B1E).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? Color(0xFFFFE135)
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
                  activeColor: Color(0xFFFFE135),
                  checkColor: Color(0xFF1A2238),
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
        trailing: _isSelectionMode
            ? null
            : Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.5),
                size: FontScaling.getResponsiveIconSize(context, 24),
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
                color: Color(0xFFFFE135),
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
                  color: Color(0xFFFFE135).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteSelectedStars(context, Provider.of<GratitudeProvider>(context, listen: false)),
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: FontScaling.getResponsiveIconSize(context, 20),
                    ),
                    label: Text(
                      AppLocalizations.of(context)!.deleteSelected,
                      style: FontScaling.getBodySmall(context).copyWith(
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.8),
                      padding: EdgeInsets.symmetric(
                        vertical: FontScaling.getResponsiveSpacing(context, 12),
                      ),
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
        backgroundColor: Color(0xFF1A2238),
        title: Text(
          l10n.deleteSelected,
          style: FontScaling.getHeadingMedium(dialogContext).copyWith(
            color: Colors.red,
          ),
        ),
        content: Text(
          l10n.deleteSelectedStars(count),
          style: FontScaling.getBodyMedium(dialogContext).copyWith(
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.cancelButton,
              style: FontScaling.getButtonText(dialogContext).copyWith(
                color: Colors.white70,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              l10n.deleteButton,
              style: FontScaling.getButtonText(dialogContext).copyWith(
                color: Colors.white,
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
                  color: Colors.white,
                ),
              ),
              backgroundColor: Color(0xFF1A2238),
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
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}