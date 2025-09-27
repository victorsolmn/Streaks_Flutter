# Streaker App - Frontend Architecture & Design

## App Overview
Streaker is a comprehensive fitness and health tracking Flutter application built with modern architecture patterns, featuring unified OTP authentication, real-time health data integration, and an elegant Material Design 3 UI.

## Core Features

### 1. Authentication System (Unified OTP)
- **Passwordless Login**: 6-digit OTP codes via email
- **Google OAuth**: Social sign-in integration
- **Password Fallback**: Traditional authentication support
- **Auto User Detection**: Seamless signup/signin flow
- **Session Management**: JWT-based with auto-refresh

### 2. Health Data Integration
- **Samsung Health** (Primary source via Health Connect)
- **Google Fit** (Secondary fallback)
- **Apple HealthKit** (iOS platform)
- **Manual Entry** (Tertiary option)
- **Real-time Sync**: Background data synchronization

### 3. Nutrition Tracking
- **AI Food Recognition**: Camera-based food identification
- **Barcode Scanning**: Product nutrition lookup
- **Indian Food Database**: Comprehensive local food data
- **Manual Entry**: Custom food logging
- **Daily Totals**: Automatic calculation and tracking
- **Meal Categories**: Breakfast, Lunch, Dinner, Snacks

### 4. Achievement & Streak System
- **Dynamic Achievements**: Progress-based unlocking
- **Streak Tracking**: Consecutive day monitoring
- **Visual Progress**: Charts and animations
- **Milestone Notifications**: Achievement alerts
- **Recovery Mechanisms**: Streak protection features
- **Calendar View**: Visual streak history display
- **Milestone Rings**: Progress visualization

### 5. Profile Management (NEW - Sept 2025)
- **Profile Photo Upload**: Supabase storage integration
- **Edit Profile**: Complete profile editing with validation
- **Pull-to-Refresh**: Dynamic data updates
- **Input Validation**: Comprehensive field validation
- **Photo Management**: Automatic cleanup of old photos

## Frontend Architecture

### Design Pattern: Provider + MVVM
The app follows a Provider-based state management pattern with MVVM architecture:

```
View (Screens) ← → ViewModel (Providers) ← → Model (Services) ← → Data (Supabase)
```

### Directory Structure
```
lib/
├── screens/              # UI Layer (Views)
│   ├── auth/            # Authentication screens
│   │   ├── unified_auth_screen.dart    # New OTP auth
│   │   ├── otp_verification_screen.dart
│   │   ├── signin_screen.dart         # Password fallback
│   │   └── welcome_screen.dart
│   ├── main/            # Core app screens
│   │   ├── home_screen_clean.dart
│   │   ├── nutrition_screen.dart
│   │   ├── progress_screen_new.dart
│   │   └── profile_screen.dart
│   ├── onboarding/      # User onboarding
│   └── legal/           # Terms & privacy
│
├── providers/           # State Management (ViewModels)
│   ├── supabase_auth_provider.dart    # Auth state
│   ├── user_provider.dart             # User profile
│   ├── health_provider.dart           # Health metrics
│   ├── nutrition_provider.dart        # Food tracking
│   ├── streak_provider.dart           # Streak logic
│   └── achievement_provider.dart      # Achievements
│
├── services/            # Business Logic (Models)
│   ├── supabase_service.dart         # Database
│   ├── unified_health_service.dart   # Health data
│   ├── permission_flow_manager.dart  # Permission lifecycle management
│   ├── health_onboarding_service.dart # Health permission dialogs
│   ├── calorie_tracking_service.dart # Advanced calorie management
│   ├── toast_service.dart            # UI feedback
│   └── realtime_sync_service.dart    # Real-time sync
│
├── models/              # Data Models
│   ├── user_model.dart
│   ├── health_metric_model.dart
│   ├── nutrition_entry_model.dart
│   ├── achievement_model.dart
│   ├── calorie_segment.dart          # Time-based calorie data
│   └── daily_calorie_total.dart      # Daily calorie aggregation
│
├── utils/               # Utilities
│   ├── app_theme.dart                # Theme & colors
│   ├── constants.dart                # App constants
│   └── validators.dart               # Input validation
│
└── widgets/             # Reusable Components
    ├── progress_circle.dart
    ├── nutrition_card.dart
    └── achievement_tile.dart
```

## UI/UX Design System

