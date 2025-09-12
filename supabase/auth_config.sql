-- Supabase Authentication Configuration for OTP and Google SSO
-- Run this in your Supabase SQL Editor

-- 1. Enable Email OTP Authentication
-- This is handled through Supabase Dashboard, but we'll set up the auth schema

-- 2. Create or update auth settings (if not exists)
DO $$
BEGIN
  -- Enable OTP sign-in method
  UPDATE auth.config 
  SET 
    mailer_autoconfirm = false,
    sms_autoconfirm = false,
    phone_autoconfirm = false,
    email_autoconfirm = false
  WHERE id = 1;
  
  -- Set OTP expiry to 10 minutes (600 seconds)
  UPDATE auth.config
  SET 
    otp_exp = 600
  WHERE id = 1;
EXCEPTION
  WHEN undefined_table THEN
    -- Config table might not be directly accessible
    NULL;
END $$;

-- 3. Create custom claims for user metadata
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Create user profile on signup
  INSERT INTO public.user_profiles (
    user_id,
    email,
    name,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'full_name', ''),
    NOW(),
    NOW()
  )
  ON CONFLICT (user_id) DO UPDATE
  SET 
    email = EXCLUDED.email,
    name = CASE 
      WHEN EXCLUDED.name IS NOT NULL AND EXCLUDED.name != '' 
      THEN EXCLUDED.name 
      ELSE public.user_profiles.name 
    END,
    updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Create trigger for new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5. Create function to check if email exists (for signup flow)
