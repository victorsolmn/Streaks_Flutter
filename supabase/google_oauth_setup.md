# Google OAuth Setup for Streaker App

## Prerequisites
- Google Cloud Console account
- Access to Supabase Dashboard
- Your app's package name: `com.streaker.streaker`

## Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Click "Select a project" → "New Project"
3. Project name: `Streaker Fitness App`
4. Click "Create"

## Step 2: Enable Required APIs

1. In your project, go to **APIs & Services** → **Enable APIs and Services**
2. Search and enable these APIs:
   - Google+ API
   - Google Sign-In API
   - People API

## Step 3: Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Choose **External** user type
3. Fill in the details:
   - App name: `Streaker`
   - User support email: Your email
   - App logo: Upload Streaker logo
   - Application home page: `https://streaker.app`
   - Privacy policy: `https://streaker.app/privacy`
   - Terms of service: `https://streaker.app/terms`
   - Developer contact: Your email
4. Add scopes:
   - `email`
   - `profile`
   - `openid`
5. Add test users if in development
6. Save and continue

## Step 4: Create OAuth Credentials

### Web Application (Required for Supabase)

1. Go to **Credentials** → **Create Credentials** → **OAuth client ID**
2. Application type: **Web application**
3. Name: `Streaker Web (Supabase)`
4. Authorized redirect URIs:
   ```
   https://veeskeibmbbzrwdhqnoj.supabase.co/auth/v1/callback
   ```
5. Click "Create"
6. **SAVE THESE**:
   - Client ID: `[YOUR_WEB_CLIENT_ID].apps.googleusercontent.com`
   - Client Secret: `[YOUR_CLIENT_SECRET]`

### Android Application

1. Create another OAuth client ID
2. Application type: **Android**
3. Name: `Streaker Android`
4. Package name: `com.streaker.streaker`
5. SHA-1 certificate fingerprint:

   **For Debug (Development):**
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

   **For Release (Production):**
   ```bash
   keytool -list -v -keystore [path-to-your-keystore] -alias [your-alias]
   ```

6. Click "Create"
7. **SAVE**: Android Client ID

### iOS Application (Optional - if you have iOS app)

1. Create another OAuth client ID
2. Application type: **iOS**
3. Name: `Streaker iOS`
4. Bundle ID: `com.streaker.streaker`
5. Click "Create"
6. **SAVE**: iOS Client ID

## Step 5: Configure in Supabase

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Navigate to **Authentication** → **Providers**
4. Find **Google** and enable it
5. Enter credentials:
   - **Client ID**: Use the Web Application Client ID
   - **Client Secret**: Use the Web Application Client Secret
   - Skip domain whitelist (or add your domains)
6. Click "Save"

## Step 6: Update Flutter App

### Update Android Configuration

1. Open `android/app/src/main/AndroidManifest.xml`
2. Add inside `<application>` tag:

```xml
<!-- Google Sign-In Configuration -->
<meta-data 
    android:name="com.google.android.gms.auth.api.signin.CLIENT_ID"
    android:value="[YOUR_ANDROID_CLIENT_ID].apps.googleusercontent.com" />

<!-- Deep linking for OAuth callback -->
<activity
    android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
    android:exported="true">
    <intent-filter android:label="flutter_web_auth_2">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="com.streaker.streaker" />
    </intent-filter>
</activity>
```

### Update iOS Configuration (if applicable)

1. Open `ios/Runner/Info.plist`
2. Add:

```xml
<!-- Google Sign-In Configuration -->
<key>GIDClientID</key>
<string>[YOUR_IOS_CLIENT_ID].apps.googleusercontent.com</string>

<!-- URL Schemes -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.streaker.streaker</string>
            <!-- Reversed iOS Client ID -->
            <string>com.googleusercontent.apps.[YOUR_IOS_CLIENT_ID]</string>
        </array>
    </dict>
</array>
```

### Update Flutter Code

1. Create environment configuration file:

```dart
// lib/config/auth_config.dart
class AuthConfig {
  // Web Client ID (used by Supabase)
  static const String googleWebClientId = '[YOUR_WEB_CLIENT_ID].apps.googleusercontent.com';
  
  // Platform-specific (optional, for native sign-in)
  static const String googleAndroidClientId = '[YOUR_ANDROID_CLIENT_ID].apps.googleusercontent.com';
  static const String googleIosClientId = '[YOUR_IOS_CLIENT_ID].apps.googleusercontent.com';
}
```

## Step 7: Test the Integration

### Test Checklist:
- [ ] Click "Continue with Google" on Sign In screen
- [ ] Google account selection appears
- [ ] User can select account
- [ ] App receives user data (email, name)
- [ ] User is logged in successfully
- [ ] Profile shows Google account info

### Common Issues & Solutions:

**Issue: "Unauthorized client" error**
- Solution: Ensure redirect URI matches exactly in Google Console and Supabase

**Issue: Sign-in popup doesn't appear**
- Solution: Check that Android Client ID is in AndroidManifest.xml

**Issue: "Developer error" on Android**
- Solution: SHA-1 fingerprint doesn't match. Re-generate and update in Google Console

**Issue: Redirect doesn't work**
- Solution: Check deep link configuration in AndroidManifest.xml

## Step 8: Production Deployment

Before releasing to production:

1. **Update SHA-1 fingerprints**:
   - Add production keystore SHA-1 to Google Console
   - Keep debug SHA-1 for development

2. **Verify OAuth consent screen**:
   - Submit for verification if needed
   - Ensure all links work (privacy, terms)

3. **Update redirect URIs**:
   - Add any custom domain redirects
   - Keep Supabase redirect URI

4. **Test on real devices**:
   - Test on various Android versions
   - Test on different device manufacturers

## Security Best Practices

1. **Never commit credentials**:
   - Use environment variables
   - Add to `.gitignore`

2. **Restrict API keys**:
   - Set Android/iOS restrictions in Google Console
   - Limit to your app's package/bundle ID

3. **Monitor usage**:
   - Check Google Cloud Console for unusual activity
   - Set up alerts for quota limits

## Quick Reference

### Required Credentials:
- **Supabase Dashboard**: Web Client ID + Secret
- **Android App**: Android Client ID
- **iOS App**: iOS Client ID

### Test URLs:
- Google Console: https://console.cloud.google.com
- Supabase Dashboard: https://app.supabase.com
- OAuth Playground: https://developers.google.com/oauthplayground/

## Support Resources

- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)