### Design Language: Material Design 3
- **Theme**: Dynamic color system with light/dark mode
- **Typography**: SF Pro (iOS) / Roboto (Android)
- **Animations**: Smooth transitions with Hero animations
- **Responsive**: Adaptive layouts for all screen sizes

### Color Palette
```dart
Primary: #FF6B1A (Vibrant Orange)
Primary Gradient: LinearGradient(#FF6B1A → #FF9051)
Secondary: #4A5568 (Dark Gray)
Success: #48BB78 (Green)
Error: #F56565 (Red)
Warning: #ED8936 (Orange)
Info: #4299E1 (Blue)
Background Light: #FFFFFF
Background Dark: #1A202C
Surface Light: #F7FAFC
Surface Dark: #2D3748
```

### Component Library
- **Buttons**: Elevated, Outlined, Text variants
- **Cards**: Elevated with rounded corners (16px)
- **Input Fields**: Filled variant with rounded borders
- **Progress Indicators**: Circular and linear variants
- **Bottom Navigation**: Fixed with 4 items
- **App Bar**: Transparent with gradient support

## Authentication Flow Architecture

### Unified OTP Authentication
```
1. Welcome Screen
   ├── Get Started → Unified Auth Screen
   └── Password Login → Traditional Flow

2. Unified Auth Screen
   ├── Email Input
   │   ├── Check User Exists (Internal)
   │   └── Send OTP
   ├── Google OAuth
   │   └── OAuth Callback Handler
   └── Password Fallback
       └── Traditional Auth Screen

3. OTP Verification
   ├── 6-Digit Code Input
   ├── Auto-Submit on Complete
   ├── Resend with Cooldown
   └── Verify & Route
       ├── New User → Onboarding
       └── Existing → Main App

4. Session Management
   ├── JWT Token Storage
   ├── Auto-Refresh Logic
   └── Deep Link Handling
```

### Authentication Components

#### UnifiedAuthScreen Features
- Email validation with regex
- Terms acceptance checkbox
- Loading states with indicators
- Error handling with toasts
- Security benefits display
- Responsive layout

#### OTP Verification Features
- 6 PIN input fields with auto-focus
- Auto-submit when complete
- 60-second resend cooldown
- Visual countdown timer
- Error state handling
- Keyboard optimization

## Data Flow Architecture

### Health Metrics Flow
```
Samsung Health / Google Fit
        ↓
Health Connect API (Android)
        ↓
MainActivity.kt (Native Android)
        ↓
UnifiedHealthService (Flutter)
        ↓
HealthProvider (State Management)
        ↓
Supabase (Cloud Storage)
```

### Nutrition Data Flow
```
Camera / Manual Input
        ↓
NutritionProvider
        ↓
Validation & Deduplication
        ↓
Supabase (with timestamp checking)
```

## Key Components

### State Management Architecture

#### Providers (State Management)
- **SupabaseAuthProvider**: Authentication state and OTP flow
  - User session management
  - OTP sending and verification
  - OAuth integration handling
  - Error state management
- **UserProvider**: User profile and preferences
  - Profile data management
  - Onboarding state tracking
  - Settings and preferences
- **HealthProvider**: Central health metrics state
  - Real-time health data
  - Platform-specific integration
  - Data synchronization
- **NutritionProvider**: Nutrition entries and totals
  - Food entry management
  - Daily totals calculation
  - Meal categorization
- **StreakProvider**: Streak calculation and persistence
  - Consecutive day tracking
  - Recovery logic
  - Milestone detection
- **AchievementProvider**: Achievement progress tracking
  - Dynamic achievement updates
  - Progress calculation
  - Unlock notifications

### Services (Business Logic)
- **UnifiedHealthService**: Health source routing with platform-specific data types
- **FlutterHealthService**: Alternative health service with cross-platform support
- **PermissionFlowManager**: App lifecycle-aware permission state management
- **HealthOnboardingService**: Enhanced permission dialogs with Samsung-specific handling
- **CalorieTrackingService**: Advanced time-segmented calorie data management
- **SupabaseService**: Database operations
- **IndianFoodNutritionService**: Food database
- **RealtimeSyncService**: Real-time data sync
- **NativeHealthConnectService**: Android-specific native health integration
- **VersionManagerService**: Force update management with caching

### UI Screens
- **MainScreen**: Navigation container with lifecycle management
- **HomeScreenClean**: Dashboard with health metrics
- **NutritionScreen**: Food tracking interface
- **ProgressScreenNew**: Streak and achievement display
- **ProfileScreen**: User settings and health source connection

