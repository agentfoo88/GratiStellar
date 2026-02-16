import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme/app_theme.dart';
import '../font_scaling.dart';
import '../l10n/app_localizations.dart';
import '../modal_dialogs.dart'; // For showDeleteConfirmation
import '../storage.dart'; // For GratitudeStar
import 'color_picker_dialog.dart';
import 'scrollable_dialog_content.dart';

class EditStarDialog extends StatefulWidget {
  final GratitudeStar star;
  final List<GratitudeStar> allStars;
  final Function(GratitudeStar) onSave;
  final Function(GratitudeStar) onDelete;
  final Function(GratitudeStar) onShare;
  final VoidCallback? onJumpToStar;
  final VoidCallback? onAfterSave;
  final VoidCallback? onAfterDelete;

  const EditStarDialog({
    super.key,
    required this.star,
    required this.allStars,
    required this.onSave,
    required this.onDelete,
    required this.onShare,
    this.onJumpToStar,
    this.onAfterSave,
    this.onAfterDelete,
  });

  @override
  State<EditStarDialog> createState() => _EditStarDialogState();
}

class _EditStarDialogState extends State<EditStarDialog> {
  // Dialog owns its state (not shared with parent widget)
  bool isEditMode = false;
  Color? tempColorPreview;
  int? tempColorIndexPreview;
  static const int maxCharacters = 300;
  static const int maxTags = 20;
  static const int maxTagLength = 30;

  // Tags editing state
  late List<String> _editingTags;
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _tagFocusNode = FocusNode();

