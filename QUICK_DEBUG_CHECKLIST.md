# Quick Debug Checklist

## Before Starting

1. **Make sure you're running in DEBUG mode:**
   - Click the **green bug icon** (🐛) not the green play icon (▶️)
   - Or: Run > Debug 'main.dart'
   - Check the bottom status bar - should say "Debug" not "Run"

2. **Configure Logcat:**
   - Open Logcat (View > Tool Windows > Logcat)
   - Click gear icon (⚙️) in Logcat toolbar
   - **Uncheck** "Show only selected application"
   - Set log level to **"Verbose"** (shows all logs)
   - Clear any search filters

3. **Clear old logs:**
   - Click trash icon (🗑️) in Logcat

## Quick Test - Verify Logging Works

1. Run app in debug mode
2. Look for these logs in Logcat (should appear immediately):
   - `🚀 [START] 🚀 App starting...`
   - `📦 [DATA]  Initializing Firebase...`
   - `✅ [SUCCESS] ✅ Firebase initialized`

If you DON'T see these logs:
- App might not be running in debug mode
- Logcat filter might be too restrictive
- Try "No Filters" in Logcat dropdown

## What You Should See

When you sign in, you should see logs like:
- `🔐 DEBUG: signInWithEmail called`
- `🔐 DEBUG: After signInWithEmail`
- `🔄 DEBUG: _triggerCloudSync started`
- `📥 DEBUG: downloadDeltaStars`
- `🔄 DEBUG: Merged stars summary`

If you don't see these:
- The code path isn't being executed
- Or logs are being filtered out

## Using Breakpoints (Alternative)

If logs still don't show:

1. Set breakpoint at line 195 in `sign_in_screen.dart`:
   ```dart
   await _authService.signInWithEmail(email, password);
   ```

2. Run in debug mode and sign in

3. When breakpoint hits:
   - Check Variables panel
   - Look for `email` and `password` values
   - Press F8 to continue

4. Set breakpoint at line 40 in `sign_in_screen.dart`:
   ```dart
   Future<void> _triggerCloudSync() async {
   ```

5. When it hits, check Variables panel for auth state

