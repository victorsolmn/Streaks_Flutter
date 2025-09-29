# Supabase Database Cleanup Instructions

## Overview
This guide provides instructions for safely cleaning up your Supabase database to start fresh testing with the Streaks Flutter app.

## Prerequisites
- Access to your Supabase project dashboard
- Database credentials (if using CLI)
- **IMPORTANT**: Backup any important data before proceeding

## Method 1: Using Supabase Dashboard (Recommended)

### Steps:
1. **Login to Supabase Dashboard**
   - Go to https://supabase.com/dashboard
   - Select your project

2. **Navigate to SQL Editor**
   - Click on "SQL Editor" in the left sidebar
   - Click "New Query" button

3. **Run the Cleanup Script**
   - Copy the entire contents of `scripts/cleanup_supabase.sql`
   - Paste into the SQL editor
   - Click "Run" button

4. **Verify Cleanup**
   - The last query will show record counts for all tables
   - All counts should be 0 (except achievements table)

## Method 2: Using Supabase CLI

### Setup:
```bash
# Install Supabase CLI if not already installed
npm install -g supabase

# Login to Supabase
supabase login
```

### Execute:
```bash
# Navigate to project directory
cd /Users/Vicky/Streaks_Flutter

# Run the cleanup script
supabase db execute -f scripts/cleanup_supabase.sql --project-ref <your-project-ref>
```

## Method 3: Using psql Command Line

### Connection:
```bash
# Connect to your database
psql -h <your-db-host>.supabase.co \
     -p 5432 \
     -d postgres \
     -U postgres \
     -f scripts/cleanup_supabase.sql
```

## What Gets Cleaned

### Tables Completely Cleared:
- `user_profiles` - All user profile data
- `nutrition_entries` - All food and nutrition logs
- `health_data` - All health metrics
- `streaks` - All streak records
- `user_goals` - All user goals
- `workouts` - All workout sessions
- `user_achievements` - All user achievement progress
- `chat_messages` - All AI chat history
- `smartwatch_data` - All smartwatch sync data

### Tables Preserved:
- `achievements` - Badge definitions remain (only progress reset)
- Auth tables - User accounts remain intact

## Safety Features

### The script includes:
1. **RLS Disabling** - Temporarily disables Row Level Security for cleanup
2. **Foreign Key Handling** - Deletes in correct order to avoid constraint violations
3. **Sequence Reset** - Resets auto-increment counters
4. **RLS Re-enabling** - Restores security after cleanup
5. **Verification Query** - Shows final record counts

## Post-Cleanup Steps

### After running the cleanup:

1. **Verify in Dashboard**
   - Go to Table Editor in Supabase
   - Check each table shows 0 records

2. **Test App Login**
   - Open the Streaks Flutter app
   - Sign in with your existing account
   - You should see a fresh profile with no data

3. **Start Fresh Testing**
   - Create new profile data
   - Test nutrition tracking
   - Test health sync
   - Test streak tracking
   - Test achievement unlocking

## Troubleshooting

### If cleanup fails:

1. **Permission Issues**
   - Ensure you have admin/owner access
   - Check RLS policies aren't blocking

2. **Foreign Key Constraints**
   - Script handles order, but check for custom constraints
   - May need to disable constraints temporarily

3. **Partial Cleanup**
   - Run individual DELETE statements
   - Check for triggers preventing deletion

## Backup Recommendation

### Before cleanup:
```sql
-- Export data (run in SQL Editor)
COPY (SELECT * FROM public.user_profiles) TO '/tmp/user_profiles_backup.csv' CSV HEADER;
COPY (SELECT * FROM public.nutrition_entries) TO '/tmp/nutrition_entries_backup.csv' CSV HEADER;
-- Repeat for other tables as needed
```

## Alternative: Soft Reset

If you want to preserve some data:
```sql
-- Only clear recent data (last 7 days)
DELETE FROM public.nutrition_entries WHERE created_at > NOW() - INTERVAL '7 days';
DELETE FROM public.health_data WHERE created_at > NOW() - INTERVAL '7 days';
-- etc.
```

## Contact Support

If you encounter issues:
1. Check Supabase logs in Dashboard > Logs
2. Review RLS policies in Authentication > Policies
3. Contact Supabase support if database errors persist

---
**WARNING**: This cleanup is irreversible. Always backup important data first!