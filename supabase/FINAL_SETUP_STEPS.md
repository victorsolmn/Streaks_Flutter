# 🚀 Final Supabase Setup Steps

## ✅ Completed Automatically:
- All configuration files updated with your credentials
- Database schema ready to deploy
- Email templates generated
- Authentication flow configured in Flutter app

## 🔧 Manual Steps Required:

### Step 1: Configure Supabase Dashboard

1. **Go to your Supabase Dashboard**: https://app.supabase.com
2. **Select your project**: `njlafkaqjjtozdbiwjtj`

### Step 2: Run SQL Configuration

1. **Navigate to**: SQL Editor (left sidebar)
2. **Create new query**
3. **Copy and paste**: Contents from `auth_config.sql`
4. **Click "Run"** to execute

### Step 3: Enable Email OTP

1. **Go to**: Authentication → Providers
2. **Find "Email"** in the list
3. **Enable it** and configure:
   - ✅ Enable Email Signup
   - ✅ Enable Email OTP
   - ❌ Disable Email/Password (uncheck)
   - Set OTP Expiry: 600 seconds

### Step 4: Enable Google OAuth

1. **Still in**: Authentication → Providers
2. **Find "Google"** and enable it
3. **Enter credentials**:
   - **Client ID**: `[REDACTED].apps.googleusercontent.com`
   - **Client Secret**: `[REDACTED]`
   - **Redirect URL**: `https://njlafkaqjjtozdbiwjtj.supabase.co/auth/v1/callback`
4. **Click Save**

### Step 5: Update Email Template

1. **Go to**: Authentication → Email Templates
2. **Select**: Magic Link/OTP template
3. **Subject**: `Your Streaker Verification Code`
4. **Body**: Copy from `email_otp_template.html`

### Step 6: Test Configuration

Open your Supabase project and verify:
- ✅ Email provider enabled with OTP
- ✅ Google provider enabled with credentials
- ✅ Email template updated
- ✅ Database tables created

## 🎯 Ready to Test!

Your Flutter app is now ready with:
- **Email OTP authentication**
- **Google Sign-In**
- **Professional email templates**
- **Rate limiting and security**

Would you like me to build the APK for testing?

## 🆘 If Something Goes Wrong:

**Email OTP not working?**
- Check spam folder
- Verify Email provider is enabled
- Check template formatting

**Google Sign-In failing?**
- Verify credentials match exactly
- Check redirect URL is correct
- Ensure Google Cloud project is active

**Database errors?**
- Run the SQL script again
- Check for syntax errors in SQL Editor
- Verify table permissions