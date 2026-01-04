import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/season_config.dart';
import '../../../../core/accessibility/semantic_helper.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';
import '../state/galaxy_provider.dart';

/// Season drawer widget - slide-out panel from top-right
/// Contains controls for cycling seasons, returning to current time, and toggling season tracking
class SeasonDrawer extends StatefulWidget {
  const SeasonDrawer({super.key});

  @override
  State<SeasonDrawer> createState() => _SeasonDrawerState();
}

class _SeasonDrawerState extends State<SeasonDrawer>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _cycleSeason(GalaxyProvider galaxyProvider) async {
    final galaxy = galaxyProvider.activeGalaxy;
    if (galaxy == null) {
      AppLogger.warning('⚠️ Cannot cycle season: No active galaxy');
      return;
    }

    try {
      final currentSeason = galaxy.currentSeason ?? Season.spring;
      final nextSeason = SeasonConfig.getNextSeason(currentSeason);

      // Update galaxy with new season and set manual override
      await galaxyProvider.updateGalaxy(
        galaxy.copyWith(
          currentSeason: nextSeason,
          isManualOverride: true,
          seasonTrackingEnabled: true,
        ),
      );
      AppLogger.info('✅ Cycled season to: $nextSeason');
    } catch (e) {
      AppLogger.error('⚠️ Error cycling season: $e');
    }
  }

  Future<void> _returnToCurrentTime(GalaxyProvider galaxyProvider) async {
    final galaxy = galaxyProvider.activeGalaxy;
    if (galaxy == null) {
      AppLogger.warning('⚠️ Cannot return to current time: No active galaxy');
      return;
    }

    try {
      // Calculate actual season from current date
      final seasonInfo = SeasonConfig.calculateSeason(
        DateTime.now(),
        galaxy.hemisphere,
      );

      // Update galaxy with actual season and clear manual override
      await galaxyProvider.updateGalaxy(
        galaxy.copyWith(
          currentSeason: seasonInfo.season,
          isManualOverride: false,
          seasonTrackingEnabled: true,
        ),
      );
      AppLogger.info('✅ Returned to current season: ${seasonInfo.season}');
    } catch (e) {
      AppLogger.error('⚠️ Error returning to current time: $e');
    }
  }

  Future<void> _toggleSeasonTracking(GalaxyProvider galaxyProvider, bool enabled) async {
    final galaxy = galaxyProvider.activeGalaxy;
    if (galaxy == null) {
      AppLogger.warning('⚠️ Cannot toggle season tracking: No active galaxy');
      return;
    }

    try {
      if (enabled && galaxy.currentSeason == null) {
        // If enabling and no season set, calculate current season
        final seasonInfo = SeasonConfig.calculateSeason(
          DateTime.now(),
          galaxy.hemisphere,
        );
        await galaxyProvider.updateGalaxy(
          galaxy.copyWith(
            seasonTrackingEnabled: true,
            currentSeason: seasonInfo.season,
            isManualOverride: false,
          ),
        );
        AppLogger.info('✅ Enabled season tracking with season: ${seasonInfo.season}');
      } else {
        // Just toggle the setting
        await galaxyProvider.updateGalaxy(
          galaxy.copyWith(seasonTrackingEnabled: enabled),
        );
        AppLogger.info('✅ ${enabled ? "Enabled" : "Disabled"} season tracking');
      }
    } catch (e) {
      AppLogger.error('⚠️ Error toggling season tracking: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GalaxyProvider>(
      builder: (context, galaxyProvider, _) {
        final galaxy = galaxyProvider.activeGalaxy;
        final seasonTrackingEnabled = galaxy?.seasonTrackingEnabled ?? false;
        final currentSeason = galaxy?.currentSeason ?? Season.spring;

        return Stack(
          children: [
            // Invisible barrier to catch taps outside drawer when expanded (must be BEFORE drawer)
            // Drawer is tested first (reverse order), so taps on drawer won't reach barrier
            if (_isExpanded)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleDrawer,
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),
              ),
            // Drawer itself - must be clickable and on top
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0), // Off-screen right
                    end: Offset.zero, // On-screen
                  ).animate(_slideAnimation),
                  child: Container(
                      constraints: const BoxConstraints(maxWidth: 280),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2238).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFE135).withValues(alpha: 0.3),
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                        // Toggle button (always visible)
                        SemanticHelper.label(
                          label: _isExpanded ? 'Hide season controls' : 'Show season controls',
                          hint: 'Toggle season drawer',
                          isButton: true,
                          child: InkWell(
                            onTap: _toggleDrawer,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: Container(
                              padding: EdgeInsets.all(
                                FontScaling.getResponsiveSpacing(context, 12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    currentSeason.icon,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
                                  Text(
                                    AppLocalizations.of(context)!.seasonTitle,
                                    style: FontScaling.getBodyMedium(context),
                                  ),
                                  SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
                                  Icon(
                                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                                    size: FontScaling.getResponsiveIconSize(context, 20),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Expanded content
                        if (_isExpanded) ...[
                          Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          Padding(
                            padding: EdgeInsets.all(
                              FontScaling.getResponsiveSpacing(context, 16),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Cycle Season Button
                                SemanticHelper.label(
                                  label: 'Cycle to next season',
                                  hint: 'Click to preview next season',
                                  isButton: true,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _cycleSeason(galaxyProvider),
                                    icon: Text(
                                      currentSeason.icon,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    label: Text(
                                      currentSeason.displayName, // TODO: Use l10n after regeneration
                                      style: FontScaling.getButtonText(context).copyWith(
                                        color: const Color(0xFF1A2238), // Dark text for WCAG contrast
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white, // White background for better contrast
                                      foregroundColor: const Color(0xFF1A2238), // Dark text
                                      padding: EdgeInsets.symmetric(
                                        horizontal: FontScaling.getResponsiveSpacing(context, 16),
                                        vertical: FontScaling.getResponsiveSpacing(context, 12),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                  ),
                                ),

                                SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),

                                // Return to Current Time Button
                                SemanticHelper.label(
                                  label: 'Return to current season',
                                  hint: 'Reset to actual current season',
                                  isButton: true,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _returnToCurrentTime(galaxyProvider),
                                    icon: const Text('🕐', style: TextStyle(fontSize: 18)),
                                    label: Text(
                                      AppLocalizations.of(context)!.nowLabel,
                                      style: FontScaling.getButtonText(context).copyWith(
                                        color: Colors.white, // Full opacity for WCAG contrast
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.5), // Increased opacity
                                        width: 1.5,
                                      ),
                                      foregroundColor: Colors.white, // Full opacity for WCAG contrast
                                      padding: EdgeInsets.symmetric(
                                        horizontal: FontScaling.getResponsiveSpacing(context, 16),
                                        vertical: FontScaling.getResponsiveSpacing(context, 12),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),

                                // Toggle Switch
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.seasonTrackingTitle,
                                      style: FontScaling.getBodyMedium(context),
                                    ),
                                    Switch(
                                      value: seasonTrackingEnabled,
                                      onChanged: (value) => _toggleSeasonTracking(galaxyProvider, value),
                                      activeThumbColor: const Color(0xFFFFE135),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}