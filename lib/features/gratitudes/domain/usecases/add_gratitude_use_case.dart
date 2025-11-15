import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/security/input_validator.dart';
import '../../../../gratitude_stars.dart';
import '../../../../storage.dart';
import 'use_case.dart';

/// Parameters for adding a new gratitude
class AddGratitudeParams {
  final String text;
  final Size screenSize;
  final List<GratitudeStar> existingStars;
  final String galaxyId;
  final int? colorPresetIndex;
  final Color? customColor;

  const AddGratitudeParams({
    required this.text,
    required this.screenSize,
    required this.existingStars,
    required this.galaxyId,
    this.colorPresetIndex,
    this.customColor,
  });
}

/// Use case for adding a new gratitude star
///
/// Creates a new star with:
/// - Trimmed and validated text
/// - Random position in the universe
/// - Random color from presets
/// - Proper spacing from other stars
class AddGratitudeUseCase extends UseCase<GratitudeStar, AddGratitudeParams> {
  final math.Random random;

  AddGratitudeUseCase(this.random);

  @override
  Future<GratitudeStar> call(AddGratitudeParams params) async {
    // Sanitize input (removes dangerous characters, normalizes whitespace)
    final sanitizedText = InputValidator.sanitizeGratitudeText(params.text);

    // Validate sanitized text
    if (sanitizedText.isEmpty) {
      throw ArgumentError('Gratitude text cannot be empty');
    }

    // Additional security check
    if (InputValidator.hasDangerousContent(sanitizedText)) {
      throw ArgumentError('Invalid characters detected in gratitude text');
    }

    // Create the new star using the sanitized text
    final newStar = GratitudeStarService.createStar(
      sanitizedText,  // ← Use sanitized, not original
      params.screenSize,
      random,
      params.existingStars,
      galaxyId: params.galaxyId,
      colorPresetIndex: params.colorPresetIndex,
      customColor: params.customColor,
    );

    return newStar;
  }
}