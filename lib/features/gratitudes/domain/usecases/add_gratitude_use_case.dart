// lib/features/gratitudes/domain/usecases/add_gratitude_use_case.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../gratitude_stars.dart';
import '../../../../storage.dart';
import 'use_case.dart';

/// Parameters for adding a new gratitude
class AddGratitudeParams {
  final String text;
  final Size screenSize;
  final List<GratitudeStar> existingStars;

  const AddGratitudeParams({
    required this.text,
    required this.screenSize,
    required this.existingStars,
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
    // Trim whitespace, newlines, and collapse multiple spaces
    final trimmedText = params.text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');

    if (trimmedText.isEmpty) {
      throw ArgumentError('Gratitude text cannot be empty');
    }

    // Create the new star using the service
    final newStar = GratitudeStarService.createStar(
      trimmedText,
      params.screenSize,
      random,
      params.existingStars,
    );

    return newStar;
  }
}