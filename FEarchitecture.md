# Streaker App Feature Architecture

## Overview
Streaker is a comprehensive fitness tracking application built with Flutter, featuring AI-powered nutrition analysis, health tracking, and progress monitoring capabilities.

## Core Architecture Components

### 1. Frontend Layer (Flutter/Dart)

#### Screen Components
```
lib/screens/
├── auth/
│   ├── login_screen.dart
│   └── register_screen.dart
├── home/
│   ├── home_screen.dart
│   └── dashboard_widgets/
├── profile/
│   ├── profile_screen.dart
│   └── edit_profile_screen.dart
├── tracking/
│   ├── weight_tracking_screen.dart
│   ├── food_scanner_screen.dart
│   └── workout_screen.dart
└── settings/
    └── settings_screen.dart
```

#### Widget Components
```
lib/widgets/
├── weight_progress_chart.dart  // Enhanced with + button UI
├── nutrition_display.dart
├── progress_card.dart
├── custom_buttons.dart
└── loading_states.dart
```

#### State Management (Provider Pattern)
```
lib/providers/
├── auth_provider.dart
├── weight_provider.dart  // Fixed DB queries
├── nutrition_provider.dart
├── profile_provider.dart
└── health_provider.dart
```

### 2. Service Layer

#### API Services
```
lib/services/
├── supabase_service.dart
├── indian_food_nutrition_service.dart  // Gemini 2.5 integration
├── health_kit_service.dart
├── analytics_service.dart
└── notification_service.dart
```

#### Configuration
```
lib/config/
├── api_config.dart  // Gemini API key
├── app_theme.dart
├── constants.dart
└── routes.dart
```

### 3. Backend Architecture (Supabase)

#### Database Schema
```sql
-- Users table (managed by Supabase Auth)
auth.users

-- Profiles table
CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id),
    name TEXT,
    weight NUMERIC,
    target_weight NUMERIC,
    height NUMERIC,
    age INTEGER,
    gender TEXT,
    weight_unit TEXT DEFAULT 'kg',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Weight entries table
CREATE TABLE weight_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id),
    weight NUMERIC NOT NULL,
    date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Trigger for auto-sync
CREATE OR REPLACE FUNCTION update_profile_weight()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE profiles
    SET weight = NEW.weight,
        updated_at = NOW()
    WHERE id = NEW.user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

#### RLS Policies
- Users can only access their own data
- Profiles are private to users
- Weight entries are user-specific

## Feature Implementations

### 1. AI-Powered Food Scanner

#### Components
- **Camera Integration**: Uses device camera for food capture
- **Gemini 2.5 Flash API**: Processes images for nutrition data
- **Fallback System**: Multiple model versions for reliability

#### Flow
```
1. User opens food scanner
2. Captures food image
3. Image sent to Gemini API
4. AI analyzes and returns nutrition data
5. Data displayed and can be logged
```

#### Code Structure
```dart
// lib/services/indian_food_nutrition_service.dart
class IndianFoodNutritionService {
  final modelVersions = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-flash-latest',
  ];

  Future<NutritionInfo> analyzeFood(File image) async {
    // Multi-model fallback logic
    // Detailed nutrition extraction
    // Error handling
  }
}
```

### 2. Weight Progress Tracking

#### Components
- **WeightProvider**: Manages weight data state
- **WeightProgressChart**: Visualizes progress with fl_chart
- **Database Integration**: Auto-sync with profiles

#### UI Features
- Gradient + button for adding entries
- Line chart with trend analysis
- Empty state with clear CTAs
- Real-time updates

#### Fixed Issues
- Database query corrections (user_id → id)
- Trigger function updates
- UI enhancements

### 3. Health Integration

#### HealthKit (iOS)
- Step counting
- Weight sync
- Workout data
- Heart rate monitoring

#### Health Connect (Android)
- Similar features as HealthKit
- Permission management
- Background sync

### 4. User Profile System

#### Features
- Personal information management
- Goal setting (weight, fitness)
- Unit preferences
- Progress tracking
- Avatar management

## Technical Implementation Details

### State Management Flow
```
User Action → Provider → Service → Backend → Provider → UI Update
```

### Data Flow Example (Weight Entry)
```
1. User taps + button
2. Opens weight entry dialog
3. User enters weight
4. WeightProvider.addWeightEntry() called
5. Supabase insert operation
6. Trigger updates profile
7. Real-time subscription updates UI
8. Chart refreshes automatically
```

### API Integration Pattern
```dart
class ServicePattern {
  // Retry logic
  Future<T> withRetry<T>(Future<T> Function() fn) async {
    int attempts = 3;
    while (attempts > 0) {
      try {
        return await fn();
      } catch (e) {
        attempts--;
        if (attempts == 0) rethrow;
        await Future.delayed(Duration(seconds: 2));
      }
    }
  }

