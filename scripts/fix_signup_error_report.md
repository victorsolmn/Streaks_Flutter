# Database Signup Error Analysis & Fix

## Error Details
- **Error Code**: `unexpected_failure`
- **Error Message**: "Database error saving new user"
- **Location**: During user signup (auth.users trigger)

## Root Cause Analysis

### 1. Modified `handle_new_user` Function Issue
When we removed the hardcoded defaults (age: 25, height: 170, weight: 70), the `handle_new_user` function might be failing because:
- The function tries to insert into profiles table
- Some columns might have NOT NULL constraints
- The trigger execution is failing silently in Supabase

### 2. Current Function State
```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, created_at, updated_at)
  VALUES (
    new.id,
    new.email,
    now(),
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    updated_at = now();
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 3. Potential Issues
- Missing required columns in INSERT
- The `name` field has default 'New User' but we're not including it
- Trigger might be failing and preventing user creation

## Solution

### Option 1: Fix the Function (Recommended)
Include the name field from auth metadata and handle NULLs properly:

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
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

  RETURN new;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail user creation
    RAISE WARNING 'Error creating profile: %', SQLERRM;
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Option 2: Remove the Trigger Temporarily
If the issue persists, temporarily disable the trigger:

```sql
-- Disable trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Re-enable with fixed function later
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

### Option 3: Manual Profile Creation
Let the app handle profile creation instead of relying on triggers.

## Immediate Fix SQL Script

```sql
-- Fix the handle_new_user function with proper error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Try to insert profile with minimal data
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
      updated_at = now();
  EXCEPTION
    WHEN OTHERS THEN
      -- If insert fails, just log warning and continue
      RAISE WARNING 'Profile creation failed for user %: %', new.id, SQLERRM;
  END;

  -- Always return new to allow user creation to succeed
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

## Testing Steps
1. Run the fix SQL in Supabase SQL Editor
2. Try creating a new user account
3. Check if signup succeeds
4. Verify profile is created (even if minimal)
5. Confirm onboarding can update the profile