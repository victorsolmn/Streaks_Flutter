# 📧 Configure Supabase for OTP Emails (Not Magic Links)

## 🚨 **Current Issue**: You're receiving magic links instead of 6-digit OTP codes

## ✅ **Solution**: Configure Supabase properly for OTP emails

---

## **Step 1: Configure Email Provider Settings**

1. **Go to Supabase Dashboard**: https://app.supabase.com
2. **Select your project**: `njlafkaqjjtozdbiwjtj`
3. **Navigate to**: Authentication → Providers
4. **Click on Email** provider
5. **Configure these settings**:

   ### ✅ **Enable These:**
   - ✅ **Enable sign up** 
   - ✅ **Enable Email OTP** ← **CRITICAL: This must be ON**
   
   ### ❌ **Disable These:**
   - ❌ **Confirm email** ← **CRITICAL: This sends magic links - TURN OFF**
   - ❌ **Secure email change** (optional, can enable later)

6. **Set OTP Settings**:
   - **OTP expiry**: `600` seconds (10 minutes)
   - **OTP length**: `6` digits (default)

7. **Click SAVE**

---

## **Step 2: Configure SMTP Settings** 

**Option A: Use Gmail (Recommended)**

1. **Go to**: Settings → SMTP Settings  
2. **Enable custom SMTP**
3. **Configure**:
   ```
   SMTP Host: smtp.gmail.com
   SMTP Port: 587
   SMTP Username: your-gmail@gmail.com
   SMTP Password: [Gmail App Password - see below]
   From Email: noreply@streaker.app
   From Name: Streaker
   ```

### **How to Get Gmail App Password:**
1. Go to Google Account Settings
2. Security → 2-Step Verification (must be enabled)
3. App passwords → Generate password for "Mail"
4. Use this password (not your regular Gmail password)

**Option B: Use Supabase Default SMTP (Limited)**
- Skip SMTP setup to use Supabase's default email service
- May have delivery limitations

---

## **Step 3: Update Email Templates**

1. **Go to**: Authentication → Email Templates
2. **Select**: Confirm signup / OTP template
3. **Subject**: `Your Streaker Verification Code`
4. **Body**: Copy from `email_otp_template.html`

### **Important Template Variables:**
- Use `{{ .Token }}` for the 6-digit OTP code
- Use `{{ .EmailActionType }}` to detect signup vs signin
- Use `{{ .SiteURL }}` for app redirect (if needed)

---

## **Step 4: Test Configuration**

### **Test OTP Flow:**
1. Open Streaker app
2. Go to Sign In → Enter email → "Continue with Email"
3. **Should receive**: 6-digit code email (not a link)
4. Enter code in app → Should login successfully

### **If Still Getting Magic Links:**
1. Double-check Email provider settings
2. Ensure "Confirm email" is DISABLED  
3. Ensure "Enable Email OTP" is ENABLED
4. Clear browser cache and try again

---

## **Step 5: Verify Database Tables**

Run this in Supabase SQL Editor to ensure proper setup:

```sql
-- Check if user profiles table exists
SELECT * FROM information_schema.tables 
WHERE table_name = 'profiles';

-- Check auth settings
SELECT * FROM auth.config;

-- Test email existence check function
SELECT public.check_email_exists('test@example.com');
```

---

## **🔧 Advanced Configuration (Optional)**

### **Rate Limiting Settings:**
```sql
-- View current rate limits
SELECT * FROM public.otp_rate_limits;

-- Clear rate limit for testing
DELETE FROM public.otp_rate_limits WHERE email = 'your-test-email@gmail.com';
```

### **Email Template Customization:**
- Add your logo/branding
- Customize colors to match app theme
- Add social links or support information

---

## **🚨 Troubleshooting**

### **Still Getting Magic Links?**
1. Check Email provider configuration again
2. Try different browser/incognito mode
3. Check Supabase Auth logs for errors

### **Not Receiving Any Emails?**
1. Check spam/junk folder
2. Verify SMTP credentials
3. Check Supabase logs for delivery errors
4. Try different email address

### **OTP Code Invalid?**
1. Check system clock (time sync issues)
2. Verify OTP expiry settings
3. Check for rate limiting

### **App Navigation Issues?**
- New users → Always go to Onboarding first
- Existing users → Go to Main Screen if profile complete
- Incomplete profiles → Go to Onboarding to complete

---

## **✅ Success Indicators**

When properly configured, you should see:
- 📧 **6-digit OTP codes** in email (not links)
- ⏱️ **10-minute expiry** clearly stated
- 🎨 **Professional email template** with Streaker branding
- 🔄 **Proper app navigation** based on user type
- 🚫 **Rate limiting** prevents spam

---

## **📞 Need Help?**

If issues persist:
1. Check Supabase Auth logs
2. Verify Flutter app logs
3. Test with different email providers
4. Ensure database tables are created properly

**Expected Result**: Beautiful OTP emails with 6-digit codes that seamlessly integrate with your Streaker app! 🎉