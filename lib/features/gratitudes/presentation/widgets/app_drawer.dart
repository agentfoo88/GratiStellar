// lib/features/gratitudes/presentation/widgets/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/config/constants.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth_service.dart';

/// App navigation drawer widget
///
/// Contains menu items for Account, List View, Feedback, and Exit
class AppDrawerWidget extends StatelessWidget {
  final AuthService authService;
  final VoidCallback onAccountTap;
  final VoidCallback onListViewTap;
  final VoidCallback onFeedbackTap;
  final VoidCallback onExitTap;

  const AppDrawerWidget({
    super.key,
    required this.authService,
    required this.onAccountTap,
    required this.onListViewTap,
    required this.onFeedbackTap,
    required this.onExitTap,
  });

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
              authService.hasEmailAccount ? Icons.account_circle : Icons.login,
              color: Color(0xFFFFE135),
              size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
            ),
            title: Text(
              authService.hasEmailAccount
                  ? l10n.accountMenuItem
                  : l10n.signInWithEmailMenuItem,
              style: FontScaling.getBodyMedium(context).copyWith(
                fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
              ),
            ),
            subtitle: authService.hasEmailAccount
                ? Text(
              authService.currentUser?.displayName ?? l10n.defaultUserName,
              style: FontScaling.getCaption(context),
            )
                : null,
            onTap: onAccountTap,
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
            onTap: onListViewTap,
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
            onTap: onFeedbackTap,
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
            onTap: onExitTap,
          ),
          Divider(
            color: Color(0xFFFFE135).withValues(alpha: 0.2),
            height: 1,
          ),

          // Version number at bottom
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '1.0.0';
              final buildNumber = snapshot.data?.buildNumber ?? '1';

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