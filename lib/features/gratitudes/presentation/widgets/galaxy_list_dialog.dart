import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/accessibility/semantic_helper.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/error/error_context.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../font_scaling.dart';
import '../../../../galaxy_metadata.dart';
import '../../../../l10n/app_localizations.dart';
import '../state/galaxy_provider.dart';

/// Full-screen dialog showing all galaxies with create/switch options
class GalaxyListDialog extends StatefulWidget {
  const GalaxyListDialog({super.key});

  @override
  State<GalaxyListDialog> createState() => _GalaxyListDialogState();
}

class _GalaxyListDialogState extends State<GalaxyListDialog> {
  final bool _isLoading = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedGalaxyIds = {};
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<GalaxyProvider>(
      builder: (context, galaxyProvider, child) {
        final activeGalaxies = galaxyProvider.activeGalaxies;

        return Scaffold(
          backgroundColor: Color(0xFF1A2238).withValues(alpha: 0.98),
          appBar: AppBar(
            backgroundColor: Color(0xFF1A2238),
            elevation: 0,
            leading: SemanticHelper.label(
              label: l10n.closeButton,
              hint: l10n.closeAppHint,
              isButton: true,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            title: Text(
              _isSelectionMode && _selectedGalaxyIds.isNotEmpty
                  ? l10n.selectedCount(_selectedGalaxyIds.length)
                  : l10n.myGalaxies,
              style: FontScaling.getHeadingMedium(context).copyWith(
                color: Color(0xFFFFE135),
                fontSize:
                    FontScaling.getHeadingMedium(context).fontSize! *
                    UIConstants.universalUIScale,
              ),
            ),
            centerTitle: true,
            actions: _isSelectionMode
                ? [
                    // Select All / Deselect All button
                    SemanticHelper.label(
                      label: _selectedGalaxyIds.length == activeGalaxies.length
                          ? l10n.deselectAll
                          : l10n.selectAll,
                      hint: _selectedGalaxyIds.length == activeGalaxies.length
                          ? l10n.deselectAllGalaxies
                          : l10n.selectAllGalaxies,
                      isButton: true,
                      child: IconButton(
                        icon: Icon(
                          _selectedGalaxyIds.length == activeGalaxies.length
                              ? Icons.deselect
                              : Icons.select_all,
                          color: Color(0xFFFFE135),
                          size:
                              FontScaling.getResponsiveIconSize(context, 24) *
                              UIConstants.universalUIScale,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_selectedGalaxyIds.length ==
                                activeGalaxies.length) {
                              _selectedGalaxyIds.clear();
                            } else {
                              _selectedGalaxyIds.addAll(
                                activeGalaxies.map((g) => g.id),
                              );
                            }
                          });
                        },
                        tooltip:
                            _selectedGalaxyIds.length == activeGalaxies.length
                            ? l10n.deselectAll
                            : l10n.selectAll,
                      ),
                    ),
                    // Cancel selection mode
                    SemanticHelper.label(
                      label: l10n.cancelSelection,
                      hint: 'Exit selection mode',
                      isButton: true,
                      child: IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.white,
                          size:
                              FontScaling.getResponsiveIconSize(context, 24) *
                              UIConstants.universalUIScale,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSelectionMode = false;
                            _selectedGalaxyIds.clear();
                          });
                        },
                        tooltip: l10n.cancelSelection,
                      ),
                    ),
                  ]
                : [
                    // Enter selection mode button
                    SemanticHelper.label(
                      label: l10n.selectMode,
                      hint: 'Enter selection mode to select multiple galaxies',
                      isButton: true,
                      child: IconButton(
                        icon: Icon(
                          Icons.check_box_outline_blank,
                          color: Color(0xFFFFE135),
                          size:
                              FontScaling.getResponsiveIconSize(context, 24) *
                              UIConstants.universalUIScale,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSelectionMode = true;
                          });
                        },
                        tooltip: l10n.selectMode,
                      ),
                    ),
                  ],
          ),
          body: _buildBody(context, galaxyProvider, l10n),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    GalaxyProvider galaxyProvider,
    AppLocalizations l10n,
  ) {
    if (galaxyProvider.isLoading || _isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFE135)),
        ),
      );
    }

    final activeGalaxies = galaxyProvider.activeGalaxies;

    return Column(
      children: [
        // Action buttons when items are selected
        if (_isSelectionMode && _selectedGalaxyIds.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal:
                  FontScaling.getResponsiveSpacing(context, 16) *
                  UIConstants.universalUIScale,
              vertical:
                  FontScaling.getResponsiveSpacing(context, 8) *
                  UIConstants.universalUIScale,
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
                    label: l10n.deleteSelected,
                    hint:
                        'Delete ${_selectedGalaxyIds.length} selected galaxy/galaxies',
                    isButton: true,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _deleteSelectedGalaxies(context, galaxyProvider),
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size:
                            FontScaling.getResponsiveIconSize(context, 20) *
                            UIConstants.universalUIScale,
                      ),
                      label: Text(
                        l10n.deleteSelected,
                        style: FontScaling.getBodySmall(context).copyWith(
                          color: Colors.white,
                          fontSize:
                              FontScaling.getBodySmall(context).fontSize! *
                              UIConstants.universalUIScale,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.8),
                        padding: EdgeInsets.symmetric(
                          vertical:
                              FontScaling.getResponsiveSpacing(context, 12) *
                              UIConstants.universalUIScale,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Galaxy list
        Expanded(
          child: activeGalaxies.isEmpty
              ? _buildEmptyState(context, l10n)
              : Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: false,
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.all(
                      FontScaling.getResponsiveSpacing(context, 16) *
                          UIConstants.universalUIScale,
                    ),
                    itemCount: activeGalaxies.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Color(0xFFFFE135).withValues(alpha: 0.2),
                      height: FontScaling.getResponsiveSpacing(context, 1),
                    ),
                    itemBuilder: (context, index) {
                      final galaxy = activeGalaxies[index];
                      return _buildGalaxyItem(
                        context,
                        galaxy,
                        galaxyProvider,
                        l10n,
                      );
                    },
                  ),
                ),
        ),

        // Create new galaxy button at bottom
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            FontScaling.getResponsiveSpacing(context, 16) *
                UIConstants.universalUIScale,
          ),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Color(0xFFFFE135).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: SemanticHelper.label(
            label: l10n.createNewGalaxy,
            hint: l10n.startNewGalaxyWithFreshStars,
            isButton: true,
            child: ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _showCreateGalaxyDialog(context),
              icon: Icon(
                Icons.add,
                color: Color(0xFF1A2238),
                size:
                    FontScaling.getResponsiveIconSize(context, 20) *
                    UIConstants.universalUIScale,
              ),
              label: Text(
                l10n.createNewGalaxy,
                style: FontScaling.getBodyMedium(context).copyWith(
                  color: Color(0xFF1A2238),
                  fontWeight: FontWeight.w600,
                  fontSize:
                      FontScaling.getBodyMedium(context).fontSize! *
                      UIConstants.universalUIScale,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFE135),
                foregroundColor: Color(0xFF1A2238),
                padding: EdgeInsets.symmetric(
                  horizontal:
                      FontScaling.getResponsiveSpacing(context, 24) *
                      UIConstants.universalUIScale,
                  vertical:
                      FontScaling.getResponsiveSpacing(context, 16) *
                      UIConstants.universalUIScale,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    FontScaling.getResponsiveSpacing(context, 12) *
                        UIConstants.universalUIScale,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGalaxyItem(
    BuildContext context,
    GalaxyMetadata galaxy,
    GalaxyProvider galaxyProvider,
    AppLocalizations l10n,
  ) {
    final isActive = galaxyProvider.activeGalaxyId == galaxy.id;
    final isSelected = _selectedGalaxyIds.contains(galaxy.id);
    final formattedDate = _formatDate(galaxy.createdAt);

    return SemanticHelper.label(
      label: _isSelectionMode
          ? (isSelected
                ? 'Selected: ${galaxy.name}'
                : 'Not selected: ${galaxy.name}')
          : (isActive
                ? l10n.activeGalaxyItem(galaxy.name, galaxy.starCount)
                : l10n.galaxyItem(galaxy.name, galaxy.starCount)),
      hint: _isSelectionMode
          ? (isSelected
                ? 'Tap to deselect this galaxy'
                : 'Tap to select this galaxy')
          : (isActive ? l10n.currentlyActiveGalaxy : l10n.tapToSwitchToGalaxy),
      isButton: true,
      isToggle: _isSelectionMode,
      toggleValue: _isSelectionMode ? isSelected : null,
      child: InkWell(
        onTap: _isSelectionMode
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedGalaxyIds.remove(galaxy.id);
                    if (_selectedGalaxyIds.isEmpty) {
                      _isSelectionMode = false;
                    }
                  } else {
                    _selectedGalaxyIds.add(galaxy.id);
                  }
                });
              }
            : (isActive
                  ? null
                  : () => _switchToGalaxy(context, galaxy.id, galaxyProvider)),
        onLongPress: _isSelectionMode
            ? null
            : () => _showRenameDialog(context, galaxy, galaxyProvider),
        child: Container(
          padding: EdgeInsets.all(
            FontScaling.getResponsiveSpacing(context, 16) *
                UIConstants.universalUIScale,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? Color(0xFFFFE135).withValues(alpha: 0.1)
                : (isActive
                      ? Color(0xFFFFE135).withValues(alpha: 0.1)
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(
              FontScaling.getResponsiveSpacing(context, 8) *
                  UIConstants.universalUIScale,
            ),
            border: (isSelected || isActive)
                ? Border.all(
                    color: Color(
                      0xFFFFE135,
                    ).withValues(alpha: isSelected ? 1.0 : 0.5),
                    width: isSelected ? 2 : 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              // Checkbox or Galaxy icon
              _isSelectionMode
                  ? SemanticHelper.label(
                      label: isSelected
                          ? 'Selected: ${galaxy.name}'
                          : 'Not selected: ${galaxy.name}',
                      hint: isSelected ? 'Tap to deselect' : 'Tap to select',
                      isToggle: true,
                      toggleValue: isSelected,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedGalaxyIds.add(galaxy.id);
                            } else {
                              _selectedGalaxyIds.remove(galaxy.id);
                              if (_selectedGalaxyIds.isEmpty) {
                                _isSelectionMode = false;
                              }
                            }
                          });
                        },
                        activeColor: Color(0xFFFFE135),
                        checkColor: Color(0xFF1A2238),
                      ),
                    )
                  : Icon(
                      Icons.stars,
                      color: isActive ? Color(0xFFFFE135) : Colors.white70,
                      size:
                          FontScaling.getResponsiveIconSize(context, 32) *
                          UIConstants.universalUIScale,
                    ),

              SizedBox(
                width:
                    FontScaling.getResponsiveSpacing(context, 16) *
                    UIConstants.universalUIScale,
              ),

              // Galaxy info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            galaxy.name,
                            style: FontScaling.getBodyLarge(context).copyWith(
                              color: isActive
                                  ? Color(0xFFFFE135)
                                  : Colors.white,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize:
                                  FontScaling.getBodyLarge(context).fontSize! *
                                  UIConstants.universalUIScale,
                            ),
                          ),
                        ),
                        if (isActive) ...[
                          SizedBox(
                            width: FontScaling.getResponsiveSpacing(context, 8),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  FontScaling.getResponsiveSpacing(context, 8) *
                                  UIConstants.universalUIScale,
                              vertical:
                                  FontScaling.getResponsiveSpacing(context, 4) *
                                  UIConstants.universalUIScale,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFE135).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                FontScaling.getResponsiveSpacing(context, 12) *
                                    UIConstants.universalUIScale,
                              ),
                            ),
                            child: Text(
                              l10n.active.toUpperCase(),
                              style: FontScaling.getCaption(context).copyWith(
                                color: Color(0xFFFFE135),
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    FontScaling.getCaption(context).fontSize! *
                                    UIConstants.universalUIScale,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(
                      height: FontScaling.getResponsiveSpacing(context, 4),
                    ),
                    Text(
                      l10n.galaxyStats(galaxy.starCount, formattedDate),
                      style: FontScaling.getCaption(context).copyWith(
                        color: isActive ? Colors.white70 : Colors.white60,
                        fontSize:
                            FontScaling.getCaption(context).fontSize! *
                            UIConstants.universalUIScale,
                      ),
                    ),
                  ],
                ),
              ),

              // Edit button (visible when not in selection mode)
              if (!_isSelectionMode) ...[
                SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
                SemanticHelper.label(
                  label: l10n.editGalaxy,
                  hint: l10n.renameGalaxyHint,
                  isButton: true,
                  child: IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: isActive ? Color(0xFFFFE135) : Colors.white60,
                      size:
                          FontScaling.getResponsiveIconSize(context, 20) *
                          UIConstants.universalUIScale,
                    ),
                    onPressed: () =>
                        _showRenameDialog(context, galaxy, galaxyProvider),
                    tooltip: l10n.renameGalaxy,
                  ),
                ),

                // Arrow for non-active galaxies
                if (!isActive) ...[
                  SizedBox(width: FontScaling.getResponsiveSpacing(context, 4)),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white60,
                    size:
                        FontScaling.getResponsiveIconSize(context, 16) *
                        UIConstants.universalUIScale,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          FontScaling.getResponsiveSpacing(context, 32) *
              UIConstants.universalUIScale,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.stars,
              size:
                  FontScaling.getResponsiveIconSize(context, 64) *
                  UIConstants.universalUIScale,
              color: Color(0xFFFFE135).withValues(alpha: 0.6),
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
            Text(
              l10n.noGalaxiesYet,
              style: FontScaling.getHeadingMedium(context).copyWith(
                color: Colors.white,
                fontSize:
                    FontScaling.getHeadingMedium(context).fontSize! *
                    UIConstants.universalUIScale,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 8)),
            Text(
              l10n.createYourFirstGalaxy,
              style: FontScaling.getBodyMedium(context).copyWith(
                color: Colors.white70,
                fontSize:
                    FontScaling.getBodyMedium(context).fontSize! *
                    UIConstants.universalUIScale,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _switchToGalaxy(
    BuildContext context,
    String galaxyId,
    GalaxyProvider galaxyProvider,
  ) async {
    // Capture context-dependent objects BEFORE async gap and dialog close
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bodyMediumStyle = FontScaling.getBodyMedium(context);

    // Close dialog immediately for instant feedback
    navigator.popUntil((route) => route.isFirst);

    try {
      // switchGalaxy handles everything: sets active, updates filter, loads gratitudes, AND syncs
      // This happens on the main screen now, with loading state visible in the provider
      await galaxyProvider.switchGalaxy(galaxyId);

      // Store galaxy name for success message
      final galaxyName = galaxyProvider.activeGalaxy?.name ?? 'Unknown Galaxy';

      // Show confirmation on main screen
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.galaxySwitchedSuccess(galaxyName),
            style: bodyMediumStyle,
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF1A2238),
        ),
      );
    } catch (e, stack) {
      // Handle error with ErrorHandler for user-friendly message
      final error = ErrorHandler.handle(
        e,
        stack,
        context: ErrorContext.galaxy,
        l10n: l10n,
      );

      // Show error on main screen
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.galaxySwitchFailed(error.userMessage),
            style: bodyMediumStyle,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCreateGalaxyDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => CreateGalaxyDialog());
  }

  void _showRenameDialog(
    BuildContext context,
    GalaxyMetadata galaxy,
    GalaxyProvider galaxyProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => RenameGalaxyDialog(galaxy: galaxy),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _deleteSelectedGalaxies(
    BuildContext context,
    GalaxyProvider galaxyProvider,
  ) async {
    if (_selectedGalaxyIds.isEmpty) return;

    // Capture context-dependent objects before async gap
    final l10n = AppLocalizations.of(context)!;
    final count = _selectedGalaxyIds.length;
    final messenger = ScaffoldMessenger.of(context);
    final textStyle = FontScaling.getBodyMedium(context);

    // Check if deleting all galaxies
    final activeGalaxies = galaxyProvider.activeGalaxies;
    final galaxiesToDelete = activeGalaxies
        .where((galaxy) => _selectedGalaxyIds.contains(galaxy.id))
        .toList();
    final isDeletingAllGalaxies =
        galaxiesToDelete.length == activeGalaxies.length;

    // Show appropriate confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Color(0xFF1A2238),
        title: Text(
          isDeletingAllGalaxies
              ? l10n.deleteLastGalaxyTitle
              : l10n.deleteSelected,
          style: FontScaling.getHeadingMedium(
            dialogContext,
          ).copyWith(color: Colors.red),
        ),
        content: Text(
          isDeletingAllGalaxies
              ? l10n.deleteLastGalaxyMessage
              : l10n.deleteSelectedGalaxies(count),
          style: FontScaling.getBodyMedium(
            dialogContext,
          ).copyWith(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.cancelButton,
              style: FontScaling.getButtonText(
                dialogContext,
              ).copyWith(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              isDeletingAllGalaxies
                  ? l10n.deleteLastGalaxyButton
                  : l10n.deleteButton,
              style: FontScaling.getButtonText(
                dialogContext,
              ).copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Delete selected galaxies
    try {
      for (final galaxy in galaxiesToDelete) {
        await galaxyProvider.deleteGalaxy(galaxy.id);
      }

      // Check if a new galaxy was auto-created
      final remainingGalaxies = galaxyProvider.activeGalaxies;
      final String successMessage;
      if (isDeletingAllGalaxies && remainingGalaxies.isNotEmpty) {
        // A new galaxy was auto-created
        final newGalaxyName = remainingGalaxies.first.name;
        successMessage = l10n.newGalaxyCreated(newGalaxyName);
      } else {
        // Normal deletion
        successMessage = l10n.galaxiesDeleted(count);
      }

      if (mounted) {
        setState(() {
          _selectedGalaxyIds.clear();
          _isSelectionMode = false;
        });

        if (messenger.mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                successMessage,
                style: textStyle.copyWith(color: Colors.white),
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
              'Error deleting galaxies: $e',
              style: textStyle.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

/// Dialog for creating a new galaxy
class CreateGalaxyDialog extends StatefulWidget {
  const CreateGalaxyDialog({super.key});

  @override
  State<CreateGalaxyDialog> createState() => _CreateGalaxyDialogState();
}

class _CreateGalaxyDialogState extends State<CreateGalaxyDialog> {
  final _controller = TextEditingController();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Auto-suggest current year
    _controller.text = DateTime.now().year.toString();
    // Pre-select the text for easy editing
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: Color(0xFF1A2238),
      title: Text(
        l10n.createNewGalaxy,
        style: FontScaling.getHeadingMedium(
          context,
        ).copyWith(color: Color(0xFFFFE135)),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.nameYourGalaxy,
              style: FontScaling.getBodyMedium(
                context,
              ).copyWith(color: Colors.white),
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
            SemanticHelper.label(
              label: l10n.galaxyNameField,
              hint: l10n.enterGalaxyName,
              child: TextField(
                controller: _controller,
                style: FontScaling.getBodyMedium(
                  context,
                ).copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: l10n.galaxyNameHint,
                  hintStyle: FontScaling.getBodyMedium(
                    context,
                  ).copyWith(color: Colors.white60),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFFE135)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFFFFE135).withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFFE135)),
                  ),
                ),
                autofocus: true,
                maxLength: 50,
                enabled: !_isCreating,
              ),
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
            Text(
              l10n.createGalaxyDescription,
              style: FontScaling.getCaption(
                context,
              ).copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: Text(
            l10n.cancel,
            style: FontScaling.getButtonText(
              context,
            ).copyWith(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createGalaxy,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFFE135),
            foregroundColor: Color(0xFF1A2238),
          ),
          child: _isCreating
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF1A2238),
                    ),
                  ),
                )
              : Text(l10n.createGalaxy),
        ),
      ],
    );
  }

  Future<void> _createGalaxy() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreating = true);

    // Capture l10n and textStyle before async gap
    final l10n = AppLocalizations.of(context)!;
    final textStyle = FontScaling.getBodyMedium(context);

    try {
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final galaxyProvider = Provider.of<GalaxyProvider>(
        context,
        listen: false,
      );
      await galaxyProvider.createGalaxy(name: name, switchToNew: true);

      if (navigator.mounted) {
        navigator.pop(); // Close create dialog
        navigator.pop(); // Close galaxy list dialog

        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.galaxyCreatedSuccess(name), style: textStyle),
            backgroundColor: const Color(0xFF1A2238),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stack) {
      // Handle error with ErrorHandler for user-friendly message
      final error = ErrorHandler.handle(
        e,
        stack,
        context: ErrorContext.galaxy,
        l10n: l10n, // Use captured value
      );

      ScaffoldMessengerState? messenger;
      if (mounted) {
        messenger = ScaffoldMessenger.of(context);
      }

      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            l10n.galaxyCreateFailed(error.userMessage),
            style: textStyle,
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}

