import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/feedback_service.dart';
import '../../../../widgets/scrollable_dialog_content.dart';
import '../../../../core/utils/app_logger.dart';

/// Feedback dialog widget for submitting user feedback
class FeedbackDialog extends StatefulWidget {
  final AuthService authService;

  const FeedbackDialog({
    super.key,
    required this.authService,
  });

  static Future<bool?> show({
    required BuildContext context,
    required AuthService authService,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,  // Prevent accidental dismissal
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => FeedbackDialog(authService: authService),
    );
  }

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  String _selectedType = 'bug';
  String _message = '';
  String _contactEmail = '';
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: AppTheme.textPrimary.withValues(alpha: 0.1),
        splashColor: AppTheme.textPrimary.withValues(alpha: 0.05),
        hoverColor: AppTheme.textPrimary.withValues(alpha: 0.08),
        focusColor: AppTheme.textPrimary.withValues(alpha: 0.12),
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: AppTheme.textPrimary.withValues(alpha: 0.3),
          onSurface: AppTheme.textPrimary,
        ),
      ),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
        constraints: BoxConstraints(maxWidth: 500),
        padding: EdgeInsets.all(
          FontScaling.getResponsiveSpacing(context, 24),
        ),
        decoration: BoxDecoration(
          color: AppTheme.backgroundDark.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.borderNormal,
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
        child: Form(
          key: _formKey,
          child: ScrollableDialogContent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  l10n.feedbackDialogTitle,
                  style: FontScaling.getModalTitle(
                    context,
                  ).copyWith(color: AppTheme.primary),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: FontScaling.getResponsiveSpacing(context, 20),
                ),

                // Type dropdown
                Text(
                  l10n.feedbackTypeLabel,
                  style: FontScaling.getBodyMedium(
                    context,
                  ).copyWith(color: AppTheme.textPrimary.withValues(alpha: 0.9)),
                ),
                SizedBox(
                  height: FontScaling.getResponsiveSpacing(context, 8),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  dropdownColor: AppTheme.backgroundDark,
                  focusColor: AppTheme.textPrimary.withValues(alpha: 0.12),
                  style: FontScaling.getInputText(context),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.textPrimary.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.borderSubtle,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.borderSubtle,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.borderFocused,
                        width: 2,
                      ),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'bug',
                      child: Text(
                        l10n.feedbackTypeBug,
                        style: FontScaling.getInputText(context),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'feature',
                      child: Text(
                        l10n.feedbackTypeFeature,
                        style: FontScaling.getInputText(context),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'general',
                      child: Text(
                        l10n.feedbackTypeGeneral,
                        style: FontScaling.getInputText(context),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedType = value!);
                  },
                ),
                SizedBox(
                  height: FontScaling.getResponsiveSpacing(context, 16),
                ),

                // Message field
                Text(
                  l10n.feedbackMessageLabel,
                  style: FontScaling.getBodyMedium(
                    context,
                  ).copyWith(color: AppTheme.textPrimary.withValues(alpha: 0.9)),
                ),
                SizedBox(
                  height: FontScaling.getResponsiveSpacing(context, 8),
                ),
                TextFormField(
                  textCapitalization: TextCapitalization.sentences,
                  style: FontScaling.getInputText(context),
                  decoration: InputDecoration(
                    hintText: l10n.feedbackMessageHint,
                    hintStyle: FontScaling.getInputText(
                      context,
                    ).copyWith(color: AppTheme.textHint),
                    filled: true,
                    fillColor: AppTheme.textPrimary.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.borderSubtle,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.borderSubtle,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.borderFocused,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.error.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.error, width: 2),
                    ),
                    counterStyle: FontScaling.getCaption(
                      context,
                    ).copyWith(color: AppTheme.textDisabled),
                  ),
                  maxLines: 5,
                  maxLength: 1000,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.feedbackMessageRequired;
                    }
                    return null;
                  },
                  onChanged: (value) => _message = value,
                ),
                SizedBox(
                  height: FontScaling.getResponsiveSpacing(context, 16),
                ),

                // Optional email (only show if anonymous)
                if (widget.authService.currentUser?.isAnonymous ?? false) ...[
                  Text(
                    l10n.feedbackEmailLabel,
                    style: FontScaling.getBodyMedium(
                      context,
                    ).copyWith(color: AppTheme.textPrimary.withValues(alpha: 0.9)),
                  ),
                  SizedBox(
                    height: FontScaling.getResponsiveSpacing(context, 8),
                  ),
                  TextFormField(
                    textCapitalization: TextCapitalization.none,
                    style: FontScaling.getInputText(context),
                    keyboardType: TextInputType.emailAddress,
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: l10n.feedbackEmailHint,
                      hintStyle: FontScaling.getInputText(context).copyWith(
                        color: AppTheme.textHint,
                      ),
                      counterStyle: FontScaling.getCaption(context)
                          .copyWith(
                            color: AppTheme.textDisabled,
                          ),
                      filled: true,
                      fillColor: AppTheme.textPrimary.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.borderSubtle,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.borderSubtle,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.borderFocused,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.error.withValues(alpha: 0.5),
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.error, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final emailRegex = RegExp(
                          r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$',
                        );
                        if (!emailRegex.hasMatch(value)) {
                          return l10n.feedbackEmailInvalid;
                        }
                      }
                      return null;
                    },
                    onChanged: (value) => _contactEmail = value,
                  ),
                  SizedBox(
                    height: FontScaling.getResponsiveSpacing(context, 16),
                  ),
                ],

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        l10n.cancelButton,
                        style: FontScaling.getInputText(context).copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isSubmitting = true;
                          });

                          // #region agent log
                          if (kDebugMode) {
                            AppLogger.info('📤 Submitting feedback - type=$_selectedType, messageLength=${_message.length}');
                          }
                          // #endregion

                          final feedbackService = FeedbackService();

                          try {
                            final success = await feedbackService.submitFeedback(
                              type: _selectedType,
                              message: _message,
                              contactEmail:
                                  _contactEmail.isNotEmpty ? _contactEmail : null,
                            );

                            // #region agent log
                            if (kDebugMode) {
                              AppLogger.info('📤 Feedback submission result - success=$success');
                              AppLogger.info('📤 About to close dialog - mounted=$mounted');
                            }
                            // #endregion

                            // Close dialog and return result
                            if (!mounted) {
                              if (kDebugMode) {
                                AppLogger.error('📤 Widget not mounted, cannot close dialog!');
                              }
                              return;
                            }

                            // #region agent log
                            if (kDebugMode) {
                              AppLogger.info('📤 Calling Navigator.pop with result: $success');
                            }
                            // #endregion

                            // ignore: use_build_context_synchronously
                            Navigator.of(context).pop(success);

                            // #region agent log
                            if (kDebugMode) {
                              AppLogger.info('📤 Navigator.pop completed');
                            }
                            // #endregion
                          } catch (e, stack) {
                            // #region agent log
                            if (kDebugMode) {
                              AppLogger.error('📤 Feedback submission exception - $e');
                              AppLogger.info('Stack trace: $stack');
                              AppLogger.info('📤 About to close dialog with error - mounted=$mounted');
                            }
                            // #endregion

                            // Close dialog and return failure
                            // Parent will handle showing error message
                            if (!mounted) {
                              if (kDebugMode) {
                                AppLogger.error('📤 Widget not mounted, cannot close dialog!');
                              }
                              return;
                            }

                            // #region agent log
                            if (kDebugMode) {
                              AppLogger.info('📤 Calling Navigator.pop with result: false');
                            }
                            // #endregion

                            // ignore: use_build_context_synchronously
                            Navigator.of(context).pop(false);

                            // #region agent log
                            if (kDebugMode) {
                              AppLogger.info('📤 Navigator.pop completed (error case)');
                            }
                            // #endregion
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.textOnPrimary,
                        padding: EdgeInsets.symmetric(
                          horizontal: FontScaling.getResponsiveSpacing(
                            context,
                            24,
                          ),
                          vertical: FontScaling.getResponsiveSpacing(
                            context,
                            12,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.textOnPrimary,
                                ),
                              ),
                            )
                          : Text(
                              l10n.feedbackSubmit,
                              style: FontScaling.getButtonText(
                                context,
                              ).copyWith(color: AppTheme.textOnPrimary),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

