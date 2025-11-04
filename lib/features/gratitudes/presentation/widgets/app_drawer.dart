// lib/features/gratitudes/presentation/widgets/app_drawer.dart
import '../../../../services/layer_cache_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/config/constants.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth_service.dart';
import '../../../../storage.dart';

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
                SvgPicture.asset(
                  'assets/icon_star.svg',
                  width: FontScaling.getResponsiveIconSize(context, 48) * UIConstants.universalUIScale,
                  height: FontScaling.getResponsiveIconSize(context, 48) * UIConstants.universalUIScale,
                  colorFilter: ColorFilter.mode(Color(0xFFFFE135), BlendMode.srcIn),
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
          ListTile(
            leading: Icon(
              widget.authService.hasEmailAccount ? Icons.account_circle : Icons.login,
              color: Color(0xFFFFE135),
              size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
            ),
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

          // Heavy divider
          Divider(
            color: Color(0xFFFFE135).withValues(alpha: 0.5),
            thickness: 2,
            height: 2,
          ),

          // List View
          ListTile(
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

          Divider(
            color: Color(0xFFFFE135).withValues(alpha: 0.2),
            height: 1,
          ),

          // Font Size Setting
          ListTile(
            leading: Icon(Icons.text_fields, color: Colors.white70),
            title: Text(
              'Font Size',
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
                    Slider(
                      value: textScaleFactor,
                      min: 0.75,
                      max: 1.75,
                      divisions: 4,
                      label: '${(textScaleFactor * 100).round()}%',
                      activeColor: Color(0xFFFFE135),
                      inactiveColor: Colors.white24,
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
                    Text(
                      'Preview: The quick brown fox jumps',
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

          Divider(color: Colors.white24),

          // Trash
          FutureBuilder<int>(
            future: _getTrashCount(),
            builder: (context, snapshot) {
              final trashCount = snapshot.data ?? 0;

              return ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Color(0xFFFFE135),
                  size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
                ),
                title: Row(
                  children: [
                    Text(
                      'Trash',
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
              );
            },
          ),

          Divider(
            color: Color(0xFFFFE135).withValues(alpha: 0.2),
            height: 1,
          ),

          // Send Feedback
          ListTile(
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
            onTap: widget.onFeedbackTap ,
          ),

          Divider(
            color: Color(0xFFFFE135).withValues(alpha: 0.2),
            height: 1,
          ),

          // Exit
          ListTile(
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
          Divider(
            color: Color(0xFFFFE135).withValues(alpha: 0.2),
            height: 1,
          ),

          ListTile(
            leading: Icon(Icons.cleaning_services, color: Colors.white70),
            title: Text(
              'Clear Layer Cache',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Regenerate background layers',
              style: TextStyle(color: Colors.white60, fontSize: 15),
            ),
            onTap: () async {
              Navigator.of(context).pop(); // Close drawer

              // Show confirmation dialog
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Clear Cache?'),
                  content: Text('This will regenerate all background layers. The app will restart.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Clear Cache'),
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
                      content: Text('Cache cleared. Restart the app to regenerate.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
          ),

          // Version number at bottom
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink(); // Avoid showing placeholder text
              }
              final info = snapshot.data!;
              final version = info.version;
              final buildNumber = info.buildNumber;

              return Padding(
                padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 16)),
                child: Center(
                  child: Text(
                    'Version $version ($buildNumber)',
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
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        Icons.menu,
        color: Colors.white.withValues(alpha: 0.8),
        size: FontScaling.getResponsiveIconSize(context, 28) * UIConstants.universalUIScale,
      ),
    );
  }
}