-- Script to test force update functionality
-- Run this against your Supabase database to test different update scenarios

-- Test 1: Enable force update for iOS
UPDATE public.app_config
SET
  min_version = '2.0.0',  -- Set to a version higher than current app version
  force_update = true,
  update_severity = 'critical',
  update_message = 'Critical security update required. Please update immediately.',
  features_list = ARRAY[
    '🔒 Critical security fixes',
    '⚡ Performance improvements',
    '🐛 Bug fixes'
  ],
  updated_at = NOW()
WHERE platform = 'ios' AND active = true;

-- Test 2: Enable force update for Android
UPDATE public.app_config
SET
  min_version = '2.0.0',  -- Set to a version higher than current app version
  force_update = true,
  update_severity = 'critical',
  update_message = 'Critical security update required. Please update immediately.',
  features_list = ARRAY[
    '🔒 Critical security fixes',
    '⚡ Performance improvements',
    '🐛 Bug fixes'
  ],
  updated_at = NOW()
WHERE platform = 'android' AND active = true;

-- Test 3: Enable maintenance mode
-- UPDATE public.app_config
-- SET
--   maintenance_mode = true,
--   maintenance_message = 'We are performing scheduled maintenance. Please try again in a few minutes.',
--   updated_at = NOW()
-- WHERE active = true;

-- Test 4: Soft update (recommended)
-- UPDATE public.app_config
-- SET
--   recommended_version = '1.0.6',
--   force_update = false,
--   update_severity = 'recommended',
--   update_message = 'A new version is available with exciting new features!',
--   features_list = ARRAY[
--     '✨ New dashboard design',
--     '📊 Enhanced analytics',
--     '🚀 Faster sync'
--   ],
--   updated_at = NOW()
-- WHERE active = true;

-- Reset to normal (no update required)
-- UPDATE public.app_config
-- SET
--   min_version = '1.0.0',
--   recommended_version = NULL,
--   force_update = false,
--   update_severity = 'optional',
--   maintenance_mode = false,
--   maintenance_message = NULL,
--   update_message = NULL,
--   updated_at = NOW()
-- WHERE active = true;

-- Query to check current config
SELECT
  platform,
  min_version,
  recommended_version,
  force_update,
  update_severity,
  maintenance_mode,
  update_message,
  features_list
FROM public.app_config
WHERE active = true;