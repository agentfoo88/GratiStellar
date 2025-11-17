import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../font_scaling.dart';
import '../l10n/app_localizations.dart';
import '../modal_dialogs.dart'; // For showDeleteConfirmation and _showColorPickerDialog
import '../storage.dart'; // For GratitudeStar
import 'color_picker_dialog.dart';

// TODO: Refactor _showColorPickerDialog into its own widget as well
// This widget will replace the contents of the showEditStar method

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

  // Dialog owns its controllers (disposed when dialog closes)
  late final TextEditingController editTextController;

  @override
  void initState() {
    super.initState();
    editTextController = TextEditingController(text: widget.star.text);
  }

  @override
  void dispose() {
    editTextController.dispose();
    super.dispose();
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
          color: const Color(0xFF1A2238).withValues(alpha:0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: currentStar.color.withValues(alpha:0.5),
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
                  color: Colors.white.withValues(alpha:0.9),
                ),
                textAlign: TextAlign.center,
              )
            else
            // Calculate remaining chars for counter and limit indicator
              Builder(
                  builder: (innerContext) { // Use Builder to get a new context for setState
                    final remainingChars = maxCharacters - editTextController.text.length;
                    final isOverLimit = remainingChars < 0;

                    return TextField(
                      controller: editTextController,
                      textCapitalization: TextCapitalization.sentences,
                      autofocus: true,
                      focusNode: FocusNode(),
                      maxLength: maxCharacters, // <--- ADD THIS LINE
                      maxLines: null, // Allow unlimited lines visually, but limit characters
                      keyboardType: TextInputType.multiline, // <--- ADD THIS LINE for better multi-line input
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.editGratitudeHint,
                        hintStyle: FontScaling.getInputHint(context),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha:0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isOverLimit // <--- UPDATED LOGIC
                                ? Colors.red
                                : const Color(0xFFFFE135).withValues(alpha:0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder( // <--- ADDED FOR CONSISTENCY
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isOverLimit // <--- UPDATED LOGIC
                                ? Colors.red
                                : const Color(0xFFFFE135).withValues(alpha:0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder( // <--- ADDED FOR CONSISTENCY
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isOverLimit // <--- UPDATED LOGIC
                                ? Colors.red
                                : const Color(0xFFFFE135),
                            width: isOverLimit ? 2 : 2, // Keep width 2
                          ),
                        ),
                        counterStyle: FontScaling.getCaption(context).copyWith( // <--- ADDED COUNTER STYLE
                          color: isOverLimit
                              ? Colors.red
                              : Colors.white.withValues(alpha:0.6),
                        ),
                      ),
                      style: FontScaling.getInputText(context),
                      onChanged: (value) {
                        setState(() {}); // Rebuild to update counter and border color
                      },
                    );
                  }
              ),

            SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),

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
                          color: const Color(0xFF1A2238),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE135),
                        foregroundColor: const Color(0xFF1A2238),
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
                          return ColorPickerDialog(
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
                      backgroundColor: const Color(0xFFFFE135).withValues(alpha:0.2),
                      foregroundColor: const Color(0xFFFFE135),
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
                            color: Colors.white.withValues(alpha:0.6),
                          ),
                        ),
                      ),
                      SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
                      ElevatedButton(
                        onPressed: editTextController.text.length > maxCharacters ? null : () { // <--- UPDATED LOGIC
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

                          widget.onSave(updatedStar);
                          Navigator.of(context).pop('saved'); // ← Pass result
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFE135),
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
                            color: const Color(0xFF1A2238),
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
  }
}
