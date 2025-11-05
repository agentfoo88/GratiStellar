import '../../../../services/layer_cache_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/config/constants.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth_service.dart';
import '../../../../storage.dart';
import '../../../../core/accessibility/semantic_helper.dart';

/// App navigation drawer widget
///
/// Contains menu items for Account, List View, Feedback, and Exit
class AppDrawerWidget extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onAccountTap;
  final VoidCallback onListViewTap;
  final VoidCallback onFeedbackTap;
  final VoidCallback onExitTap;
  final VoidCallback onFontScaleChanged;
  final VoidCallback onTrashTap;

  const AppDrawerWidget({
    super.key,
    required this.authService,
    required this.onAccountTap,
    required this.onListViewTap,
    required this.onFeedbackTap,
    required this.onExitTap,
    required this.onFontScaleChanged,
    required this.onTrashTap,
  });

  @override
  State<AppDrawerWidget> createState() => _AppDrawerWidgetState();
}

class _AppDrawerWidgetState extends State<AppDrawerWidget> {
  double textScaleFactor = 1.0;

  @override
  void initState() {
    super.initState();
    _loadFontScale();
  }

  Future<void> _loadFontScale() async {
    final scale = await StorageService.getFontScale();
    if (mounted) {
      setState(() {
        textScaleFactor = scale;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      backgroundColor: Color(0xFF1A2238).withValues(alpha: 0.98),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header with Icon and Title side-by-side
          Container(
            padding: EdgeInsets.fromLTRB(
              FontScaling.getResponsiveSpacing(context, 16),
              MediaQuery.of(context).padding.top + FontScaling.getResponsiveSpacing(context, 16),
              FontScaling.getResponsiveSpacing(context, 16),
              FontScaling.getResponsiveSpacing(context, 16),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4A6FA5).withValues(alpha: 0.3),
                  Color(0xFF1A2238),
                ],
              ),
            ),
            child: Row(
              children: [
                SemanticHelper.decorative(
                  child: SvgPicture.asset(
                    'assets/icon_star.svg',
                    width: FontScaling.getResponsiveIconSize(context, 48) * UIConstants.universalUIScale,
                    height: FontScaling.getResponsiveIconSize(context, 48) * UIConstants.universalUIScale,
                    colorFilter: ColorFilter.mode(Color(0xFFFFE135), BlendMode.srcIn),
                  ),
                ),
                SizedBox(width: FontScaling.getResponsiveSpacing(context, 16)),
                Expanded(
                  child: Text(
                    l10n.appTitle,
                    style: FontScaling.getHeadingMedium(context).copyWith(
                      fontSize: FontScaling.getHeadingMedium(context).fontSize! * UIConstants.universalUIScale,
                      color: Color(0xFFFFE135),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Account section
          SemanticHelper.label(
            label: l10n.accountSettings,
            hint: l10n.manageAccountHint,
            isButton: true,
            child: ListTile(
              focusNode: FocusNode(),
              leading: Icon(Icons.account_circle, color: Colors.white70),
              title: Text(
                widget.authService.hasEmailAccount
                    ? l10n.accountMenuItem
                    : l10n.signInWithEmailMenuItem,
                style: FontScaling.getBodyMedium(context).copyWith(
                  fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
                ),
              ),
              subtitle: widget.authService.hasEmailAccount
                  ? Text(
                widget.authService.currentUser?.displayName ?? l10n.defaultUserName,
                style: FontScaling.getCaption(context),
              )
                  : null,
              onTap: widget.onAccountTap,
            ),
          ),

          // Heavy divider
          Divider(
            color: Color(0xFFFFE135).withValues(alpha: 0.5),
            thickness: 2,
            height: 2,
          ),

          // List View
          SemanticHelper.label(
            label: l10n.listViewMenuItem,
            hint: l10n.viewGratitudesAsList,
            isButton: true,
            child: ListTile(
              focusNode: FocusNode(),
              leading: Icon(
                Icons.list,
                color: Color(0xFFFFE135),
                size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
              ),
              title: Text(
                l10n.listViewMenuItem,
                style: FontScaling.getBodyMedium(context).copyWith(
                  fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
                ),
              ),
              onTap: widget.onListViewTap,
            ),
          ),

          Divider(
            color: Color(0xFFFFE135).withValues(alpha: 0.2),
            height: 1,
          ),

          // Font Size Setting
          ListTile(
            leading: Icon(Icons.text_fields, color: Colors.white70),
            title: Text(
              l10n.fontSize,
              style: FontScaling.getBodyMedium(context).copyWith(
                color: Colors.white,
              ),
            ),
            subtitle: StatefulBuilder(
              builder: (context, setSliderState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    Text(
                      '${(textScaleFactor * 100).round()}%',
                      style: FontScaling.getBodySmall(context).copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    SemanticHelper.label(
                      label: l10n.fontSizeSlider,
                      hint: l10n.adjustTextSize,
                      child: Slider(
                        value: textScaleFactor,
                        min: 0.75,
                        max: 1.75,
                        divisions: 4,
                        label: '${(textScaleFactor * 100).round()}%',
                        activeColor: Color(0xFFFFE135),
                        inactiveColor: Colors.white24,
                        thumbColor: Color(0xFFFFE135),
                        overlayColor: WidgetStateProperty.all(
                          Color(0xFFFFE135).withValues(alpha: 0.1),
                        ),
                        onChanged: (value) async {
                          // Update local state immediately
                          setSliderState(() {
                            textScaleFactor = value;
                          });
                        },
                        onChangeEnd: (value) async {
                          // Save to storage when user releases slider
                          await StorageService.saveFontScale(value);

                          // Trigger parent rebuild by calling the callback
                          widget.onFontScaleChanged();
                        },
                      ),
                    ),
                    Text(
                      l10n.fontPreviewText,
                      style: TextStyle(
                        fontSize: 16 * textScaleFactor,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),

          Divider(color: Colors.white24),

          // Trash
          FutureBuilder<int>(
            future: _getTrashCount(),
            builder: (context, snapshot) {
              final trashCount = snapshot.data ?? 0;

              return SemanticHelper.label(
                label: trashCount > 0
                    ? l10n.trashWithCount(trashCount)
                    : l10n.trashEmpty,
                hint: l10n.viewDeletedGratitudes,
                isButton: true,
                child: ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: Color(0xFFFFE135),
                    size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
                  ),
                  title: Row(
                    children: [
                      Text(
                        l10n.trash,
                        style: FontScaling.getBodyMedium(context).copyWith(
                          fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
                        ),
                      ),
                      if (trashCount > 0) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$trashCount',
                            style: FontScaling.getCaption(context).copyWith(
                              color: Colors.orange[300],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: widget.onTrashTap,
                ),
              );
            },
          ),

          Divider(
            color: Color(0xFFFFE135).withValues(alpha: 0.2),
            height: 1,
          ),

          // Send Feedback
          SemanticHelper.label(
            label: l10n.feedbackMenuItem,
            hint: l10n.sendFeedbackHint,
            isButton: true,
            child: ListTile(
              leading: Icon(
                Icons.feedback_outlined,
                color: Color(0xFFFFE135),
                size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
              ),
              title: Text(
                l10n.feedbackMenuItem,
                style: FontScaling.getBodyMedium(context).copyWith(
                  fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
                ),
              ),
              onTap: widget.onFeedbackTap,
            ),
          ),

          Divider(
            color: Color(0xFFFFE135).withValues(alpha: 0.2),
            height: 1,
          ),

          // Exit
          SemanticHelper.label(
            label: l10n.exitButton,
            hint: l10n.closeAppHint,
            isButton: true,
            child: ListTile(
              leading: Icon(
                Icons.close,
                color: Color(0xFFFFE135),
                size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
              ),
              title: Text(
                l10n.exitButton,
                style: FontScaling.getBodyMedium(context).copyWith(
                  fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
                ),
              ),
              onTap: widget.onExitTap,
            ),
          ),

          Divider(
            color: Color(0xFFFFE135).withValues(alpha: 0.2),
            height: 1,
          ),

          // Clear Layer Cache
          SemanticHelper.label(
            label: l10n.clearLayerCache,
            hint: l10n.regenerateBackgroundHint,
            isButton: true,
            child: ListTile(
              leading: Icon(Icons.cleaning_services, color: Colors.white70),
              title: Text(
                l10n.clearLayerCache,
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                l10n.regenerateBackgroundLayers,
                style: TextStyle(color: Colors.white60, fontSize: 15),
              ),
              onTap: () async {
                Navigator.of(context).pop(); // Close drawer

                // Show confirmation dialog
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.clearCacheTitle),
                    content: Text(l10n.clearCacheMessage),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(l10n.clearCache),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await LayerCacheService().clearCache();

                  // Show snackbar
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.cacheCleared),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
            ),
          ),

          // Version number at bottom
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }
              final info = snapshot.data!;
              final version = info.version;
              final buildNumber = info.buildNumber;

              return Padding(
                padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 16)),
                child: Center(
                  child: Text(
                    l10n.version(version, buildNumber),
                    style: FontScaling.getCaption(context).copyWith(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<int> _getTrashCount() async {
    try {
      final allStars = await StorageService.loadGratitudeStars();
      return allStars.where((star) => star.deleted).length;
    } catch (e) {
      return 0;
    }
  }
}

/// Hamburger menu button for opening the drawer
class HamburgerButton extends StatelessWidget {
  final VoidCallback onTap;

  const HamburgerButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SemanticHelper.label(
      label: l10n.openMenu,
      hint: l10n.openNavigationMenu,
      isButton: true,
      child: GestureDetector(
        onTap: onTap,
        child: Icon(
          Icons.menu,
          color: Colors.white.withValues(alpha: 0.8),
          size: FontScaling.getResponsiveIconSize(context, 28) * UIConstants.universalUIScale,
        ),
      ),
    );
  }
}