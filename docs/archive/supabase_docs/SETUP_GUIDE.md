# Supabase Authentication Setup Guide

## Prerequisites
1. Access to your Supabase Dashboard
2. Google Cloud Console account for OAuth setup

## Step 1: Run SQL Configuration

1. Go to your [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Navigate to **SQL Editor** in the left sidebar
4. Create a new query
5. Copy and paste the contents of `auth_config.sql`
6. Click **Run** to execute the script

## Step 2: Configure Email Authentication

### Enable Email Provider
1. Go to **Authentication** → **Providers**
2. Find **Email** in the list
3. Toggle it **ON**
4. Configure the following settings:
   - ✅ Enable Email Signup
   - ✅ Enable Email OTP (Magic Link)
   - ❌ Disable Email/Password signup (uncheck)
   - OTP Expiry: 600 seconds (10 minutes)

### Configure Email Templates
1. Go to **Authentication** → **Email Templates**
2. Select **Magic Link** template
3. Replace with the following:

**Subject:** `Your Streaker Verification Code`

**Body:**
```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { text-align: center; margin-bottom: 30px; }
    .logo { color: #FF6B35; font-size: 32px; font-weight: bold; }
    .code-box { 
      background: linear-gradient(135deg, #FF6B35 0%, #F46E2B 100%);
      color: white;
      padding: 20px;
      border-radius: 12px;
      text-align: center;
      margin: 30px 0;
    }
    .code { 
      font-size: 40px;
      letter-spacing: 10px;
      font-weight: bold;
      margin: 10px 0;
    }
    .footer { 
      text-align: center;
      color: #666;
      font-size: 12px;
      margin-top: 40px;
    }
    .tip {
      background: #fff3cd;
      border-left: 4px solid #ffc107;
      padding: 15px;
      margin: 20px 0;
      color: #856404;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">🔥 STREAKER</div>
      <p style="color: #666;">Your Fitness Journey Companion</p>
    </div>
    
    <h2>Verification Code</h2>
    <p>Hi there! Use this code to complete your sign in:</p>
    
    <div class="code-box">
      <div class="code">{{ .Token }}</div>
      <p style="margin: 0; opacity: 0.9;">Valid for 10 minutes</p>
    </div>
    
    <div class="tip">
      <strong>📧 Can't find this email?</strong><br>
      Check your spam or junk folder. Add noreply@streaker.app to your contacts to prevent this.
    </div>
    
    <div class="footer">
      <p>If you didn't request this code, please ignore this email.</p>
      <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
      <p>© 2024 Streaker • <a href="https://streaker.app" style="color: #FF6B35;">streaker.app</a></p>
    </div>
  </div>
</body>
</html>
```

## Step 3: Configure Google OAuth

### Create Google OAuth Credentials
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing
3. Enable **Google+ API** and **Google Sign-In API**
4. Go to **Credentials** → **Create Credentials** → **OAuth client ID**

### For Web Application
1. Application type: **Web application**
2. Name: `Streaker Web`
3. Authorized redirect URIs:
   ```
   https://njlafkaqjjtozdbiwjtj.supabase.co/auth/v1/callback
   ```
4. Save the Client ID and Client Secret

### For iOS
1. Create new OAuth client ID
2. Application type: **iOS**
3. Bundle ID: `com.streaker.streaker`
4. Save the iOS Client ID

### For Android
1. Create new OAuth client ID
2. Application type: **Android**
3. Package name: `com.streaker.streaker`
4. SHA-1 certificate fingerprint: (get from your keystore)
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
5. Save the Android Client ID

### Enable in Supabase
1. Go to **Authentication** → **Providers**
2. Find **Google** and enable it
3. Enter your credentials:
   - Client ID: (from Web application)
   - Client Secret: (from Web application)
4. Click **Save**

## Step 4: Configure SMTP (Optional - for custom emails)

1. Go to **Settings** → **SMTP Settings**
2. Enable custom SMTP
3. Enter your SMTP details:
   - Host: `smtp.gmail.com` (for Gmail)
   - Port: `587`
   - Username: Your email
   - Password: App-specific password
   - From Email: `noreply@streaker.app`
   - From Name: `Streaker`

## Step 5: Update Flutter App Configuration

### Update Android Configuration

1. Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<!-- Add inside <application> tag -->
<meta-data 
    android:name="com.google.android.gms.auth.api.signin.CLIENT_ID"
    android:value="YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com" />

<!-- Add intent filter for deep linking -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data 
        android:scheme="com.streaker.streaker"
        android:host="callback" />
</intent-filter>
```

### Update iOS Configuration

1. Edit `ios/Runner/Info.plist`:
```xml
<!-- Add URL Schemes -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.streaker.streaker</string>
            <string>YOUR_IOS_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>

<!-- Add Google Sign In Config -->
<key>GIDClientID</key>
<string>YOUR_IOS_CLIENT_ID.apps.googleusercontent.com</string>
```

## Step 6: Test the Implementation

### Test OTP Flow
1. Open your app
2. Go to Sign In/Sign Up
3. Enter email and click "Continue with Email"
4. Check email for 6-digit code
5. Enter code to complete authentication

### Test Google OAuth
1. Click "Continue with Google"
2. Select Google account
3. Grant permissions
4. Should redirect back to app

## Step 7: Production Checklist

- [ ] Remove test email addresses from allowed list
- [ ] Set up production SMTP server
- [ ] Configure rate limiting for OTP requests
- [ ] Set up email domain verification (SPF, DKIM)
- [ ] Monitor authentication logs
- [ ] Set up email bounce handling
- [ ] Configure backup authentication method
- [ ] Test on both iOS and Android devices

## Troubleshooting

### OTP Not Received
- Check spam/junk folder
- Verify SMTP settings
- Check Supabase logs for errors
- Ensure email provider is enabled

### Google Sign-In Not Working
- Verify OAuth credentials match platform
- Check redirect URI configuration
- Ensure bundle ID/package name matches
- Verify SHA-1 fingerprint (Android)

### Rate Limiting Issues
- Check `otp_rate_limits` table
- Clear blocked entries if needed
- Adjust rate limit settings

## Security Best Practices

1. **Never commit sensitive keys** to version control
2. **Use environment variables** for configuration
3. **Enable 2FA** on your Supabase account
4. **Monitor authentication logs** regularly
5. **Set up alerting** for suspicious activity
6. **Regularly rotate** service keys
7. **Use HTTPS** for all communications

## Support

For issues or questions:
1. Check Supabase documentation
2. Review Flutter logs
3. Check authentication logs in Supabase Dashboard
4. Contact support with error details

---

Last Updated: December 2024