# Streaker App - Knowledge Base

## Project Overview
Streaker (formerly Streaks Flutter) is a comprehensive health and fitness tracking application that integrates with Samsung Health, Google Fit, and Apple HealthKit to provide users with real-time health metrics, nutrition tracking, and achievement systems. The app features a unified OTP authentication system for seamless and secure user access.

## Recent Updates (December 2024 - Version 1.0.4)

### Privacy Policy & Google Play Compliance
**Issue:** Google Play Console requires privacy policy for apps using camera permissions
**Solution:**
- Created comprehensive privacy policy and terms screens in `/lib/screens/legal/`
- Hosted privacy policy on GitHub Pages: https://victorsolmn.github.io/streaker-privacy/
- Added camera permissions to AndroidManifest.xml
- Implemented clickable legal links in signup flow using TapGestureRecognizer
- Version updated from 1.0.1+2 to 1.0.4+5

**Files Modified:**
- `/lib/screens/auth/signup_screen.dart` - Added privacy policy links
- `/lib/screens/legal/privacy_policy_screen.dart` - New privacy policy screen
- `/lib/screens/legal/terms_conditions_screen.dart` - New terms screen
- `/android/app/src/main/AndroidManifest.xml` - Camera permissions

## Recent Critical Fixes (September 2025)

### 1. UI Overflow Issue Fix
**Problem:** Persistent 6.8px right overflow next to steps progress circle on Samsung devices (720x1544 resolution)

**Solution:**
- Replaced rigid Row layout with Flexible widgets
- Used `MainAxisAlignment.spaceEvenly` for better distribution
- Added horizontal padding and proper constraints
- Reduced icon sizes (24px → 20px) and font sizes
- Implemented `TextOverflow.ellipsis` for long text
- Changed from fixed widths to responsive design

**Key Code Location:** `/lib/screens/main/home_screen_clean.dart:362-480`

### 2. Nutrition Duplicate Entries Fix
**Problem:** Nutrition entries were being duplicated on every app sync/restart

**Root Cause:** `saveNutritionEntry` was using `.insert()` without checking for existing entries

**Solution:**
- Added duplicate detection before insertion
- Check for existing entries within 5-second timestamp window
- Pass timestamp through sync process for proper deduplication
- Modified `/lib/services/supabase_service.dart:189-238`
- Updated `/lib/providers/nutrition_provider.dart:355-364`

### 3. Health Data Sync Issues
**Problem:** Steps showing 0 in Supabase after app restart

**Solutions Implemented:**
- Changed initial values from 0 to -1 to track unloaded state
- Added validation to prevent saving uninitialized data
- Load Supabase data BEFORE initializing health services
- Implemented native Android deduplication for proper step counting
- Samsung Health now properly prioritized over Google Fit

### 4. iOS HealthKit Integration Fix (September 2025)
**Problem:** Only steps were syncing on iOS; calories, heart rate, and sleep data showed 0 despite having permissions

**Root Causes Identified:**
1. Missing HealthKit entitlements file (`Runner.entitlements`)
2. Invalid data type `TOTAL_CALORIES_BURNED` not supported on iOS
3. Missing data types: `RESTING_HEART_RATE`, `SLEEP_AWAKE`, `SLEEP_IN_BED`
4. Inconsistent implementation between `UnifiedHealthService` and `FlutterHealthService`

**Solution:**
- Created `/ios/Runner/Runner.entitlements` with HealthKit permissions
- Added HealthKit capability in Xcode project settings
- Removed unsupported `TOTAL_CALORIES_BURNED` type for iOS
- Added iOS-specific health data types:
  - `RESTING_HEART_RATE` for Apple Watch resting heart rate
  - `SLEEP_AWAKE` and `SLEEP_IN_BED` for comprehensive sleep tracking
- Implemented `forceRequestAllPermissions()` method to re-request permissions for new data types
- Added "Re-authorize" button in Profile screen for permission refresh

**Files Modified:**
- `/ios/Runner/Runner.entitlements` - New file with HealthKit entitlements
- `/ios/Runner.xcodeproj/project.pbxproj` - Added HealthKit capability
- `/lib/services/unified_health_service.dart` - Fixed iOS data types and added force permission request
- `/lib/services/flutter_health_service.dart` - Removed invalid TOTAL_CALORIES_BURNED
- `/lib/screens/main/profile_screen.dart` - Added Re-authorize button

**Key Implementation Details:**
- iOS uses different health data types than Android
- HealthKit requires explicit permission for each data type
- Must re-request permissions when adding new data types
- Platform-specific code for fetching different metrics

## OTP Authentication Implementation (January 2025)

### Overview
Implemented a unified passwordless authentication system using OTP (One-Time Password) codes sent via email. This replaces the traditional password-based authentication while maintaining backward compatibility.

### Key Features
- **Unified Auth Screen**: Single entry point for all authentication methods
- **6-Digit OTP Codes**: Secure time-limited verification codes
- **Auto User Detection**: Seamlessly handles both new signups and existing users
- **Multiple Auth Methods**: Email OTP, Google OAuth, and password fallback
- **Beautiful Email Templates**: Branded HTML emails with gradient design

### Technical Implementation

#### 1. UnifiedAuthScreen (`/lib/screens/auth/unified_auth_screen.dart`)
- Single email input field for both signin/signup
- Terms & Privacy Policy acceptance checkbox
- Google OAuth integration button
- Password login fallback option
- Security benefits information display

#### 2. SupabaseAuthProvider Updates
- **sendOTP()**: Sends 6-digit verification code to email
- **verifyOTP()**: Validates the entered code
- **checkUserExists()**: Internal helper for user detection
- Maintains all existing auth methods for backward compatibility

#### 3. Email Template Configuration
```html
<div style="background: linear-gradient(135deg, #FF6B1A 0%, #FF9051 100%);">
  <h1 style="color: white;">🔥 Streaker</h1>
  <div style="background: linear-gradient(135deg, #FF6B1A 0%, #FF9051 100%);">
    <h1 style="color: white; font-size: 48px; letter-spacing: 12px;">{{ .Token }}</h1>
  </div>
</div>
```

### Authentication Flow
```
Welcome Screen → Unified Auth Screen → Send OTP → Verify Code
                                     ↓
                                Google OAuth
                                     ↓
                              Password Fallback
```

### Security Improvements
- No password storage (eliminates password vulnerabilities)
- Time-limited codes (5-minute expiration)
- Rate limiting protection
- Email ownership verification
- JWT-based session management

### Supabase Configuration Required
1. Enable Email Provider in Supabase Dashboard
2. Set "Confirm email" toggle to ON
3. Configure OTP expiry to 300 seconds
4. Add redirect URL: `com.streaker.streaker://auth-callback`

### Files Modified/Created
- `/lib/screens/auth/unified_auth_screen.dart` - New unified auth screen
- `/lib/providers/supabase_auth_provider.dart` - Added OTP methods
- `/lib/screens/auth/welcome_screen.dart` - Updated navigation
- `/send_test_otp.dart` - Test script for OTP emails
- `/UNIFIED_AUTH_IMPLEMENTATION.md` - Complete implementation guide

### Testing
- Created test scripts for OTP configuration and flow testing
- Successfully tested with victorsolmn@gmail.com
- Verified email delivery with branded templates
- Tested on iOS simulator (iPhone 16 Pro)
