# Streaks Flutter - Technical Architecture

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Client Layer (Flutter)                 │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer  │  Business Logic  │   Data Layer      │
│  - Screens/Widgets   │  - Providers      │  - Repositories   │
│  - UI Components     │  - Services       │  - Models         │
│  - Navigation        │  - State Mgmt     │  - API Clients    │
├─────────────────────────────────────────────────────────────┤
│                     Platform Integration                     │
│  iOS: HealthKit      │  Android: Health Connect             │
├─────────────────────────────────────────────────────────────┤
│                      Backend Services                        │
│  Supabase (Auth/DB)  │  Firebase (Analytics)  │  Gemini AI │
└─────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user_model.dart
│   ├── nutrition_model.dart
│   ├── health_data_model.dart
│   ├── profile_model.dart
│   └── supabase_enums.dart
├── providers/                # State management
│   ├── supabase_auth_provider.dart
│   ├── health_provider.dart
│   ├── nutrition_provider.dart
│   ├── user_provider.dart
│   └── streak_provider.dart
├── screens/                  # UI screens
│   ├── auth/                # Authentication screens
│   ├── main/                # Main app screens
│   └── onboarding/          # Onboarding flow
├── services/                 # Business logic
│   ├── supabase_service.dart
│   ├── health_service.dart
│   ├── notification_service.dart
│   ├── toast_service.dart
│   ├── popup_service.dart
│   └── onboarding_service.dart
├── utils/                    # Utilities
│   ├── app_theme.dart
│   ├── constants.dart
│   └── validators.dart
└── widgets/                  # Reusable components
    ├── custom_button.dart
    ├── loading_indicator.dart
    └── sync_status_indicator.dart
```

## Core Components

### 1. State Management Architecture

#### Provider Pattern Implementation
```dart
class AppProviders {
  static List<Provider> get providers => [
    ChangeNotifierProvider<SupabaseAuthProvider>(),
    ChangeNotifierProvider<HealthProvider>(),
    ChangeNotifierProvider<NutritionProvider>(),
    ChangeNotifierProvider<UserProvider>(),
    ChangeNotifierProvider<StreakProvider>(),
  ];
}
```

#### Provider Responsibilities
- **SupabaseAuthProvider**: Handles authentication, session management, OTP verification
- **HealthProvider**: Manages health data sync with HealthKit/Health Connect
- **NutritionProvider**: Tracks meals, calories, macros
- **UserProvider**: User profile, preferences, onboarding status
- **StreakProvider**: Streak calculation, goal tracking

### 2. Navigation Architecture

#### Navigation Flow
```
SplashScreen
    ├── AuthCheck
    │   ├── SignInScreen → OTPVerificationScreen
    │   └── SignUpScreen → OTPVerificationScreen
    └── Authenticated
        ├── OnboardingScreen (if new user)
        └── MainScreen (5 bottom tabs)
            ├── HomeScreen
            ├── ProgressScreen
            ├── NutritionScreen
            ├── ChatScreen
            └── ProfileScreen
```

### 3. Data Layer Architecture

#### Repository Pattern
```dart
abstract class BaseRepository<T> {
  Future<T?> getById(String id);
  Future<List<T>> getAll();
  Future<void> create(T item);
  Future<void> update(T item);
  Future<void> delete(String id);
}
```

#### API Client Structure
```dart
class SupabaseClient {
  // Singleton pattern
  static final instance = Supabase.instance.client;
  
  // Auth operations
  Future<AuthResponse> signInWithOTP(String email);
  Future<AuthResponse> verifyOTP(String email, String token);
  
  // Database operations
  PostgrestQueryBuilder from(String table);
  RealtimeChannel channel(String name);
}
```

### 4. Health Integration Architecture

#### Platform-Specific Implementation
```dart
class HealthService {
  // Platform detection
  final bool isIOS = Platform.isIOS;
  final bool isAndroid = Platform.isAndroid;
  
  // Permission handling
  Future<bool> requestPermissions();
  
  // Data sync
  Future<void> syncHealthData() {
    if (isIOS) return _syncWithHealthKit();
    if (isAndroid) return _syncWithHealthConnect();
  }
}
```

#### Health Data Flow
1. Request permissions from user
2. Fetch data from health platform
3. Process and normalize data
4. Sync to Supabase backend
5. Update local state via Provider

### 5. Authentication Architecture

#### OTP Flow Implementation
```
User enters email
    ↓
