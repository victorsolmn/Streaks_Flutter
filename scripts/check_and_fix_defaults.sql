-- CHECK AND FIX DATABASE DEFAULTS/TRIGGERS

-- Step 1: Check column defaults
SELECT
    column_name,
    data_type,
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'profiles'
  AND column_name IN ('age', 'height', 'weight', 'activity_level', 'fitness_goal')
ORDER BY column_name;

-- Step 2: Check for triggers
SELECT
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'profiles';

-- Step 3: Remove defaults if they exist
ALTER TABLE profiles
  ALTER COLUMN age DROP DEFAULT,
  ALTER COLUMN height DROP DEFAULT,
  ALTER COLUMN weight DROP DEFAULT,
  ALTER COLUMN activity_level DROP DEFAULT,
  ALTER COLUMN fitness_goal DROP DEFAULT;

-- Step 4: Check if there's a function setting these values
SELECT
    proname AS function_name,
    prosrc AS function_source
FROM pg_proc
WHERE prosrc LIKE '%age%25%'
   OR prosrc LIKE '%height%170%'
   OR prosrc LIKE '%weight%70%';

-- Step 5: If there's a trigger function, here's how to fix it
-- First, check the current trigger function
SELECT
    pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname LIKE '%profile%';

-- Step 6: Create or replace the trigger function to NOT set defaults
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Only insert the basic required fields
  -- Do NOT set age, height, weight defaults
  INSERT INTO public.profiles (id, email, created_at, updated_at)
  VALUES (
    new.id,
    new.email,
    now(),
    now()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 7: Verify the fix
SELECT
    column_name,
    column_default
FROM information_schema.columns
WHERE table_name = 'profiles'
  AND column_name IN ('age', 'height', 'weight');