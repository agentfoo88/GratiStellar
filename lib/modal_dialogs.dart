import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'storage.dart';
import 'font_scaling.dart';
import 'l10n/app_localizations.dart';
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

  static void showStarDetailsWithJump({
    required BuildContext context,
    required GratitudeStar star,
    required String starId,  // NEW: Track by ID
    required List<GratitudeStar> gratitudeStars,  // NEW: For lookup
    required TextEditingController editTextController,
    required TextEditingController hexColorController,
    required TextEditingController redController,
    required TextEditingController greenController,
    required TextEditingController blueController,
    required Function(GratitudeStar, StateSetter) onShowColorPicker,
    required Function(GratitudeStar) onSaveEdits,
    required Function(GratitudeStar) onDelete,
    required Function(GratitudeStar) onShare,
    required VoidCallback? onJumpToStar,
    VoidCallback? onListRefresh,
  }) {
    bool isEditMode = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Look up the current star by ID on every rebuild
            final currentStar = gratitudeStars.firstWhere(
                  (s) => s.id == starId,
              orElse: () => star, // Fallback to original if somehow deleted
            );

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
                    SvgPicture.asset(
                      'assets/icon_star.svg',
                      width: FontScaling.getResponsiveIconSize(context, 64),
                      height: FontScaling.getResponsiveIconSize(context, 64),
                      colorFilter: ColorFilter.mode(star.color, BlendMode.srcIn),
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

                    // Action buttons
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
                          // Jump to Star button (only if callback provided)
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
                                  color: Color(0xFF1A2238), // Black text on yellow button
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
                      Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              onShowColorPicker(currentStar, setState);
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  showDeleteConfirmation(
                                    context: context,
                                    modalContext: dialogContext,
                                    star: currentStar,
                                    onDelete: (deletedStar) {
                                      onDelete(deletedStar);
                                      onListRefresh?.call();
                                    },
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
                                  onSaveEdits(currentStar);
                                  Navigator.of(context).pop();
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
    );
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

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext context) {
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
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.createStarHint,
                    hintStyle: FontScaling.getInputHint(context),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Color(0xFFFFE135).withValues(alpha: 0.3),
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
                  ),
                  style: FontScaling.getInputText(context),
                  maxLines: 4,
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
                      child: Text(
                        AppLocalizations.of(context)!.cancelButton,
                        style: FontScaling.getButtonText(context).copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    SizedBox(width: FontScaling.getResponsiveSpacing(context, 12)),
                    ElevatedButton(
                      onPressed: () {
                        onAdd();
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