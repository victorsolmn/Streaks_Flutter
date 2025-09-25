# Force Update Feature Guide

## Overview
The force update feature ensures users are always on the latest version of the app by displaying mandatory or optional update dialogs based on configuration stored in Supabase.

## Components

### 1. Database Schema (`app_config` table)
- **platform**: ios, android, or all
- **min_version**: Minimum required version
- **min_build_number**: Minimum required build number
- **recommended_version**: Optional newer version
- **force_update**: Whether update is mandatory
- **update_severity**: critical, required, recommended, or optional
- **maintenance_mode**: Enable/disable maintenance mode
- **features_list**: Array of new features to display

### 2. VersionManagerService
Located at: `lib/services/version_manager_service.dart`

Key features:
- Version comparison logic
- 12-hour caching to reduce API calls
- Automatic store navigation
- Maintenance mode support

### 3. ForceUpdateDialog
Located at: `lib/widgets/force_update_dialog.dart`

UI component that displays:
- Force update dialogs (no dismiss option)
- Soft update dialogs (can dismiss)
- Maintenance mode screens
- Version information and feature lists

### 4. AppWrapper
Located at: `lib/widgets/app_wrapper.dart`

Wraps the entire app to:
- Check for updates on app launch
- Re-check when app returns to foreground
- Block app usage during critical updates

## Testing the Feature

### 1. Enable Force Update
Run this SQL in Supabase SQL editor:
```sql
UPDATE public.app_config
SET
  min_version = '2.0.0',  -- Higher than current version
  force_update = true,
  update_severity = 'critical',
  update_message = 'Critical update required.',
  features_list = ARRAY['Security fixes', 'Bug fixes'],
  updated_at = NOW()
WHERE platform = 'ios' AND active = true;
```

### 2. Enable Maintenance Mode
```sql
UPDATE public.app_config
SET
  maintenance_mode = true,
  maintenance_message = 'Under maintenance. Please try later.',
  updated_at = NOW()
WHERE active = true;
```

### 3. Enable Soft Update
```sql
UPDATE public.app_config
SET
  recommended_version = '1.0.6',
  force_update = false,
  update_severity = 'recommended',
  update_message = 'New features available!',
  updated_at = NOW()
WHERE active = true;
```

### 4. Reset to Normal
```sql
UPDATE public.app_config
SET
  min_version = '1.0.0',
  recommended_version = NULL,
  force_update = false,
  maintenance_mode = false,
  updated_at = NOW()
WHERE active = true;
```

## Update Severity Levels

1. **Critical**: Blocks app usage, no dismiss option
2. **Required**: Shows update dialog, limited dismiss
3. **Recommended**: Shows update dialog, can dismiss and skip version
4. **Optional**: No dialog shown

## Cache Behavior
- Config is cached for 12 hours locally
- Force refresh on app foreground after cache expiry
- Manual cache clear: `VersionManagerService().clearCache()`

## Debug Mode
In debug mode (development), set `shouldSkipVersionCheck()` return value to:
- `true`: Skip all version checks
- `false`: Enable version checking for testing

## Store URLs
Default store URLs are configured in `VersionManagerService`:
- iOS: https://apps.apple.com/app/streaker/id6737292817
- Android: https://play.google.com/store/apps/details?id=com.streaker.streaker

Custom URLs can be set in the `app_config` table's `update_url` field.

## Monitoring
Check update status in debug console:
- 🔍 Checking for app updates
- 📱 Current version info
- 📊 Version comparison results
- ✅ Update check complete

## Troubleshooting

### Dialog not showing?
1. Check if `shouldSkipVersionCheck()` returns false
2. Verify Supabase connection
3. Check app_config table has active records
4. Clear cache and restart app

### Dialog shows on every launch?
1. Ensure version numbers are correct in app_config
2. Check cache is working (12-hour expiry)
3. Verify SharedPreferences is initialized

### Maintenance mode not working?
1. Ensure maintenance_mode is true in database
2. Check platform matches (ios/android/all)
3. Verify active flag is true