/// Dialog for renaming an existing galaxy
class RenameGalaxyDialog extends StatefulWidget {
  final GalaxyMetadata galaxy;

  const RenameGalaxyDialog({super.key, required this.galaxy});

  @override
  State<RenameGalaxyDialog> createState() => _RenameGalaxyDialogState();
}

class _RenameGalaxyDialogState extends State<RenameGalaxyDialog> {
  final _controller = TextEditingController();
  bool _isRenaming = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.galaxy.name;
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 24)),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2238).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFFE135).withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.renameGalaxy,
                style: FontScaling.getHeadingMedium(
                  context,
                ).copyWith(color: const Color(0xFFFFE135)),
              ),
              SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
              SemanticHelper.label(
                label: l10n.galaxyNameField,
                hint: l10n.enterNewGalaxyName,
                child: TextField(
                  controller: _controller,
                  style: FontScaling.getBodyMedium(
                    context,
                  ).copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFFE135)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color(0xFFFFE135).withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFFE135)),
                    ),
                  ),
                  autofocus: true,
                  maxLength: 50,
                  enabled: !_isRenaming,
                ),
              ),
              SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),
              // Actions row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Delete button on the left
                  TextButton(
                    onPressed: _isRenaming
                        ? null
                        : () => _confirmDelete(context),
                    child: Text(
                      l10n.deleteButton,
                      style: FontScaling.getButtonText(
                        context,
                      ).copyWith(color: Colors.red.withValues(alpha: 0.8)),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _isRenaming
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(
                      l10n.cancel,
                      style: FontScaling.getButtonText(
                        context,
                      ).copyWith(color: Colors.white70),
                    ),
                  ),
                  SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
                  ElevatedButton(
                    onPressed: _isRenaming ? null : _renameGalaxy,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE135),
                      foregroundColor: const Color(0xFF1A2238),
                    ),
                    child: _isRenaming
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF1A2238),
                              ),
                            ),
                          )
                        : Text(l10n.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final galaxyProvider = Provider.of<GalaxyProvider>(context, listen: false);

    // Check if this is the last galaxy
    final activeGalaxies = galaxyProvider.activeGalaxies;
    final isLastGalaxy = activeGalaxies.length == 1;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Color(0xFF1A2238),
        title: Text(
          isLastGalaxy ? l10n.deleteLastGalaxyTitle : l10n.deleteGalaxy,
          style: FontScaling.getHeadingMedium(
            context,
          ).copyWith(color: Colors.red),
        ),
        content: Text(
          isLastGalaxy
              ? l10n.deleteLastGalaxyMessage
              : l10n.deleteGalaxyConfirmation(
                  widget.galaxy.name,
                  widget.galaxy.starCount,
                ),
          style: FontScaling.getBodyMedium(
            context,
          ).copyWith(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              l10n.cancel,
              style: FontScaling.getButtonText(
                context,
              ).copyWith(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _deleteGalaxy();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              isLastGalaxy ? l10n.deleteLastGalaxyButton : l10n.deleteButton,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGalaxy() async {
    setState(() => _isRenaming = true); // Reuse loading state

    final l10n = AppLocalizations.of(context)!;
    final textStyle = FontScaling.getBodyMedium(context);
    final galaxyProvider = Provider.of<GalaxyProvider>(context, listen: false);

    // Check if this is the last galaxy (before deletion)
    final activeGalaxiesBefore = galaxyProvider.activeGalaxies;
    final isLastGalaxy = activeGalaxiesBefore.length == 1;

    try {
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      await galaxyProvider.deleteGalaxy(widget.galaxy.id);

      // Check if a new galaxy was auto-created
      final remainingGalaxies = galaxyProvider.activeGalaxies;
      final String successMessage;
      if (isLastGalaxy && remainingGalaxies.isNotEmpty) {
        // A new galaxy was auto-created
        final newGalaxyName = remainingGalaxies.first.name;
        successMessage = l10n.newGalaxyCreated(newGalaxyName);
      } else {
        // Normal deletion
        successMessage = l10n.galaxyDeletedSuccess(widget.galaxy.name);
      }

      if (navigator.mounted) {
        navigator.pop(); // Close rename dialog
        navigator.pop(); // Close galaxy list dialog

        messenger.showSnackBar(
          SnackBar(
            content: Text(successMessage, style: textStyle),
            backgroundColor: const Color(0xFF1A2238),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stack) {
      final error = ErrorHandler.handle(
        e,
        stack,
        context: ErrorContext.galaxy,
        l10n: l10n,
      );

      final messenger = mounted ? ScaffoldMessenger.of(context) : null;

      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            l10n.galaxyDeleteFailed(error.userMessage),
            style: textStyle,
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRenaming = false);
      }
    }
  }

  Future<void> _renameGalaxy() async {
    final name = _controller.text.trim();
    if (name.isEmpty || name == widget.galaxy.name) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isRenaming = true);

    final l10n = AppLocalizations.of(context)!;
    final textStyle = FontScaling.getBodyMedium(context);

    try {
      // Capture context-dependent objects BEFORE the async gap
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final galaxyProvider = Provider.of<GalaxyProvider>(
        context,
        listen: false,
      );

      await galaxyProvider.renameGalaxy(widget.galaxy.id, name);

      // Use only the captured objects after the await
      if (navigator.mounted) {
        navigator.pop();

        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.galaxyRenamedSuccess(name), style: textStyle),
            backgroundColor: const Color(0xFF1A2238),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stack) {
      // Handle error with ErrorHandler for user-friendly message
      final error = ErrorHandler.handle(
        e,
        stack,
        context: ErrorContext.galaxy,
        l10n: l10n, // Use captured value
      );

      // Safe fallback — do NOT use Navigator.of(context) here
      final messenger = mounted ? ScaffoldMessenger.of(context) : null;

      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            l10n.galaxyRenameFailed(error.userMessage),
            style: textStyle,
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRenaming = false);
      }
    }
  }
}
