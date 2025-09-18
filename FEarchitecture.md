# Streaks Flutter - Frontend Architecture & Design
**Last Updated:** September 19, 2025

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
- **SupabaseAuthProvider**: Enhanced authentication with Google OAuth, iOS simulator fix, and intelligent error handling
- **SupabaseUserProvider**: User profile data with rebuild loop prevention and real-time sync
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
- **Provider:** Grok API via X.AI platform (Model: grok-3)
- **Features:** Health coaching, nutrition advice, motivation
- **UI:** Complete ChatGPT-style interface with markdown rendering
- **Response Format:** Structured with titles, bullet points, and contextual suggestions
- **Context:** Conversation history and user health data integration
- **Enhancements:** Short, actionable responses under 150 words

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

## Recent Critical Updates (September 2025)

### September 19, 2025 - Major Stability & UX Improvements

#### 🔧 Critical Rebuild Loop Fix
**Problem**: Infinite rebuild loops causing screen blinking every 25-30ms due to Provider notification cycles
**Solution**:
- **main.dart**: Replaced `postFrameCallback` with `Future.microtask` for profile loading
- **SupabaseUserProvider**: Added double-checking to prevent race conditions
- **Impact**: Eliminated rebuild loops, improved app performance and stability

#### 🔐 Google OAuth iOS Simulator Resolution
**Problem**: Google sign-in failing with "can't connect to server" error in iOS simulator
**Root Cause**: iOS simulator restrictions on external OAuth URL launches
**Solution**:
- Removed custom `redirectTo` parameter causing launch failures
- Implemented intelligent error detection for simulator limitations
- Added helpful fallback messaging for development environment
- **Files**: `lib/providers/supabase_auth_provider.dart`
- **Status**: Works perfectly on real devices, graceful fallback in simulator

#### 💬 ChatGPT-Style AI Interface Transformation
**Enhancement**: Complete redesign of AI chat interface for better user experience
**Changes**:
- Updated Grok API model from deprecated 'grok-beta' to 'grok-3'
- Implemented markdown rendering with `flutter_markdown: ^0.6.18`
- Redesigned message bubbles to ChatGPT-style layout
- Added contextual suggestion prompts below responses
- Structured AI responses with titles, bullet points under 150 words
- **Files**: `lib/services/grok_service.dart`, `lib/screens/main/chat_screen.dart`, `pubspec.yaml`

#### 🛠️ Widget Lifecycle Improvements
**Problem**: App infinite reloading due to unmounted widget context access
**Solution**: Added comprehensive `mounted` checks before any setState or context access
**Files**: `chat_screen_agent.dart`, `profile_screen.dart`

#### 📱 UI Bug Fixes
- Fixed dropdown overflow error in onboarding screen
- Resolved "BOTTOM OVERFLOWED BY 31 PIXELS" in activity level dropdown
- Simplified dropdown items with Flexible widget and adjusted padding

## Previous Updates (September 16, 2025)

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
├── supabase_auth_provider.dart       # OAuth + simulator fix + intelligent error handling
├── supabase_user_provider.dart       # Rebuild loop prevention + real-time profile sync
├── supabase_nutrition_provider.dart  # Offline-first nutrition tracking
├── health_provider.dart              # Native health platform integration
├── streak_provider.dart              # Gamification and progress tracking
└── theme_provider.dart               # App theming and preferences
```

#### ChatGPT-Style UI Components
```
screens/main/chat_screen.dart
├── ChatGPT-style message bubbles with distinct user/AI styling
├── Markdown rendering for AI responses with flutter_markdown
├── Contextual suggestion prompts below responses
├── Structured AI responses (titles, bullet points, emojis)
├── Loading states and error handling
└── Intelligent response truncation (150 words max)
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
