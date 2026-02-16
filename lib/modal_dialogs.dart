import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'core/accessibility/semantic_helper.dart';
import 'core/config/palette_preset_config.dart';
import 'core/theme/app_theme.dart';
import 'font_scaling.dart';
import 'gratitude_stars.dart';
import 'l10n/app_localizations.dart';
import 'l10n/app_localizations_extensions.dart';
import 'storage.dart';
import 'widgets/app_dialog.dart';
import 'widgets/edit_star_dialog.dart';
import 'widgets/color_picker_dialog.dart';
import 'widgets/color_grid.dart';
import 'widgets/scrollable_dialog_content.dart';

/// Centralized dialogs for GratiStellar app
/// All modal dialogs are static methods that accept callbacks for actions
class GratitudeDialogs {
  // ========================================
  // SIMPLE DIALOGS
  // ========================================

  static void showComingSoon(BuildContext context, String feature) {
    final l10n = AppLocalizations.of(context)!;
    AppDialog.showInfo(
      context: context,
      title: feature,
      message: l10n.comingSoonTitle,
      icon: Icons.info_outline,
      buttonText: l10n.okButton,
    );
  }

  static void showQuitConfirmation(BuildContext context) {
    AppDialog.showConfirmation(
      context: context,
      title: AppLocalizations.of(context)!.exitTitle,
      message: AppLocalizations.of(context)!.exitMessage,
      icon: Icons.logout,
      confirmText: AppLocalizations.of(context)!.exitButton,
      cancelText: AppLocalizations.of(context)!.cancelButton,
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed == true) {
        SystemNavigator.pop();
      }
    });
  }

  static Future<bool?> showSignOutConfirmation({
    required BuildContext context,
    required VoidCallback onConfirm,
    bool isAnonymous = false,
  }) {
    if (isAnonymous) {
      // Show dialog with options for anonymous users
      return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          final l10n = AppLocalizations.of(context)!;
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(maxWidth: 500, minWidth: 300),
              padding: EdgeInsets.all(
                FontScaling.getResponsiveSpacing(context, 24),
              ),
              decoration: BoxDecoration(
                color: AppTheme.getDialogBackground(opacity: 0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.borderSubtle,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.logout,
                    color: AppTheme.error.withValues(alpha: 0.8),
                    size: FontScaling.getResponsiveIconSize(context, 48),
                  ),
                  SizedBox(
                    height: FontScaling.getResponsiveSpacing(context, 16),
                  ),
                  Text(
                    l10n.signOutTitle,
                    style: FontScaling.getHeadingMedium(
                      context,
                    ).copyWith(color: AppTheme.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: FontScaling.getResponsiveSpacing(context, 12),
                  ),
                  Text(
                    l10n.signOutKeepDataQuestion,
                    style: FontScaling.getBodySmall(
                      context,
                    ).copyWith(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: FontScaling.getResponsiveSpacing(context, 12),
                  ),
                  // Warning message for clear data option
                  SemanticHelper.label(
                    label: l10n.signOutClearDataWarning,
                    hint: 'Warning about permanent data deletion',
                    child: Container(
                      padding: EdgeInsets.all(
                        FontScaling.getResponsiveSpacing(context, 12),
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppTheme.error.withValues(alpha: 0.8),
                            size: FontScaling.getResponsiveIconSize(
                              context,
                              20,
                            ),
                            semanticLabel: 'Warning icon',
                          ),
                          SizedBox(
                            width: FontScaling.getResponsiveSpacing(context, 8),
                          ),
                          Expanded(
                            child: Text(
                              l10n.signOutClearDataWarning,
                              style: FontScaling.getBodySmall(context).copyWith(
                                color: AppTheme.error.withValues(alpha: 0.9),
                                fontWeight: FontScaling.normalWeight,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: FontScaling.getResponsiveSpacing(context, 24),
                  ),
                  // Sign Out and Keep Data button
                  SizedBox(
                    width: double.infinity,
                    child: SemanticHelper.label(
                      label: l10n.signOutKeepDataButton,
                      hint: 'Sign out while keeping your local data',
                      isButton: true,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, true); // true = keep data
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: EdgeInsets.symmetric(
                            vertical: FontScaling.getResponsiveSpacing(
                              context,
                              16,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          l10n.signOutKeepDataButton,
                          style: FontScaling.getButtonText(
                            context,
                          ).copyWith(color: AppTheme.textOnLight),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: FontScaling.getResponsiveSpacing(context, 12),
                  ),
                  // Sign Out and Clear Data button
                  SizedBox(
                    width: double.infinity,
                    child: SemanticHelper.label(
                      label: l10n.signOutClearDataButton,
                      hint: 'Sign out and delete all local data',
                      isButton: true,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context, false); // false = clear data
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: BorderSide(color: AppTheme.error, width: 2),
                          padding: EdgeInsets.symmetric(
                            vertical: FontScaling.getResponsiveSpacing(
                              context,
                              16,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          l10n.signOutClearDataButton,
                          style: FontScaling.getButtonText(
                            context,
                          ).copyWith(color: AppTheme.error),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: FontScaling.getResponsiveSpacing(context, 12),
                  ),
                  // Cancel button
                  SemanticHelper.label(
                    label: l10n.cancelButton,
                    hint: 'Cancel sign out',
                    isButton: true,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: Text(
                        l10n.cancelButton,
                        style: FontScaling.getBodySmall(
                          context,
                        ).copyWith(color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // Standard confirmation for email users - always clear local data
      return AppDialog.showConfirmation(
        context: context,
        title: AppLocalizations.of(context)!.signOutTitle,
        message: AppLocalizations.of(context)!.signOutEmailMessage,
        icon: Icons.logout,
        iconColor: AppTheme.error.withValues(alpha: 0.8),
        confirmText: AppLocalizations.of(context)!.signOutButton,
        cancelText: AppLocalizations.of(context)!.cancelButton,
        isDestructive: true,
      ).then((confirmed) {
        if (confirmed == true) {
          onConfirm();
        }
        return confirmed;
      });
    }
  }

  static void showMindfulnessNoStars(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, minWidth: 400),
            padding: EdgeInsets.all(
              FontScaling.getResponsiveSpacing(context, 24),
            ),
            decoration: BoxDecoration(
              color: AppTheme.getDialogBackground(opacity: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.borderSubtle,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.self_improvement,
                  color: AppTheme.primary,
                  size: FontScaling.getResponsiveIconSize(context, 48),
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                Text(
                  AppLocalizations.of(context)!.mindfulnessNoStarsTitle,
                  style: FontScaling.getModalTitle(context),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
                Text(
                  AppLocalizations.of(context)!.mindfulnessNoStarsMessage,
                  style: FontScaling.getBodyMedium(
                    context,
                  ).copyWith(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppLocalizations.of(context)!.closeButton,
                    style: FontScaling.getButtonText(
                      context,
                    ).copyWith(color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showDeleteConfirmation({
    required BuildContext context,
    required BuildContext modalContext,
    required GratitudeStar star,
    required Function(GratitudeStar) onDelete,
    VoidCallback? onAfterDelete,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, minWidth: 400),
            padding: EdgeInsets.all(
              FontScaling.getResponsiveSpacing(context, 24),
            ),
            decoration: BoxDecoration(
              color: AppTheme.getDialogBackground(opacity: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.error.withValues(alpha: 0.5),
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
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.error,
                    size: FontScaling.getResponsiveIconSize(context, 48),
                  ),
                  SizedBox(
                    height: FontScaling.getResponsiveSpacing(context, 16),
                  ),
                  Text(
                    AppLocalizations.of(context)!.deleteConfirmTitle,
                    style: FontScaling.getModalTitle(
                      context,
                    ).copyWith(color: AppTheme.error),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: FontScaling.getResponsiveSpacing(context, 12),
                  ),
                  Container(
                    padding: EdgeInsets.all(
                      FontScaling.getResponsiveSpacing(context, 12),
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.textPrimary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '"${star.text}"',
                      style: FontScaling.getBodySmall(context).copyWith(
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    height: FontScaling.getResponsiveSpacing(context, 12),
                  ),
                  Text(
                    AppLocalizations.of(context)!.deleteWarning,
                    style: FontScaling.getBodySmall(
                      context,
                    ).copyWith(color: AppTheme.error.withValues(alpha: 0.7)),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: FontScaling.getResponsiveSpacing(context, 20),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            AppLocalizations.of(context)!.cancelButton,
                            style: FontScaling.getButtonText(context).copyWith(
                              color: AppTheme.textTertiary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Flexible(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            onDelete(star);
                            Navigator.of(context).pop(); // Close confirmation
                            Navigator.of(modalContext).pop(); // Close edit modal

                            // Trigger refresh callback
                            onAfterDelete?.call();
                          },
                          icon: Icon(
                            Icons.close,
                            size: FontScaling.getResponsiveIconSize(context, 18),
                          ),
                          label: Text(
                            AppLocalizations.of(context)!.deleteButton,
                            style: FontScaling.getButtonText(context),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error,
                            foregroundColor: AppTheme.textPrimary,
                          padding: EdgeInsets.symmetric(
                            horizontal: FontScaling.getResponsiveSpacing(
                              context,
                              20,
                            ),
                            vertical: FontScaling.getResponsiveSpacing(
                              context,
                              12,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ========================================
  // HELPER WIDGETS
  // ========================================

  /// Helper widget to manage ScrollController for dialog scrollbar
  static Widget _buildScrollableDialogContent({required Widget child}) {
    return ScrollableDialogContent(child: child);
  }

  /// Helper widget to build tags section for create/edit dialogs
  static Widget _buildTagsSection({
    required BuildContext context,
    required List<String> editingTags,
    required TextEditingController tagController,
    required List<GratitudeStar> allStars,
    required int maxTags,
    required int maxTagLength,
    required Function(List<String>) onTagsChanged,
  }) {
    final l10n = AppLocalizations.of(context)!;

    // Get all unique tags from all stars for autocomplete
    final allTags = <String>{};
    for (final star in allStars) {
      allTags.addAll(star.tags);
    }
    // Remove tags already on this star
    allTags.removeAll(editingTags);
    final availableTags = allTags.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    void addTag(String tag) {
      final trimmedTag = tag.trim();
      if (trimmedTag.isEmpty) return;
      if (trimmedTag.length > maxTagLength) return;
      if (editingTags.length >= maxTags) return;

      // Case-insensitive deduplication
      final lowerTag = trimmedTag.toLowerCase();
      if (editingTags.any((t) => t.toLowerCase() == lowerTag)) return;

      final newTags = List<String>.from(editingTags)..add(trimmedTag);
      onTagsChanged(newTags);
      tagController.clear();
    }

    void removeTag(String tag) {
      final newTags = List<String>.from(editingTags)..remove(tag);
      onTagsChanged(newTags);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tags label
        Padding(
          padding: EdgeInsets.only(
            bottom: FontScaling.getResponsiveSpacing(context, 8),
          ),
          child: Text(
            l10n.tagsLabel,
            style: FontScaling.getBodySmall(context).copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),

        // Current tags as chips
        if (editingTags.isNotEmpty) ...[
          Semantics(
            label: l10n.currentTagsLabel(editingTags.join(", ")),
            child: Wrap(
              spacing: FontScaling.getResponsiveSpacing(context, 8),
              runSpacing: FontScaling.getResponsiveSpacing(context, 8),
              children: editingTags.map((tag) {
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
                    onDeleted: () => removeTag(tag),
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
        if (editingTags.length < maxTags)
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return availableTags.take(5);
              }
              final query = textEditingValue.text.toLowerCase();
              return availableTags
                  .where((tag) => tag.toLowerCase().contains(query))
                  .take(5);
            },
            onSelected: (String selection) {
              addTag(selection);
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
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
                          addTag(controller.text);
                          controller.clear();
                        },
                      ),
                    ),
                  ),
                  onSubmitted: (value) {
                    addTag(value);
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
                          label: AppLocalizations.of(context)!
                              .suggestedTagLabel(option),
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

  static Future<void> showAddGratitude({
    required BuildContext context,
    required TextEditingController controller,
    required Function([int? colorIndex, Color? customColor, String? inspirationPrompt, List<String>? tags]) onAdd,
    required bool isAnimating,
    List<GratitudeStar>? allStars,
  }) async {
    if (isAnimating) return;

    const int maxCharacters = 300; // Set character limit

    // Load default color preference
    final defaultColor = await StorageService.getDefaultColor();

    // Load selected palette preset for the colour grid
    final selectedPresetId = await StorageService.getSelectedPalettePreset();
    final selectedPreset = PalettePresetConfig.getPresetById(selectedPresetId);

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext context) {
        // Initialize based on default color preference
        bool showColorPicker =
            defaultColor != null; // Auto-expand if default set
        int? selectedColorIndex = defaultColor?.$1; // Preset index or null
        Color? customColorPreview = defaultColor?.$2; // Custom color or null
        bool setAsDefault = false; // Checkbox state
        // Initialize paletteColors as a state variable
        List<Color> paletteColors =
            selectedPreset?.colors ?? StarColors.palette;
        // Cache the current prompt to prevent regeneration on rebuilds
        String currentPrompt = AppLocalizations.of(context)!.defaultCreateStarHint;
        // Tags state
        List<String> editingTags = [];
        final tagController = TextEditingController();
        const int maxTags = 20;
        const int maxTagLength = 30;

        return StatefulBuilder(
          builder: (context, setState) {
            final remainingChars = maxCharacters - controller.text.length;
            final isOverLimit = remainingChars < 0;

            // Function to reload palette from storage
            Future<void> reloadPalette() async {
              final updatedPresetId =
                  await StorageService.getSelectedPalettePreset();
              final updatedPreset = PalettePresetConfig.getPresetById(
                updatedPresetId,
              );
              final updatedPaletteColors =
                  updatedPreset?.colors ?? StarColors.palette;
              if (context.mounted) {
                setState(() {
                  paletteColors = updatedPaletteColors;
                });
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500, minWidth: 400),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.getDialogBackground(opacity: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isOverLimit
                          ? AppTheme.error
                          : AppTheme.borderSubtle,
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
                  child: Padding(
                    padding: EdgeInsets.all(
                      FontScaling.getResponsiveSpacing(context, 20),
                    ),
                    child: _buildScrollableDialogContent(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.createStarModalTitle,
                            style: FontScaling.getModalTitle(context),
                          ),
                          SizedBox(
                            height: FontScaling.getResponsiveSpacing(
                              context,
                              16,
                            ),
                          ),

                          // Scrollable text field with character counter
                          Scrollbar(
                            child: TextField(
                              controller: controller,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              autofocus: true,
                              maxLength: maxCharacters,
                              minLines: 3,
                              maxLines: 5,
                              keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  hintText: currentPrompt,
                                  hintStyle: FontScaling.getInputHint(context),
                                  filled: true,
                                  fillColor: AppTheme.textPrimary.withValues(
                                    alpha: 0.1,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: AppTheme.borderSubtle,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: AppTheme.borderSubtle,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: AppTheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  counterStyle: FontScaling.getCaption(context)
                                      .copyWith(
                                        color: isOverLimit
                                            ? AppTheme.error
                                            : AppTheme.textTertiary,
                                      ),
                                ),
                                style: FontScaling.getInputText(context),
                                onChanged: (value) {
                                  setState(
                                    () {},
                                  ); // Rebuild to update counter color
                                },
                                onSubmitted: (value) {
                                  // Submit star when user presses Done/Enter (hard return)
                                  if (!isOverLimit && value.trim().isNotEmpty) {
                                    // Save default if checkbox is checked
                                    if (setAsDefault) {
                                      if (customColorPreview != null) {
                                        StorageService.saveDefaultCustomColor(
                                          customColorPreview!,
                                        );
                                      } else if (selectedColorIndex != null) {
                                        StorageService.saveDefaultPresetColor(
                                          selectedColorIndex!,
                                        );
                                      }
                                    }

                                    // Create the star
                                    if (showColorPicker &&
                                        selectedColorIndex != null) {
                                      // Map palette colour to StarColors.palette index if it exists, otherwise use as custom
                                      final selectedColour =
                                          selectedColorIndex! <
                                              paletteColors.length
                                          ? paletteColors[selectedColorIndex!]
                                          : paletteColors[0];
                                      final starColorsIndex = StarColors.palette
                                          .indexOf(selectedColour);
                                      if (starColorsIndex >= 0) {
                                        onAdd(starColorsIndex, null, currentPrompt, editingTags.isNotEmpty ? editingTags : null);
                                      } else {
                                        onAdd(null, selectedColour, currentPrompt, editingTags.isNotEmpty ? editingTags : null);
                                      }
                                    } else {
                                      onAdd(null, null, currentPrompt, editingTags.isNotEmpty ? editingTags : null); // Random colour
                                    }
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  }
                                },
                              ),
                            ),

                          // Shuffle prompt button - centered under text field
                          Padding(
                            padding: EdgeInsets.only(
                              top: FontScaling.getResponsiveSpacing(context, 4),
                            ),
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  currentPrompt = AppLocalizations.of(context)!.getRandomCreateStarHint();
                                });
                              },
                              icon: Icon(
                                Icons.shuffle,
                                size: FontScaling.getResponsiveIconSize(context, 16),
                                color: AppTheme.textSecondary,
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.shufflePromptTooltip,
                                style: FontScaling.getCaption(context).copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: FontScaling.getResponsiveSpacing(context, 8),
                                  vertical: FontScaling.getResponsiveSpacing(context, 4),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                            height: FontScaling.getResponsiveSpacing(
                              context,
                              8,
                            ),
                          ),

                          // Optional color selection (collapsed by default)
                          Column(
                            children: [
                              // Toggle button - Made more prominent with palette indicator
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.textPrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.borderNormal,
                                    width: 1.5,
                                  ),
                                ),
                                child: TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      showColorPicker = !showColorPicker;
                                      // Set default color when opening
                                      if (showColorPicker &&
                                          selectedColorIndex == null) {
                                        selectedColorIndex = 0;
                                      }
                                    });
                                  },
                                  icon: Icon(
                                    showColorPicker
                                        ? Icons.expand_less
                                        : Icons.palette,
                                    size: FontScaling.getResponsiveIconSize(
                                      context,
                                      24,
                                    ),
                                    color: AppTheme.primary,
                                  ),
                                  label: Text(
                                    showColorPicker
                                        ? AppLocalizations.of(
                                            context,
                                          )!.useRandomColor
                                        : '${AppLocalizations.of(context)!.chooseColorButton} (Palette Options)',
                                    style: FontScaling.getButtonText(context)
                                        .copyWith(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontScaling.mediumWeight,
                                        ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          FontScaling.getResponsiveSpacing(
                                            context,
                                            16,
                                          ),
                                      vertical:
                                          FontScaling.getResponsiveSpacing(
                                            context,
                                            12,
                                          ),
                                    ),
                                  ),
                                ),
                              ),

                              // Expandable color picker
                              if (showColorPicker) ...[
                                SizedBox(
                                  height: FontScaling.getResponsiveSpacing(
                                    context,
                                    12,
                                  ),
                                ),

                                // Star preview
                                Container(
                                  padding: EdgeInsets.all(
                                    FontScaling.getResponsiveSpacing(
                                      context,
                                      12,
                                    ),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/icon_star.svg',
                                    width: FontScaling.getResponsiveIconSize(
                                      context,
                                      40,
                                    ),
                                    height: FontScaling.getResponsiveIconSize(
                                      context,
                                      40,
                                    ),
                                    colorFilter: ColorFilter.mode(
                                      customColorPreview ??
                                          (selectedColorIndex != null &&
                                                  selectedColorIndex! <
                                                      paletteColors.length
                                              ? paletteColors[selectedColorIndex!]
                                              : paletteColors[0]),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: FontScaling.getResponsiveSpacing(
                                    context,
                                    12,
                                  ),
                                ),

                                ColorGrid(
                                  // Use the selected palette preset colours
                                  colors: paletteColors,
                                  selectedIndex: customColorPreview != null
                                      ? -1
                                      : (selectedColorIndex ?? 0),
                                  onColorTap: (index) {
                                    setState(() {
                                      selectedColorIndex = index;
                                      customColorPreview = null;
                                    });
                                  },
                                ),

                                SizedBox(
                                  height: FontScaling.getResponsiveSpacing(
                                    context,
                                    8,
                                  ),
                                ),

                                // Custom color button
                                TextButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      barrierColor: Colors.black.withValues(
                                        alpha: 0.7,
                                      ),
                                      builder: (BuildContext dialogContext) {
                                        return ColorPickerDialog(
                                          initialColorIndex: selectedColorIndex,
                                          initialCustomColor:
                                              customColorPreview,
                                          onColorSelected:
                                              (colorIndex, customColor) {
                                                setState(() {
                                                  if (colorIndex != null) {
                                                    selectedColorIndex =
                                                        colorIndex;
                                                    customColorPreview = null;
                                                  } else if (customColor !=
                                                      null) {
                                                    customColorPreview =
                                                        customColor;
                                                    selectedColorIndex = null;
                                                  }
                                                });
                                              },
                                        );
                                      },
                                    ).then((_) {
                                      // Reload palette when ColorPickerDialog closes
                                      reloadPalette();
                                    });
                                  },
                                  icon: Icon(
                                    Icons.color_lens,
                                    size: FontScaling.getResponsiveIconSize(
                                      context,
                                      18,
                                    ),
                                  ),
                                  label: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.customColorButton,
                                    style: FontScaling.getButtonText(context)
                                        .copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                  ),
                                ),

                                SizedBox(
                                  height: FontScaling.getResponsiveSpacing(
                                    context,
                                    12,
                                  ),
                                ),

                                // Set as default checkbox
                                CheckboxListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  value: setAsDefault,
                                  onChanged: (value) {
                                    setState(() {
                                      setAsDefault = value ?? false;
                                    });
                                  },
                                  title: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.setAsDefaultColor,
                                    style: FontScaling.getBodySmall(context)
                                        .copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  activeColor: AppTheme.primary,
                                  checkColor: AppTheme.textOnLight,
                                ),
                              ],
                            ],
                          ),

                          SizedBox(
                            height: FontScaling.getResponsiveSpacing(
                              context,
                              16,
                            ),
                          ),

                          // Tags section
                          _buildTagsSection(
                            context: context,
                            editingTags: editingTags,
                            tagController: tagController,
                            allStars: allStars ?? [],
                            maxTags: maxTags,
                            maxTagLength: maxTagLength,
                            onTagsChanged: (newTags) {
                              setState(() {
                                editingTags = newTags;
                              });
                            },
                          ),

                          SizedBox(
                            height: FontScaling.getResponsiveSpacing(
                              context,
                              16,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () {
                                  controller.clear();
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  AppLocalizations.of(context)!.cancelButton,
                                  style: FontScaling.getButtonText(context)
                                      .copyWith(
                                        color: AppTheme.textTertiary,
                                      ),
                                ),
                              ),
                              SizedBox(
                                width: FontScaling.getResponsiveSpacing(
                                  context,
                                  12,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: isOverLimit
                                    ? null
                                    : () async {
                                        // Save default if checkbox is checked
                                        if (setAsDefault) {
                                          if (customColorPreview != null) {
                                            await StorageService.saveDefaultCustomColor(
                                              customColorPreview!,
                                            );
                                          } else if (selectedColorIndex !=
                                              null) {
                                            await StorageService.saveDefaultPresetColor(
                                              selectedColorIndex!,
                                            );
                                          }
                                        }

                                        // Create the star
                                        if (showColorPicker &&
                                            selectedColorIndex != null) {
                                          onAdd(
                                            selectedColorIndex,
                                            customColorPreview,
                                            currentPrompt,
                                            editingTags.isNotEmpty ? editingTags : null,
                                          );
                                        } else {
                                          onAdd(null, null, currentPrompt, editingTags.isNotEmpty ? editingTags : null); // Random color
                                        }
                                        if (context.mounted) {
                                          Navigator.of(context).pop();
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  disabledBackgroundColor: Colors.grey,
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        FontScaling.getResponsiveSpacing(
                                          context,
                                          24,
                                        ),
                                    vertical: FontScaling.getResponsiveSpacing(
                                      context,
                                      12,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.createStarButton,
                                  style: FontScaling.getButtonText(
                                    context,
                                  ).copyWith(color: AppTheme.textOnLight),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ========================================
  // STAR EDIT DIALOG (Unified Implementation)
  // ========================================

  /// Shows a dialog to view and edit a gratitude star.
  ///
  /// This is the single source of truth for star editing - used by both
  /// tap-to-edit and list view. The dialog manages its own state and controllers.
  ///
  /// [star] - The star to display/edit
  /// [allStars] - Full list for ID lookup (handles updates during editing)
  /// [onSave] - Called when user saves changes
  /// [onDelete] - Called when user deletes the star
  /// [onShare] - Called when user shares the star
  /// [onJumpToStar] - Optional callback to jump to star (shows button if provided)
  static void showEditStar({
    required BuildContext context,
    required GratitudeStar star,
    required List<GratitudeStar> allStars,
    required Function(GratitudeStar) onSave,
    required Function(GratitudeStar) onDelete,
    required Function(GratitudeStar) onShare,
    VoidCallback? onJumpToStar,
    VoidCallback? onAfterSave,
    VoidCallback? onAfterDelete,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext dialogContext) {
        return EditStarDialog(
          star: star,
          allStars: allStars,
          onSave: onSave,
          onDelete: onDelete,
          onShare: onShare,
          onJumpToStar: onJumpToStar,
          onAfterSave: onAfterSave,
          onAfterDelete: onAfterDelete,
        );
      },
    ).then((result) {
      // If dialog closed with 'saved' result, trigger refresh
      if (result == 'saved') {
        onAfterSave?.call();
      }
    });
  }

  static Widget buildModalIconButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppTheme.primary,
              size: FontScaling.getResponsiveIconSize(context, 28),
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 4)),
            Text(
              label,
              style: FontScaling.getCaption(
                context,
              ).copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper StatefulWidget to manage ScrollController for dialog scrollbar