CREATE OR REPLACE FUNCTION public.check_email_exists(user_email TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth.users 
    WHERE email = LOWER(user_email)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.check_email_exists TO anon;
GRANT EXECUTE ON FUNCTION public.check_email_exists TO authenticated;

-- 7. Create RLS policies for user_profiles if not exists
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Policy for users to read their own profile
CREATE POLICY "Users can view own profile" ON public.user_profiles
  FOR SELECT USING (auth.uid() = user_id);

-- Policy for users to update their own profile  
CREATE POLICY "Users can update own profile" ON public.user_profiles
  FOR UPDATE USING (auth.uid() = user_id);

-- Policy for users to insert their own profile
CREATE POLICY "Users can insert own profile" ON public.user_profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 8. Create email template configurations table
CREATE TABLE IF NOT EXISTS public.email_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_type TEXT NOT NULL UNIQUE,
  subject TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Insert OTP email template
INSERT INTO public.email_templates (template_type, subject, content)
VALUES (
  'otp',
  'Your Streaker Verification Code',
  '<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="text-align: center; margin-bottom: 30px;">
      <h1 style="color: #FF6B35; font-size: 28px; margin: 0;">Streaker</h1>
      <p style="color: #666; margin: 5px 0;">Your Fitness Journey Companion</p>
    </div>
    
    <div style="background: #f9f9f9; border-radius: 10px; padding: 30px; margin-bottom: 20px;">
      <h2 style="color: #333; font-size: 20px; margin-top: 0;">Verification Code</h2>
      <p style="color: #666; margin-bottom: 20px;">Please use the following code to complete your authentication:</p>
      
      <div style="background: #FF6B35; color: white; padding: 15px 20px; border-radius: 8px; text-align: center; font-size: 32px; letter-spacing: 8px; font-weight: bold;">
        {{ .Token }}
      </div>
      
      <p style="color: #999; font-size: 14px; margin-top: 20px; text-align: center;">
        This code will expire in 10 minutes
      </p>
    </div>
    
    <div style="background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin-bottom: 20px;">
      <p style="color: #856404; margin: 0; font-size: 14px;">
        <strong>📧 Tip:</strong> If you don''t see this email in your inbox, please check your spam or junk folder.
      </p>
    </div>
    
    <div style="text-align: center; color: #999; font-size: 12px;">
      <p>If you didn''t request this code, you can safely ignore this email.</p>
      <p style="margin-top: 20px;">© 2024 Streaker. All rights reserved.</p>
    </div>
  </div>'
) ON CONFLICT (template_type) DO UPDATE
SET 
  subject = EXCLUDED.subject,
  content = EXCLUDED.content,
  updated_at = NOW();

-- 10. Create function to send custom OTP email (optional, for custom flow)
CREATE OR REPLACE FUNCTION public.send_otp_email(
  user_email TEXT,
  otp_code TEXT
)
RETURNS VOID AS $$
DECLARE
  template RECORD;
BEGIN
  -- Get email template
  SELECT * INTO template 
  FROM public.email_templates 
  WHERE template_type = 'otp';
  
  -- Log email send (you can integrate with your email service here)
  INSERT INTO public.email_logs (
    recipient,
    subject,
    template_type,
    sent_at
  ) VALUES (
    user_email,
    template.subject,
    'otp',
    NOW()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. Create email logs table for tracking
CREATE TABLE IF NOT EXISTS public.email_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient TEXT NOT NULL,
  subject TEXT NOT NULL,
  template_type TEXT,
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  delivered_at TIMESTAMPTZ,
  opened_at TIMESTAMPTZ
);

-- 12. Create index for faster email lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON auth.users(email);
CREATE INDEX IF NOT EXISTS idx_email_logs_recipient ON public.email_logs(recipient);

-- 13. Set up rate limiting for OTP requests
CREATE TABLE IF NOT EXISTS public.otp_rate_limits (
  email TEXT PRIMARY KEY,
  attempt_count INT DEFAULT 0,
  last_attempt TIMESTAMPTZ DEFAULT NOW(),
  blocked_until TIMESTAMPTZ
);

-- Function to check OTP rate limit
CREATE OR REPLACE FUNCTION public.check_otp_rate_limit(user_email TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  rate_limit RECORD;
  max_attempts INT := 5;
  window_minutes INT := 15;
BEGIN
  SELECT * INTO rate_limit
  FROM public.otp_rate_limits
  WHERE email = LOWER(user_email);
  
  -- If blocked, check if block period has passed
  IF rate_limit.blocked_until IS NOT NULL AND rate_limit.blocked_until > NOW() THEN
    RETURN FALSE;
  END IF;
  
  -- If no record or outside window, allow
  IF rate_limit.email IS NULL OR 
     rate_limit.last_attempt < NOW() - INTERVAL '15 minutes' THEN
    INSERT INTO public.otp_rate_limits (email, attempt_count, last_attempt)
    VALUES (LOWER(user_email), 1, NOW())
    ON CONFLICT (email) DO UPDATE
    SET attempt_count = 1, last_attempt = NOW(), blocked_until = NULL;
    RETURN TRUE;
  END IF;
  
  -- Check if within rate limit
  IF rate_limit.attempt_count < max_attempts THEN
    UPDATE public.otp_rate_limits
    SET attempt_count = attempt_count + 1, last_attempt = NOW()
    WHERE email = LOWER(user_email);
    RETURN TRUE;
  ELSE
    -- Block for 30 minutes after max attempts
    UPDATE public.otp_rate_limits
    SET blocked_until = NOW() + INTERVAL '30 minutes'
    WHERE email = LOWER(user_email);
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.check_otp_rate_limit TO anon;
GRANT EXECUTE ON FUNCTION public.check_otp_rate_limit TO authenticated;

-- 14. Create app settings table for storing OAuth configs
CREATE TABLE IF NOT EXISTS public.app_settings (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert Google OAuth settings (update with your actual credentials)
INSERT INTO public.app_settings (key, value)
VALUES (
  'google_oauth',
  '{
    "enabled": true,
    "client_id": "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com",
    "redirect_uri": "com.streaker.streaker://callback",
    "scopes": ["email", "profile"],
    "ios_client_id": "YOUR_IOS_CLIENT_ID.apps.googleusercontent.com",
    "android_client_id": "YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com"
  }'::jsonb
) ON CONFLICT (key) DO UPDATE
SET value = EXCLUDED.value, updated_at = NOW();

-- 15. Success message
DO $$
BEGIN
  RAISE NOTICE 'Authentication configuration completed successfully!';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '1. Enable Email provider in Supabase Dashboard > Authentication > Providers';
  RAISE NOTICE '2. Enable Google provider and add OAuth credentials';
  RAISE NOTICE '3. Update email templates in Dashboard > Authentication > Email Templates';
  RAISE NOTICE '4. Configure SMTP settings if using custom email service';
END $$;