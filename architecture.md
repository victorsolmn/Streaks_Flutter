# Streaks Flutter - Architecture Documentation

## System Architecture Overview

### Technology Stack
- **Frontend Framework**: Flutter 3.35.2 (Dart 3.9.0)
- **Backend Service**: Supabase (PostgreSQL + PostgREST API)
- **Authentication**: Supabase Auth (Email/Password + Google OAuth)
- **State Management**: Provider Pattern
- **Local Storage**: SharedPreferences + Flutter Secure Storage
- **Real-time Sync**: Supabase Realtime + Custom Sync Service
- **AI Integration**: Google Gemini API + Grok API
- **Health Integration**: Apple HealthKit (iOS) + Health Connect (Android)

## Application Architecture

### Layer Structure

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│         (Screens & Widgets)             │
├─────────────────────────────────────────┤
│          State Management               │
│            (Providers)                  │
├─────────────────────────────────────────┤
│           Service Layer                 │
│     (Business Logic & API Calls)        │
├─────────────────────────────────────────┤
│           Data Layer                    │
│    (Models & Data Persistence)          │
├─────────────────────────────────────────┤
│          External Services              │
│    (Supabase, APIs, Health Data)        │
└─────────────────────────────────────────┘
```

## Core Components

### 1. Authentication System

#### Components
- `SupabaseAuthProvider` - Central auth state management
- `SupabaseService` - Low-level auth operations
- Auth Screens (SignIn, SignUp, Welcome)

#### Flow
1. User initiates auth action
2. Provider validates and calls service
3. Service communicates with Supabase Auth
4. Provider updates state
5. UI rebuilds based on auth state

### 2. User Profile Management

#### Components
- `SupabaseUserProvider` - Profile state management
- `UserProfile` model - Complete user data structure
- `EnhancedOnboardingScreen` - Multi-step profile setup

#### Data Model (Updated Sept 17, 2025)
```dart
UserProfile {
  // Basic Info
  String name
  String email
  int? age
  double? height
  double? weight

  // New Fitness Fields
  double? targetWeight
  String? activityLevel
  String? fitnessGoal
  String? experienceLevel
  String? workoutConsistency

  // Daily Targets
  int? dailyCaloriesTarget
  int? dailyStepsTarget
  double? dailySleepTarget
  double? dailyWaterTarget

  // Status Flags
  bool hasCompletedOnboarding
  bool hasSeenFitnessGoalSummary

  // Device Info
  String? deviceName
  bool deviceConnected

  // Calculated Fields
  double? bmiValue
  String? bmiCategoryValue
}
```

### 3. Database Integration

#### Supabase Tables
- `profiles` - User profile data (extended schema)
- `nutrition` - Food tracking records
- `health_metrics` - Daily health measurements
- `streaks` - Habit tracking
- `goals` - User fitness goals

#### Service Architecture
```
EnhancedSupabaseService
├── User Operations
│   ├── createProfile()
│   ├── updateProfile()
│   └── deleteProfile()
├── Nutrition Operations
│   ├── addMeal()
│   ├── updateMeal()
│   └── getMealHistory()
├── Health Operations
│   ├── saveHealthMetrics()
│   └── getHealthHistory()
└── Sync Operations
    ├── syncOfflineData()
    └── handleRealtimeUpdates()
```

### 4. State Management Pattern

#### Provider Structure
```
MultiProvider
├── SupabaseAuthProvider (Auth State)
├── SupabaseUserProvider (User Profile)
├── SupabaseNutritionProvider (Food Data)
├── HealthProvider (Health Metrics)
├── StreakProvider (Habit Tracking)
└── ThemeProvider (UI Preferences)
```

#### State Update Flow
1. User action triggers provider method
2. Provider calls service layer
3. Service interacts with Supabase/APIs
4. Response updates provider state
5. ChangeNotifier triggers UI rebuild

### 5. Real-time Synchronization

#### Components
- `RealtimeSyncService` - Manages WebSocket connections
- Offline queue for failed operations
- Automatic retry with exponential backoff
- Conflict resolution for concurrent edits

#### Sync Strategy
```
Online Mode:
- Direct API calls
- Real-time updates via WebSocket
- Immediate UI feedback

