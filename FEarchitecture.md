# Streaks Flutter - Frontend Architecture & Design
**Last Updated:** September 16, 2025

## Architecture Overview

### Design Pattern: Provider + MVVM
The app follows a Provider-based state management pattern with MVVM architecture, leveraging Flutter 3.35.2 with native platform integrations.

## Folder Structure

```
lib/
├── providers/               # State management
│   ├── supabase_auth_provider.dart      # Enhanced authentication
│   ├── supabase_user_provider.dart      # User profile management
│   ├── supabase_nutrition_provider.dart # Nutrition tracking
│   └── [existing providers...]          # Other state providers
├── screens/                 # UI screens
│   ├── auth/               # Authentication flows
│   ├── onboarding/         # User onboarding
│   ├── main/               # Main app screens
│   ├── database_test_screen.dart        # NEW: Integration testing
│   └── splash/             # App initialization
├── services/               # Business logic
│   ├── enhanced_supabase_service.dart   # NEW: Comprehensive CRUD ops
│   ├── supabase_service.dart            # Core database service
│   └── [existing services...]           # Other business logic
├── models/                 # Data models
├── utils/                  # Utilities
└── widgets/                # Reusable components
```

## Core Components

### Authentication Flow
- SplashScreen → AuthCheck → SignIn/SignUp/Main/Onboarding

### State Management
- **SupabaseAuthProvider**: Enhanced authentication with Google OAuth and error handling
- **SupabaseUserProvider**: User profile data with real-time sync
- **SupabaseNutritionProvider**: Nutrition tracking with offline support
- **StreakProvider**: Streak calculations and gamification
- **HealthProvider**: Health metrics integration
- **ThemeProvider**: App theming and preferences

## UI/UX Design System

### Color Palette
- Primary: Orange (#FF6B35)
- Background: Dark blue (#1A1A2E)
- Success: Green (#4CAF50)
- Error: Red (#E74C3C)

### Typography
- Headers: 32sp bold
- Body: 16sp regular
- Captions: 12sp regular

### Component Patterns
- Rounded corners (12px)
- Consistent padding (16-24px)
- Material Design guidelines

## Navigation
- Navigator 2.0 with MaterialPageRoute
- Deep linking: com.streaker.streaker://
- Tab navigation with BottomNavigationBar

## Form Validation
- Email regex validation
- Password min 6 characters
- Real-time error display

## Performance
- SVG for logos
- Lazy loading
- Proper disposal of controllers

## Key Features Implemented

### Health Integration
- **Native Android:** Health Connect API with direct Kotlin integration
- **iOS:** Apple HealthKit integration via Flutter Health plugin
- **Data Sources:** Samsung Health, Google Fit, Apple Health
- **Metrics:** Steps, calories, heart rate, sleep, distance tracking

### AI Chat System
- **Provider:** Grok API via X.AI platform
- **Features:** Health coaching, nutrition advice, motivation
- **UI:** ChatGPT-style interface with gradient user messages
- **Context:** Conversation history and user health data integration

### Nutrition Tracking
- **Food Logging:** Photo + text input for AI analysis
- **Macro Tracking:** Protein, carbs, fats, calories
- **Goal Management:** Customizable daily targets
- **Progress Visualization:** Charts and goal achievement indicators

### Streak System
- **Logic:** All daily goals must be met to earn a streak
- **Tracking:** Current streak, longest streak, total days
- **Gamification:** Dynamic badges based on streak length
- **Social Elements:** Achievement sharing and motivation

### Data Synchronization
- **Backend:** Supabase PostgreSQL with real-time sync
- **Offline Support:** Local storage with background sync
- **Conflict Resolution:** Timestamp-based data merging
- **Performance:** Optimized queries with caching strategy

## Recent Updates (September 16, 2025)

### Enhanced Database Integration
- **EnhancedSupabaseService**: Comprehensive CRUD operations for all app modules
- **DatabaseTestScreen**: Interactive testing interface with real-time logging
- **Integration Testing Framework**: Automated testing for 10 dummy accounts
- **API Documentation**: Complete specification with 17 endpoints documented

### New Architecture Components

#### Enhanced Services Layer
```
services/
├── enhanced_supabase_service.dart    # NEW: Comprehensive database operations
│   ├── User management (signup, signin, profile CRUD)
│   ├── Nutrition tracking (add, retrieve, daily summaries)
│   ├── Health metrics (save, retrieve, history)
│   ├── Streaks management (update, calculate, retrieve)
│   ├── Goals system (set, update progress, retrieve)
│   ├── Dashboard aggregation (combined data views)
│   └── Test data generation (10 dummy accounts)
├── supabase_service.dart             # Core database service
├── realtime_sync_service.dart        # Background synchronization
├── daily_reset_service.dart          # Daily data reset logic
└── bluetooth_smartwatch_service.dart # Smartwatch integration
```

#### Enhanced Provider Architecture
```
providers/
├── supabase_auth_provider.dart       # Enhanced with Google OAuth + error handling
├── supabase_user_provider.dart       # Real-time profile sync
├── supabase_nutrition_provider.dart  # Offline-first nutrition tracking
├── health_provider.dart              # Native health platform integration
├── streak_provider.dart              # Gamification and progress tracking
└── theme_provider.dart               # App theming and preferences
```

#### Testing Infrastructure
```
screens/
├── database_test_screen.dart         # Interactive testing interface
│   ├── Test data generation UI
│   ├── CRUD operations testing
│   ├── Real-time logging with color coding
│   └── Google sign-in testing
└── main/profile_screen.dart          # Debug menu integration
```

### Integration Test Results
**Overall System Status**: 🟡 55% Functional (September 16, 2025)

| Component | Status | Success Rate |
|-----------|--------|--------------|
| Authentication | ✅ PASS | 100% |
| Database Connection | ✅ PASS | 100% |
| Profile Management | ⚠️ PARTIAL | 70% |
| Nutrition Tracking | ❌ FAIL | 30% |
| Health Metrics | ❌ FAIL | 20% |
| Streaks Management | ❌ FAIL | 10% |
| Goals System | ⚠️ PARTIAL | 60% |

### Current Issues Identified
1. **Database Schema Mismatches**: Missing columns and table reference errors
2. **Type Casting Errors**: String vs List conflicts in nutrition module
3. **Constraint Violations**: Overly restrictive database constraints
4. **Infinite Retry Loops**: Error handling needs circuit breaker pattern

### Performance Metrics
- **App Launch**: ~3.2 seconds (Good)
- **Authentication**: <1 second (Excellent)
- **Database Connection**: <500ms (Excellent)
- **API Response**: 200-800ms (Good)
- **Real-time Sync**: Functional but needs optimization

### Enhanced Real-time Architecture
```
Data Flow:
App UI → Provider → EnhancedSupabaseService → Supabase → PostgreSQL
                ↓
            Offline Queue → Background Sync → Real-time Updates
```

### Quality Assurance
- **Comprehensive API Documentation**: 17 endpoints with field specifications
- **Interactive Testing Interface**: Real-time validation of all operations
- **Automated Test Scripts**: Ready for CI/CD integration
- **Performance Monitoring**: Built-in logging and metrics collection

## Future Enhancements
- **Immediate**: Fix database schema mismatches (Priority 1)
- **Short-term**: Implement circuit breaker pattern for error handling
- **Medium-term**: Complete automated testing pipeline
- **Long-term**: Advanced features (dark mode, biometric auth, Apple Watch)
