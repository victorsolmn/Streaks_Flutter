# 🎯 Actual Issues to Fix in Your New Database

Since your **profiles** and **chats** are working perfectly, here are the REAL issues:

## 1. ❌ Table Name Mismatch: `goals` vs `user_goals`

**Problem**: Your database has `goals` but Flutter code expects `user_goals`

### Fix Option A: Rename the table in database
```sql
ALTER TABLE public.goals RENAME TO user_goals;
```

### Fix Option B: Update Flutter code to use `goals`
Search and replace in all `.dart` files:
- Replace: `.from('user_goals')`
- With: `.from('goals')`

Files affected:
- `/lib/services/enhanced_supabase_service.dart`
- `/lib/providers/streak_provider.dart`
- `/lib/utils/database_migrator.dart`

## 2. ⚠️ Check Column Names Match

Your Flutter models expect specific column names. Verify these exist:

### In `profiles` table:
```sql
-- Check if these columns exist (Flutter code needs them):
SELECT column_name FROM information_schema.columns
WHERE table_name = 'profiles'
AND column_name IN (
  'fitness_goal',     -- NOT 'goal'
  'activity_level',   -- NOT 'activityLevel'
  'has_completed_onboarding',
  'target_weight',
  'daily_calories_target',
  'daily_steps_target'
);
```

### In `nutrition_entries` table:
```sql
-- Verify column is named correctly:
SELECT column_name FROM information_schema.columns
WHERE table_name = 'nutrition_entries'
AND column_name = 'food_name';  -- NOT 'foods' or 'food'
```

## 3. 🔧 Quick SQL to Add Any Missing Columns

Run this to ensure all columns exist:

```sql
-- Add any missing columns to profiles
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS fitness_goal TEXT,
ADD COLUMN IF NOT EXISTS has_completed_onboarding BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS target_weight DECIMAL,
ADD COLUMN IF NOT EXISTS daily_calories_target INTEGER DEFAULT 2000,
ADD COLUMN IF NOT EXISTS daily_steps_target INTEGER DEFAULT 10000,
ADD COLUMN IF NOT EXISTS daily_sleep_target DECIMAL DEFAULT 8,
ADD COLUMN IF NOT EXISTS daily_water_target DECIMAL DEFAULT 2.5;

-- Rename 'goals' table to match Flutter code
ALTER TABLE IF EXISTS public.goals RENAME TO user_goals;

-- Ensure user_goals has required columns
ALTER TABLE public.user_goals
ADD COLUMN IF NOT EXISTS goal_type TEXT,
ADD COLUMN IF NOT EXISTS target_value DECIMAL,
ADD COLUMN IF NOT EXISTS current_value DECIMAL DEFAULT 0,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
```

## 4. ✅ What's Already Working
- ✅ Authentication (profiles creating correctly)
- ✅ Chat (chat_sessions recording properly)
- ✅ Basic profile data

## 5. 🔴 What Needs Testing After Fixes
- Nutrition tracking (add a meal)
- Health metrics (log steps/heart rate)
- Streaks (check daily streak counter)
- Goals (set and track goals)

---

**The main issue is the `goals` vs `user_goals` table name mismatch!** Fix that and most features should work.