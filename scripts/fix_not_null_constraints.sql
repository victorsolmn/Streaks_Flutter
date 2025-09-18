-- IMMEDIATE FIX FOR PROFILE UPDATE FAILURE
-- Removes NOT NULL constraints that are blocking signup

-- ================================================
-- Remove NOT NULL constraints from user-entered fields
-- ================================================
ALTER TABLE public.profiles
  ALTER COLUMN age DROP NOT NULL,
  ALTER COLUMN height DROP NOT NULL,
  ALTER COLUMN weight DROP NOT NULL,
  ALTER COLUMN activity_level DROP NOT NULL,
  ALTER COLUMN fitness_goal DROP NOT NULL,
  ALTER COLUMN target_weight DROP NOT NULL,
  ALTER COLUMN experience_level DROP NOT NULL,
  ALTER COLUMN workout_consistency DROP NOT NULL,
  ALTER COLUMN daily_calories_target DROP NOT NULL,
  ALTER COLUMN daily_steps_target DROP NOT NULL,
  ALTER COLUMN daily_sleep_target DROP NOT NULL,
  ALTER COLUMN daily_water_target DROP NOT NULL;

-- ================================================
-- Verify constraints are removed
-- ================================================
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
  AND column_name IN (
    'age', 'height', 'weight',
    'activity_level', 'fitness_goal',
    'target_weight', 'experience_level',
    'workout_consistency', 'daily_calories_target',
    'daily_steps_target', 'daily_sleep_target',
    'daily_water_target'
  )
ORDER BY column_name;

-- ================================================
-- Success message
-- ================================================
-- After running this:
-- ✅ Signup will succeed with NULL values
-- ✅ Onboarding can update these fields later
-- ✅ No more constraint violations