# Feature Architecture Documentation

## Overview
This document outlines the architecture and implementation details of major features in the Streaker app, providing context for future development and maintenance.

## Weight Progress Feature

### Migration from Profile to Progress Screen
**Date**: December 2024
**Status**: Completed

#### Architecture Overview
The weight progress feature has been migrated from the Profile screen to the Progress screen to better align with the app's user experience design. The feature now appears as the second widget in the Progress tab, positioned below the weekly progress chart.

#### Component Structure

##### 1. Provider Layer (`lib/providers/weight_provider.dart`)
- **Purpose**: State management for weight data using Provider pattern
- **Key Features**:
  - Supabase integration for data persistence
  - Cache management with 5-minute validity
  - Graceful error handling for missing database tables
  - Real-time weight tracking and trend calculations

**Error Handling Strategy**:
```dart
// Handles missing weight_entries table gracefully
try {
  entriesResponse = await _supabase.from('weight_entries').select()...
} catch (e) {
  debugPrint('weight_entries table not found or error: $e');
  entriesResponse = []; // Continue with empty entries
}
```

##### 2. Widget Components

**WeightProgressChart** (`lib/widgets/weight_progress_chart.dart`)
- Interactive line graph using fl_chart library
- Two display modes:
  - Compact mode: For Progress screen overview
  - Full mode: For detailed view in WeightDetailsScreen
- Features:
  - Touch interactions for viewing specific data points
  - Animated transitions
  - Actual weight line vs target weight line
  - Dynamic Y-axis scaling

**Integration Points**:
- Progress Screen: Displays compact chart with navigation to details
- Weight Details Screen: Full chart with complete history

##### 3. Database Architecture

**Tables**:
- `weight_entries`: Stores individual weight measurements
  - Fields: id, user_id, weight, timestamp, note
  - RLS policies for user data isolation

- `profiles`: Extended with weight-related fields
  - Fields: weight, target_weight, weight_unit

**Triggers**:
- `update_profile_weight`: Automatically syncs latest weight entry to profile
- Maintains data consistency between tables

##### 4. Screen Integration

**Progress Screen** (`lib/screens/main/progress_screen_new.dart`)
- Widget Order (after reordering):
  1. Milestone Progress Ring (centered, main feature)
  2. Weekly Progress Chart
  3. Weight Progress Chart (newly added)
  4. Other widgets...

**Profile Screen** (`lib/screens/main/profile_screen.dart`)
- Weight section completely removed
- All weight-related methods and imports cleaned up
- Users now navigate to Progress tab for weight tracking

#### Data Flow
1. User adds weight entry → WeightProvider → Supabase
2. Trigger updates profile table with latest weight
3. Provider notifies listeners → UI updates
4. Chart displays historical data with trend lines

#### Migration Checklist
- [x] Create WeightProvider with Supabase integration
- [x] Implement WeightProgressChart widget with fl_chart
- [x] Create WeightDetailsScreen for management
- [x] Add database migration script
- [x] Integrate into Progress screen
- [x] Remove from Profile screen
- [x] Handle missing database table errors
- [x] Reorder widgets (Milestone first)
- [x] Test on physical devices

## Milestone Progress Feature

### Architecture
The milestone progress ring is the primary visual element in the Progress screen, displaying user's overall streak achievement.

#### Components
- **MilestoneProgressRing**: Custom circular progress widget
- Positioned as the first element in Progress screen for maximum visibility
- Size: 160px with 16px stroke width
- Centered with max width constraint of 300px

## Weekly Progress Chart

### Architecture
Displays user's weekly activity patterns and consistency.

#### Integration
- Positioned between Milestone Ring and Weight Progress
- Uses similar charting patterns as Weight Progress for consistency
- Shares color scheme and animation patterns

## Navigation Architecture

### Bottom Navigation Structure
1. **Home Tab**: Dashboard and quick actions
2. **Progress Tab**:
   - Milestone achievements
   - Weekly progress
   - Weight tracking (newly added)
3. **Profile Tab**: User settings and preferences (weight section removed)

## State Management

### Provider Pattern Implementation
- All features use Provider for state management
- Providers initialized at app root level
- Lazy loading with cache management for performance

### Cache Strategy
- 5-minute cache validity for weight data
- Force refresh available via pull-to-refresh
- Automatic refresh on data mutations

## Error Handling Philosophy

### Graceful Degradation
- Features continue to work even if backend tables don't exist
- Clear error messages with retry options
- Fallback to cached data when available

### User Feedback
- Success notifications for data operations
- Clear error messages with actionable solutions
- Loading states for all async operations

## Future Enhancements

### Planned Features
1. **Data Export**: Allow users to export weight history
2. **Advanced Analytics**: BMI calculations, body composition
3. **Goal Setting**: Multiple weight goals with timelines
4. **Social Features**: Share progress with accountability partners

### Technical Debt
1. Consider migrating to Riverpod for better type safety
2. Implement offline-first architecture with sync
3. Add comprehensive widget tests for chart components

## Testing Strategy

### Unit Tests
- Provider logic with mock Supabase client
- Calculation methods (trends, projections)

### Widget Tests
- Chart rendering with various data sets
- Error state handling
- User interactions

### Integration Tests
- Complete user flows from adding weight to viewing trends
- Database trigger verification
- Navigation between screens

## Performance Considerations

### Optimizations Implemented
- Lazy loading of chart data
- Debounced chart animations
- Efficient list rendering with Dismissible widgets

### Monitoring Points
- Chart rendering performance with large datasets
- Database query optimization
- Memory usage during chart animations

## Security Considerations

### Row Level Security
- All weight_entries protected by user_id policies
- Users can only access their own data
- Triggers respect RLS policies

### Data Validation
- Weight range validation (1-500 kg/lbs)
- Timestamp validation for entries
- Input sanitization for notes

## Deployment Notes

### Database Migration
Run migration script before deploying:
```sql
-- Creates weight_entries table with RLS
-- Adds weight fields to profiles
-- Creates necessary triggers
```

### Version Compatibility
- Minimum Flutter SDK: 2.0.0
- fl_chart: ^0.68.0
- Supabase Flutter: ^2.0.0

## Documentation References
- [Weight Provider Implementation](lib/providers/weight_provider.dart)
- [Weight Chart Widget](lib/widgets/weight_progress_chart.dart)
- [Database Schema](supabase/migrations/weight_entries_table.sql)
- [Knowledge Base](knowledge.md)