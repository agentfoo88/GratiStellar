import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../storage.dart';
import '../font_scaling.dart';
import '../l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _triggerCloudSync(List<GratitudeStar> localStars) async {
    final firestoreService = FirestoreService();

    try {
      print('🔄 Triggering cloud sync with ${localStars.length} local stars');

      // Check if there's an old anonymous account to merge
      final mergedFromUid = await _checkForMergedAccount();

      if (mergedFromUid != null) {
        print('🔀 Merging data from anonymous account: $mergedFromUid');
        await firestoreService.mergeStarsFromAnonymousAccount(mergedFromUid, localStars);
      } else {
        // Check if cloud has data
        final hasCloudData = await firestoreService.hasCloudData();

        if (hasCloudData) {
          print('📥 Cloud has data, syncing...');
          // Don't just upload - sync to merge
          final mergedStars = await firestoreService.syncStars(localStars);
          await StorageService.saveGratitudeStars(mergedStars);
          print('✅ Synced ${mergedStars.length} stars');
        } else {
          print('📤 No cloud data, uploading local stars...');
          await firestoreService.uploadStars(localStars);
        }
      }

      print('✅ Cloud sync complete');
    } catch (e) {
      print('⚠️ Sync failed: $e');
      // Don't show error to user - local data is still safe
    }
  }

  Future<String?> _checkForMergedAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      return userDoc.data()?['mergedFromAnonymous'] as String?;
    } catch (e) {
      print('⚠️ Error checking for merged account: $e');
      return null;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: FontScaling.getBodySmall(context).copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = l10n.errorEmailPassword;
      });
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _errorMessage = l10n.errorValidEmail;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = l10n.errorPasswordLength;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        // Get local stars before linking
        final localStars = await StorageService.loadGratitudeStars();

        await _authService.linkEmailPassword(email, password);

        if (mounted) {
          Navigator.of(context).pop();

          // Pass local stars to sync
          _showSuccessSnackBar(l10n.accountCreatedSuccess);

          // Trigger sync in the background
          _triggerCloudSync(localStars);
        }
      } else {
        await _authService.signInWithEmail(email, password);

        if (mounted) {
          Navigator.of(context).pop();
          _showSuccessSnackBar(l10n.signInSuccess);

          // Trigger sync in the background
          _triggerCloudSync(await StorageService.loadGratitudeStars());
        }
      }
    } catch (e) {  // ADDED catch block
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String error) {
    final l10n = AppLocalizations.of(context)!;
    print('Firebase error: $error');

    if (error.contains('email-already-in-use')) {
      return l10n.errorEmailInUse;
    } else if (error.contains('invalid-email')) {
      return l10n.errorInvalidEmail;
    } else if (error.contains('weak-password')) {
      return l10n.errorWeakPassword;
    } else if (error.contains('user-not-found')) {
      return l10n.errorUserNotFound;
    } else if (error.contains('wrong-password')) {
      return l10n.errorWrongPassword;
    } else if (error.contains('invalid-credential')) {
      return _isSignUp ? l10n.errorEmailInUse : l10n.errorInvalidCredential;
    } else if (error.contains('credential-already-in-use')) {
      return l10n.errorCredentialInUse;
    } else if (error.contains('too-many-requests')) {
      return l10n.errorTooManyRequests;
    } else if (error.contains('network-request-failed')) {
      return l10n.errorNetworkFailed;
    } else if (error.contains('No user signed in')) {
      return l10n.errorNoUserSignedIn;
    } else if (error.contains('Account is already linked')) {
      return l10n.errorAlreadyLinked;
    } else {
      return '${l10n.errorGeneric}\n${error.split(':').last.trim()}';
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A6FA5),
              Color(0xFF166088),
              Color(0xFF0B1426),
              Color(0xFF2C3E50),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      FontScaling.getResponsiveSpacing(context, 24),
                    ),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isSignUp ? l10n.signUpTitle : l10n.signInTitle,
                            style: FontScaling.getHeadingLarge(context).copyWith(
                              color: Color(0xFFFFE135),
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: FontScaling.getResponsiveSpacing(context, 8)),

                          Text(
                            _isSignUp ? l10n.signUpSubtitle : l10n.signInSubtitle,
                            style: FontScaling.getBodyMedium(context).copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: FontScaling.getResponsiveSpacing(context, 32)),

                          TextField(
                            controller: _emailController,
                            enabled: !_isLoading,
                            keyboardType: TextInputType.emailAddress,
                            style: FontScaling.getInputText(context),
                            decoration: InputDecoration(
                              labelText: l10n.emailLabel,
                              labelStyle: FontScaling.getBodySmall(context),
                              hintText: l10n.emailHint,
                              hintStyle: FontScaling.getInputHint(context),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              prefixIcon: Icon(Icons.email, color: Color(0xFFFFE135)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Color(0xFFFFE135).withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Color(0xFFFFE135).withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Color(0xFFFFE135),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),

                          TextField(
                            controller: _passwordController,
                            enabled: !_isLoading,
                            obscureText: true,
                            style: FontScaling.getInputText(context),
                            decoration: InputDecoration(
                              labelText: l10n.passwordLabel,
                              labelStyle: FontScaling.getBodySmall(context),
                              hintText: l10n.passwordHint,
                              hintStyle: FontScaling.getInputHint(context),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              prefixIcon: Icon(Icons.lock, color: Color(0xFFFFE135)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Color(0xFFFFE135).withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Color(0xFFFFE135).withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Color(0xFFFFE135),
                                  width: 2,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _handleSubmit(),
                          ),

                          if (_errorMessage != null) ...[
                            SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
                            Container(
                              padding: EdgeInsets.all(
                                FontScaling.getResponsiveSpacing(context, 12),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: FontScaling.getBodySmall(context).copyWith(
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFFE135),
                                padding: EdgeInsets.symmetric(
                                  vertical: FontScaling.getResponsiveSpacing(context, 16),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF1A2238),
                                  ),
                                ),
                              )
                                  : Text(
                                _isSignUp ? l10n.signUpButton : l10n.signInButton,
                                style: FontScaling.getButtonText(context).copyWith(
                                  color: Color(0xFF1A2238),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),

                          TextButton(
                            onPressed: _isLoading ? null : () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                                _errorMessage = null;
                              });
                            },
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: FontScaling.getBodySmall(context),
                                children: [
                                  TextSpan(
                                    text: _isSignUp
                                        ? '${l10n.alreadyHaveAccount}\n'
                                        : '${l10n.needToLinkAccount}\n',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                                  ),
                                  TextSpan(
                                    text: _isSignUp ? l10n.signInToggle : l10n.signUpToggle,
                                    style: TextStyle(
                                      color: Color(0xFFFFE135),
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}