# Frontend Architecture & UI Design System
## Streaks Flutter Application

## Table of Contents
1. [Design System Overview](#design-system-overview)
2. [Color Palette & Theming](#color-palette--theming)
3. [Typography System](#typography-system)
4. [Component Architecture](#component-architecture)
5. [Screen Layouts](#screen-layouts)
6. [Navigation Architecture](#navigation-architecture)
7. [State Management Patterns](#state-management-patterns)
8. [Animation & Interaction Design](#animation--interaction-design)
9. [Responsive Design](#responsive-design)
10. [Performance Optimization](#performance-optimization)
11. [AI Integration Architecture](#ai-integration-architecture)
12. [Device Integration](#device-integration)

---

## Design System Overview

### Design Principles
- **Clarity**: Clear visual hierarchy with distinct primary, secondary, and tertiary information levels
- **Consistency**: Unified design language across all screens and components
- **Accessibility**: High contrast ratios, adequate touch targets, semantic labeling
- **Performance**: Optimized animations and efficient rendering patterns
- **Modularity**: Reusable components with consistent APIs
- **Intelligence**: AI-powered features seamlessly integrated into UI

### Visual Language
- **Card-based Layout**: Primary content organization pattern
- **Rounded Corners**: Consistent 14-20px radius for modern, friendly appearance
- **Subtle Shadows**: Light elevation effects (opacity 0.05-0.06)
- **Gradient Accents**: Strategic use of gradients for emphasis
- **White Space**: Generous padding (16-24px) for visual breathing room
- **Dynamic Content**: Real-time updates from connected devices

### Brand Identity
- **App Icon**: Flame logo representing energy and motivation
- **Primary Color**: Orange (#FF6B1A) - Energy, enthusiasm, action
- **Visual Metaphors**: Fire/flame for streaks, charts for progress

---

## Color Palette & Theming

### Brand Colors (Updated August 2025)
```dart
// Core Brand Color - Orange Theme
primaryAccent: Color(0xFFFF6B1A)       // Vibrant Orange (Main Brand)
primaryHover: Color(0xFFFF8C42)        // Lighter Orange (Hover State)
```

### Theme-Specific Colors

#### Light Theme
```dart
// Backgrounds
backgroundLight: Color(0xFFFFFFFF)      // Pure White Background
cardBackgroundLight: Color(0xFFF8F9FA)  // Light Grey Card Surface

// Text Colors
textPrimary: Color(0xFF111111)          // Almost Black Text
textSecondary: Color(0xFF4F4F4F)        // Grey Secondary Text
textLight: Color(0xFF4F4F4F)            // Light Grey Text

// UI Elements
dividerLight: Color(0xFFE0E0E0)         // Light Divider
secondaryLight: Color(0xFF2D7EF5)       // Blue Accent
```

#### Dark Theme
```dart
// Backgrounds
darkBackground: Color(0xFF121212)       // Pure Dark Background
darkCardBackground: Color(0xFF1C1C1E)   // Elevated Dark Surface

// Text Colors
textPrimaryDark: Color(0xFFFFFFFF)      // White Text
textSecondaryDark: Color(0xFFB3B3B3)    // Light Grey Text

// UI Elements
dividerDark: Color(0xFF2E2E2E)          // Dark Divider
secondaryDark: Color(0xFF4A90E2)        // Blue Accent Dark
```

### Status Colors (Consistent Across Themes)
```dart
successGreen: Color(0xFF00D68F)         // Success States
warningYellow: Color(0xFFFFAA00)        // Warning States
errorRed: Color(0xFFFF3838)             // Error States
infoBlue: Color(0xFF0095FF)             // Information States
```

### Gradient Definitions
```dart
primaryGradient: LinearGradient(
  colors: [Color(0xFFFF6B1A), Color(0xFFFF8C42)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```

---

## Typography System

### Font Family
- **Primary**: System Default (San Francisco on iOS, Roboto on Android)
- **Weights**: 400 (Regular), 500 (Medium), 600 (SemiBold), 700 (Bold)

### Type Scale
```dart
// Display
displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)
displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)
displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)

// Headlines
headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)
headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)

// Titles
titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)
titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)

// Body
bodyLarge: TextStyle(fontSize: 16, height: 1.5)
bodyMedium: TextStyle(fontSize: 14, height: 1.5)
bodySmall: TextStyle(fontSize: 12, height: 1.5)

// Labels
labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)
labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)
labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)
```

---

## Component Architecture

### Core Components

#### 1. Cards
```dart
Card(
  elevation: 0,
  color: Theme.of(context).cardColor,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
)
```

#### 2. Buttons
```dart
// Primary Button
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primaryAccent,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  ),
)

// Secondary Button
OutlinedButton(
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: AppTheme.primaryAccent, width: 2),
  ),
)
```

#### 3. Input Fields
```dart
TextFormField(
  decoration: InputDecoration(
    filled: true,
    fillColor: Theme.of(context).cardColor,
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  ),
)
```

#### 4. Dialogs (Theme-Aware)
```dart
AlertDialog(
  backgroundColor: isDarkMode 
    ? AppTheme.darkCardBackground 
    : AppTheme.cardBackgroundLight,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
)
```

### Custom Widgets

#### MetricCard
- Displays health metrics with icon, value, and trend
- Supports gradient backgrounds
- Animated value changes

#### NutritionCard
- Shows nutrition information with progress bars
- AI-analyzed nutrition display
- Macro breakdown visualization

#### AchievementBadge
- Circular/square badges for milestones
- Progress indicators
- Locked/unlocked states

#### InsightCard
- Personalized recommendation display
- Icon + title + description layout
- Action buttons for quick actions

---

## Screen Layouts

### Main Navigation Structure
```
BottomNavigationBar
├── Home (Dashboard)
├── Progress (Analytics)
├── Nutrition (Food Tracking)
├── Workouts (Exercise)
└── Profile (Settings)
```

### Screen-Specific Layouts

#### Home Screen
```
AppBar (with sync indicator)
├── Greeting Section
├── Quick Stats Grid (2x2)
├── Insights Carousel
├── Recent Activities List
└── Quick Actions FAB (removed)
```

#### Nutrition Screen
```
AppBar with Actions
├── TabBar (Today/History)
├── Nutrition Overview Card
├── Macro Breakdown Chart
├── Meals List/Timeline
└── Camera FAB (AI Scan)
```

#### Progress Screen
```
ScrollView
├── Streak Calendar
├── Statistics Grid
├── Progress Charts
├── Achievements Grid (1.8 aspect ratio)
└── Milestones Timeline
```

#### Profile Screen
```
ScrollView
├── Profile Header (Avatar + Name)
├── Stats Summary
├── Settings List
│   ├── Personal Information
│   ├── Smartwatch Integration
│   ├── Goals & Targets
│   ├── Notifications
│   └── Privacy & Security
└── Logout Button
```

---

## Navigation Architecture

### Navigation Patterns

#### Bottom Navigation
- Persistent across main screens
- Badge support for notifications
- Animated transitions

#### Stack Navigation
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TargetScreen(),
  ),
)
```

#### Tab Navigation
- Used in Nutrition and Progress screens
- Swipeable with indicators
- Preserves state between tabs

### Route Management
```dart
// Named Routes
'/': (context) => SplashScreen(),
'/onboarding': (context) => OnboardingScreen(),
'/auth': (context) => AuthScreen(),
'/main': (context) => MainScreen(),
'/profile/edit': (context) => EditProfileScreen(),
'/settings/smartwatch': (context) => SmartwatchSettingsScreen(),
```

---

## State Management Patterns

### Provider Architecture

#### Provider Hierarchy
```dart
MultiProvider(
  providers: [
    // Local Providers (Primary)
    ChangeNotifierProvider(create: (_) => UserProvider(prefs)),
    ChangeNotifierProvider(create: (_) => HealthProvider(prefs)),
    ChangeNotifierProvider(create: (_) => NutritionProvider(prefs)),
    ChangeNotifierProvider(create: (_) => WorkoutProvider()),
    
    // Cloud Providers (Backup)
    ChangeNotifierProvider(create: (_) => SupabaseUserProvider()),
    ChangeNotifierProvider(create: (_) => SupabaseNutritionProvider()),
  ],
)
```

#### Consumer Patterns
```dart
// Single Provider
Consumer<HealthProvider>(
  builder: (context, healthProvider, child) {
    return MetricCard(
      value: healthProvider.todaySteps,
    );
  },
)

// Multiple Providers
Consumer2<HealthProvider, NutritionProvider>(
  builder: (context, health, nutrition, child) {
    return InsightsList(
      health: health,
      nutrition: nutrition,
    );
  },
)
```

#### Selective Rebuilds
```dart
Selector<HealthProvider, int>(
  selector: (context, provider) => provider.todaySteps,
  builder: (context, steps, child) {
    return Text('$steps steps');
  },
)
```

---

## Animation & Interaction Design

### Animation Types

#### Micro-animations
- Button press: Scale 0.95 with 150ms duration
- Card hover: Elevation change with shadow
- Value changes: AnimatedCounter widget
- Progress bars: Animated fill with curves

#### Page Transitions
```dart
PageRouteBuilder(
  transitionDuration: Duration(milliseconds: 300),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      )),
      child: child,
    );
  },
)
```

#### Loading States
- Shimmer effects for content loading
- Skeleton screens for initial load
- Pull-to-refresh with custom indicators
- Progress indicators during AI analysis

### Gesture Interactions
- Swipe to delete/dismiss
- Pull to refresh
- Long press for context menus
- Pinch to zoom on charts
- Drag to reorder lists

---

## Responsive Design

### Breakpoints
```dart
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}
```

### Adaptive Layouts
```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < Breakpoints.mobile) {
      return MobileLayout();
    } else if (constraints.maxWidth < Breakpoints.tablet) {
      return TabletLayout();
    } else {
      return DesktopLayout();
    }
  },
)
```

### Grid Configurations
- Mobile: 2 columns
- Tablet: 3-4 columns
- Desktop: 4-6 columns

### Text Scaling
- Support for system text size preferences
- Minimum and maximum scale factors
- Responsive line heights

---

## Performance Optimization

### Image Optimization
- Lazy loading for lists
- Cached network images
- Compressed thumbnails
- Progressive image loading

### List Performance
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListItem(items[index]);
  },
  cacheExtent: 100,
)
```

### State Optimization
- Minimize rebuilds with const widgets
- Use keys for list items
- Implement AutomaticKeepAliveClientMixin
- Debounce search and input operations

### Memory Management
- Dispose controllers and listeners
- Clear image cache on low memory
- Paginate large data sets
- Use compute for heavy processing

---

## AI Integration Architecture

### AI Services

#### Nutrition AI Service
```dart
class NutritionAIService {
  // Image Analysis Pipeline
  analyzeFood(imagePath) → 
    Vision API → 
    Food Detection → 
    Nutrition Database → 
    NutritionEntry
  
  // Fallback Strategy
  if (API fails) → Local Database
  if (No match) → Manual Entry
}
```

#### Insights Engine
```dart
class InsightsEngine {
  // Data Analysis
  analyze(health, nutrition, activity) →
    Pattern Recognition →
    Recommendation Generation →
    Priority Sorting →
    Personalized Insights
}
```

### AI UI Components
- Loading states during analysis
- Confidence indicators
- Correction/feedback options
- Manual override controls

---

## Device Integration

### Smartwatch Connection
```dart
class SmartwatchIntegration {
  // Connection Flow
  Device Selection →
  Permission Request →
  Pairing Process →
  Data Sync Setup →
  Real-time Updates
}
```

### Sync Indicators
- Connection status badge
- Last sync timestamp
- Sync progress indicator
- Error state handling

### Data Flow
```
Device → Bluetooth/API → Service → Provider → UI
         ↓                ↓           ↓
      Fallback        Cache      Update
```

---

## Accessibility Features

### Visual Accessibility
- High contrast mode support
- Dynamic type support
- Color blind friendly palettes
- Focus indicators

### Screen Reader Support
- Semantic labels
- Navigation announcements
- Action hints
- Content descriptions

### Interaction Accessibility
- Minimum touch targets (44x44)
- Gesture alternatives
- Keyboard navigation
- Voice control ready

---

## Testing Strategies

### UI Testing
```dart
testWidgets('Home screen displays metrics', (tester) async {
  await tester.pumpWidget(MaterialApp(home: HomeScreen()));
  expect(find.text('Today\'s Steps'), findsOneWidget);
  expect(find.byType(MetricCard), findsNWidgets(4));
});
```

### Golden Tests
- Screenshot comparisons
- Theme variation testing
- Device size testing
- Accessibility testing

### Integration Testing
- User flow testing
- Navigation testing
- Provider state testing
- API integration testing

---

## Documentation Standards

### Widget Documentation
```dart
/// A card displaying a single health metric.
/// 
/// Shows the metric name, current value, goal, and progress.
/// Supports both light and dark themes.
/// 
/// Example:
/// ```dart
/// MetricCard(
///   title: 'Steps',
///   value: 5000,
///   goal: 10000,
///   icon: Icons.directions_walk,
/// )
/// ```
class MetricCard extends StatelessWidget {
  // Implementation
}
```

### Style Guide
- Component usage examples
- Do's and don'ts
- Accessibility requirements
- Performance considerations

---

## Version History

### v1.0.0 (August 2025)
- Initial architecture
- Core screens implementation
- Basic provider setup
- Theme system

### v1.1.0 (August 2025)
- AI nutrition analysis
- Smartwatch integration
- Theme fixes
- Performance optimizations
- App icon update

---

*Last Updated: August 27, 2025*
*Maintained by: Development Team*
*AI Assistance: Claude Code*