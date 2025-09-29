# 🚀 Calorie Tracking System - Migration Instructions

## Quick Migration Steps

### Option 1: One-Click Migration (Recommended)

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard/project/xzwvckziavhzmghizyqx/sql/new

2. **Copy the Migration File**
   - The complete migration is in: `/supabase/migrations/20250925_calorie_tracking_system.sql`

3. **Paste and Run**
   - Copy the ENTIRE content of the migration file
   - Paste it into the SQL Editor
   - Click "Run" button

4. **Verify Success**
   - You should see green success messages
   - Check the tables were created in the Table Editor

### Option 2: Step-by-Step Migration (If errors occur)

If the full migration has issues, run these parts separately:

#### Step 1: Create Tables
```sql
-- Run this first
-- Copy from migration file: Lines 10-96 (CREATE TABLE statements)
```

#### Step 2: Create Indexes
```sql
-- Run this second
-- Copy from migration file: Lines 139-159 (CREATE INDEX statements)
```

#### Step 3: Create Functions
```sql
-- Run this third
-- Copy from migration file: Lines 163-273 (CREATE FUNCTION statements)
```

#### Step 4: Create RLS Policies
```sql
-- Run this fourth
-- Copy from migration file: Lines 277-311 (CREATE POLICY statements)
```

## Verification

After migration, run this query to verify:

```sql
-- Check if tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('calorie_sessions', 'daily_calorie_totals');

-- Should return 2 rows
```

## Features Installed

✅ **Tables Created:**
- `calorie_sessions` - Granular tracking of calorie segments
- `daily_calorie_totals` - Aggregated daily data (12am-12am)

✅ **Automatic Features:**
- Auto-aggregation when segments are inserted
- Daily totals calculation
- Backward compatibility with `health_metrics` table
- RLS security policies

✅ **Data Quality:**
- Confidence scoring
- Data completeness tracking
- Exercise session detection
- Platform-specific tracking (iOS/Android)

## What Happens Next

Once migrated:

1. **App will automatically start using new tables**
   - On next app open, calorie tracking begins
   - Full day reconstruction happens automatically
   - Workouts get proper high calorie rates

2. **Existing data preserved**
   - Old `health_metrics` table continues to work
   - New data flows to both old and new tables

3. **Benefits you'll see:**
   - Accurate daily totals
   - No more calorie reduction on app open
   - Proper workout calorie tracking
   - Complete 24-hour coverage

## Troubleshooting

**If you get "already exists" errors:**
- This is OK! It means some tables already exist
- Continue with the next steps

**If you get permission errors:**
- Make sure you're logged into Supabase Dashboard
- Use the SQL Editor (not API calls)

**To check if migration worked:**
```sql
SELECT COUNT(*) as table_count
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name LIKE 'calorie%';
-- Should return 2
```

## Quick Test

After migration, test with:
```sql
-- Insert a test segment (will auto-calculate daily total)
INSERT INTO calorie_sessions (
  user_id,
  session_date,
  session_start,
  session_end,
  bmr_calories,
  active_calories,
  segment_type,
  data_source,
  platform
) VALUES (
  (SELECT id FROM profiles WHERE email = 'victorsolmn@gmail.com'),
  CURRENT_DATE,
  NOW() - INTERVAL '1 hour',
  NOW(),
  70,
  130,
  'exercise',
  'manual',
  'android'
);

-- Check daily total was calculated
SELECT * FROM daily_calorie_totals
WHERE user_id = (SELECT id FROM profiles WHERE email = 'victorsolmn@gmail.com')
AND date = CURRENT_DATE;
```

---

**Ready to migrate? Just copy the SQL file and run it in Supabase! 🎉**