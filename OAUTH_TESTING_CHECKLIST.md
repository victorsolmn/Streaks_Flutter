# Google OAuth Testing Checklist

## ✅ Configuration Complete

### Supabase Dashboard Settings (Confirmed by User)
- ✅ Site URL: `com.streaker.streaker://login-callback`
- ✅ Redirect URLs:
  - `com.streaker.streaker://login-callback`
  - `com.streaker.streaker://`

### Code Changes Applied
- ✅ PKCE flow enabled in Supabase initialization
- ✅ Auto token refresh enabled
- ✅ Redirect URL explicitly set in OAuth method
- ✅ Launch mode set to `externalApplication`

### Deep Link Configuration (Already in Place)
- ✅ Android: `com.streaker.streaker` scheme in AndroidManifest.xml
- ✅ iOS: `com.streaker.streaker` URL scheme in Info.plist

## 🧪 Testing Steps

### On Real Device (Recommended)

1. **Build and Install App**
   ```bash
   # For iOS
   flutter build ios --release
   # Install via Xcode to device

   # For Android
   flutter build apk --release
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

2. **Test Google Sign-In Flow**
   - Open the app
   - Navigate to Sign In screen
   - Tap "Sign in with Google"
   - Chrome browser should open
   - Select your Google account
   - Grant permissions if prompted
   - **Expected**: App should automatically reopen and log you in
   - **Success**: You should see the main app screen

3. **Test New User Sign-Up**
   - Sign out if logged in
   - Navigate to Sign Up screen
   - Tap "Sign up with Google"
   - Complete Google authentication
   - **Expected**: New user profile created and logged in

### Verification Points

✅ **Working Correctly If:**
- Chrome opens with Google sign-in page
- After authentication, app reopens automatically
- User is logged in successfully
- Profile data is loaded

❌ **Still Has Issues If:**
- Redirects to localhost URL
- App doesn't reopen after authentication
- Shows "can't connect to server" error
- Authentication fails silently

## 🔍 Troubleshooting

### If Still Redirecting to Localhost:

1. **Clear Browser Data**
   ```
   Settings > Apps > Chrome > Storage > Clear Data
   ```

2. **Verify Supabase Settings Saved**
   - Go back to Supabase dashboard
   - Check that redirect URLs are still there
   - Click "Save" again if needed

3. **Check Bundle ID**
   - iOS: Verify in Xcode that Bundle ID is `com.streaker.streaker`
   - Android: Check applicationId in `android/app/build.gradle.kts`

4. **Force Rebuild**
   ```bash
   flutter clean
   flutter pub get
   flutter build [ios/apk]
   ```

### Debug Mode Testing

To see OAuth flow details:
1. Run app in debug mode: `flutter run`
2. Watch console for OAuth debug messages
3. Look for:
   - `🔐 Starting Google OAuth sign-in...`
   - `📨 OAuth response received`
   - `✅ OAuth initiated successfully`

### Alternative Testing (Simulator/Emulator)

**Note**: OAuth may have limitations on simulators

1. **Android Emulator**: Should work if Google Play Services installed
2. **iOS Simulator**: May fail due to simulator restrictions
   - Test email/password login as fallback
   - Use real device for OAuth testing

## 📊 Expected OAuth Flow

1. User taps "Sign in with Google"
2. App calls `signInWithOAuth` with redirect URL
3. Chrome opens: `https://accounts.google.com/...`
4. User authenticates with Google
5. Google redirects to Supabase callback
6. Supabase redirects to: `com.streaker.streaker://login-callback`
7. App handles deep link
8. Session established, user logged in

## ✅ Success Criteria

- [ ] Google OAuth works on Android device
- [ ] Google OAuth works on iOS device
- [ ] New users can sign up via Google
- [ ] Existing users can sign in via Google
- [ ] Email/password login still works
- [ ] No UI disruptions or errors

## 📝 Notes

- OAuth redirect URL must match exactly
- Deep links are case-sensitive
- Clear browser cache if testing multiple times
- Supabase session persists across app restarts

---
**Status**: Ready for Testing
**Last Updated**: December 2024