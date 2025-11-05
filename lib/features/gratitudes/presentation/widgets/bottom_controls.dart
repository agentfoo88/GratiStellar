import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/accessibility/semantic_helper.dart';
import '../../../../core/config/constants.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/accessibility/motion_helper.dart';

/// Bottom controls widget with add star, show all, and mindfulness buttons
///
/// Includes integrated slider for mindfulness interval control
class BottomControlsWidget extends StatelessWidget {
  final bool showAllGratitudes;
  final bool mindfulnessMode;
  final bool isAnimating;
  final int mindfulnessInterval;
  final VoidCallback onToggleShowAll;
  final VoidCallback onToggleMindfulness;
  final VoidCallback onAddStar;
  final ValueChanged<double> onMindfulnessIntervalChanged;

  const BottomControlsWidget({
    super.key,
    required this.showAllGratitudes,
    required this.mindfulnessMode,
    required this.isAnimating,
    required this.mindfulnessInterval,
    required this.onToggleShowAll,
    required this.onToggleMindfulness,
    required this.onAddStar,
    required this.onMindfulnessIntervalChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Calculate button row dimensions
    final buttonSize = FontScaling.getResponsiveSpacing(context, 56) * UIConstants.universalUIScale;
    final spacing = FontScaling.getResponsiveSpacing(context, 16) * UIConstants.universalUIScale;
    final addStarSize = FontScaling.getResponsiveSpacing(context, 70) * UIConstants.universalUIScale;

    // Debug touch targets (remove after verification)
    MotionHelper.debugTouchTarget(context, "Side Buttons", buttonSize);
    MotionHelper.debugTouchTarget(context, "Add Star Button", addStarSize);

    // Total row width
    final rowWidth = buttonSize + spacing + addStarSize + spacing + buttonSize;

    // Offset from center to mindfulness button center
    final connectorOffset = (addStarSize / 2) + spacing + (buttonSize / 2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Horizontal slider appears above buttons when mindfulness is active
        AnimatedContainer(
          duration: MotionHelper.getEssentialDuration(context),
          curve: MotionHelper.getCurve(context, Curves.easeInOut),
          height: mindfulnessMode ? null : 0,
          child: AnimatedOpacity(
            duration: MotionHelper.getEssentialDuration(context),
            opacity: mindfulnessMode ? 1.0 : 0.0,
            child: mindfulnessMode ? _buildMindfulnessSlider(context) : SizedBox.shrink(),
          ),
        ),

        // Connector line from slider to mindfulness button
        if (mindfulnessMode)
          SizedBox(
            height: FontScaling.getResponsiveSpacing(context, 12) * UIConstants.universalUIScale,
            width: rowWidth,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: (rowWidth / 2) + connectorOffset - 1,
                  child: AnimatedOpacity(
                    duration: MotionHelper.getEssentialDuration(context),
                    opacity: mindfulnessMode ? 1.0 : 0.0,
                    child: Container(
                      width: 2,
                      height: FontScaling.getResponsiveSpacing(context, 12) * UIConstants.universalUIScale,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFE135).withValues(alpha: 0.5),
                            Color(0xFFFFE135).withValues(alpha: 0.2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Stable 3-button row (never moves)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              context: context,
              icon: Icons.visibility,
              isActive: showAllGratitudes,
              onTap: onToggleShowAll,
            ),
            SizedBox(width: spacing),
            _buildAddStarButton(context),
            SizedBox(width: spacing),
            _buildActionButton(
              context: context,
              icon: Icons.self_improvement,
              isActive: mindfulnessMode,
              onTap: onToggleMindfulness,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddStarButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Focus(
      focusNode: FocusNode(),
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return SemanticHelper.label(
            label: isAnimating
                ? l10n.creatingGratitudeStar
                : l10n.addNewGratitudeStar,
            hint: l10n.addStarHint,
            isButton: true,
            onTap: isAnimating ? null : onAddStar,
            child: GestureDetector(
              onTap: isAnimating ? null : onAddStar,
              child: Container(
                width: FontScaling.getResponsiveSpacing(context, 70) * UIConstants.universalUIScale,
                height: FontScaling.getResponsiveSpacing(context, 70) * UIConstants.universalUIScale,
                decoration: BoxDecoration(
                  color: isAnimating
                      ? Color(0xFFFFE135).withValues(alpha: 0.5)
                      : Color(0xFFFFE135),
                  borderRadius: BorderRadius.circular(FontScaling.getResponsiveSpacing(context, 35) * UIConstants.universalUIScale),
                  border: isFocused ? Border.all(
                    color: Colors.white,
                    width: 3,
                  ) : null,
                  boxShadow: isAnimating ? [] : [
                    BoxShadow(
                      color: Color(0xFFFFE135).withValues(alpha: 0.4),
                      blurRadius: 20 * UIConstants.universalUIScale,
                      spreadRadius: 5 * UIConstants.universalUIScale,
                    ),
                    if (isFocused)
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Center(
                  child: SemanticHelper.decorative(
                    child: SvgPicture.asset(
                      'assets/icon_star.svg',
                      width: FontScaling.getResponsiveSpacing(context, 56) * UIConstants.universalUIScale,
                      height: FontScaling.getResponsiveSpacing(context, 56) * UIConstants.universalUIScale,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMindfulnessSlider(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

    final sliderWidth = isMobile
        ? math.min(220.0, screenWidth * 0.6)
        : 200.0;

    return Container(
      width: sliderWidth,
      padding: EdgeInsets.symmetric(
        horizontal: FontScaling.getResponsiveSpacing(context, 16) * UIConstants.universalUIScale,
        vertical: FontScaling.getResponsiveSpacing(context, 12) * UIConstants.universalUIScale,
      ),
      decoration: BoxDecoration(
        color: Color(0xFF1A2238).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20 * UIConstants.universalUIScale),
        border: Border.all(
          color: Color(0xFFFFE135).withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${l10n.mindfulnessIntervalLabel}: ${mindfulnessInterval}s',
            style: FontScaling.getCaption(context).copyWith(
              fontSize: FontScaling.getBodySmall(context).fontSize! * UIConstants.universalUIScale,
            ),
          ),
          SizedBox(height: FontScaling.getResponsiveSpacing(context, 8) * UIConstants.universalUIScale),
          SemanticHelper.label(
            label: l10n.mindfulnessIntervalSlider,
            hint: l10n.mindfulnessIntervalHint,
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Color(0xFFFFE135),
                inactiveTrackColor: Color(0xFFFFE135).withValues(alpha: 0.4),
                thumbColor: Color(0xFFFFE135),
                overlayColor: Color(0xFFFFE135).withValues(alpha: 0.2),
                trackHeight: 4 * UIConstants.universalUIScale,
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: 12 * UIConstants.universalUIScale,
                ),
                overlayShape: RoundSliderOverlayShape(
                  overlayRadius: 24 * UIConstants.universalUIScale,
                ),
              ),
              child: Slider(
                value: mindfulnessInterval.toDouble(),
                min: 3.0,
                max: 30.0,
                divisions: 18,
                onChanged: onMindfulnessIntervalChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return Focus(
      focusNode: FocusNode(),
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          final String label;
          final String hint;

          // Determine label based on button type
          if (icon == Icons.visibility) {
            label = isActive ? l10n.hideOtherGratitudes : l10n.showAllGratitudes;
            hint = isActive ? l10n.switchToSingleStarView : l10n.showAllStarsInSky;
          } else if (icon == Icons.self_improvement) {
            label = isActive ? l10n.exitMindfulnessMode : l10n.enterMindfulnessMode;
            hint = isActive ? l10n.stopCyclingGratitudes : l10n.startMindfulViewing;
          } else {
            label = l10n.actionButton;
            hint = l10n.tapToActivate;
          }

          return SemanticHelper.label(
            label: label,
            hint: hint,
            isButton: true,
            isToggle: true,
            toggleValue: isActive,
            onTap: isAnimating ? null : onTap,
            child: GestureDetector(
              onTap: isAnimating ? null : onTap,
              child: Container(
                width: FontScaling.getResponsiveSpacing(context, 56) * UIConstants.universalUIScale,
                height: FontScaling.getResponsiveSpacing(context, 56) * UIConstants.universalUIScale,
                decoration: BoxDecoration(
                  color: isActive
                      ? Color(0xFFFFE135).withValues(alpha: 0.9)
                      : Color(0xFF1A2238).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(FontScaling.getResponsiveSpacing(context, 28) * UIConstants.universalUIScale),
                  border: Border.all(
                    color: isFocused ? Colors.white :
                    Color(0xFFFFE135).withValues(alpha: isActive ? 1.0 : 0.5),
                    width: isFocused ? 3 : 2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isActive ? Color(0xFF1A2238) : Colors.white.withValues(alpha: 0.8),
                  size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}