Offline Mode:
- Queue operations locally
- Update UI optimistically
- Sync when connection restored
- Handle conflicts gracefully
```

## Data Flow Architecture

### Authentication Flow
```
User Input → AuthScreen → SupabaseAuthProvider → SupabaseService → Supabase Auth
                                ↓
                        Update Auth State
                                ↓
                        Navigate to Home/Onboarding
```

### Profile Update Flow (Fixed Sept 17)
```
Onboarding Screen → Collect User Data → SupabaseUserProvider
                                              ↓
                                    Get Fresh Auth State
                                              ↓
                                    Update Profile via API
                                              ↓
                                    Update Local State
```

### Health Data Integration
```
HealthKit/Health Connect → HealthService → HealthProvider
                                              ↓
                                    Process & Aggregate
                                              ↓
                                    Save to Supabase
                                              ↓
                                    Update Dashboard
```

## Error Handling Strategy

### Levels of Error Handling
1. **Silent Recovery** - Retry without user notification
2. **User Notification** - Toast/Snackbar for important errors
3. **Fallback UI** - Show cached data when API fails
4. **Graceful Degradation** - Disable features when services unavailable

### Error Recovery Patterns
- Automatic retry with exponential backoff
- Circuit breaker for persistent failures
- Offline queue for network errors
- Rollback capability for critical operations

## Security Architecture

### Authentication Security
- Secure token storage using Flutter Secure Storage
- Automatic token refresh
- Session timeout handling
- Biometric authentication support (planned)

### Data Security
- Row Level Security (RLS) in Supabase
- User data isolation
- Encrypted local storage for sensitive data
- API key management via environment variables

## Performance Optimizations

### Implemented Optimizations
- Lazy loading for large data sets
- Image caching and compression
- Debounced search inputs
- Memoized expensive calculations
- Connection pooling for database

### Caching Strategy
```
Level 1: In-memory cache (Provider state)
Level 2: Local storage (SharedPreferences)
Level 3: Remote database (Supabase)
```

## Testing Architecture

### Test Coverage
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for API flows
- End-to-end tests for critical paths

### Testing Infrastructure
- `DatabaseTestScreen` - Interactive API testing
- Automated test scripts
- Mock data generators
- Performance benchmarking tools

## Deployment Architecture

### Build Configuration
- Development, staging, production environments
- Environment-specific configurations
- Feature flags for gradual rollout
- A/B testing infrastructure (planned)

### CI/CD Pipeline (Planned)
```
Code Push → GitHub Actions → Run Tests → Build App → Deploy to TestFlight/Play Console
```

## Future Architecture Enhancements

### Planned Improvements
1. **Microservices Migration** - Split monolithic services
2. **GraphQL Integration** - Replace REST with GraphQL
3. **Event-Driven Architecture** - Implement event sourcing
4. **ML Pipeline** - On-device AI for personalized recommendations
5. **Multi-tenancy Support** - Support for gym/trainer accounts

### Scalability Considerations
- Database sharding for user data
- CDN for static assets
- Edge functions for computation
- WebSocket scaling for real-time features

## Architecture Decisions Log

### Sept 17, 2025
- **Decision**: Get auth state fresh from service instead of caching
- **Reason**: Cached state was becoming stale, causing auth failures
- **Impact**: More reliable but slightly more API calls

### Sept 16, 2025
- **Decision**: Use Provider pattern over Riverpod/Bloc
- **Reason**: Simpler implementation, sufficient for current needs
- **Impact**: Easier maintenance but less powerful state management

### Sept 15, 2025
- **Decision**: Supabase over Firebase
- **Reason**: Better PostgreSQL support, simpler pricing
- **Impact**: More control over database but less mature ecosystem