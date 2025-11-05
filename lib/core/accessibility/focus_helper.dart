import 'package:flutter/material.dart';

/// Helper for managing focus in dialogs and forms
class FocusHelper {
  /// Auto-focus the first focusable widget in a dialog
  static void autoFocusFirst(BuildContext context, {Duration delay = const Duration(milliseconds: 100)}) {
    Future.delayed(delay, () {
      if (context.mounted) {
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
  }

  /// Return focus to the element that opened a dialog
  static void returnFocusToTrigger(FocusNode? triggerFocusNode) {
    if (triggerFocusNode != null && triggerFocusNode.canRequestFocus) {
      triggerFocusNode.requestFocus();
    }
  }

  /// Trap focus within a dialog (prevent tabbing outside)
  static Widget trapFocus({
    required Widget child,
    required FocusNode focusNode,
  }) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        // Handle Escape key to close dialog
        if (event.logicalKey.keyLabel == 'Escape') {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}