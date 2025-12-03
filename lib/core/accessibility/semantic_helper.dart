import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Helper for adding semantic labels and announcements
class SemanticHelper {
  /// Wrap a widget with semantic information for screen readers
  static Widget label({
    required Widget child,
    required String label,
    String? hint,
    bool isButton = false,
    bool isToggle = false,
    bool? toggleValue,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      toggled: isToggle ? toggleValue : null,
      onTap: onTap,
      child: child,
    );
  }

  /// Announce a message to screen readers
  static void announce(BuildContext context, String message) {
    final view = View.of(context);
    SemanticsService.sendAnnouncement(view, message, TextDirection.ltr);
  }

  /// Mark a widget as decorative (excluded from screen readers)
  static Widget decorative({required Widget child}) {
    return ExcludeSemantics(child: child);
  }

  /// Create a live region for dynamic content updates
  static Widget liveRegion({
    required Widget child,
    required String label,
    LiveRegionImportance importance = LiveRegionImportance.polite,
  }) {
    return Semantics(
      liveRegion: true,
      label: label,
      child: child,
    );
  }
}

/// Enum for live region importance levels
enum LiveRegionImportance {
  polite,
  assertive,
}