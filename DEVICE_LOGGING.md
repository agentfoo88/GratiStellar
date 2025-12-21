# Getting Debug Logs from Android Device

## Using Android Studio Logcat (Recommended)

Android Studio has a built-in Logcat viewer that's the easiest way to view logs.

### Steps:

1. **Open Logcat in Android Studio:**
   - Go to **View > Tool Windows > Logcat** (or click the Logcat tab at the bottom)
   - If you don't see it, it's usually at the bottom of the Android Studio window

2. **Select your device:**
   - At the top of Logcat, use the device dropdown to select your connected Android device
   - Make sure your app package is selected (usually shows as `com.example.gratistellar` or similar)

3. **Configure Logcat settings:**
   - Click the gear icon (⚙️) in Logcat toolbar
   - **IMPORTANT:** Uncheck "Show only selected application" (or set to "No Filters")
   - Set log level to "Verbose" to see all logs
   - This ensures you see all our debug logs

4. **Filter logs:**
   - In the search box at the top of Logcat, enter: `DEBUG|SYNC|AUTH|ERROR|gratistellar`
   - **OR** clear the search box and set log level to "Info" or "Debug" to see our logs
   - Check the regex checkbox if you want regex filtering

4. **Clear logs before testing:**
   - Click the trash can icon (🗑️) in Logcat toolbar to clear old logs
   - This gives you a clean slate

5. **Reproduce the issue:**
   - Now perform the action you want to debug (submit feedback, sign in, etc.)
   - Watch the logs appear in real-time

6. **Save logs (optional):**
   - Right-click in the Logcat window
   - Select **Save Logcat to File...**
   - Choose a location and save

### What to Look For

Our instrumentation logs are prefixed with:
- `📥 DEBUG:` - Firebase sync downloads
- `🔄 DEBUG:` - Sync operations  
- `📋 DEBUG:` - Loading/filtering operations
- `📤 DEBUG:` - Feedback submission
- `✅ DEBUG:` - Success operations
- `❌ DEBUG:` - Error operations

### Logcat Tips:

- **Use regex filtering:** Check the regex checkbox next to the search box for more powerful filtering
- **Filter by tag:** You can filter by specific tags like `flutter`, `DartVM`, or custom tags
- **Filter by package:** Select your app package from the dropdown to see only your app's logs
- **Color coding:** Logcat color-codes logs by severity (red for errors, yellow for warnings, etc.)

## Alternative: Command Line (if needed)

If you prefer command line or need to automate:

### Using adb logcat:
```bash
# View filtered logs in real-time
adb logcat | Select-String -Pattern "DEBUG|SYNC|AUTH|ERROR|gratistellar"

# Save to file
adb logcat > device_logs.txt
```

### Using PowerShell script:
Run `.\get_device_logs.ps1` (if you have the script)

## Using Android Studio Debug Mode

When running in debug mode (clicking the debug button), you can:

1. **Set Breakpoints:**
   - Click in the left margin next to any line of code to set a breakpoint
   - When the app hits that line, execution pauses
   - You can inspect variable values in the Variables panel
   - Press F8 to step over, F7 to step into

2. **View Logs:**
   - Logcat still works the same way in debug mode
   - Make sure Logcat is visible (View > Tool Windows > Logcat)
   - The logs appear in real-time as you debug

3. **Debug Console:**
   - The Debug Console shows output from your app
   - Look for the "Debug" tab at the bottom of Android Studio

## Troubleshooting

**Logcat not showing logs:**
- Make sure your device is selected in the device dropdown
- Make sure your app is running in **debug mode** (not release mode)
- Check Logcat filter settings:
  - Click the filter dropdown (usually says "Show only selected application" or "No Filters")
  - Try "No Filters" to see all logs
  - Or select your app package name
- Try clicking the refresh icon in Logcat
- Check that USB debugging is enabled on your device
- Make sure you're running a **debug build** (not release)

**Logcat shows "No debuggable processes":**
- Make sure you're running the app in debug mode (green bug icon, not green play icon)
- Or use "Run" instead of "Debug" - logs will still appear

**Too many logs:**
- Use the filter/search box to narrow down
- Filter by log level (Error, Warn, Info)
- Filter by package name (your app)
- In search box, enter: `DEBUG|SYNC|AUTH|ERROR` to see only our debug logs

**Logs not appearing:**
- Check if you're filtering by log level - try "Verbose" level
- Clear the search box and try again
- Restart the app
- Check Android Studio's Logcat settings (gear icon) - make sure "Show only selected application" is unchecked

