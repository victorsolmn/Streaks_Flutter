-- Fix sample1@gmail.com profile
UPDATE public.profiles
SET
  has_completed_onboarding = true,
  updated_at = NOW()
WHERE email = 'sample1@gmail.com';

-- Verify the update
SELECT id, email, name, has_completed_onboarding, created_at, updated_at
FROM public.profiles
WHERE email IN ('sample1@gmail.com', 'victorvegeta007@gmail.com')
ORDER BY email;