Send OTP via Supabase
    ↓
User enters 6-digit code
    ↓
Verify OTP
    ↓
Create/Update user profile
    ↓
Navigate to app/onboarding
```

#### Session Management
- Token stored in secure storage
- Auto-refresh on app launch
- Session validation on API calls
- Logout clears all local data

## Database Schema

### Core Tables

#### user_profiles
```sql
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  age INTEGER,
  weight DECIMAL,
  height DECIMAL,
  activity_level TEXT,
  fitness_goal TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

#### health_data
```sql
CREATE TABLE health_data (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES user_profiles(id),
  date DATE,
  steps INTEGER,
  calories_burned DECIMAL,
  active_minutes INTEGER,
  distance DECIMAL,
  heart_rate_avg INTEGER,
  synced_at TIMESTAMP
);
```

#### nutrition_entries
```sql
CREATE TABLE nutrition_entries (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES user_profiles(id),
  meal_type TEXT,
  food_name TEXT,
  calories DECIMAL,
  protein DECIMAL,
  carbs DECIMAL,
  fat DECIMAL,
  logged_at TIMESTAMP
);
```

## Performance Optimizations

### 1. Widget Lifecycle Management
- Always check `mounted` before async operations
- Proper disposal of controllers and listeners
- Timer management to prevent memory leaks

### 2. Data Caching Strategy
- Local caching with SharedPreferences
- Offline-first approach for critical data
- Sync queue for failed operations

### 3. Image Optimization
- Lazy loading for images
- Compression before upload
- CDN integration for assets

## Security Implementation

### 1. Data Protection
- Flutter Secure Storage for sensitive data
- Environment variables for API keys
- Certificate pinning for API calls

### 2. Authentication Security
- OTP expiration (60 seconds)
- Rate limiting on auth endpoints
- Session timeout after inactivity

### 3. Health Data Privacy
- Explicit permission requests
- Minimal data collection
- User control over data sharing

## Error Handling Strategy

### 1. Global Error Handling
```dart
class ErrorHandler {
  static void handleError(dynamic error) {
    if (error is NetworkException) {
      PopupService.showNetworkError();
    } else if (error is AuthException) {
      NavigationService.navigateToLogin();
    } else {
      ToastService.showError('An error occurred');
    }
  }
}
```

### 2. Retry Mechanisms
- Exponential backoff for network requests
- Offline queue for failed syncs
- User-initiated retry options

## Testing Strategy

### 1. Unit Tests
- Provider logic testing
- Model serialization tests
- Utility function tests

### 2. Widget Tests
- Screen navigation tests
- Form validation tests
- Component interaction tests

### 3. Integration Tests
- Auth flow testing
- Health sync testing
- End-to-end user journeys

## Build & Deployment

### iOS Configuration
- Bundle ID: com.streaker.streaker
- Minimum iOS: 13.0
- HealthKit capabilities enabled

### Android Configuration
- Package: com.streaker.streaker
- Min SDK: 26 (Android 8.0)
- Target SDK: 36
- Health Connect integration

### CI/CD Pipeline (Planned)
```yaml
pipeline:
  - lint: flutter analyze
  - test: flutter test
  - build_ios: flutter build ios
  - build_android: flutter build apk
  - deploy: fastlane deploy
```

## Monitoring & Analytics

### 1. Firebase Analytics Events
- User registration
- Feature usage
- Error tracking
- Performance metrics

### 2. Crash Reporting
- Firebase Crashlytics (when enabled)
- Error boundaries
- Stack trace collection

### 3. Performance Monitoring
- App startup time
- Screen load times
- API response times
- Memory usage tracking

## Future Architecture Improvements

### 1. Scalability Enhancements
- Implement GraphQL for efficient data fetching
- Add Redis caching layer
- Microservices architecture for backend

### 2. Technical Debt Reduction
- Migrate to Riverpod for better state management
- Implement clean architecture principles
- Add comprehensive error boundaries

### 3. Feature Additions
- Real-time collaboration features
- WebSocket for live updates
- Background task scheduling
- ML model integration for predictions

---
Last Updated: September 2025
Version: 1.0.0
