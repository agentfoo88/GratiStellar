# Testing the ErrorHandler System

## Quick Compilation Test

Run Flutter analyzer on the error handling code:

```bash
flutter analyze lib/core/error/
```

Expected: No errors (only info messages about prints in test file are OK)

---

## Manual Testing Options

### Option 1: Run the Test Suite (Recommended)

Add this to your `main.dart` temporarily (before `runApp`):

```dart
import 'core/error/error_handler_test.dart';

void main() async {
  // ... existing Firebase initialization ...

  // Run ErrorHandler tests
  await ErrorHandlerTest.runAllTests();

  runApp(MyApp());
}
```

This will print comprehensive test results to console showing:
- Error mapping (Firebase exceptions → user-friendly messages)
- Retry policy calculations
- Retry logic with automatic backoff
- Non-retriable error handling

### Option 2: Test Individual Components

You can test individual methods interactively:

```dart
// Test 1: Simple error handling
try {
  throw FirebaseAuthException(code: 'wrong-password');
} catch (e, stack) {
  final error = ErrorHandler.handle(
    e,
    stack,
    context: ErrorContext.auth,
  );
  print('User message: ${error.userMessage}');
  // Prints: "Incorrect password. Please try again."
}

// Test 2: Retry with exponential backoff
try {
  await ErrorHandler.withRetry(
    operation: () async {
      // Your risky operation here
      await someFirestoreOperation();
    },
    context: ErrorContext.sync,
    policy: RetryPolicy.sync,
  );
} catch (e, stack) {
  final error = ErrorHandler.handle(e, stack, context: ErrorContext.sync);
  showSnackBar(error.userMessage);
}
```

---

## Expected Test Results

### ✅ Test 1: Firebase Auth Exception
- **Input:** `FirebaseAuthException(code: 'wrong-password')`
- **Expected user message:** "Incorrect password. Please try again."
- **Severity:** Error
- **Retriable:** false

### ✅ Test 2: Rate Limit Exception
- **Input:** `RateLimitException('sync_operation', Duration(minutes: 5))`
- **Expected user message:** "Rate limit exceeded. Please try again in 5 minutes."
- **Retriable:** false (don't auto-retry rate limits)

### ✅ Test 3: Timeout Exception
- **Input:** `TimeoutException('Operation timed out')`
- **Expected user message:** "Operation timed out. Please check your connection and try again."
- **Retriable:** true

### ✅ Test 4: Firestore Permission Denied
- **Input:** `FirebaseException(code: 'permission-denied')`
- **Expected user message:** "Permission denied. Please sign in again."
- **Retriable:** false

### ✅ Test 5: Unknown Exception
- **Input:** `Exception('Something unexpected')`
- **Expected user message:** "An unexpected error occurred."
- **Retriable:** false

### ✅ Test 6: Retry Policy Delays
- **Sync policy (exponential):**
  - Attempt 1: 2 minutes
  - Attempt 2: 4 minutes
  - Attempt 3: 8 minutes

- **Quick policy (constant):**
  - Attempt 1: 30 seconds
  - Attempt 2: 30 seconds

### ✅ Test 7: Retry Logic
- Operation fails with `unavailable` error (retriable)
- Should retry automatically up to 3 times
- Should succeed on 3rd attempt

### ✅ Test 8: Non-Retriable Error
- Operation throws `RateLimitException`
- Should NOT retry (stops immediately after 1 attempt)

---

## Integration Verification

After basic tests pass, verify integration:

1. **Check localization works:**
   ```bash
   # Verify new error strings are generated
   grep -r "errorEmailInUse" lib/l10n/
   ```
   Should find the string in generated localization files.

2. **Check Crashlytics integration:**
   - Trigger an error with severity `ErrorSeverity.error`
   - Verify custom keys are set in Crashlytics
   - Check Firebase Console for error report

3. **Check AppLogger integration:**
   - Run app in debug mode
   - Trigger errors
   - Verify console shows proper emoji tags and messages

---

## Cleanup After Testing

Once testing is complete:

1. Remove test invocation from `main.dart`
2. Delete `lib/core/error/error_handler_test.dart` (or keep for reference)
3. Delete this `README_TESTING.md` file

---

## Next Steps

Once testing confirms everything works:

1. **Phase 2:** Refactor `galaxy_list_dialog.dart` to use ErrorHandler
2. **Phase 2:** Refactor `sign_in_screen.dart` to use ErrorHandler
3. **Phase 3:** Replace manual retry logic in `gratitude_provider.dart`

See the main implementation plan for details.
