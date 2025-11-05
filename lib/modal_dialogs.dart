import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'core/security/input_validator.dart';
import 'font_scaling.dart';
import 'gratitude_stars.dart';
import 'l10n/app_localizations.dart';
import 'storage.dart';
import 'widgets/app_dialog.dart';

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
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxWidth: 500, minWidth: 400),
            padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 24)),
            decoration: BoxDecoration(
              color: Color(0xFF1A2238).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Color(0xFFFFE135).withValues(alpha: 0.3),
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
                  color: Color(0xFFFFE135),
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
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppLocalizations.of(context)!.closeButton,
                    style: FontScaling.getButtonText(context).copyWith(
                      color: Color(0xFFFFE135),
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
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxWidth: 500, minWidth: 400),
            padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 24)),
            decoration: BoxDecoration(
              color: Color(0xFF1A2238).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.5),
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
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '"${star.text}"',
                    style: FontScaling.getBodySmall(context).copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
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
                    color: Colors.red.withValues(alpha: 0.7),
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
                          color: Colors.white.withValues(alpha: 0.6),
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
  /// Internal helper to show color picker dialog
  static void _showColorPickerDialog({
    required BuildContext context,
    required GratitudeStar currentStar,
    required Function(int?, Color?) onColorSelected,
  }) {
    // Color picker owns its state
    Color previewColor = currentStar.color;
    int? selectedColorIndex = currentStar.customColor == null ? currentStar.colorPresetIndex : null;

    // Color picker owns its controllers
    final hexController = TextEditingController();
    final redController = TextEditingController();
    final greenController = TextEditingController();
    final blueController = TextEditingController();

    // Initialize controllers with current color
    final r = (currentStar.color.r * 255).round();
    final g = (currentStar.color.g * 255).round();
    final b = (currentStar.color.b * 255).round();
    hexController.text = '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
    redController.text = r.toString();
    greenController.text = g.toString();
    blueController.text = b.toString();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 24)),
                decoration: BoxDecoration(
                  color: Color(0xFF1A2238).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Color(0xFFFFE135).withValues(alpha: 0.3),
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
                      // Live preview
                      Text(
                        AppLocalizations.of(context)!.colorPreviewTitle,
                        style: FontScaling.getModalTitle(context),
                      ),
                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                      Container(
                        padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 20)),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SvgPicture.asset(
                          'assets/icon_star.svg',
                          width: FontScaling.getResponsiveIconSize(context, 64),
                          height: FontScaling.getResponsiveIconSize(context, 64),
                          colorFilter: ColorFilter.mode(previewColor, BlendMode.srcIn),
                        ),
                      ),
                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),

                      // Preset colors grid
                      Text(
                        AppLocalizations.of(context)!.presetColorsTitle,
                        style: FontScaling.getBodyMedium(context),
                      ),
                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
                      _buildColorGrid(
                        context: context,
                        selectedIndex: selectedColorIndex ?? -1,
                        onColorTap: (index) {
                          setState(() {
                            selectedColorIndex = index;
                            previewColor = StarColors.getColor(index);

                            // Update RGB/hex controllers
                            final color = StarColors.getColor(index);
                            final r = (color.r * 255).round();
                            final g = (color.g * 255).round();
                            final b = (color.b * 255).round();
                            hexController.text = '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
                            redController.text = r.toString();
                            greenController.text = g.toString();
                            blueController.text = b.toString();
                          });
                        },
                      ),

                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),

                      // Custom color section
                      Text(
                        AppLocalizations.of(context)!.customColorTitle,
                        style: FontScaling.getBodyMedium(context),
                      ),
                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),

                      // Hex input
                      TextField(
                        controller: hexController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.hexColorLabel,
                          hintText: AppLocalizations.of(context)!.hexColorHint,
                          hintStyle: FontScaling.getInputHint(context),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: FontScaling.getInputText(context),
                        onChanged: (value) {
                          // Sanitize hex input
                          final sanitized = InputValidator.sanitizeHexColor(value);
                          if (sanitized == null) return; // Invalid format

                          String hexValue = sanitized;
                          if (!hexValue.startsWith('#') && hexValue.length >= 6) {
                            hexValue = '#$hexValue';
                            hexController.value = TextEditingValue(
                              text: hexValue,
                              selection: TextSelection.collapsed(offset: hexValue.length),
                            );
                          }

                          if (hexValue.length == 7 && hexValue.startsWith('#')) {
                            try {
                              final color = Color(int.parse(hexValue.substring(1), radix: 16) + 0xFF000000);
                              setState(() {
                                previewColor = color;
                                selectedColorIndex = null;
                                redController.text = ((color.r * 255).round()).toString();
                                greenController.text = ((color.g * 255).round()).toString();
                                blueController.text = ((color.b * 255).round()).toString();
                              });
                            } catch (e) {
                              // Invalid hex
                            }
                          }
                        },
                      ),

                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),

                      // RGB inputs
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: redController,
                              decoration: InputDecoration(
                                labelText: 'R',
                                filled: true,
                                fillColor: Colors.red.withValues(alpha: 0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: FontScaling.getInputText(context),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => _updateFromRGB(
                                setState: setState,
                                redController: redController,
                                greenController: greenController,
                                blueController: blueController,
                                hexController: hexController,
                                onUpdate: (color) {
                                  previewColor = color;
                                  selectedColorIndex = null;
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
                          Expanded(
                            child: TextField(
                              controller: greenController,
                              decoration: InputDecoration(
                                labelText: 'G',
                                filled: true,
                                fillColor: Colors.green.withValues(alpha: 0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: FontScaling.getInputText(context),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => _updateFromRGB(
                                setState: setState,
                                redController: redController,
                                greenController: greenController,
                                blueController: blueController,
                                hexController: hexController,
                                onUpdate: (color) {
                                  previewColor = color;
                                  selectedColorIndex = null;
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
                          Expanded(
                            child: TextField(
                              controller: blueController,
                              decoration: InputDecoration(
                                labelText: 'B',
                                filled: true,
                                fillColor: Colors.blue.withValues(alpha: 0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: FontScaling.getInputText(context),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => _updateFromRGB(
                                setState: setState,
                                redController: redController,
                                greenController: greenController,
                                blueController: blueController,
                                hexController: hexController,
                                onUpdate: (color) {
                                  previewColor = color;
                                  selectedColorIndex = null;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              AppLocalizations.of(context)!.cancelButton,
                              style: FontScaling.getButtonText(context).copyWith(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              onColorSelected(selectedColorIndex, selectedColorIndex == null ? previewColor : null);
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFFE135),
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
                              AppLocalizations.of(context)!.applyButton,
                              style: FontScaling.getButtonText(context).copyWith(
                                color: Color(0xFF1A2238),
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
      },
    );
  }

  /// Helper to build color grid
  static Widget _buildColorGrid({
    required BuildContext context,
    required int selectedIndex,
    required Function(int) onColorTap,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: FontScaling.getResponsiveSpacing(context, 8),
        mainAxisSpacing: FontScaling.getResponsiveSpacing(context, 8),
      ),
      itemCount: StarColors.palette.length,
      itemBuilder: (context, index) {
        final isSelected = index == selectedIndex;
        return GestureDetector(
          onTap: () => onColorTap(index),
          child: Container(
            decoration: BoxDecoration(
              color: StarColors.palette[index],
              shape: BoxShape.circle,
              border: isSelected ? Border.all(
                color: Colors.white,
                width: 3,
              ) : null,
              boxShadow: isSelected ? [
                BoxShadow(
                  color: StarColors.palette[index].withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ] : null,
            ),
            child: isSelected ? Icon(
              Icons.check,
              color: Colors.white,
              size: FontScaling.getResponsiveIconSize(context, 16),
            ) : null,
          ),
        );
      },
    );
  }

  /// Helper to update preview from RGB values
  static void _updateFromRGB({
    required StateSetter setState,
    required TextEditingController redController,
    required TextEditingController greenController,
    required TextEditingController blueController,
    required TextEditingController hexController,
    required Function(Color) onUpdate,
  }) {
    try {
      final r = int.parse(redController.text).clamp(0, 255);
      final g = int.parse(greenController.text).clamp(0, 255);
      final b = int.parse(blueController.text).clamp(0, 255);

      final color = Color.fromARGB(255, r, g, b);
      setState(() {
        onUpdate(color);
        hexController.text = '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
      });
    } catch (e) {
      // Invalid RGB input
    }
  }

  // ========================================
  // HELPER WIDGETS
  // ========================================

  static void showAddGratitude({
    required BuildContext context,
    required TextEditingController controller,
    required VoidCallback onAdd,
    required bool isAnimating,
  }) {
    if (isAnimating) return;

    const int maxCharacters = 300; // Set character limit

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final remainingChars = maxCharacters - controller.text.length;
            final isOverLimit = remainingChars < 0;

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(maxWidth: 500, minWidth: 400),
                padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 20)),
                decoration: BoxDecoration(
                  color: Color(0xFF1A2238).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Color(0xFFFFE135).withValues(alpha: 0.3),
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
                    Text(
                      AppLocalizations.of(context)!.createStarModalTitle,
                      style: FontScaling.getModalTitle(context),
                    ),
                    SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),

                    // Scrollable text field with character counter
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 200),
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
                            fillColor: Colors.white.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: isOverLimit
                                    ? Colors.red
                                    : Color(0xFFFFE135).withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Color(0xFFFFE135).withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Color(0xFFFFE135),
                                width: 2,
                              ),
                            ),
                            counterStyle: FontScaling.getCaption(context).copyWith(
                              color: isOverLimit
                                  ? Colors.red
                                  : Colors.white.withValues(alpha: 0.6),
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
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        SizedBox(width: FontScaling.getResponsiveSpacing(context, 12)),
                        ElevatedButton(
                          onPressed: isOverLimit ? null : () {
                            onAdd();
                            Navigator.of(context).pop();
                          },
                          focusNode: FocusNode(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFFE135),
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
                              color: Color(0xFF1A2238),
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
    // Dialog owns its state (not shared with parent widget)
    bool isEditMode = false;
    Color? tempColorPreview;
    int? tempColorIndexPreview;

    // Dialog owns its controllers (disposed when dialog closes)
    final editTextController = TextEditingController(text: star.text);
    // final hexColorController = TextEditingController();
    // final redController = TextEditingController();
    // final greenController = TextEditingController();
    // final blueController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Look up current star by ID (handles updates from other sources)
            var currentStar = allStars.firstWhere(
                  (s) => s.id == star.id,
              orElse: () => star,
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
                constraints: BoxConstraints(maxWidth: 500, minWidth: 400),
                padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 20)),
                decoration: BoxDecoration(
                  color: Color(0xFF1A2238).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: currentStar.color.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
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
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      )
                    else
                      TextField(
                        controller: editTextController,
                        textCapitalization: TextCapitalization.sentences,
                        autofocus: true,
                        focusNode: FocusNode(),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.editGratitudeHint,
                          hintStyle: FontScaling.getInputHint(context),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Color(0xFFFFE135).withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        style: FontScaling.getInputText(context),
                        maxLines: 4,
                      ),

                    SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),

                    // View mode buttons
                    if (!isEditMode)
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              buildModalIconButton(
                                context: context,
                                icon: Icons.edit,
                                label: AppLocalizations.of(context)!.editButton,
                                onTap: () {
                                  setState(() {
                                    isEditMode = true;
                                  });
                                },
                              ),
                              buildModalIconButton(
                                context: context,
                                icon: Icons.share,
                                label: AppLocalizations.of(context)!.shareButton,
                                onTap: () => onShare(currentStar),
                              ),
                              buildModalIconButton(
                                context: context,
                                icon: Icons.close,
                                label: AppLocalizations.of(context)!.closeButton,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                          // Jump button (only shown if callback provided)
                          if (onJumpToStar != null) ...[
                            SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                onJumpToStar();
                              },
                              icon: Icon(Icons.my_location, size: FontScaling.getResponsiveIconSize(context, 20)),
                              label: Text(
                                AppLocalizations.of(context)!.jumpToStarButton,
                                style: FontScaling.getButtonText(context).copyWith(
                                  color: Color(0xFF1A2238),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFFE135),
                                foregroundColor: Color(0xFF1A2238),
                                minimumSize: Size(double.infinity, 48),
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
                              _showColorPickerDialog(
                                context: context,
                                currentStar: currentStar,
                                onColorSelected: (colorIndex, customColor) {
                                  setState(() {
                                    tempColorIndexPreview = colorIndex;
                                    tempColorPreview = customColor;
                                  });
                                },
                              );
                            },
                            icon: Icon(Icons.palette, size: FontScaling.getResponsiveIconSize(context, 20)),
                            label: Text(
                              AppLocalizations.of(context)!.changeColorButton,
                              style: FontScaling.getButtonText(context),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFFE135).withValues(alpha: 0.2),
                              foregroundColor: Color(0xFFFFE135),
                              minimumSize: Size(double.infinity, 48),
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
                                  showDeleteConfirmation(
                                    context: context,
                                    modalContext: dialogContext,
                                    star: currentStar,
                                    onDelete: onDelete,
                                    onAfterDelete: onAfterDelete,
                                  );
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
                                  });
                                },
                                child: Text(
                                  AppLocalizations.of(context)!.cancelButton,
                                  style: FontScaling.getButtonText(context).copyWith(
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                              SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
                              ElevatedButton(
                                onPressed: () {
                                  // Build updated star with all changes
                                  var updatedStar = currentStar.copyWith(
                                    text: editTextController.text,
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

                                  onSave(updatedStar);
                                  Navigator.of(context).pop('saved'); // ← Pass result
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFFFE135),
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
                                    color: Color(0xFF1A2238),
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
            );
          },
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
              color: Color(0xFFFFE135),
              size: FontScaling.getResponsiveIconSize(context, 28),
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 4)),
            Text(
              label,
              style: FontScaling.getCaption(context).copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}