  // Dialog owns its controllers (disposed when dialog closes)
  late final TextEditingController editTextController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    editTextController = TextEditingController(text: widget.star.text);
    _focusNode = FocusNode();
    _editingTags = List<String>.from(widget.star.tags);
  }

  @override
  void dispose() {
    editTextController.dispose();
    _focusNode.dispose();
    _tagController.dispose();
    _tagFocusNode.dispose();
    super.dispose();
  }

  // Get all unique tags from all stars for autocomplete
  List<String> _getAllUniqueTags() {
    final allTags = <String>{};
    for (final star in widget.allStars) {
      allTags.addAll(star.tags);
    }
    // Remove tags already on this star
    allTags.removeAll(_editingTags);
    return allTags.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isEmpty) return;
    if (trimmedTag.length > maxTagLength) return;
    if (_editingTags.length >= maxTags) return;

    // Case-insensitive deduplication
    final lowerTag = trimmedTag.toLowerCase();
    if (_editingTags.any((t) => t.toLowerCase() == lowerTag)) return;

    setState(() {
      _editingTags.add(trimmedTag);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _editingTags.remove(tag);
    });
  }

  Widget _buildTagsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final availableTags = _getAllUniqueTags();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tags label
        Padding(
          padding: EdgeInsets.only(bottom: FontScaling.getResponsiveSpacing(context, 8)),
          child: Text(
            l10n.tagsLabel,
            style: FontScaling.getBodySmall(context).copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),

        // Current tags as chips
        if (_editingTags.isNotEmpty) ...[
          Semantics(
            label: l10n.currentTagsLabel(_editingTags.join(", ")),
            child: Wrap(
              spacing: FontScaling.getResponsiveSpacing(context, 8),
              runSpacing: FontScaling.getResponsiveSpacing(context, 8),
              children: _editingTags.map((tag) {
                return Semantics(
                  label: l10n.tagRemoveHint(tag),
                  button: true,
                  child: Chip(
                    label: Text(
                      tag,
                      style: FontScaling.getBodySmall(context).copyWith(
                        color: AppTheme.textOnLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    deleteIcon: Icon(
                      Icons.close,
                      size: FontScaling.getResponsiveIconSize(context, 18),
                      color: AppTheme.textOnLight,
                    ),
                    onDeleted: () => _removeTag(tag),
                    backgroundColor: AppTheme.primary,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: FontScaling.getResponsiveSpacing(context, 4),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
        ],

        // Add tag input with autocomplete
        if (_editingTags.length < maxTags)
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return availableTags.take(5);
              }
              final query = textEditingValue.text.toLowerCase();
              return availableTags.where((tag) =>
                tag.toLowerCase().contains(query)
              ).take(5);
            },
            onSelected: (String selection) {
              _addTag(selection);
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              // Sync the controller
              _tagController.text = controller.text;
              return Semantics(
                label: l10n.tagInputLabel,
                textField: true,
                child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: FontScaling.getInputText(context),
                maxLength: maxTagLength,
                decoration: InputDecoration(
                  hintText: l10n.addTagHint,
                  hintStyle: FontScaling.getInputHint(context),
                  counterText: '',
                  filled: true,
                  fillColor: AppTheme.textPrimary.withValues(alpha: 0.1),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: FontScaling.getResponsiveSpacing(context, 12),
                    vertical: FontScaling.getResponsiveSpacing(context, 10),
                  ),
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
                    borderSide: BorderSide(color: AppTheme.borderFocused),
                  ),
                  suffixIcon: Semantics(
                    label: l10n.addTagLabel,
                    button: true,
                    child: IconButton(
                      icon: Icon(
                        Icons.add_circle,
                        size: FontScaling.getResponsiveIconSize(context, 24),
                        color: AppTheme.primary,
                      ),
                      tooltip: l10n.addTagHint,
                      onPressed: () {
                        _addTag(controller.text);
                        controller.clear();
                      },
                    ),
                  ),
                ),
                onSubmitted: (value) {
                  _addTag(value);
                  controller.clear();
                },
              ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8,
                  color: AppTheme.backgroundDark,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderSubtle),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: BoxConstraints(
                      maxHeight: 200,
                      maxWidth: 300,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return Semantics(
                          label: l10n.suggestedTagLabel(option),
                          button: true,
                          child: ListTile(
                            dense: true,
                            title: Text(
                              option,
                              style: FontScaling.getBodyMedium(context).copyWith(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            onTap: () => onSelected(option),
                            hoverColor: AppTheme.primary.withValues(alpha: 0.1),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          )
        else
          Text(
            l10n.tagLimitReached,
            style: FontScaling.getCaption(context).copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Look up current star by ID (handles updates from other sources)
    var currentStar = widget.allStars.firstWhere(
      (s) => s.id == widget.star.id,
      orElse: () => widget.star,
    );

    // Apply temporary color preview if exists
    if (tempColorPreview != null || tempColorIndexPreview != null) {
      if (tempColorIndexPreview != null) {
        currentStar = currentStar.copyWith(
          colorPresetIndex: tempColorIndexPreview,
          clearCustomColor: true,
        );
      } else {
        currentStar = currentStar.copyWith(
          customColor: tempColorPreview,
        );
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, minWidth: 400),
        padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 20)),
        decoration: BoxDecoration(
          color: AppTheme.backgroundDark.withValues(alpha:0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: currentStar.color.withValues(alpha:0.5),
            width: 2,
          ),
        ),
        child: ScrollableDialogContent(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Star icon preview
            SvgPicture.asset(
              'assets/icon_star.svg',
              width: FontScaling.getResponsiveIconSize(context, 48),
              height: FontScaling.getResponsiveIconSize(context, 48),
              colorFilter: ColorFilter.mode(currentStar.color, BlendMode.srcIn),
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),

            // Text display or edit mode
            if (!isEditMode)
              Text(
                currentStar.text,
                style: FontScaling.getBodyLarge(context).copyWith(
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              )
            else
            // Calculate remaining chars for counter and limit indicator
              Builder(
                  builder: (innerContext) { // Use Builder to get a new context for setState
                    final remainingChars = maxCharacters - editTextController.text.length;
                    final isOverLimit = remainingChars < 0;

                    return Scrollbar(
                      child: TextField(
                        controller: editTextController,
                        textCapitalization: TextCapitalization.sentences,
                        autofocus: true,
                        focusNode: _focusNode,
                        maxLength: maxCharacters,
                        minLines: 3,
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.editGratitudeHint,
                        hintStyle: FontScaling.getInputHint(context),
                        filled: true,
                        fillColor: AppTheme.textPrimary.withValues(alpha:0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isOverLimit // <--- UPDATED LOGIC
                                ? AppTheme.error
                                : AppTheme.borderSubtle,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder( // <--- ADDED FOR CONSISTENCY
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isOverLimit // <--- UPDATED LOGIC
                                ? AppTheme.error
                                : AppTheme.borderSubtle,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder( // <--- ADDED FOR CONSISTENCY
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isOverLimit // <--- UPDATED LOGIC
                                ? AppTheme.error
                                : AppTheme.borderFocused,
                            width: isOverLimit ? 2 : 2, // Keep width 2
                          ),
                        ),
                        counterStyle: FontScaling.getCaption(context).copyWith( // <--- ADDED COUNTER STYLE
                          color: isOverLimit
                              ? AppTheme.error
                              : AppTheme.textTertiary,
                        ),
                      ),
                      style: FontScaling.getInputText(context),
                        onChanged: (value) {
                          setState(() {}); // Rebuild to update counter and border color
                        },
                      ),
                    );
                  }
              ),

            SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),

            // Tags section (only in edit mode)
            if (isEditMode) ...[
              _buildTagsSection(context),
              SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
            ],

            // View mode buttons
            if (!isEditMode)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GratitudeDialogs.buildModalIconButton(
                        context: context,
                        icon: Icons.edit,
                        label: AppLocalizations.of(context)!.editButton,
                        onTap: () {
                          setState(() {
                            isEditMode = true;
                          });
                        },
                      ),
                      GratitudeDialogs.buildModalIconButton(
                        context: context,
                        icon: Icons.share,
                        label: AppLocalizations.of(context)!.shareButton,
                        onTap: () => widget.onShare(currentStar),
                      ),
                      GratitudeDialogs.buildModalIconButton(
                        context: context,
                        icon: Icons.close,
                        label: AppLocalizations.of(context)!.closeButton,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  // Jump button (only shown if callback provided)
                  if (widget.onJumpToStar != null) ...[
                    SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onJumpToStar?.call();
                      },
                      icon: Icon(Icons.my_location, size: FontScaling.getResponsiveIconSize(context, 20)),
                      label: Text(
                        AppLocalizations.of(context)!.jumpToStarButton,
                        style: FontScaling.getButtonText(context).copyWith(
                          color: AppTheme.textOnPrimary,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.textOnPrimary,
                        minimumSize: const Size(double.infinity, 48),
                        padding: EdgeInsets.symmetric(
                          horizontal: FontScaling.getResponsiveSpacing(context, 20),
                          vertical: FontScaling.getResponsiveSpacing(context, 12),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ],
              )
            else
            // Edit mode buttons
              Column(
                children: [
                  // Change color button
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierColor: Colors.black.withValues(alpha:0.7),
                        builder: (BuildContext dialogContext) {
                          return ColorPickerDialog.fromStar(
                            currentStar: currentStar,
                            onColorSelected: (colorIndex, customColor) {
                              setState(() {
                                tempColorIndexPreview = colorIndex;
                                tempColorPreview = customColor;
                              });
                            },
                          );
                        },
                      );
                    },
                    icon: Icon(Icons.palette, size: FontScaling.getResponsiveIconSize(context, 20)),
                    label: Text(
                      AppLocalizations.of(context)!.changeColorButton,
                      style: FontScaling.getButtonText(context),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.overlayLight,
                      foregroundColor: AppTheme.primary,
                      minimumSize: const Size(double.infinity, 48),
                      padding: EdgeInsets.symmetric(
                        horizontal: FontScaling.getResponsiveSpacing(context, 20),
                        vertical: FontScaling.getResponsiveSpacing(context, 12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),

                  // Delete, Cancel, Save row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          GratitudeDialogs.showDeleteConfirmation(
                            context: context,
                            modalContext: context, // Use current context for deletion confirmation
                            star: currentStar,
                            onDelete: widget.onDelete,
                            onAfterDelete: widget.onAfterDelete,
                          );
                        },
                        icon: Icon(Icons.close, size: FontScaling.getResponsiveIconSize(context, 18)),
                        label: Text(
                          AppLocalizations.of(context)!.deleteButton,
                          style: FontScaling.getButtonText(context),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: AppTheme.textPrimary,
                          padding: EdgeInsets.symmetric(
                            horizontal: FontScaling.getResponsiveSpacing(context, 16),
                            vertical: FontScaling.getResponsiveSpacing(context, 10),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                      ),
                      SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isEditMode = false;
                            editTextController.text = currentStar.text;
                            tempColorPreview = null;
                            tempColorIndexPreview = null;
                            _editingTags = List<String>.from(widget.star.tags);
                          });
                        },
                        child: Text(
                          AppLocalizations.of(context)!.cancelButton,
                          style: FontScaling.getButtonText(context).copyWith(
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ),
                      SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
                      ElevatedButton(
                        onPressed: editTextController.text.length > maxCharacters ? null : () {
                          // Build updated star with all changes
                          var updatedStar = currentStar.copyWith(
                            text: editTextController.text,
                            tags: _editingTags,
                          );

                          // Apply color changes if any
                          if (tempColorIndexPreview != null) {
                            updatedStar = updatedStar.copyWith(
                              colorPresetIndex: tempColorIndexPreview,
                              clearCustomColor: true,
                            );
                          } else if (tempColorPreview != null) {
                            updatedStar = updatedStar.copyWith(
                              customColor: tempColorPreview,
                            );
                          }

                          widget.onSave(updatedStar);
                          Navigator.of(context).pop('saved');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: EdgeInsets.symmetric(
                            horizontal: FontScaling.getResponsiveSpacing(context, 20),
                            vertical: FontScaling.getResponsiveSpacing(context, 12),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.saveButton,
                          style: FontScaling.getButtonText(context).copyWith(
                            color: AppTheme.textOnPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