## Sync Strategy

### Health Data Sync
- On app startup (with smart permission check)
- On app resume (throttled to 60 seconds)
- On app pause (save latest data)
- After health source connection

### Nutrition Sync
- Immediate after entry addition
- Periodic sync every 5 minutes
- On app pause
- Network recovery sync

## Database Schema

### health_metrics
- user_id (FK)
- date (DATE)
- steps, calories, heart_rate, sleep, distance
- UNIQUE: (user_id, date)

### nutrition_entries
- user_id (FK)
- food_name, calories, protein, carbs, fat, fiber
- quantity_grams, meal_type, food_source
- created_at (timestamp for deduplication)

### streaks
- user_id (FK)
- current_streak, longest_streak
- last_activity_date

### achievements
- user_id (FK)
- achievement_id
- progress, unlocked_at

## Error Handling

### Network Issues
- Offline queue implementation
- Retry mechanisms
- User feedback via toast/popup

### Data Validation
- Check for uninitialized values (-1)
- Prevent saving zero/empty data
- Timestamp-based duplicate prevention

### Permission Handling
- Smart auto-connect on startup
- Graceful fallback to manual entry
- Clear permission request dialogs

## Performance Optimizations

### Data Loading
1. Load from Supabase first
2. Initialize health services
3. Fetch latest health data
4. Merge and deduplicate

### UI Rendering
- Flexible widgets for responsive design
- Overflow protection with ellipsis
- Lazy loading for large lists
- Cached images for achievements

### Sync Optimization
- Batch operations where possible
- Track synced items with Sets
- Throttle sync frequency
- Skip unnecessary syncs

## Platform-Specific Health Implementation

### iOS (HealthKit)
**Supported Data Types:**
- STEPS, HEART_RATE, RESTING_HEART_RATE
- ACTIVE_ENERGY_BURNED (not TOTAL_CALORIES_BURNED)
- SLEEP_ASLEEP, SLEEP_AWAKE, SLEEP_IN_BED
- DISTANCE_WALKING_RUNNING, WATER, WEIGHT
- BLOOD_OXYGEN, WORKOUT

**Key Requirements:**
- Runner.entitlements file with HealthKit capabilities
- Info.plist with NSHealthShareUsageDescription
- Must re-request permissions when adding new data types
- Use forceRequestAllPermissions() for permission updates

### Android (Health Connect)
**Supported Data Types:**
- All standard health metrics including TOTAL_CALORIES_BURNED
- Native deduplication for accurate step counting
- Samsung Health prioritization over Google Fit
- Background sync support

**Version-Aware Navigation (September 2025):**
- Android 14+ (SDK 34+): Uses `ACTION_MANAGE_HEALTH_PERMISSIONS`
- Android 13- (SDK 33-): Uses `ACTION_HEALTH_CONNECT_SETTINGS`
- Samsung devices: Deep system integration similar to iOS
- Native Kotlin methods in MainActivity for proper intent handling
- Device-specific user guidance via AndroidHealthPermissionGuide widget

## Testing Strategy

### Unit Tests
- Provider logic validation
- Service method testing
- Data transformation verification

### Integration Tests
- Health data flow end-to-end
- Nutrition sync verification
- Achievement calculation

### Device Testing
- Multiple screen sizes
- Samsung specific testing (720x1544)
- iOS iPhone testing with HealthKit
- Network condition simulation

## OTP Authentication Implementation Details

### Key Files Modified
1. **`/lib/screens/auth/unified_auth_screen.dart`**
   - New unified authentication screen
   - Single email field for both signin/signup
   - Google OAuth integration
   - Password fallback option
   - Terms & Privacy acceptance

2. **`/lib/providers/supabase_auth_provider.dart`**
   - `sendOTP()`: Sends 6-digit codes via email
   - `verifyOTP()`: Validates entered codes
   - `checkUserExists()`: Internal user detection
   - Backward compatibility maintained

3. **`/lib/screens/auth/welcome_screen.dart`**
   - Primary CTA: "Get Started" → Unified Auth
   - Secondary: "Sign In with Password" → Traditional

