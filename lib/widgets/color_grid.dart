import 'package:flutter/material.dart';

import '../font_scaling.dart';
import '../gratitude_stars.dart'; // For StarColors

class ColorGrid extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onColorTap;

  const ColorGrid({
    super.key,
    required this.selectedIndex,
    required this.onColorTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: FontScaling.getResponsiveSpacing(context, 8),
        mainAxisSpacing: FontScaling.getResponsiveSpacing(context, 8),
      ),
      itemCount: StarColors.palette.length,
      itemBuilder: (context, index) {
        final isSelected = index == selectedIndex;
        return GestureDetector(
          onTap: () => onColorTap(index),
          child: Container(
            decoration: BoxDecoration(
              color: StarColors.palette[index],
              shape: BoxShape.circle,
              border: isSelected ? Border.all(
                color: Colors.white,
                width: 3,
              ) : null,
              boxShadow: isSelected ? [
                BoxShadow(
                  color: StarColors.palette[index].withOpacity(0.5),
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
