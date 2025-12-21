# Using Breakpoints to Debug Issues

Since Logcat isn't showing much, you can use breakpoints to inspect what's happening.

## Key Breakpoints to Set

### For Firebase Sync Issue:

1. **In `lib/screens/sign_in_screen.dart`:**
   - Line ~195: `await _authService.signInWithEmail(email, password);`
   - Line ~205: `await _triggerCloudSync();`
   - Line ~40: Start of `_triggerCloudSync()` method

2. **In `lib/services/auth_service.dart`:**
   - Line ~153: Start of `signInWithEmail()` method
   - Line ~21: `hasEmailAccount` getter

3. **In `lib/services/firestore_service.dart`:**
   - Line ~145: Start of `downloadDeltaStars()` method
   - Line ~299: Start of `syncStars()` method

4. **In `lib/features/gratitudes/presentation/state/gratitude_provider.dart`:**
   - Line ~150: Start of `loadGratitudes()` method
   - Line ~171: Where stars are filtered by galaxyId

### For Feedback Submission Issue:

1. **In `lib/features/gratitudes/presentation/widgets/feedback_dialog.dart`:**
   - Line ~309: `onPressed` handler
   - Line ~328: `await feedbackService.submitFeedback(...)`
   - Line ~340: `Navigator.pop(context)`

2. **In `lib/services/feedback_service.dart`:**
   - Line ~14: Start of `submitFeedback()` method
   - Line ~50: `await _firestore.collection('feedback')...`

## How to Use Breakpoints

1. **Set a breakpoint:**
   - Click in the left margin (gutter) next to the line number
   - A red dot appears

2. **Run in debug mode:**
   - Click the green bug icon (not the play icon)
   - Or Run > Debug 'main.dart'

3. **When breakpoint hits:**
   - Execution pauses
   - Variables panel shows current values
   - You can hover over variables to see their values
   - Call Stack shows where you are

4. **Step through code:**
   - **F8** (Step Over) - Execute current line, move to next
   - **F7** (Step Into) - Go into function calls
   - **Shift+F8** (Step Out) - Exit current function
   - **F9** (Resume) - Continue execution

5. **Inspect values:**
   - Look at Variables panel (usually on left)
   - Hover over variables in code
   - Use "Evaluate Expression" (Alt+F8) to run code

## What to Check at Each Breakpoint

### At sign-in breakpoint:
- Check `user?.uid` - Is user signed in?
- Check `user?.isAnonymous` - Is user anonymous or has email?
- Check `user?.email` - What email is associated?

### At sync breakpoint:
- Check `localStars.length` - How many local stars?
- Check `hasCloudData` - Does cloud have data?
- Check `mergedStars.length` - How many after sync?

### At loadGratitudes breakpoint:
- Check `activeGalaxyId` - What galaxy is active?
- Check `purgedStars.length` - How many stars before filtering?
- Check `_gratitudeStars.length` - How many after filtering?

### At feedback breakpoint:
- Check `_isSubmitting` - Is submission flag set?
- Check `success` - Did submission succeed?
- Check if `Navigator.pop()` is being called

## Quick Debug Session

1. Set breakpoint at sign-in line
2. Sign in with email
3. When breakpoint hits, check Variables panel for user info
4. Press F8 to continue
5. Set breakpoint at `_triggerCloudSync`
6. When it hits, check if `hasEmailAccount` is true
7. Step through sync to see where it fails

