import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'font_scaling.dart';
import 'gratitude_stars.dart';
import 'l10n/app_localizations.dart';
import 'storage.dart';
import 'widgets/app_dialog.dart';
import 'widgets/edit_star_dialog.dart';
import 'widgets/color_picker_dialog.dart';
import 'widgets/color_grid.dart'; // <--- ADD THIS LINE

/// Centralized dialogs for GratiStellar app
/// All modal dialogs are static methods that accept callbacks for actions
class GratitudeDialogs {

  // ========================================
  // SIMPLE DIALOGS
  // ========================================

  static void showComingSoon(BuildContext context, String feature) {
    AppDialog.showInfo(
      context: context,
      title: feature,
      message: AppLocalizations.of(context)!.comingSoonTitle,
      icon: Icons.info_outline,
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

  static void showMindfulnessNoStars(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha:0.7),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, minWidth: 400),
            padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 24)),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2238).withValues(alpha:0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFFFE135).withValues(alpha:0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.5),
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
                  color: const Color(0xFFFFE135),
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
                  style: FontScaling.getBodyMedium(context).copyWith(
                    color: Colors.white.withValues(alpha:0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppLocalizations.of(context)!.closeButton,
                    style: FontScaling.getButtonText(context).copyWith(
                      color: const Color(0xFFFFE135),
                    ),
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
      barrierColor: Colors.black.withValues(alpha:0.7),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, minWidth: 400),
            padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 24)),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2238).withValues(alpha:0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.red.withValues(alpha:0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: FontScaling.getResponsiveIconSize(context, 48),
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                Text(
                  AppLocalizations.of(context)!.deleteConfirmTitle,
                  style: FontScaling.getModalTitle(context).copyWith(
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
                Container(
                  padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 12)),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '"${star.text}"',
                    style: FontScaling.getBodySmall(context).copyWith(
                      color: Colors.white.withValues(alpha:0.7),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
                Text(
                  AppLocalizations.of(context)!.deleteWarning,
                  style: FontScaling.getBodySmall(context).copyWith(
                    color: Colors.red.withValues(alpha:0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 20)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        AppLocalizations.of(context)!.cancelButton,
                        style: FontScaling.getButtonText(context).copyWith(
                          color: Colors.white.withValues(alpha:0.6),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        onDelete(star);
                        Navigator.of(context).pop(); // Close confirmation
                        Navigator.of(modalContext).pop(); // Close edit modal

                        // Trigger refresh callback
                        onAfterDelete?.call();
                      },
                      icon: Icon(Icons.close, size: FontScaling.getResponsiveIconSize(context, 18)),
                      label: Text(
                        AppLocalizations.of(context)!.deleteButton,
                        style: FontScaling.getButtonText(context),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: FontScaling.getResponsiveSpacing(context, 20),
                          vertical: FontScaling.getResponsiveSpacing(context, 12),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  /// Internal helper to show color picker dialog (now delegates to ColorPickerDialog widget)
  static void _showColorPickerDialog({
    required BuildContext context,
    required GratitudeStar currentStar,
    required Function(int?, Color?) onColorSelected,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha:0.7),
      builder: (BuildContext dialogContext) {
        return ColorPickerDialog(
          currentStar: currentStar,
          onColorSelected: onColorSelected,
        );
      },
    );
  }

  // ========================================
  // HELPER WIDGETS
  // ========================================

  static void showAddGratitude({
    required BuildContext context,
    required TextEditingController controller,
    required Function([int? colorIndex, Color? customColor]) onAdd,
    required bool isAnimating,
  }) {
    if (isAnimating) return;

    const int maxCharacters = 300; // Set character limit

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha:0.7),
      builder: (BuildContext context) {
        bool showColorPicker = false; // Collapsed by default
        int? selectedColorIndex; // null = use random
        Color? customColorPreview;

        return StatefulBuilder(
          builder: (context, setState) {
            final remainingChars = maxCharacters - controller.text.length;
            final isOverLimit = remainingChars < 0;

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500, minWidth: 400),
                padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 20)),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2238).withValues(alpha:0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isOverLimit
                        ? Colors.red
                        : const Color(0xFFFFE135).withValues(alpha:0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.createStarModalTitle,
                      style: FontScaling.getModalTitle(context),
                    ),
                    SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),

                    // Scrollable text field with character counter
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: Scrollbar(
                        child: TextField(
                          controller: controller,
                          textCapitalization: TextCapitalization.sentences,
                          autofocus: true,
                          focusNode: FocusNode(),
                          maxLength: maxCharacters,
                          maxLines: null, // Allow unlimited lines
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.createStarHint,
                            hintStyle: FontScaling.getInputHint(context),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha:0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: const Color(0xFFFFE135).withValues(alpha:0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: const Color(0xFFFFE135).withValues(alpha:0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFFFE135),
                                width: 2,
                              ),
                            ),
                            counterStyle: FontScaling.getCaption(context).copyWith(
                              color: isOverLimit
                                  ? Colors.red
                                  : Colors.white.withValues(alpha:0.6),
                            ),
                          ),
                          style: FontScaling.getInputText(context),
                          onChanged: (value) {
                            setState(() {}); // Rebuild to update counter color
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),

                    // Optional color selection (collapsed by default)
                    Column(
                      children: [
                        // Toggle button
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              showColorPicker = !showColorPicker;
                              // Set default color when opening
                              if (showColorPicker && selectedColorIndex == null) {
                                selectedColorIndex = 0;
                              }
                            });
                          },
                          icon: Icon(
                            showColorPicker ? Icons.expand_less : Icons.palette,
                            size: FontScaling.getResponsiveIconSize(context, 20),
                          ),
                          label: Text(
                            showColorPicker
                                ? AppLocalizations.of(context)!.useRandomColor
                                : AppLocalizations.of(context)!.chooseColorButton,
                            style: FontScaling.getButtonText(context).copyWith(
                              color: const Color(0xFFFFE135),
                            ),
                          ),
                        ),

                        // Expandable color picker
                        if (showColorPicker) ...[
                          SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),

                          // Star preview
                          Container(
                            padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 12)),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha:0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SvgPicture.asset(
                              'assets/icon_star.svg',
                              width: FontScaling.getResponsiveIconSize(context, 40),
                              height: FontScaling.getResponsiveIconSize(context, 40),
                              colorFilter: ColorFilter.mode(
                                customColorPreview ?? StarColors.getColor(selectedColorIndex ?? 0),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),

                          ColorGrid( // Use the new ColorGrid widget
                            selectedIndex: customColorPreview != null ? -1 : (selectedColorIndex ?? 0),
                            onColorTap: (index) {
                              setState(() {
                                selectedColorIndex = index;
                                customColorPreview = null;
                              });
                            },
                          ),

                          SizedBox(height: FontScaling.getResponsiveSpacing(context, 8)),

                          // Custom color button
                          TextButton.icon(
                            onPressed: () {
                              _showColorPickerDialog(
                                context: context,
                                currentStar: GratitudeStar(
                                  text: '',
                                  worldX: 0.5,
                                  worldY: 0.5,
                                  colorPresetIndex: selectedColorIndex ?? 0,
                                  customColor: customColorPreview,
                                  spinDirection: 1.0,
                                  spinRate: 0.5,
                                  pulseSpeedH: 2.0,
                                  pulseSpeedV: 2.0,
                                  pulsePhaseH: 0.0,
                                  pulsePhaseV: 0.0,
                                  pulseMinScaleH: 0.0,
                                  pulseMinScaleV: 0.0,
                                ),
                                onColorSelected: (colorIndex, customColor) {
                                  setState(() {
                                    if (colorIndex != null) {
                                      selectedColorIndex = colorIndex;
                                      customColorPreview = null;
                                    } else if (customColor != null) {
                                      customColorPreview = customColor;
                                    }
                                  });
                                },
                              );
                            },
                            icon: Icon(Icons.color_lens, size: FontScaling.getResponsiveIconSize(context, 18)),
                            label: Text(
                              AppLocalizations.of(context)!.customColorButton,
                              style: FontScaling.getButtonText(context).copyWith(
                                color: Colors.white.withValues(alpha:0.7),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            controller.clear();
                            Navigator.of(context).pop();
                          },
                          focusNode: FocusNode(),
                          child: Text(
                            AppLocalizations.of(context)!.cancelButton,
                            style: FontScaling.getButtonText(context).copyWith(
                              color: Colors.white.withValues(alpha:0.6),
                            ),
                          ),
                        ),
                        SizedBox(width: FontScaling.getResponsiveSpacing(context, 12)),
                        ElevatedButton(
                          onPressed: isOverLimit ? null : () {
                            if (showColorPicker && selectedColorIndex != null) {
                              onAdd(selectedColorIndex, customColorPreview);
                            } else {
                              onAdd(); // Random color
                            }
                            Navigator.of(context).pop();
                          },
                          focusNode: FocusNode(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFE135),
                            disabledBackgroundColor: Colors.grey,
                            padding: EdgeInsets.symmetric(
                              horizontal: FontScaling.getResponsiveSpacing(context, 24),
                              vertical: FontScaling.getResponsiveSpacing(context, 12),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.createStarButton,
                            style: FontScaling.getButtonText(context).copyWith(
                              color: const Color(0xFF1A2238),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
      barrierColor: Colors.black.withValues(alpha:0.7),
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
              color: const Color(0xFFFFE135),
              size: FontScaling.getResponsiveIconSize(context, 28),
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 4)),
            Text(
              label,
              style: FontScaling.getCaption(context).copyWith(
                color: Colors.white.withValues(alpha:0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
