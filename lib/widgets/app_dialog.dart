import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../font_scaling.dart';

class AppDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    List<AppDialogAction>? actions,
    Color? borderColor,
    IconData? icon,
    Color? iconColor,
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxWidth: 500, minWidth: 300),
            padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 24)),
            decoration: BoxDecoration(
              color: Color(0xFF1A2238).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: borderColor ?? Color(0xFFFFE135).withValues(alpha: 0.3),
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon (optional)
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: iconColor ?? Color(0xFFFFE135),
                      size: FontScaling.getResponsiveIconSize(context, 48),
                    ),
                    SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                  ],

                  // Title
                  Text(
                    title,
                    style: FontScaling.getModalTitle(context),
                    textAlign: TextAlign.center,
                  ),

                  // Message or custom content
                  if (message != null || content != null) ...[
                    SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
                    if (content != null)
                      content
                    else if (message != null)
                      Text(
                        message,
                        style: FontScaling.getBodyMedium(context).copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],

                  // Actions
                  if (actions != null && actions.isNotEmpty) ...[
                    SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),
                    if (actions.length == 1)
                    // Single action - full width
                      SizedBox(
                        width: double.infinity,
                        child: _buildActionButton(context, actions[0]),
                      )
                    else
                    // Multiple actions - row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: actions.map((action) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: FontScaling.getResponsiveSpacing(context, 4),
                              ),
                              child: _buildActionButton(context, action),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildActionButton(BuildContext context, AppDialogAction action) {
    final bool isPrimary = action.isPrimary ?? false;
    final bool isDestructive = action.isDestructive ?? false;

    Color backgroundColor;
    Color textColor;

    if (isDestructive) {
      backgroundColor = Colors.red;
      textColor = Colors.white;
    } else if (isPrimary) {
      backgroundColor = Color(0xFFFFE135);
      textColor = Color(0xFF1A2238);
    } else {
      backgroundColor = Colors.transparent;
      textColor = Colors.white.withValues(alpha: 0.8);
    }

    if (isPrimary || isDestructive) {
      return ElevatedButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          action.onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: EdgeInsets.symmetric(
            horizontal: FontScaling.getResponsiveSpacing(context, 16),
            vertical: FontScaling.getResponsiveSpacing(context, 12),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: Text(
          action.text,
          style: FontScaling.getButtonText(context).copyWith(
            color: textColor,
          ),
        ),
      );
    } else {
      return TextButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          action.onPressed();
        },
        child: Text(
          action.text,
          style: FontScaling.getButtonText(context).copyWith(
            color: textColor,
          ),
        ),
      );
    }
  }

  // Convenience methods for common dialogs
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
    Color? iconColor,
  }) {
    return show<bool>(
      context: context,
      title: title,
      message: message,
      icon: icon,
      iconColor: iconColor,
      borderColor: isDestructive ? Colors.red.withValues(alpha: 0.5) : null,
      actions: [
        AppDialogAction(
          text: cancelText,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppDialogAction(
          text: confirmText,
          isPrimary: !isDestructive,
          isDestructive: isDestructive,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }

  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    IconData? icon,
    Color? iconColor,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      icon: icon,
      iconColor: iconColor,
      actions: [
        AppDialogAction(
          text: buttonText,
          isPrimary: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class AppDialogAction {
  final String text;
  final VoidCallback onPressed;
  final bool? isPrimary;
  final bool? isDestructive;

  AppDialogAction({
    required this.text,
    required this.onPressed,
    this.isPrimary,
    this.isDestructive,
  });
}