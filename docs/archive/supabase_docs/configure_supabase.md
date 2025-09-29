# Quick Supabase Configuration Steps

## Step 1: Enable Email OTP in Supabase Dashboard

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project: `veeskeibmbbzrwdhqnoj`
3. Navigate to **Authentication** → **Providers**
4. Find **Email** and click to configure:
   - ✅ Enable Email Provider
   - ✅ Enable Email OTP
   - ❌ Disable Password (uncheck)
   - Set OTP Expiry: 600 seconds

## Step 2: Run SQL Configuration

Copy and run this in your SQL Editor:

```sql
-- Already provided in auth_config.sql
-- This sets up user profiles, triggers, and rate limiting
```

## Step 3: Configure Google OAuth

1. In Supabase Dashboard → **Authentication** → **Providers**
2. Enable **Google** provider
3. Add these details:
   - Client ID: [Your Web Client ID]
   - Client Secret: [Your Client Secret]
   - Authorized Redirect URI: `https://veeskeibmbbzrwdhqnoj.supabase.co/auth/v1/callback`

## Step 4: Update Email Templates

In **Authentication** → **Email Templates** → **OTP**:

### Subject:
```
Your Streaker Verification Code
```

### Email Body:
Use the HTML template from `configure_auth.js` (lines 27-99)

## Step 5: Update Your Flutter App

Add these to your environment variables or directly in the app:

```dart
// In lib/services/supabase_service.dart
static const String supabaseUrl = 'https://veeskeibmbbzrwdhqnoj.supabase.co';
static const String supabaseAnonKey = 'YOUR_ANON_KEY_HERE';
```

## Step 6: Configure Google Sign-In

### For Android:
1. Get SHA-1 fingerprint:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

2. Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data 
    android:name="com.google.android.gms.auth.api.signin.CLIENT_ID"
    android:value="YOUR_ANDROID_CLIENT_ID" />
```

### For iOS (if applicable):
Add to `ios/Runner/Info.plist`:
```xml
<key>GIDClientID</key>
<string>YOUR_IOS_CLIENT_ID</string>
```

## Quick Test

After configuration:
1. Test Email OTP: Enter email → Receive 6-digit code → Verify
2. Test Google SSO: Click "Continue with Google" → Select account → Redirect back

## Troubleshooting

- **No OTP received**: Check spam folder, verify SMTP settings
- **Google sign-in fails**: Verify client IDs match platform
- **Rate limiting**: Check `otp_rate_limits` table in database