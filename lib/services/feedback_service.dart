import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../storage.dart';
import '../core/utils/app_logger.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Submit feedback to Firestore
  Future<bool> submitFeedback({
    required String type,
    required String message,
    String? contactEmail,
  }) async {
    try {
      // #region agent log
      AppLogger.info('📤 DEBUG: submitFeedback called - type=$type, messageLength=${message.length}, hasContactEmail=${contactEmail != null}');
      // #endregion

      final user = _auth.currentUser;
      // Require authentication (even anonymous) for Firestore security rules
      if (user == null) {
        // #region agent log
        AppLogger.error('📤 DEBUG: No user authenticated for feedback submission');
        // #endregion
        throw Exception('Please sign in to submit feedback');
      }

      final userId = user.uid;
      final userEmail = user.email;
      final displayName = user.displayName;

      // #region agent log
      AppLogger.info('📤 DEBUG: Submitting feedback - userId=$userId, isAnonymous=${user.isAnonymous}, hasEmail=${userEmail != null}');
      // #endregion

      // Get app version
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';

      // Detect platform
      final platform = switch (defaultTargetPlatform) {
        TargetPlatform.iOS => 'iOS',
        TargetPlatform.android => 'Android',
        TargetPlatform.windows => 'Windows',
        TargetPlatform.macOS => 'macOS',
        TargetPlatform.linux => 'Linux',
        TargetPlatform.fuchsia => 'Fuchsia',
      };

      final feedback = FeedbackItem(
        userId: userId,
        userEmail: userEmail,
        displayName: displayName,
        type: type,
        message: message.trim(),
        contactEmail: contactEmail?.trim(),
        appVersion: appVersion,
        platform: platform,
      );

      // #region agent log
      AppLogger.info('📤 DEBUG: Attempting to write feedback to Firestore - feedbackId=${feedback.id}');
      // #endregion

      await _firestore.collection('feedback').doc(feedback.id).set(feedback.toJson());

      // #region agent log
      AppLogger.success('📤 DEBUG: Feedback successfully written to Firestore - feedbackId=${feedback.id}');
      // #endregion

      AppLogger.success('✅ Feedback submitted: ${feedback.id}');
      return true;
    } catch (e, stack) {
      // #region agent log
      AppLogger.error('📤 DEBUG: Feedback submission failed - error=$e');
      AppLogger.info('Stack trace: $stack');
      // #endregion
      AppLogger.error('❌ Error submitting feedback: $e');
      return false;
    }
  }
}