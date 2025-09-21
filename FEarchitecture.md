# Streaks Flutter - Feature Architecture

## Core Features

### 1. Health Data Integration
- **Samsung Health** (Primary source via Health Connect)
- **Google Fit** (Secondary fallback)
- **Manual Entry** (Tertiary option)

### 2. Nutrition Tracking
- Food scanning with camera
- Indian food database integration
- Manual nutrition entry
- Daily totals calculation
- Sync with Supabase

### 3. Achievement System
- Dynamic achievement tracking
- Progress visualization
- Milestone notifications

### 4. Streak Tracking
- Daily goal completion
- Streak persistence
- Recovery mechanisms

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

### Providers (State Management)
- **HealthProvider**: Central health metrics state
- **NutritionProvider**: Nutrition entries and totals
- **StreakProvider**: Streak calculation and persistence
- **AchievementProvider**: Achievement progress tracking
- **UserProvider**: User profile and preferences

### Services (Business Logic)
- **UnifiedHealthService**: Health source routing
- **SupabaseService**: Database operations
- **IndianFoodNutritionService**: Food database
- **RealtimeSyncService**: Real-time data sync
- **HealthOnboardingService**: Permission management

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
- Network condition simulation
