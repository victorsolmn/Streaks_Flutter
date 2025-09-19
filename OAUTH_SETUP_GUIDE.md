# Google OAuth Setup Guide for Streaks Flutter

## ⚠️ IMPORTANT: Supabase Dashboard Configuration Required

To fix the Google OAuth redirect issue where Chrome redirects to localhost instead of returning to the app, you need to configure the following settings in your Supabase dashboard.

## 1. Supabase Dashboard Configuration

### Navigate to Authentication Settings
1. Go to your Supabase project dashboard
2. Click on **Authentication** in the left sidebar
3. Click on **URL Configuration**

### Add Redirect URLs
Add these URLs to the **Redirect URLs** section:
```
com.streaker.streaker://login-callback
com.streaker.streaker://
```

### Site URL Configuration
Set the **Site URL** to:
```
com.streaker.streaker://login-callback
```

## 2. Google Cloud Console Configuration

### OAuth 2.0 Client Configuration
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Navigate to **APIs & Services** > **Credentials**
4. Find your OAuth 2.0 Client ID
5. Add these to **Authorized redirect URIs**:
   - `https://YOUR_SUPABASE_PROJECT_ID.supabase.co/auth/v1/callback`
   - `com.streaker.streaker://login-callback`

## 3. Code Changes Applied

### ✅ Fixed Supabase Initialization
- Added PKCE flow for better security
- Enabled auto token refresh

### ✅ Fixed Google OAuth Method
- Added explicit `redirectTo` parameter
- Set `authScreenLaunchMode` to `externalApplication`
- Configured proper callback URL

### ✅ Deep Link Configuration
Both Android and iOS are already configured with the correct URL scheme:
- **Android**: `com.streaker.streaker` (AndroidManifest.xml)
- **iOS**: `com.streaker.streaker` (Info.plist)

## 4. Testing the Fix

### On Real Device:
1. Sign out if already logged in
2. Click "Sign in with Google"
3. Chrome should open
4. Select your Google account
5. App should automatically open and log you in

### On Simulator/Emulator:
- iOS Simulator: May have limitations with OAuth redirects
- Android Emulator: Should work if properly configured

## 5. Troubleshooting

### If still redirecting to localhost:
1. **Clear browser cache** in Chrome
2. **Check Supabase Dashboard** redirect URLs are saved
3. **Verify** the app bundle ID matches: `com.streaker.streaker`
4. **Ensure** you're using the latest app build

### Common Issues:
- **"Invalid redirect URI"**: Check Supabase dashboard configuration
- **App doesn't open**: Verify deep link configuration in AndroidManifest.xml/Info.plist
- **Auth fails silently**: Check debug logs in console

## 6. Alternative Login Methods

While OAuth is being configured, users can:
- Use **Email/Password** authentication
- Sign up with email and password
- All features work the same regardless of login method

## Technical Details

### OAuth Flow:
1. User clicks "Sign in with Google"
2. App opens Chrome with Supabase OAuth URL
3. User authenticates with Google
4. Google redirects to Supabase callback
5. Supabase redirects to `com.streaker.streaker://login-callback`
6. App handles deep link and completes authentication

### Security:
- Using PKCE (Proof Key for Code Exchange) for enhanced security
- Tokens are automatically refreshed
- Sessions are securely stored

---
**Last Updated**: December 2024
**Status**: Implementation Complete - Requires Dashboard Configuration