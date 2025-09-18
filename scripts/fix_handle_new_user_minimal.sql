-- FIX: Remove age, height, weight from initial profile creation
-- These fields should ONLY be set during onboarding when user enters them

-- ================================================
-- Update handle_new_user to create minimal profile
-- ================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Create minimal profile with ONLY the essential fields
  -- DO NOT set age, height, weight - these come from onboarding
  BEGIN
    INSERT INTO public.profiles (
      id,
      email,
      name,
      created_at,
      updated_at
    )
    VALUES (
      new.id,
      new.email,
      COALESCE(new.raw_user_meta_data->>'name', 'New User'),
      now(),
      now()
    )
    ON CONFLICT (id) DO UPDATE SET
      email = EXCLUDED.email,
      name = COALESCE(EXCLUDED.name, profiles.name),
      updated_at = now();
  EXCEPTION
    WHEN OTHERS THEN
      -- Log but don't block user creation
      RAISE WARNING 'Profile creation failed for user %: %', new.id, SQLERRM;
  END;

  RETURN new;
END;
$$;

-- ================================================
-- Verify the function is correct
-- ================================================
SELECT pg_get_functiondef(oid)
FROM pg_proc
WHERE proname = 'handle_new_user';

-- ================================================
-- Ensure columns allow NULL (for initial creation)
-- ================================================
ALTER TABLE public.profiles
  ALTER COLUMN age DROP NOT NULL,
  ALTER COLUMN height DROP NOT NULL,
  ALTER COLUMN weight DROP NOT NULL;

-- ================================================
-- Success message
-- ================================================
-- After running this:
-- ✅ Signup creates profile with ONLY id, email, name
-- ✅ NO age, height, weight until user enters them
-- ✅ Onboarding will save user-entered values