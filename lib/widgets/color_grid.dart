import 'package:flutter/material.dart';

import '../font_scaling.dart';
import '../gratitude_stars.dart'; // For StarColors

class ColorGrid extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onColorTap;
  final List<Color>? colors; // Optional custom color list

  const ColorGrid({
    super.key,
    required this.selectedIndex,
    required this.onColorTap,
    this.colors, // Optional - defaults to StarColors.palette
  });

  @override
  Widget build(BuildContext context) {
    // Use provided colors or fall back to default palette
    final colorList = colors ?? StarColors.palette;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: FontScaling.getResponsiveSpacing(context, 8),
        mainAxisSpacing: FontScaling.getResponsiveSpacing(context, 8),
      ),
      itemCount: colorList.length,
      itemBuilder: (context, index) {
        final isSelected = index == selectedIndex;
        final color = colorList[index];
        return GestureDetector(
          onTap: () => onColorTap(index),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(
                color: Colors.white,
                width: 3,
              ) : null,
              boxShadow: isSelected ? [
                BoxShadow(
                  color: color.withValues(alpha:0.5),
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
}
