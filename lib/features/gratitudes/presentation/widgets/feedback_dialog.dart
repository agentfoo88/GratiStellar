import 'package:flutter/material.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/feedback_service.dart';

/// Feedback dialog widget for submitting user feedback
class FeedbackDialog extends StatefulWidget {
  final AuthService authService;

  const FeedbackDialog({
    super.key,
    required this.authService,
  });

  static void show({
    required BuildContext context,
    required AuthService authService,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => FeedbackDialog(authService: authService),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: 500),
        padding: EdgeInsets.all(
          FontScaling.getResponsiveSpacing(context, 24),
        ),
        decoration: BoxDecoration(
          color: Color(0xFF1A2238).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Color(0xFFFFE135).withValues(alpha: 0.5),
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  l10n.feedbackDialogTitle,
                  style: FontScaling.getModalTitle(
                    context,
                  ).copyWith(color: Color(0xFFFFE135)),
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
                  ).copyWith(color: Colors.white.withValues(alpha: 0.9)),
                ),
                SizedBox(
                  height: FontScaling.getResponsiveSpacing(context, 8),
                ),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  dropdownColor: Color(0xFF1A2238),
                  style: FontScaling.getInputText(context),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color(0xFFFFE135).withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color(0xFFFFE135).withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color(0xFFFFE135),
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
                  ).copyWith(color: Colors.white.withValues(alpha: 0.9)),
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
                    ).copyWith(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color(0xFFFFE135).withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color(0xFFFFE135).withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color(0xFFFFE135),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.red.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                    counterStyle: FontScaling.getCaption(
                      context,
                    ).copyWith(color: Colors.white.withValues(alpha: 0.5)),
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
                    ).copyWith(color: Colors.white.withValues(alpha: 0.9)),
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
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      counterStyle: FontScaling.getCaption(context)
                          .copyWith(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFFFFE135).withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFFFFE135).withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFFFFE135),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.red.withValues(alpha: 0.5),
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.red, width: 2),
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
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(context);

                          final feedbackService = FeedbackService();
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          final textStyle = FontScaling.getBodyMedium(
                            context,
                          );

                          final success = await feedbackService.submitFeedback(
                            type: _selectedType,
                            message: _message,
                            contactEmail:
                                _contactEmail.isNotEmpty ? _contactEmail : null,
                          );

                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? l10n.feedbackSuccess
                                      : l10n.feedbackError,
                                  style: textStyle,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                backgroundColor:
                                    success ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFE135),
                        foregroundColor: Color(0xFF1A2238),
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
                      child: Text(
                        l10n.feedbackSubmit,
                        style: FontScaling.getButtonText(
                          context,
                        ).copyWith(color: Color(0xFF1A2238)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