### Email Template Configuration
```html
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto;">
  <!-- Header with gradient -->
  <div style="background: linear-gradient(135deg, #FF6B1A 0%, #FF9051 100%);
              padding: 40px 20px; text-align: center;">
    <h1 style="color: white; font-size: 36px;">🔥 Streaker</h1>
    <p style="color: rgba(255,255,255,0.9);">Your Fitness Journey Companion</p>
  </div>

  <!-- OTP Code Section -->
  <div style="padding: 40px 20px; text-align: center;">
    <h2>Your verification code is:</h2>
    <div style="background: linear-gradient(135deg, #FF6B1A 0%, #FF9051 100%);
                padding: 30px; border-radius: 16px;">
      <h1 style="color: white; font-size: 48px; letter-spacing: 12px;">
        {{ .Token }}
      </h1>
    </div>
    <p>This code expires in 5 minutes</p>
  </div>
</div>
```

### Security Benefits
1. **No Password Vulnerabilities**: Eliminates weak passwords
2. **Time-Limited Access**: 5-minute code expiration
3. **Email Verification**: Confirms ownership
4. **Rate Limiting**: Prevents brute force
5. **Single Flow**: No user enumeration attacks

### User Experience Improvements
- **50% faster signup**: No password creation
- **Single screen**: Unified entry point
- **Auto-detection**: Seamless new/existing user handling
- **Multiple options**: Email, Google, or password
- **Beautiful emails**: Branded HTML templates

## Performance Optimizations

### App Launch Optimization
1. Lazy loading of heavy components
2. Deferred initialization of non-critical services
3. Preloading of authentication state
4. Splash screen with smooth transition

### State Management Optimization
1. Selective widget rebuilds with Consumer
2. Cached computed values in providers
3. Debounced API calls
4. Optimistic UI updates

### Image & Asset Optimization
1. SVG for logos and icons
2. WebP for photos where supported
3. Cached network images
4. Lazy loading for lists

## Deployment Configuration

### iOS Configuration
- Bundle ID: `com.streaker.streaker`
- Deep Links: `com.streaker.streaker://auth-callback`
- HealthKit entitlements enabled
- Push notification capabilities

### Android Configuration
- Package: `com.streaker.streaker`
- Health Connect permissions
- Camera permissions for food scanning
- Deep link handling in manifest

### Environment Management
```dart
// Development
const DEV_SUPABASE_URL = 'https://dev.supabase.co';
const DEV_ANON_KEY = 'dev-key';

// Staging
const STAGING_SUPABASE_URL = 'https://staging.supabase.co';
const STAGING_ANON_KEY = 'staging-key';

// Production
const PROD_SUPABASE_URL = 'https://xzwvckziavhzmghizyqx.supabase.co';
const PROD_ANON_KEY = 'production-key';
```

## Repository Structure
- **Main Repository**: https://github.com/victorsolmn/Streaks_Flutter
- **OTP Version**: https://github.com/victorsolmn/Streaker_OTP
- **Privacy Policy**: https://victorsolmn.github.io/streaker-privacy/

## Force Update System (September 2025)

### Overview
Comprehensive force update mechanism ensuring users stay on the latest app version with graceful handling of updates and maintenance modes.

### Architecture Components

1. **AppWrapper Widget**: Wraps entire app for version checking
   - Checks version on app launch and foreground
   - Shows loading state during initial check
   - Blocks app usage for critical updates

2. **VersionManagerService**: Core update logic
   - Semantic version comparison (major.minor.patch)
   - 12-hour local caching to reduce server calls
   - Platform-specific store URL handling
   - Offline graceful fallback

3. **ForceUpdateDialog**: Update UI component
   - Severity-based gradient icons
   - Version upgrade path display (1.0.4 → 2.0.0)
   - "What's New" feature lists
   - Skip version option for soft updates
   - Maintenance mode screen

4. **Database Configuration** (app_config table):
   ```sql
   - platform: ios/android/all
   - min_version: Required minimum version
   - recommended_version: Optional update version
   - force_update: Boolean for mandatory updates
   - update_severity: critical/required/recommended/optional
   - maintenance_mode: Service downtime handling
   - features_list: Array of new features to display
   ```

### Update Flow
```
App Launch → AppWrapper → Version Check → Cache Check
                                       ↓
                              Fetch from Supabase
                                       ↓
                              Compare Versions
                                       ↓
                    [No Update] ← → [Update Required]
                                           ↓
                                   Show Update Dialog
                                           ↓
                                   [Force] → Block App
                                   [Soft] → Allow Dismiss
```

### Severity Levels
- **Critical**: App blocked, no dismiss, red gradient
- **Required**: Strong prompt, limited dismiss, orange gradient
- **Recommended**: Soft prompt, skip version option, primary gradient
- **Optional**: No dialog shown

## Permission Flow Management System (December 2024)

