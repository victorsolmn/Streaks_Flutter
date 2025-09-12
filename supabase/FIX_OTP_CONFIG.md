# 🔧 Fix: "Error sending magic link email" - Force OTP Mode

## 🚨 **Problem**: Supabase is sending magic links instead of OTP codes

## ✅ **Solution**: Configure Supabase to ONLY send OTP codes

---

## **Step 1: Email Provider Configuration (CRITICAL)**

### **Go to Supabase Dashboard**:
1. **Navigation**: Authentication → Providers
2. **Find**: Email provider (should show "Enabled")
3. **Click**: Email provider to configure

### **Essential Settings**:
```
✅ Enable sign up: ON
✅ Enable Email OTP: ON  ← MUST BE ENABLED
❌ Confirm email: OFF    ← MUST BE DISABLED (this sends magic links!)
❌ Secure email change: OFF (optional)
```

### **OTP Specific Settings**:
```
OTP expiry: 600 seconds
OTP length: 6 digits
```

4. **Click**: "Save" button

---

## **Step 2: Check Auth Configuration Table**

Run this in **SQL Editor** to verify configuration:

```sql
-- Check current auth configuration
SELECT * FROM auth.config;

-- Update auth config to disable email confirmation
UPDATE auth.config 
SET 
  mailer_autoconfirm = false,
  email_autoconfirm = false
WHERE id = 1;

-- Verify the update
SELECT mailer_autoconfirm, email_autoconfirm FROM auth.config;
```

---

## **Step 3: Verify SMTP Settings**

**Go to**: Settings → SMTP Settings

Ensure these are configured:
```
SMTP Host: smtp.gmail.com
SMTP Port: 587
SMTP Username: [your-gmail]
SMTP Password: [gmail-app-password]
From Email: noreply@streaker.app
From Name: Streaker
Enable TLS: YES
```

**Test SMTP**: Click "Send test email" button

---

## **Step 4: Update Flutter Code (Alternative Method)**

If dashboard settings don't work, let's force OTP in code:

```dart
// In supabase_auth_provider.dart
await _supabaseService.client.auth.signInWithOtp(
  email: email,
  shouldCreateUser: isSignUp,
  emailRedirectTo: null,  // No redirect = forces OTP
);
```

---

## **Step 5: Test Configuration**

### **Method 1: Via API Test**
```bash
curl -X POST 'https://njlafkaqjjtozdbiwjtj.supabase.co/auth/v1/otp' \
-H 'apikey: YOUR_ANON_KEY' \
-H 'Content-Type: application/json' \
-d '{
  "email": "victorsolmn@gmail.com",
  "create_user": false
}'
```

### **Method 2: Via App**
1. Open Streaker app
2. Sign In → Enter email
3. Should receive 6-digit code (not link)

---

## **🔍 Common Issues & Fixes**

### **Issue 1**: Still getting "magic link" error
**Fix**: Clear browser cache, ensure "Confirm email" is OFF

### **Issue 2**: SMTP errors
**Fix**: Verify Gmail app password, check SMTP test email

### **Issue 3**: No emails received
**Fix**: Check spam folder, verify SMTP configuration

### **Issue 4**: OTP codes not working in app
**Fix**: Verify OTP verification code in Flutter app

---

## **✅ Expected Success Indicators**

When fixed, you should see:
- ✅ No "magic link" errors
- ✅ 6-digit OTP codes in email
- ✅ Professional Streaker email template
- ✅ Successful login with OTP codes

---

## **🆘 If Still Not Working**

Try this **nuclear option** - recreate email provider:

1. **Disable** Email provider completely
2. **Save** settings
3. **Re-enable** Email provider
4. **Configure** with OTP settings only
5. **Test** again

**The key is ensuring "Confirm email" is NEVER enabled - this forces magic links!**