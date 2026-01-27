import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../../../core/accessibility/semantic_helper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../screens/onboarding/enhanced_splash_screen.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/daily_reminder_service.dart';
import '../../../../services/layer_cache_service.dart';
import '../../../../services/url_launch_service.dart';
import '../../../../services/user_profile_manager.dart';
import '../../../../services/user_scoped_storage.dart';
import '../../../../storage.dart';
import '../../../../gratitude_stars.dart';
import '../../../../widgets/backup_restore_dialog.dart';
import '../../../../widgets/color_picker_dialog.dart';
import '../state/gratitude_provider.dart';
import '../state/galaxy_provider.dart';

/// App navigation drawer widget
///
/// Contains menu items for Account, List View, Feedback, and Exit
class AppDrawerWidget extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onAccountTap;
  final VoidCallback onListViewTap;
  final VoidCallback onGalaxiesTap;
  final VoidCallback onFeedbackTap;
  final VoidCallback onExitTap;
  final VoidCallback onFontScaleChanged;
  final VoidCallback onTrashTap;

  const AppDrawerWidget({
    super.key,
    required this.authService,
    required this.onAccountTap,
    required this.onListViewTap,
    required this.onGalaxiesTap,
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
  PackageInfo? _packageInfo;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _loadFontScale();
    _loadPackageInfo();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFontScale() async {
    final scale = await StorageService.getFontScale();
    if (mounted) {
      setState(() {
        textScaleFactor = scale;
      });
    }
  }

  Future<void> _loadPackageInfo() async {
    _packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {});
    }
  }

  double _getResponsiveDrawerWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 500) {
      return screenWidth * 0.85;
    } else if (screenWidth < 900) {
      return 320;
    } else {
      return 360;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      width: _getResponsiveDrawerWidth(context),
      backgroundColor: AppTheme.primaryDark.withValues(alpha: 0.98),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: false,
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          children: [
          // Enhanced Header with Icon, Title, Galaxy Stats (TAPPABLE)
          Consumer2<GalaxyProvider, GratitudeProvider>(
            builder: (context, galaxyProvider, gratitudeProvider, _) {
              final activeGalaxy = galaxyProvider.activeGalaxy;
              final stars = gratitudeProvider.gratitudeStars;
              final galaxyName = activeGalaxy?.name ?? 'All Stars';
              final starCount = stars.length;
              final todayCount = _getTodayStarCount(stars);
              final weekCount = StorageService.getThisWeekStars(stars);

              return SemanticHelper.label(
                label: l10n.aboutMenuItem,
                hint: l10n.viewAppInfo,
                isButton: true,
                child: InkWell(
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context); // Close drawer
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EnhancedSplashScreen(
                          displayMode: SplashDisplayMode.about,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      FontScaling.getResponsiveSpacing(context, 12),
                      MediaQuery.of(context).padding.top + FontScaling.getResponsiveSpacing(context, 12),
                      FontScaling.getResponsiveSpacing(context, 12),
                      FontScaling.getResponsiveSpacing(context, 12),
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.gradientTop.withValues(alpha: 0.3),
                          AppTheme.primaryDark,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SemanticHelper.decorative(
                              child: SvgPicture.asset(
                                'assets/icon_star.svg',
                                width: FontScaling.getResponsiveIconSize(context, 48) * UIConstants.universalUIScale,
                                height: FontScaling.getResponsiveIconSize(context, 48) * UIConstants.universalUIScale,
                                colorFilter: ColorFilter.mode(AppTheme.primary, BlendMode.srcIn),
                              ),
                            ),
                            SizedBox(width: FontScaling.getResponsiveSpacing(context, 16)),
                            Expanded(
                              child: Text(
                                l10n.appTitle,
                                style: FontScaling.getHeadingMedium(context).copyWith(
                                  fontSize: FontScaling.getHeadingMedium(context).fontSize! * UIConstants.universalUIScale,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: FontScaling.getResponsiveSpacing(context, 8)),
                        Text(
                          l10n.activeGalaxyLabel(galaxyName),
                          style: FontScaling.getBodySmall(context).copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        SizedBox(height: FontScaling.getResponsiveSpacing(context, 4)),
                        Row(
                          children: [
                            Text(
                              '$starCount ${starCount == 1 ? "star" : "stars"}',
                              style: FontScaling.getCaption(context).copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontScaling.mediumWeight,
                              ),
                            ),
                            SizedBox(width: FontScaling.getResponsiveSpacing(context, 12)),
                            Text(
                              l10n.drawerStatsToday(todayCount),
                              style: FontScaling.getCaption(context).copyWith(
                                color: AppTheme.textTertiary,
                              ),
                            ),
                            SizedBox(width: FontScaling.getResponsiveSpacing(context, 12)),
                            Text(
                              l10n.drawerStatsThisWeek(weekCount),
                              style: FontScaling.getCaption(context).copyWith(
                                color: AppTheme.textTertiary,
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
          ),

          // Navigation Section
          _buildSectionHeader(context, l10n.navigationSection),
          
          SemanticHelper.label(
            label: l10n.listViewMenuItem,
            hint: l10n.viewGratitudesAsList,
            isButton: true,
            child: ListTile(
              leading: Icon(
                Icons.list,
                color: AppTheme.primary,
                size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
              ),
              title: Text(
                l10n.listViewMenuItem,
                style: FontScaling.getBodyMedium(context).copyWith(
                  fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
                ),
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onListViewTap();
              },
            ),
          ),

          _buildThinDivider(),

          SemanticHelper.label(
            label: l10n.myGalaxies,
            hint: l10n.manageGalaxiesHint,
            isButton: true,
            child: ListTile(
              leading: Icon(
                Icons.stars,
                color: AppTheme.primary,
                size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
              ),
              title: Text(
                l10n.myGalaxies,
                style: FontScaling.getBodyMedium(context).copyWith(
                  fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
                ),
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onGalaxiesTap();
              },
            ),
          ),

          _buildThinDivider(),

          // Trash with improved badge
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
                    color: AppTheme.primary,
                    size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
                  ),
                  title: Text(
                    l10n.trash,
                    style: FontScaling.getBodyMedium(context).copyWith(
                      fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
                    ),
                  ),
                  trailing: trashCount > 0
                      ? Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.warning,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$trashCount',
                            style: FontScaling.getCaption(context).copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: (FontScaling.getCaption(context).fontSize ?? 12) * 0.9,
                            ),
                          ),
                        )
                      : null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onTrashTap();
                  },
                ),
              );
            },
          ),

          _buildThickDivider(),

          // Settings Section (Collapsible)
          ExpansionTile(
            leading: Icon(
              Icons.settings,
              color: AppTheme.primary,
              size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
            ),
            title: Text(
              l10n.settingsSection,
              style: FontScaling.getBodyMedium(context).copyWith(
                fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
                color: AppTheme.textPrimary,
                fontWeight: FontScaling.mediumWeight,
              ),
            ),
            iconColor: AppTheme.primary,
            collapsedIconColor: AppTheme.primary.withValues(alpha: 0.7),
            backgroundColor: AppTheme.textPrimary.withValues(alpha: 0.03),
            collapsedBackgroundColor: Colors.transparent,
            children: [
              // Font Size Setting
              Padding(
                padding: EdgeInsets.only(
                  left: FontScaling.getResponsiveSpacing(context, 16),
                  right: FontScaling.getResponsiveSpacing(context, 16),
                  bottom: FontScaling.getResponsiveSpacing(context, 8),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.text_fields, color: AppTheme.textSecondary),
                  title: Text(
                    l10n.fontSize,
                    style: FontScaling.getBodyMedium(context).copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: StatefulBuilder(
                    builder: (context, setSliderState) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text(
                            '${(textScaleFactor * 100).round()}%',
                            style: FontScaling.getBodySmall(context).copyWith(
                              color: AppTheme.textSecondary,
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
                              activeColor: AppTheme.primary,
                              inactiveColor: AppTheme.textDisabled,
                              thumbColor: AppTheme.primary,
                              overlayColor: WidgetStateProperty.all(
                                AppTheme.primary.withValues(alpha: 0.1),
                              ),
                              onChanged: (value) async {
                                setSliderState(() {
                                  textScaleFactor = value;
                                });
                              },
                              onChangeEnd: (value) async {
                                await StorageService.saveFontScale(value);
                                widget.onFontScaleChanged();
                              },
                            ),
                          ),
                          Text(
                            l10n.fontPreviewText,
                            style: TextStyle(
                              fontSize: 16 * textScaleFactor,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          SizedBox(height: 4),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // Default Star Color Setting
              FutureBuilder<(int?, Color?)?>(
                future: StorageService.getDefaultColor(),
                builder: (context, snapshot) {
                  final defaultColor = snapshot.data;
                  final bool hasDefault = defaultColor != null;

                  // Determine display color if set
                  Color? displayColor;
                  if (hasDefault) {
                    if (defaultColor.$1 != null) {
                      displayColor = StarColors.getColor(defaultColor.$1!);
                    } else {
                      displayColor = defaultColor.$2!;
                    }
                  }

                  return InkWell(
                    onTap: () async {
                      await showDialog<void>(
                        context: context,
                        builder: (dialogContext) => ColorPickerDialog(
                          initialColorIndex: defaultColor?.$1,
                          initialCustomColor: defaultColor?.$2,
                          onColorSelected: (colorIndex, customColor) async {
                            if (colorIndex != null) {
                              await StorageService.saveDefaultPresetColor(colorIndex);
                            } else if (customColor != null) {
                              await StorageService.saveDefaultCustomColor(customColor);
                            }
                            if (context.mounted) {
                              setState(() {}); // Refresh to show new color
                            }
                          },
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: FontScaling.getResponsiveSpacing(context, 16),
                        vertical: FontScaling.getResponsiveSpacing(context, 8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.palette, color: AppTheme.textSecondary, size: FontScaling.getResponsiveIconSize(context, 24)),
                          SizedBox(width: FontScaling.getResponsiveSpacing(context, 16)),
                          Text(
                            l10n.defaultStarColor,
                            style: FontScaling.getBodyMedium(context).copyWith(
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (hasDefault && displayColor != null)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: displayColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.textTertiary, width: 2),
                              ),
                            )
                          else
                            Text(
                              l10n.defaultColorNotSet,
                              style: FontScaling.getCaption(context).copyWith(
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          if (hasDefault)
                            SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
                          if (hasDefault)
                            IconButton(
                              onPressed: () async {
                                await StorageService.clearDefaultColor();
                                setState(() {}); // Refresh to show "Not set"
                              },
                              icon: Icon(Icons.clear, size: 20, color: AppTheme.textTertiary),
                              tooltip: l10n.clearDefaultColor,
                              padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 8)),
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Daily Reminder Setting
              Consumer<DailyReminderService>(
                builder: (context, reminderService, child) {
                  return SemanticHelper.label(
                    label: l10n.dailyReminderSetting,
                    hint: reminderService.isEnabled
                        ? l10n.dailyReminderEnabledHint
                        : l10n.dailyReminderDisabledHint,
                    isButton: true,
                    child: ListTile(
                      leading: Icon(
                        reminderService.isEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_none,
                        color: AppTheme.primary,
                        size: FontScaling.getResponsiveIconSize(context, 24) *
                            UIConstants.universalUIScale,
                      ),
                      title: Text(
                        l10n.dailyReminderTitle,
                        style: FontScaling.getBodyMedium(context).copyWith(
                          fontSize: FontScaling.getBodyMedium(context).fontSize! *
                              UIConstants.universalUIScale,
                        ),
                      ),
                      subtitle: reminderService.isEnabled
                          ? Text(
                              l10n.reminderTimeDisplay(
                                reminderService.reminderTime.format(context),
                              ),
                              style: FontScaling.getCaption(context).copyWith(
                                fontSize: FontScaling.getCaption(context).fontSize! *
                                    UIConstants.universalUIScale,
                              ),
                            )
                          : null,
                      trailing: Switch(
                        value: reminderService.isEnabled,
                        activeTrackColor: AppTheme.primary,
                        onChanged: (value) async {
                          HapticFeedback.selectionClick();
                          try {
                            if (value) {
                              final granted = await reminderService.requestPermission();
                              if (!granted) {
                                if (context.mounted) {
                                  Navigator.pop(context); // Close drawer first
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.reminderPermissionDenied,
                                        style: FontScaling.getBodyMedium(context),
                                      ),
                                      backgroundColor: AppTheme.error,
                                    ),
                                  );
                                }
                                return;
                              }
                              if (!context.mounted) return;
                              final time = await showTimePicker(
                                context: context,
                                initialTime: reminderService.reminderTime,
                                helpText: l10n.reminderTimePickerTitle,
                              );
                              if (time == null) return;
                              if (!context.mounted) return;
                              await reminderService.scheduleReminder(time);
                              await reminderService.setEnabled(true);
                              if (context.mounted) {
                                Navigator.pop(context); // Close drawer first
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.reminderEnabledSuccess,
                                      style: FontScaling.getBodyMedium(context),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } else {
                              await reminderService.cancelReminder();
                              await reminderService.setEnabled(false);
                              if (context.mounted) {
                                Navigator.pop(context); // Close drawer first
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.reminderDisabledSuccess,
                                      style: FontScaling.getBodyMedium(context),
                                    ),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            AppLogger.error('❌ Error toggling reminder: $e');
                            if (context.mounted) {
                              Navigator.pop(context); // Close drawer first
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().contains('permission')
                                        ? l10n.reminderPermissionDenied
                                        : l10n.reminderScheduleError,
                                    style: FontScaling.getBodyMedium(context),
                                  ),
                                  backgroundColor: AppTheme.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      onTap: reminderService.isEnabled
                          ? () async {
                              HapticFeedback.selectionClick();
                              try {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: reminderService.reminderTime,
                                  helpText: l10n.reminderTimePickerTitle,
                                );
                                if (time == null) return;
                                await reminderService.scheduleReminder(time);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.reminderTimeUpdatedSuccess,
                                        style: FontScaling.getBodyMedium(context),
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                AppLogger.error('❌ Error updating reminder time: $e');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.errorReminderTimeUpdate,
                                        style: FontScaling.getBodyMedium(context),
                                      ),
                                      backgroundColor: AppTheme.error,
                                    ),
                                  );
                                }
                              }
                            }
                          : null,
                    ),
                  );
                },
              ),
            ],
          ),

          _buildThickDivider(),

          // Account & Data Section
          _buildSectionHeader(context, l10n.accountSettings),

          FutureBuilder<String>(
            future: _getAccountDisplayName(),
            builder: (context, snapshot) {
              final displayName = snapshot.data ?? l10n.defaultUserName;

              return SemanticHelper.label(
                label: l10n.accountSettings,
                hint: l10n.manageAccountHint,
                isButton: true,
                child: ListTile(
                  leading: Icon(Icons.account_circle, color: AppTheme.textSecondary),
                  title: Text(
                    l10n.accountMenuItem,
                    style: FontScaling.getBodyMedium(context).copyWith(
                      fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
                    ),
                  ),
                  subtitle: Text(
                    displayName,
                    style: FontScaling.getCaption(context),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onAccountTap();
                  },
                ),
              );
            },
          ),

          SemanticHelper.label(
            label: l10n.backupRestoreTitle,
            hint: l10n.exportBackupSubtitle,
            isButton: true,
            child: ListTile(
              leading: Icon(
                Icons.backup,
                color: AppTheme.primary,
                size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
              ),
              title: Text(
                l10n.backupRestoreTitle,
                style: FontScaling.getBodyMedium(context).copyWith(
                  fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
                ),
              ),
              subtitle: Text(
                l10n.exportBackupSubtitle,
                style: FontScaling.getCaption(context),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textTertiary,
                size: FontScaling.getResponsiveIconSize(context, 16) * UIConstants.universalUIScale,
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                showDialog(
                  context: context,
                  builder: (context) => const BackupRestoreDialog(),
                );
              },
            ),
          ),

          _buildThickDivider(),

          // Help & Legal Section (Collapsible)
          ExpansionTile(
            leading: Icon(
              Icons.help_outline,
              color: AppTheme.primary,
              size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
            ),
            title: Text(
              l10n.helpLegalSection,
              style: FontScaling.getBodyMedium(context).copyWith(
                fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
                color: AppTheme.textPrimary,
                fontWeight: FontScaling.mediumWeight,
              ),
            ),
            iconColor: AppTheme.primary,
            collapsedIconColor: AppTheme.primary.withValues(alpha: 0.7),
            backgroundColor: AppTheme.textPrimary.withValues(alpha: 0.03),
            collapsedBackgroundColor: Colors.transparent,
            children: [
              SemanticHelper.label(
                label: l10n.feedbackMenuItem,
                hint: l10n.sendFeedbackHint,
                isButton: true,
                child: ListTile(
                  leading: Icon(
                    Icons.feedback_outlined,
                    color: AppTheme.textSecondary,
                    size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
                  ),
                  title: Text(
                    l10n.feedbackMenuItem,
                    style: FontScaling.getBodyMedium(context).copyWith(
                      fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
                    ),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                    widget.onFeedbackTap();
                  },
                ),
              ),

              SemanticHelper.label(
                label: l10n.aboutMenuItem,
                hint: l10n.viewAppInfo,
                isButton: true,
                child: ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: AppTheme.textSecondary,
                    size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
                  ),
                  title: Text(
                    l10n.aboutMenuItem,
                    style: FontScaling.getBodyMedium(context).copyWith(
                      fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
                    ),
                  ),
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EnhancedSplashScreen(
                          displayMode: SplashDisplayMode.about,
                        ),
                      ),
                    );
                  },
                ),
              ),

              SemanticHelper.label(
                label: l10n.privacyPolicyMenuItem,
                hint: l10n.viewLegalDocuments,
                isButton: true,
                child: ListTile(
                  leading: Icon(
                    Icons.privacy_tip_outlined,
                    color: AppTheme.textSecondary,
                    size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
                  ),
                  title: Text(
                    l10n.privacyPolicyMenuItem,
                    style: FontScaling.getBodyMedium(context).copyWith(
                      fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
                    ),
                  ),
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    try {
                      await UrlLaunchService.launchUrlSafely(AppConfig.privacyPolicyUrl);
                    } catch (e) {
                      AppLogger.error('Failed to open privacy policy: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.errorOpenUrl(l10n.privacyPolicyMenuItem), style: FontScaling.getBodyMedium(context)),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),

              SemanticHelper.label(
                label: l10n.termsOfServiceMenuItem,
                hint: l10n.viewLegalDocuments,
                isButton: true,
                child: ListTile(
                  leading: Icon(
                    Icons.description_outlined,
                    color: AppTheme.textSecondary,
                    size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
                  ),
                  title: Text(
                    l10n.termsOfServiceMenuItem,
                    style: FontScaling.getBodyMedium(context).copyWith(
                      fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
                    ),
                  ),
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    try {
                      await UrlLaunchService.launchUrlSafely(AppConfig.termsOfServiceUrl);
                    } catch (e) {
                      AppLogger.error('Failed to open terms of service: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.errorOpenUrl(l10n.termsOfServiceMenuItem), style: FontScaling.getBodyMedium(context)),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),

          _buildThickDivider(),

          // DEBUG ONLY: Developer options
          if (kDebugMode) ...[
            // Clear Layer Cache
            SemanticHelper.label(
            label: l10n.clearLayerCache,
            hint: l10n.regenerateBackgroundHint,
            isButton: true,
            child: ListTile(
              leading: Icon(Icons.cleaning_services, color: AppTheme.textSecondary),
              title: Text(
                l10n.clearLayerCache,
                style: FontScaling.getBodyMedium(context).copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              subtitle: Text(
                l10n.regenerateBackgroundLayers,
                style: FontScaling.getCaption(context).copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
              onTap: () async {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop(); // Close drawer

                // Show confirmation dialog
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.primaryDark,
                    title: Text(
                      l10n.clearCacheTitle,
                      style: FontScaling.getModalTitle(context),
                    ),
                    content: Text(
                      l10n.clearCacheMessage,
                      style: FontScaling.getBodyMedium(context).copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          l10n.cancel,
                          style: FontScaling.getButtonText(context).copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          l10n.clearCache,
                          style: FontScaling.getButtonText(context).copyWith(
                            color: AppTheme.primary,
                          ),
                        ),
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
                        content: Text(l10n.cacheCleared, style: FontScaling.getBodyMedium(context)),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
            ),
          ),

          // TEMPORARY RECOVERY OPTION
          ListTile(
            leading: Icon(Icons.cloud_download, color: AppTheme.error),
            title: Text(l10n.debugRecoverDataTitle),
            subtitle: Text(l10n.debugRecoverDataSubtitle),
            onTap: () async {
              HapticFeedback.selectionClick();
              Navigator.pop(context);

              // Clear sync timestamp to force full download
              await StorageService.clearLastSyncTime();

              if (!context.mounted) return;

              // Reload gratitudes - will trigger full sync
              final gratitudeProvider = Provider.of<GratitudeProvider>(context, listen: false);
              await gratitudeProvider.loadGratitudes();

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.debugSyncCompleteMessage, style: FontScaling.getBodyMedium(context)),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
          ], // End DEBUG ONLY section

          // Exit (moved to bottom, less prominent)
          _buildThinDivider(),
          
          SemanticHelper.label(
            label: l10n.exitButton,
            hint: l10n.closeAppHint,
            isButton: true,
            child: ListTile(
              leading: Icon(
                Icons.close,
                color: AppTheme.textTertiary,
                size: FontScaling.getResponsiveIconSize(context, 20) * UIConstants.universalUIScale,
              ),
              title: Text(
                l10n.exitButton,
                style: FontScaling.getBodyMedium(context).copyWith(
                  fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
                  color: AppTheme.textSecondary,
                ),
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onExitTap();
              },
            ),
          ),

          // Version number at bottom
          if (_packageInfo != null)
            Padding(
              padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 16)),
              child: Center(
                child: Text(
                  l10n.version(_packageInfo!.version, _packageInfo!.buildNumber),
                  style: FontScaling.getCaption(context).copyWith(
                    color: AppTheme.textDisabled,
                  ),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }

  Future<int> _getTrashCount() async {
    try {
      final provider = Provider.of<GratitudeProvider>(context, listen: false);
      return await provider.getDeletedGratitudesCount();
    } catch (e) {
      AppLogger.error('Failed to get trash count: $e');
      return 0;
    }
  }

  Future<String> _getAccountDisplayName() async {
    try {
      // Get l10n before async operations
      final l10n = AppLocalizations.of(context)!;
      final defaultName = l10n.defaultUserName;
      
      if (widget.authService.hasEmailAccount) {
        // For email users, get from Firebase
        final name = await widget.authService.getDisplayName(defaultName: defaultName);
        return name ?? defaultName;
      } else {
        // For anonymous users, get from local storage
        final userProfileManager = Provider.of<UserProfileManager>(context, listen: false);
        final userId = await userProfileManager.getOrCreateActiveUserId();
        
        // Use helper method to get display name (handles both Firebase UID and device-based IDs)
        return await UserScopedStorage.getDisplayName(userId, defaultName: defaultName);
      }
    } catch (e) {
      AppLogger.error('Failed to get account display name: $e');
      if (!mounted) return 'User';
      final l10n = AppLocalizations.of(context)!;
      return l10n.defaultUserName;
    }
  }

  int _getTodayStarCount(List<GratitudeStar> stars) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return stars.where((star) =>
        star.createdAt.isAfter(today) &&
        star.createdAt.isBefore(today.add(Duration(days: 1)))
    ).length;
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        FontScaling.getResponsiveSpacing(context, 16),
        FontScaling.getResponsiveSpacing(context, 12),
        FontScaling.getResponsiveSpacing(context, 16),
        FontScaling.getResponsiveSpacing(context, 4),
      ),
      child: Text(
        title.toUpperCase(),
        style: FontScaling.getSectionHeader(context).copyWith(
          color: AppTheme.primary.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildThickDivider() {
    return Divider(
      color: AppTheme.primary.withValues(alpha: 0.3),
      thickness: 1,
      height: 1,
    );
  }

  Widget _buildThinDivider() {
    return Divider(
      color: AppTheme.textPrimary.withValues(alpha: 0.1),
      height: 1,
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
    final l10n = AppLocalizations.of(context)!;

    return SemanticHelper.label(
      label: l10n.openMenu,
      hint: l10n.openNavigationMenu,
      isButton: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Icon(
          Icons.menu,
          color: AppTheme.textSecondary,
          size: FontScaling.getResponsiveIconSize(context, 28) * UIConstants.universalUIScale,
        ),
      ),
    );
  }
}