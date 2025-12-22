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
  bool _isLoading = false;
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
          l10n.myGalaxies,
          style: FontScaling.getHeadingMedium(context).copyWith(
            color: Color(0xFFFFE135),
            fontSize: FontScaling.getHeadingMedium(context).fontSize! * UIConstants.universalUIScale,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<GalaxyProvider>(
        builder: (context, galaxyProvider, child) {
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
                            FontScaling.getResponsiveSpacing(context, 16) * UIConstants.universalUIScale,
                          ),
                          itemCount: activeGalaxies.length,
                          separatorBuilder: (context, index) => Divider(
                    color: Color(0xFFFFE135).withValues(alpha: 0.2),
                    height: FontScaling.getResponsiveSpacing(context, 1),
                  ),
                  itemBuilder: (context, index) {
                    final galaxy = activeGalaxies[index];
                    return _buildGalaxyItem(context, galaxy, galaxyProvider, l10n);
                  },
                        ),
                      ),
              ),

              // Create new galaxy button at bottom
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(
                  FontScaling.getResponsiveSpacing(context, 16) * UIConstants.universalUIScale,
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
                    onPressed: _isLoading ? null : () => _showCreateGalaxyDialog(context),
                    icon: Icon(
                      Icons.add,
                      color: Color(0xFF1A2238),
                      size: FontScaling.getResponsiveIconSize(context, 20) * UIConstants.universalUIScale,
                    ),
                    label: Text(
                      l10n.createNewGalaxy,
                      style: FontScaling.getBodyMedium(context).copyWith(
                        color: Color(0xFF1A2238),
                        fontWeight: FontWeight.w600,
                        fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFE135),
                      foregroundColor: Color(0xFF1A2238),
                      padding: EdgeInsets.symmetric(
                        horizontal: FontScaling.getResponsiveSpacing(context, 24) * UIConstants.universalUIScale,
                        vertical: FontScaling.getResponsiveSpacing(context, 16) * UIConstants.universalUIScale,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          FontScaling.getResponsiveSpacing(context, 12) * UIConstants.universalUIScale,
                        ),
                      ),
                    ),
                  ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGalaxyItem(
      BuildContext context,
      GalaxyMetadata galaxy,
      GalaxyProvider galaxyProvider,
      AppLocalizations l10n,
      ) {
    final isActive = galaxyProvider.activeGalaxyId == galaxy.id;
    final formattedDate = _formatDate(galaxy.createdAt);

    return SemanticHelper.label(
      label: isActive
          ? l10n.activeGalaxyItem(galaxy.name, galaxy.starCount)
          : l10n.galaxyItem(galaxy.name, galaxy.starCount),
      hint: isActive
          ? l10n.currentlyActiveGalaxy
          : l10n.tapToSwitchToGalaxy,
      isButton: true,
      child: InkWell(
        onTap: isActive ? null : () => _switchToGalaxy(context, galaxy.id, galaxyProvider),
        onLongPress: () => _showRenameDialog(context, galaxy, galaxyProvider),
        child: Container(
          padding: EdgeInsets.all(
            FontScaling.getResponsiveSpacing(context, 16) * UIConstants.universalUIScale,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? Color(0xFFFFE135).withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(
              FontScaling.getResponsiveSpacing(context, 8) * UIConstants.universalUIScale,
            ),
            border: isActive
                ? Border.all(
              color: Color(0xFFFFE135).withValues(alpha: 0.5),
              width: 1,
            )
                : null,
          ),
          child: Row(
            children: [
              // Galaxy icon
              Icon(
                Icons.stars,
                color: isActive ? Color(0xFFFFE135) : Colors.white70,
                size: FontScaling.getResponsiveIconSize(context, 32) * UIConstants.universalUIScale,
              ),

              SizedBox(width: FontScaling.getResponsiveSpacing(context, 16) * UIConstants.universalUIScale),

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
                              color: isActive ? Color(0xFFFFE135) : Colors.white,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                              fontSize: FontScaling.getBodyLarge(context).fontSize! * UIConstants.universalUIScale,
                            ),
                          ),
                        ),
                        if (isActive) ...[
                          SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: FontScaling.getResponsiveSpacing(context, 8) * UIConstants.universalUIScale,
                              vertical: FontScaling.getResponsiveSpacing(context, 4) * UIConstants.universalUIScale,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFE135).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                FontScaling.getResponsiveSpacing(context, 12) * UIConstants.universalUIScale,
                              ),
                            ),
                            child: Text(
                              l10n.active.toUpperCase(),
                              style: FontScaling.getCaption(context).copyWith(
                                color: Color(0xFFFFE135),
                                fontWeight: FontWeight.bold,
                                fontSize: FontScaling.getCaption(context).fontSize! * UIConstants.universalUIScale,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: FontScaling.getResponsiveSpacing(context, 4)),
                    Text(
                      l10n.galaxyStats(galaxy.starCount, formattedDate),
                      style: FontScaling.getCaption(context).copyWith(
                        color: isActive ? Colors.white70 : Colors.white60,
                        fontSize: FontScaling.getCaption(context).fontSize! * UIConstants.universalUIScale,
                      ),
                    ),
                  ],
                ),
              ),

              // Edit button (visible for all galaxies)
              SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
              SemanticHelper.label(
                label: l10n.editGalaxy,
                hint: l10n.renameGalaxyHint,
                isButton: true,
                child: IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: isActive ? Color(0xFFFFE135) : Colors.white60,
                    size: FontScaling.getResponsiveIconSize(context, 20) * UIConstants.universalUIScale,
                  ),
                  onPressed: () => _showRenameDialog(context, galaxy, galaxyProvider),
                  tooltip: l10n.renameGalaxy,
                ),
              ),

              // Arrow for non-active galaxies
              if (!isActive) ...[
                SizedBox(width: FontScaling.getResponsiveSpacing(context, 4)),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white60,
                  size: FontScaling.getResponsiveIconSize(context, 16) * UIConstants.universalUIScale,
                ),
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
          FontScaling.getResponsiveSpacing(context, 32) * UIConstants.universalUIScale,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.stars,
              size: FontScaling.getResponsiveIconSize(context, 64) * UIConstants.universalUIScale,
              color: Color(0xFFFFE135).withValues(alpha: 0.6),
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
            Text(
              l10n.noGalaxiesYet,
              style: FontScaling.getHeadingMedium(context).copyWith(
                color: Colors.white,
                fontSize: FontScaling.getHeadingMedium(context).fontSize! * UIConstants.universalUIScale,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 8)),
            Text(
              l10n.createYourFirstGalaxy,
              style: FontScaling.getBodyMedium(context).copyWith(
                color: Colors.white70,
                fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _switchToGalaxy(BuildContext context, String galaxyId, GalaxyProvider galaxyProvider) async {
    setState(() => _isLoading = true);

    // Capture l10n before async gap to avoid BuildContext warning
    final l10n = mounted ? AppLocalizations.of(context) : null;

    try {
      // switchGalaxy handles everything: sets active, updates filter, loads gratitudes, AND syncs
      await galaxyProvider.switchGalaxy(galaxyId);

      if (context.mounted) {
        // Store galaxy name for toast before popping
        final galaxyName = galaxyProvider.activeGalaxy?.name ?? 'Unknown Galaxy';

        // Close dialog FIRST
        Navigator.of(context).popUntil((route) => route.isFirst);

        // Show confirmation on main screen context
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.galaxySwitchedSuccess(galaxyName), style: FontScaling.getBodyMedium(context)),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF1A2238),
          ),
        );
      }
    } catch (e, stack) {
      // Handle error with ErrorHandler for user-friendly message
      final error = ErrorHandler.handle(
        e,
        stack,
        context: ErrorContext.galaxy,
        l10n: l10n,  // Use captured value
      );

      // Only show error if dialog is still mounted
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.galaxySwitchFailed(error.userMessage), style: FontScaling.getBodyMedium(context)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Always reset loading state (whether success or error)
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCreateGalaxyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateGalaxyDialog(),
    );
  }

  void _showRenameDialog(BuildContext context, GalaxyMetadata galaxy, GalaxyProvider galaxyProvider) {
    showDialog(
      context: context,
      builder: (context) => RenameGalaxyDialog(galaxy: galaxy),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
    _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
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
        style: FontScaling.getHeadingMedium(context).copyWith(
          color: Color(0xFFFFE135),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.nameYourGalaxy,
              style: FontScaling.getBodyMedium(context).copyWith(
                color: Colors.white,
              ),
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
            SemanticHelper.label(
              label: l10n.galaxyNameField,
              hint: l10n.enterGalaxyName,
              child: TextField(
                controller: _controller,
                style: FontScaling.getBodyMedium(context).copyWith(
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: l10n.galaxyNameHint,
                  hintStyle: FontScaling.getBodyMedium(context).copyWith(
                    color: Colors.white60,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFFE135)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFFE135).withValues(alpha: 0.5)),
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
              style: FontScaling.getCaption(context).copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: Text(
            l10n.cancel,
            style: FontScaling.getButtonText(context).copyWith(
              color: Colors.white70,
            ),
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
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A2238)),
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
      final galaxyProvider = Provider.of<GalaxyProvider>(context, listen: false);
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
        l10n: l10n,  // Use captured value
      );

      ScaffoldMessengerState? messenger;
      if (mounted) {
        messenger = ScaffoldMessenger.of(context);
      }

      messenger?.showSnackBar(
        SnackBar(
          content: Text(l10n.galaxyCreateFailed(error.userMessage), style: textStyle),
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

  const RenameGalaxyDialog({
    super.key,
    required this.galaxy,
  });

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
    _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
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
        l10n.renameGalaxy,
        style: FontScaling.getHeadingMedium(context).copyWith(
          color: Color(0xFFFFE135),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SemanticHelper.label(
            label: l10n.galaxyNameField,
            hint: l10n.enterNewGalaxyName,
            child: TextField(
              controller: _controller,
              style: FontScaling.getBodyMedium(context).copyWith(
                color: Colors.white,
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFFE135)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFFE135).withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFFE135)),
                ),
              ),
              autofocus: true,
              maxLength: 50,
              enabled: !_isRenaming,
            ),
          ),
        ],
      ),
      actions: [
        // Delete button on the left
        TextButton(
          onPressed: _isRenaming ? null : () => _confirmDelete(context),
          child: Text(
            l10n.deleteButton,
            style: FontScaling.getButtonText(context).copyWith(
              color: Colors.red.withValues(alpha: 0.8),
            ),
          ),
        ),
        Spacer(),
        TextButton(
          onPressed: _isRenaming ? null : () => Navigator.of(context).pop(),
          child: Text(
            l10n.cancel,
            style: FontScaling.getButtonText(context).copyWith(
              color: Colors.white70,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isRenaming ? null : _renameGalaxy,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFFE135),
            foregroundColor: Color(0xFF1A2238),
          ),
          child: _isRenaming
              ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A2238)),
            ),
          )
              : Text(l10n.save),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Color(0xFF1A2238),
        title: Text(
          l10n.deleteGalaxy,
          style: FontScaling.getHeadingMedium(context).copyWith(
            color: Colors.red,
          ),
        ),
        content: Text(
          l10n.deleteGalaxyConfirmation(widget.galaxy.name, widget.galaxy.starCount),
          style: FontScaling.getBodyMedium(context).copyWith(
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              l10n.cancel,
              style: FontScaling.getButtonText(context).copyWith(
                color: Colors.white70,
              ),
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
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGalaxy() async {
    setState(() => _isRenaming = true); // Reuse loading state

    final l10n = AppLocalizations.of(context)!;
    final textStyle = FontScaling.getBodyMedium(context);

    try {
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final galaxyProvider = Provider.of<GalaxyProvider>(context, listen: false);

      await galaxyProvider.deleteGalaxy(widget.galaxy.id);

      if (navigator.mounted) {
        navigator.pop(); // Close rename dialog
        navigator.pop(); // Close galaxy list dialog

        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.galaxyDeletedSuccess(widget.galaxy.name), style: textStyle),
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
          content: Text(l10n.galaxyDeleteFailed(error.userMessage), style: textStyle),
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
      final galaxyProvider = Provider.of<GalaxyProvider>(context, listen: false);

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
        l10n: l10n,  // Use captured value
      );

      // Safe fallback — do NOT use Navigator.of(context) here
      final messenger = mounted ? ScaffoldMessenger.of(context) : null;

      messenger?.showSnackBar(
        SnackBar(
          content: Text(l10n.galaxyRenameFailed(error.userMessage), style: textStyle),
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