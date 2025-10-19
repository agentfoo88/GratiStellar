import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../storage.dart';

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
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      // Get app version
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';

      // Detect platform
      final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'iOS' : 'Android';

      final feedback = FeedbackItem(
        userId: user.uid,
        userEmail: user.email,
        displayName: user.displayName,
        type: type,
        message: message.trim(),
        contactEmail: contactEmail?.trim(),
        appVersion: appVersion,
        platform: platform,
      );

      await _firestore.collection('feedback').doc(feedback.id).set(feedback.toJson());

      print('✅ Feedback submitted: ${feedback.id}');
      return true;
    } catch (e) {
      print('❌ Error submitting feedback: $e');
      return false;
    }
  }
}