  // Error handling
  Future<Result<T>> safeCall<T>(Future<T> Function() fn) async {
    try {
      final data = await fn();
      return Result.success(data);
    } catch (e) {
      return Result.error(e.toString());
    }
  }
}
```

## Security Architecture

### API Key Management
- Stored in `lib/config/api_config.dart`
- Not committed to version control
- Environment-specific configurations

### Authentication Flow
- Supabase Auth handles user authentication
- JWT tokens for API access
- Row Level Security in database
- Secure storage for tokens

### Data Privacy
- User data isolation via RLS
- Encrypted connections
- GDPR compliance considerations
- Local data caching with encryption

## Performance Optimizations

### Image Processing
- Compression before upload
- Lazy loading of images
- Cache management
- Progressive loading

### Database Queries
- Optimized indexes
- Efficient query patterns
- Pagination for large datasets
- Real-time subscriptions management

### UI Rendering
- Widget recycling
- Lazy loading lists
- Image caching
- Smooth animations (60 FPS)

## Deployment Architecture

### Android
```
Build Process:
1. flutter build appbundle --release
2. Sign with keystore
3. Upload to Play Console
4. Gradual rollout
```

### iOS
```
Build Process:
1. flutter build ios --release
2. Archive in Xcode
3. Upload to App Store Connect
4. TestFlight beta testing
5. App Store release
```

## Monitoring & Analytics

### Firebase Analytics
- User engagement tracking
- Feature usage metrics
- Crash reporting
- Performance monitoring

### Custom Events
- Food scan usage
- Weight entry frequency
- Goal achievement
- Feature adoption

## Testing Strategy

### Unit Tests
- Provider logic
- Service functions
- Utility methods
- Model validations

### Integration Tests
- API integrations
- Database operations
- Authentication flow
- Health kit integration

### UI Tests
- Screen navigation
- Form validations
- Chart rendering
- Camera functionality

## Future Architecture Considerations

### Scalability
- Microservices architecture
- CDN for assets
- Database sharding
- Load balancing

### New Features Pipeline
- Social features (separate service)
- ML model hosting
- Video streaming for workouts
- Real-time collaboration

### Technology Upgrades
- Flutter 4.x migration path
- Dart 4.x features
- Supabase v2 features
- New health APIs

## Development Workflow

### Branch Strategy
```
main (production)
├── develop (staging)
├── feature/feature-name
├── bugfix/issue-number
└── hotfix/critical-fix
```

### CI/CD Pipeline
1. Code commit
2. Automated tests
3. Build verification
4. Deploy to staging
5. Manual approval
6. Production deploy

## Error Handling Strategy

### Client-Side
- Try-catch blocks
- User-friendly error messages
- Fallback UI states
- Offline mode support

### Server-Side
- Structured error responses
- Rate limiting
- Request validation
- Graceful degradation

## Documentation Standards

### Code Documentation
- Inline comments for complex logic
- Function documentation
- API documentation
- Architecture decision records

### User Documentation
- In-app help
- FAQ section
- Video tutorials
- Release notes

---
Last Updated: September 29, 2025
Version: 1.0.10