### PermissionFlowManager Service
New singleton service that manages Health Connect permission flows with app lifecycle awareness:

```dart
class PermissionFlowManager with WidgetsBindingObserver {
  static final _instance = PermissionFlowManager._internal();

  // Permission flow states
  enum PermissionFlowState {
    idle,
    requesting,
    inSettings,
    checkingPermissions,
    completed,
    failed
  }

  // Stream-based state updates for real-time UI synchronization
  StreamController<PermissionFlowState> _flowStateController;

  // App lifecycle tracking
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isWaitingForSettingsReturn) {
      _recheckPermissionsAfterResume();
    }
  }
}
```

### Key Features
- **Lifecycle Management**: Implements `WidgetsBindingObserver` for app resume detection
- **State Streaming**: Real-time permission flow state updates via StreamController
- **Samsung Integration**: Handles Samsung Health permission manager intents
- **Navigation Protection**: Prevents app navigation during permission flows
- **Auto-Resume Logic**: Rechecks permissions when returning from settings

### Enhanced Health Onboarding Service
Improved permission request handling with Samsung-specific flows:

```dart
// Samsung-specific permission handling
if (settingsOpened && Platform.isAndroid) {
  permissionManager.markOpeningSettings(onReturn: () async {
    await _recheckPermissionsAfterSettings(context);
  });

  await _showWaitingForPermissionsDialog(context);
}
```

### Dialog Management Architecture
Complete overhaul of health permission dialog handling:

1. **Integrated Permission Requests**: Permission flow integrated directly into dialog callbacks
2. **State-Aware Closing**: Dialogs close automatically based on permission flow state
3. **Waiting Dialogs**: Stream-based waiting dialogs with auto-close functionality
4. **Error Prevention**: Prevents duplicate popups through flow state tracking

### OTP Input Enhancement System
Fixed theme-dependent text visibility issues with forced styling:

```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,  // Force white background
    border: Border.all(color: Colors.grey.withOpacity(0.5), width: 2),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1))],
  ),
  child: TextField(
    style: TextStyle(
      color: Colors.black87,  // Force dark text
      decorationThickness: 0,
    ),
    cursorColor: Colors.black,
    showCursor: true,
  ),
)
```

### Advanced Calorie Tracking System
New time-segmented calorie data management:

#### Database Schema (calorie_segments table)
```sql
- user_id: UUID (foreign key)
- date: DATE
- hour_start: INTEGER (0-23)
- calories: REAL
- source: TEXT
- created_at: TIMESTAMP
- UNIQUE: (user_id, date, hour_start, source)
```

#### CalorieTrackingService Features
- **Hourly Segmentation**: Breaks down calorie data by hour for accurate tracking
- **Source Deduplication**: Prevents duplicate entries from multiple health sources
- **Intelligent Aggregation**: Smart daily total calculation with gap filling
- **Sync Integration**: Seamlessly integrates with HealthProvider for real-time updates

### Files Architecture Update
New service files added to the architecture:

```
lib/services/
├── permission_flow_manager.dart      # App lifecycle permission management
├── health_onboarding_service.dart    # Enhanced dialog and permission handling
├── calorie_tracking_service.dart     # Advanced calorie data management
├── unified_health_service.dart       # Enhanced with Samsung support
└── ...existing services
```

```
lib/models/
├── calorie_segment.dart              # Time-based calorie data model
├── daily_calorie_total.dart          # Daily aggregation model
└── ...existing models
```

### Native Android Enhancement
Enhanced MainActivity.kt with Samsung-specific Health Connect handling:

```kotlin
// Samsung device detection and handling
when {
  isSamsung -> {
    val intent = Intent().apply {
      setClassName(
        "com.samsung.android.shealthpermissionmanager",
        "com.samsung.android.shealthpermissionmanager.PermissionActivity"
      )
      putExtra("packageName", packageName)
    }
    startActivity(intent)
    settingsOpened = true
  }
  // ...other manufacturer handling
}
```

## Future Enhancements

### Planned Authentication Features
- Biometric authentication (FaceID/TouchID)
- Social login expansion (Apple, Facebook)
- WebAuthn support for web version
- Multi-factor authentication options

### UI/UX Improvements
- Dark mode enhancements
- Customizable themes
- Accessibility improvements
- Internationalization support

### Technical Debt
- Migration to Riverpod for state management
- Implementation of clean architecture
- Comprehensive unit test coverage
- CI/CD pipeline optimization
