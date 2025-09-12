# Streaks Flutter - Frontend Architecture & Design
**Last Updated:** September 12, 2025

## Architecture Overview

### Design Pattern: Provider + MVVM
The app follows a Provider-based state management pattern with MVVM architecture, leveraging Flutter 3.35.2 with native platform integrations.

## Folder Structure

```
lib/
├── providers/               # State management
├── screens/                 # UI screens
│   ├── auth/               # Authentication flows
│   ├── onboarding/         # User onboarding
│   ├── main/               # Main app screens
│   └── splash/             # App initialization
├── services/               # Business logic
├── models/                 # Data models
├── utils/                  # Utilities
└── widgets/                # Reusable components
```

## Core Components

### Authentication Flow
- SplashScreen → AuthCheck → SignIn/SignUp/Main/Onboarding

### State Management
- **SupabaseAuthProvider**: Authentication state
- **UserProvider**: User profile data

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

## Recent Updates (September 12, 2025)

### APK Build & Distribution
- **Release Build:** 59.0MB APK with all features
- **Distribution:** WiFi sharing via HTTP server
- **Performance:** Optimized build with tree-shaking (99.2% font reduction)
- **Compatibility:** Android 7.0+ (API level 24+)

## Future Enhancements
- Dark mode support
- Offline capabilities
- Multi-language support  
- Biometric authentication
- Apple Watch integration
- Social features expansion
