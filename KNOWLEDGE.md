# Streaks Flutter - Knowledge Base

## Project Overview
Streaks Flutter is a comprehensive fitness and health tracking application built with Flutter, designed to help users maintain healthy habits through streak tracking, nutrition monitoring, and integration with health platforms.

## Recent Updates & Fixes (September 2025)

### Critical Bugs Fixed
1. **App Infinite Reloading Issue**
   - **Problem**: App was constantly reloading due to unmounted widget context access
   - **Solution**: Added comprehensive `mounted` checks before any setState or context access
   - **Files Modified**:
     - `chat_screen_agent.dart`: Added Timer management and disposal
     - `profile_screen.dart`: Fixed async callbacks with mounted checks

2. **Dropdown Overflow Error**
   - **Problem**: "BOTTOM OVERFLOWED BY 31 PIXELS" in activity level dropdown
   - **Solution**: Simplified dropdown items with Flexible widget and adjusted padding
   - **File Modified**: `supabase_onboarding_screen.dart`

3. **Android Build Failures**
   - **Problem**: Health plugin compatibility issues with Android
   - **Solution**: Updated health plugin from 10.2.0 to 13.2.0, Android Gradle plugin to 8.9.1
   - **Files Modified**: `pubspec.yaml`, `android/settings.gradle.kts`, `android/app/build.gradle.kts`

### UI Improvements
- Removed debug sign-out button from main screen
- Fixed dropdown spacing issues in onboarding
- Improved error handling and user feedback

## Technical Architecture

### State Management
- **Provider Pattern**: Central state management
- **Key Providers**:
  - `SupabaseAuthProvider`: Authentication and session management
  - `HealthProvider`: Health data synchronization
  - `NutritionProvider`: Food and macro tracking
  - `UserProvider`: User profile management
  - `StreakProvider`: Streak tracking logic

### Backend Integration
- **Supabase**:
  - Authentication (OTP-based)
  - Real-time database
  - Cloud data synchronization
- **Firebase**: Analytics and crash reporting (partially disabled for iOS build issues)

### Health Platform Integration
- **iOS**: Apple HealthKit
- **Android**: Health Connect SDK (v1.1.0-rc03)
- **Features**:
  - Auto-sync on app lifecycle events
  - Manual refresh capability
  - Background sync support (currently disabled)

### Navigation Flow
1. **Authentication**: Email → OTP Verification
2. **Onboarding**: Profile Setup → Health Permissions → Main App
3. **Main App**: Bottom navigation with 5 screens (Home, Streaks, Nutrition, Workouts, Profile)

## Known Issues & Limitations

### Current Limitations
1. **Background Sync**: WorkManager temporarily disabled for build compatibility
2. **Firebase Services**: Some Firebase services (Crashlytics, Performance) disabled due to iOS build issues
3. **Push Notifications**: Firebase Messaging not implemented for web compatibility

### Performance Considerations
- Multiple Flutter processes can cause system slowdown (use cleanup scripts)
- Large APK size (150MB) due to health libraries and assets
- Auto-sync throttled to prevent excessive API calls (30-second minimum interval)

## Development Guidelines

### Code Style
- Follow existing patterns in the codebase
- Use Provider pattern for state management
- Implement proper widget lifecycle management
- Always check `mounted` before context access in async operations

### Testing Approach
1. Check for lint issues: `flutter analyze`
2. Run tests if available
3. Test on both iOS Simulator and Android emulator
4. Verify health integration on physical devices

### Build & Deployment

#### iOS Build
```bash
flutter build ios --release
```

#### Android Build
```bash
flutter build apk --debug --no-tree-shake-icons
```

#### APK Distribution via WiFi
```bash
cd build/app/outputs/flutter-apk
python3 -m http.server 8080
```

## Database Schema

### Key Tables
- `user_profiles`: User profile information
- `nutrition_entries`: Food logs and macros
- `health_data`: Synced health metrics
- `streaks`: User streak records
- `workouts`: Workout sessions

### Important Fields
- All timestamps use UTC
- User IDs linked to Supabase auth
- Soft deletes with `deleted_at` field

## Security Considerations
1. **Authentication**: OTP-based email verification
2. **Data Storage**: Sensitive data in Flutter Secure Storage
3. **API Keys**: Stored in environment configuration
4. **Health Permissions**: Explicit user consent required

## Troubleshooting Guide

### Common Issues

1. **App Not Building**
   - Clean build: `flutter clean && flutter pub get`
   - Check Xcode/Android Studio versions
   - Verify all dependencies in pubspec.yaml

2. **Health Data Not Syncing**
   - Check health permissions in device settings
   - Verify Supabase connection
   - Look for error messages in debug console

3. **Multiple Flutter Processes**
   - Kill all: `killall -KILL flutter dart`
   - Clean simulator: Reset iOS Simulator
   - Clear derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`

## Future Development Areas

### Planned Features
1. Social features and friend connections
2. Advanced analytics and insights
3. Workout plan generation
4. Nutrition recommendations
5. Wearable device integration

### Technical Improvements
1. Implement proper background sync
2. Reduce APK size
3. Add comprehensive testing suite
4. Implement CI/CD pipeline
5. Add crash reporting and analytics

## Contact & Support
- Repository: https://github.com/victorsolmn/Streaks_Flutter
- Issues: Report via GitHub Issues
- Documentation: See ARCHITECTURE.md for technical details

## Version History
- v1.0.0: Initial release with core features
- v1.0.1: Fixed widget lifecycle issues, Android compatibility
- Latest: Health plugin v13.2.0, improved stability

---
Last Updated: September 2025
