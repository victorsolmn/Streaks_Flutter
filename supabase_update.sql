-- Step 1: Add the daily_active_calories_target column if it doesn't exist
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS daily_active_calories_target INTEGER DEFAULT 2000;

-- Step 2: Update all profiles with calculated active calorie targets
UPDATE profiles
SET
  daily_active_calories_target = CASE
    -- Victor's profiles (by email or name)
    WHEN email LIKE '%victorsolmn%' OR LOWER(name) LIKE '%victor%' THEN 2761

    -- Calculate for profiles with complete data
    WHEN age IS NOT NULL AND height IS NOT NULL AND weight IS NOT NULL THEN
      GREATEST(500, LEAST(4000,
        ROUND(
          -- Base active calories (TDEE - BMR)
          CASE activity_level
            WHEN 'Sedentary' THEN weight * 3.5
            WHEN 'Lightly Active' THEN weight * 5.5
            WHEN 'Moderately Active' THEN weight * 7.5
            WHEN 'Very Active' THEN weight * 9.5
            WHEN 'Extra Active' THEN weight * 11.5
            ELSE weight * 7.5 -- Default moderate
          END
          -- Goal adjustments
          + CASE fitness_goal
            WHEN 'Lose Weight' THEN -200
            WHEN 'Gain Muscle' THEN 150
            ELSE 0
          END
        )::INTEGER
      ))

    -- Default for incomplete profiles
    ELSE 2000
  END,

  -- Also ensure other targets are set correctly
  daily_calories_target = CASE
    WHEN email LIKE '%victorsolmn%' OR LOWER(name) LIKE '%victor%' THEN 4369
    WHEN daily_calories_target IS NULL THEN 3500
    ELSE daily_calories_target
  END,

  daily_steps_target = CASE
    WHEN email LIKE '%victorsolmn%' OR LOWER(name) LIKE '%victor%' THEN 10000
    WHEN daily_steps_target IS NULL THEN
      CASE activity_level
        WHEN 'Sedentary' THEN 5000
        WHEN 'Lightly Active' THEN 7500
        WHEN 'Moderately Active' THEN 10000
        WHEN 'Very Active' THEN 12500
        WHEN 'Extra Active' THEN 15000
        ELSE 10000
      END
    ELSE daily_steps_target
  END,

  daily_sleep_target = CASE
    WHEN daily_sleep_target IS NULL THEN 8.0
    ELSE daily_sleep_target
  END,

  daily_water_target = CASE
    WHEN daily_water_target IS NULL THEN 3.0
    ELSE daily_water_target
  END;

-- Step 3: Verify the update for Victor's profiles
SELECT
  name,
  email,
  daily_active_calories_target,
  daily_calories_target,
  daily_steps_target,
  daily_sleep_target,
  daily_water_target
FROM profiles
WHERE email LIKE '%victorsolmn%' OR LOWER(name) LIKE '%victor%';

-- Step 4: Show summary of all profiles
SELECT
  COUNT(*) as total_profiles,
  COUNT(CASE WHEN daily_active_calories_target IS NOT NULL THEN 1 END) as profiles_with_active_target,
  AVG(daily_active_calories_target) as avg_active_calories,
  MIN(daily_active_calories_target) as min_active_calories,
  MAX(daily_active_calories_target) as max_active_calories
FROM profiles;