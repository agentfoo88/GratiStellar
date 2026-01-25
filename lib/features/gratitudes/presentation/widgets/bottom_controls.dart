import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/accessibility/semantic_helper.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/accessibility/motion_helper.dart';

/// Bottom controls widget with add star, show all, and mindfulness buttons
///
/// Includes integrated slider for mindfulness interval control
class BottomControlsWidget extends StatefulWidget {
  final bool showAllGratitudes;
  final bool mindfulnessMode;
  final bool isAnimating;
  final int mindfulnessInterval;
  final bool shouldPulse;
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
    this.shouldPulse = false,
    required this.onToggleShowAll,
    required this.onToggleMindfulness,
    required this.onAddStar,
    required this.onMindfulnessIntervalChanged,
  });

  @override
  State<BottomControlsWidget> createState() => _BottomControlsWidgetState();
}

class _BottomControlsWidgetState extends State<BottomControlsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.shouldPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BottomControlsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldPulse && !oldWidget.shouldPulse) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.shouldPulse && oldWidget.shouldPulse) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          height: widget.mindfulnessMode ? null : 0,
          child: AnimatedOpacity(
            duration: MotionHelper.getEssentialDuration(context),
            opacity: widget.mindfulnessMode ? 1.0 : 0.0,
            child: widget.mindfulnessMode ? _buildMindfulnessSlider(context) : SizedBox.shrink(),
          ),
        ),

        // Connector line from slider to mindfulness button
        if (widget.mindfulnessMode)
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
                    opacity: widget.mindfulnessMode ? 1.0 : 0.0,
                    child: Container(
                      width: 2,
                      height: FontScaling.getResponsiveSpacing(context, 12) * UIConstants.universalUIScale,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.primary.withValues(alpha: 0.5),
                            AppTheme.primary.withValues(alpha: 0.2),
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
              isActive: widget.showAllGratitudes,
              onTap: widget.onToggleShowAll,
            ),
            SizedBox(width: spacing),
            _buildAddStarButton(context),
            SizedBox(width: spacing),
            _buildActionButton(
              context: context,
              icon: Icons.self_improvement,
              isActive: widget.mindfulnessMode,
              onTap: widget.onToggleMindfulness,
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
            label: widget.isAnimating
                ? l10n.creatingGratitudeStar
                : l10n.addNewGratitudeStar,
            hint: l10n.addStarHint,
            isButton: true,
            onTap: widget.isAnimating ? null : widget.onAddStar,
            child: GestureDetector(
              onTap: widget.isAnimating ? null : () {
                HapticFeedback.selectionClick();
                widget.onAddStar();
              },
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final glowIntensity = widget.shouldPulse ? _pulseAnimation.value : 0.0;
                  return Container(
                    width: FontScaling.getResponsiveSpacing(context, 70) * UIConstants.universalUIScale,
                    height: FontScaling.getResponsiveSpacing(context, 70) * UIConstants.universalUIScale,
                    decoration: BoxDecoration(
                      color: widget.isAnimating
                          ? AppTheme.primary.withValues(alpha: 0.5)
                          : AppTheme.primary,
                      borderRadius: BorderRadius.circular(FontScaling.getResponsiveSpacing(context, 35) * UIConstants.universalUIScale),
                      border: isFocused ? Border.all(
                        color: AppTheme.textPrimary,
                        width: 3,
                      ) : null,
                      boxShadow: widget.isAnimating ? [] : [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.4 + (0.4 * glowIntensity)),
                          blurRadius: (20 + (15 * glowIntensity)) * UIConstants.universalUIScale,
                          spreadRadius: (5 + (8 * glowIntensity)) * UIConstants.universalUIScale,
                        ),
                        if (isFocused)
                          BoxShadow(
                            color: AppTheme.textPrimary.withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: child,
                  );
                },
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
        color: AppTheme.backgroundDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20 * UIConstants.universalUIScale),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${l10n.mindfulnessIntervalLabel}: ${widget.mindfulnessInterval}s',
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
                activeTrackColor: AppTheme.primary,
                inactiveTrackColor: AppTheme.primary.withValues(alpha: 0.4),
                thumbColor: AppTheme.primary,
                overlayColor: AppTheme.primary.withValues(alpha: 0.2),
                trackHeight: 4 * UIConstants.universalUIScale,
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: 12 * UIConstants.universalUIScale,
                ),
                overlayShape: RoundSliderOverlayShape(
                  overlayRadius: 24 * UIConstants.universalUIScale,
                ),
              ),
              child: Slider(
                value: widget.mindfulnessInterval.toDouble(),
                min: 3.0,
                max: 30.0,
                divisions: 18,
                onChanged: widget.onMindfulnessIntervalChanged,
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
            onTap: widget.isAnimating ? null : onTap,
            child: GestureDetector(
              onTap: widget.isAnimating ? null : () {
                HapticFeedback.selectionClick();
                onTap();
              },
              child: Container(
                width: FontScaling.getResponsiveSpacing(context, 56) * UIConstants.universalUIScale,
                height: FontScaling.getResponsiveSpacing(context, 56) * UIConstants.universalUIScale,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primary.withValues(alpha: 0.9)
                      : AppTheme.backgroundDark.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(FontScaling.getResponsiveSpacing(context, 28) * UIConstants.universalUIScale),
                  border: Border.all(
                    color: isFocused ? AppTheme.textPrimary :
                    AppTheme.primary.withValues(alpha: isActive ? 1.0 : 0.5),
                    width: isFocused ? 3 : 2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isActive ? AppTheme.backgroundDark : AppTheme.textPrimary.withValues(alpha: 0.8),
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