# Frontend Architecture & Design - Streaks Flutter

## Architecture Overview

### **Design Philosophy**
The Streaks Flutter app follows a **modular, scalable architecture** with clear separation of concerns, consistent design patterns, and maintainable code structure.

**Core Principles:**
- **Single Responsibility:** Each component has one clear purpose
- **Composition over Inheritance:** Build complex UIs from simple components
- **Declarative UI:** Describe what the UI should look like, not how to achieve it
- **State Isolation:** Keep state management predictable and testable

## Frontend Architecture Layers

### **1. Presentation Layer**
```
lib/screens/
├── auth/                    # Authentication screens
├── main/                    # Core application screens  
├── onboarding/             # First-time user experience
└── shared/                 # Reusable screen components
```

**Responsibilities:**
- User interface rendering
- User interaction handling
- Navigation flow management
- Screen-level state coordination

### **2. Component Layer**
```
lib/widgets/
├── common/                 # Generic reusable components
├── forms/                  # Form-specific components
├── cards/                  # Data display components
├── charts/                 # Data visualization components
└── overlays/               # Modal and popup components
```

**Responsibilities:**
- Reusable UI components
- Component-level state management
- Props/parameter validation
- Component composition patterns

### **3. State Management Layer**
```
lib/providers/
├── auth_provider.dart      # Authentication state
├── user_provider.dart      # User profile state
├── nutrition_provider.dart # Nutrition tracking state
├── progress_provider.dart  # Progress tracking state
└── chat_provider.dart      # Chat interface state
```

**Responsibilities:**
- Global state management
- Business logic coordination
- Data flow orchestration
- State persistence coordination

### **4. Data Layer**
```
lib/services/
├── storage_service.dart    # Local storage abstraction
├── api_service.dart        # Remote API communication
├── image_service.dart      # Image processing
└── notification_service.dart # Push notifications
```

**Responsibilities:**
- Data persistence and retrieval
- External service integration
- Data transformation and validation
- Error handling and recovery

## Component Architecture

### **Component Hierarchy**
```
MyApp (Root)
├── AuthenticationWrapper
│   ├── WelcomeScreen
│   ├── SignInScreen
│   └── SignUpScreen
└── MainApp
    ├── MainScreen (BottomNavigation)
    │   ├── HomeScreen
    │   │   ├── StreakCard
    │   │   ├── QuickActionCard[]
    │   │   └── NutritionOverviewCard
    │   ├── ProgressScreen
    │   │   ├── ProgressMetricCard[]
    │   │   ├── AchievementBadge[]
    │   │   └── ProgressChart
    │   ├── NutritionScreen
    │   │   ├── DailyNutritionCard
    │   │   ├── NutritionEntryCard[]
    │   │   └── AddFoodModal
    │   ├── ChatScreen
    │   │   ├── MessageBubble[]
    │   │   ├── ChatInput
    │   │   └── TypingIndicator
    │   └── ProfileScreen
    │       ├── ProfileHeader
    │       ├── SettingsCard[]
    │       └── GoalsConfiguration
    └── OnboardingScreen
        ├── OnboardingSlide[]
        └── OnboardingNavigation
```

### **Component Design Patterns**

#### **1. Container-Presentational Pattern**
```dart
// Container Component (Smart)
class NutritionScreenContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<NutritionProvider>(
      builder: (context, nutrition, child) {
        return NutritionScreenView(
          entries: nutrition.todaysEntries,
          dailyGoals: nutrition.dailyGoals,
          onAddFood: nutrition.addFoodEntry,
          onDeleteEntry: nutrition.deleteEntry,
        );
      },
    );
  }
}

// Presentational Component (Dumb)
class NutritionScreenView extends StatelessWidget {
  final List<NutritionEntry> entries;
  final DailyGoals dailyGoals;
  final Function(NutritionEntry) onAddFood;
  final Function(String) onDeleteEntry;

  const NutritionScreenView({
    required this.entries,
    required this.dailyGoals,
    required this.onAddFood,
    required this.onDeleteEntry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Pure UI rendering logic
    );
  }
}
```

#### **2. Composition Pattern**
```dart
class MetricCard extends StatelessWidget {
  final String title;
  final Widget content;
  final Widget? trailing;
  final VoidCallback? onTap;

  // Flexible composition through widgets
  const MetricCard({
    required this.title,
    required this.content,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(title),
              content, // Flexible content composition
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

// Usage Examples
MetricCard(
  title: "Calories",
  content: CircularProgressWidget(
    progress: calorieProgress,
    child: Text('${calories}'),
  ),
  trailing: Text('${remaining} left'),
);

MetricCard(
  title: "Streak",
  content: Text('${streakDays} days'),
  trailing: Icon(Icons.local_fire_department),
);
```

#### **3. Builder Pattern for Complex Widgets**
```dart
class ProgressChartBuilder {
  List<ProgressDataPoint> _dataPoints = [];
  Color _primaryColor = AppTheme.accentOrange;
  Duration _animationDuration = Duration(milliseconds: 1000);
  
  ProgressChartBuilder setData(List<ProgressDataPoint> data) {
    _dataPoints = data;
    return this;
  }
  
  ProgressChartBuilder setColor(Color color) {
    _primaryColor = color;
    return this;
  }
  
  ProgressChartBuilder setAnimationDuration(Duration duration) {
    _animationDuration = duration;
    return this;
  }
  
  Widget build() {
    return ProgressChart(
      dataPoints: _dataPoints,
      color: _primaryColor,
      animationDuration: _animationDuration,
    );
  }
}

// Usage
Widget chart = ProgressChartBuilder()
  .setData(weeklyData)
  .setColor(AppTheme.successGreen)
  .setAnimationDuration(Duration(milliseconds: 1500))
  .build();
```

## State Management Architecture

### **Provider Pattern Implementation**

#### **1. Provider Structure**
```dart
// Base Provider Class
abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  void clearError() => setError(null);
}

// Implementation Example
class NutritionProvider extends BaseProvider {
  List<NutritionEntry> _entries = [];
  DailyGoals _goals = DailyGoals.defaultGoals();
  
  List<NutritionEntry> get entries => _entries;
  DailyGoals get goals => _goals;
  
  // Computed properties
  int get totalCalories => _entries.fold(0, (sum, entry) => sum + entry.calories);
  double get calorieProgress => goals.calorieGoal > 0 
    ? (totalCalories / goals.calorieGoal).clamp(0.0, 1.0) 
    : 0.0;
  
  Future<void> addEntry(NutritionEntry entry) async {
    try {
      setLoading(true);
      clearError();
      
      _entries.add(entry);
      await _saveToStorage();
      
      notifyListeners();
    } catch (e) {
      setError('Failed to add nutrition entry: $e');
    } finally {
      setLoading(false);
    }
  }
}
```

#### **2. State Flow Architecture**
```
User Action → Provider Method → State Update → UI Rebuild
     ↓              ↓              ↓            ↓
  onTap()  →  addFoodEntry()  →  _entries++  → Consumer
```

#### **3. Provider Composition**
```dart
class MultiProviderSetup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        
        // Feature providers (depend on core providers)
        ChangeNotifierProxyProvider<UserProvider, NutritionProvider>(
          create: (_) => NutritionProvider(),
          update: (_, userProvider, nutritionProvider) {
            return nutritionProvider!..updateUser(userProvider.currentUser);
          },
        ),
        
        // Service providers
        Provider(create: (_) => StorageService()),
        Provider(create: (_) => ImageService()),
      ],
      child: MyApp(),
    );
  }
}
```

## Design System Architecture

### **Theme Architecture**
```dart
class AppTheme {
  // Color System
  static const ColorScheme _colorScheme = ColorScheme.dark(
    primary: _accentOrange,
    secondary: _accentOrange,
    surface: _secondaryBackground,
    background: _primaryBackground,
    error: _errorRed,
    onPrimary: _textPrimary,
    onSecondary: _textPrimary,
    onSurface: _textPrimary,
    onBackground: _textPrimary,
    onError: _textPrimary,
  );
  
  // Typography System
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.25,
      color: _textPrimary,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
      color: _textPrimary,
    ),
    // ... complete type scale
  );
  
  // Component Themes
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _colorScheme,
    textTheme: _textTheme,
    
    // Component customizations
    elevatedButtonTheme: _elevatedButtonTheme,
    cardTheme: _cardTheme,
    inputDecorationTheme: _inputDecorationTheme,
    appBarTheme: _appBarTheme,
    bottomNavigationBarTheme: _bottomNavTheme,
  );
}
```

### **Component Styling Strategy**

#### **1. Design Tokens**
```dart
class DesignTokens {
  // Spacing Scale
  static const double space0 = 0;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  
  // Border Radius Scale
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  
  // Shadow Elevations
  static const double elevation0 = 0;
  static const double elevation1 = 1;
  static const double elevation2 = 2;
  static const double elevation4 = 4;
  static const double elevation8 = 8;
}
```

#### **2. Styled Components Pattern**
```dart
class StyledCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final bool elevated;
  
  const StyledCard({
    required this.child,
    this.padding,
    this.onTap,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? EdgeInsets.all(DesignTokens.space4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(
            color: theme.colorScheme.outline,
            width: 1,
          ),
          boxShadow: elevated ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: DesignTokens.elevation4,
              offset: Offset(0, 2),
            ),
          ] : null,
        ),
        child: child,
      ),
    );
  }
}
```

## Navigation Architecture

### **Navigation Structure**
```dart
class NavigationStructure {
  static final Map<String, WidgetBuilder> routes = {
    '/': (context) => AuthenticationWrapper(),
    '/welcome': (context) => WelcomeScreen(),
    '/signin': (context) => SignInScreen(),
    '/signup': (context) => SignUpScreen(),
    '/onboarding': (context) => OnboardingScreen(),
    '/main': (context) => MainScreen(),
    '/profile-edit': (context) => ProfileEditScreen(),
    '/nutrition-details': (context) => NutritionDetailsScreen(),
    '/progress-history': (context) => ProgressHistoryScreen(),
  };
  
  // Bottom Navigation Configuration
  static const List<BottomNavItem> bottomNavItems = [
    BottomNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
      screen: HomeScreen,
    ),
    BottomNavItem(
      icon: Icons.trending_up_outlined,
      selectedIcon: Icons.trending_up,
      label: 'Progress',
      screen: ProgressScreen,
    ),
    BottomNavItem(
      icon: Icons.restaurant_outlined,
      selectedIcon: Icons.restaurant,
      label: 'Nutrition',
      screen: NutritionScreen,
    ),
    BottomNavItem(
      icon: Icons.chat_outlined,
      selectedIcon: Icons.chat,
      label: 'Streaker',
      screen: ChatScreen,
    ),
    BottomNavItem(
      icon: Icons.person_outlined,
      selectedIcon: Icons.person,
      label: 'Profile',
      screen: ProfileScreen,
    ),
  ];
}
```

### **Navigation Patterns**

#### **1. Hierarchical Navigation**
```dart
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed<T>(routeName, arguments: arguments);
  }
  
  static void pop<T>([T? result]) {
    return navigatorKey.currentState!.pop<T>(result);
  }
  
  static Future<T?> pushReplacementNamed<T, TO>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushReplacementNamed<T, TO>(routeName, arguments: arguments);
  }
  
  // Authentication flow navigation
  static void navigateToAuth() {
    pushReplacementNamed('/welcome');
  }
  
  static void navigateToMain() {
    pushReplacementNamed('/main');
  }
  
  static void navigateToOnboarding() {
    pushReplacementNamed('/onboarding');
  }
}
```

#### **2. Modal Navigation**
```dart
class ModalService {
  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: child,
        ),
      ),
    );
  }
  
  static Future<T?> showDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        child: child,
      ),
    );
  }
}
```

## Animation & Interaction Architecture

### **Animation System**
```dart
class AnimationSystem {
  // Standard durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  
  // Standard curves
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve bounce = Curves.bounceOut;
  
  // Page transitions
  static PageRouteBuilder<T> slideTransition<T>({
    required Widget child,
    required RouteSettings settings,
    Offset beginOffset = const Offset(1.0, 0.0),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(
            Tween(begin: beginOffset, end: Offset.zero).chain(
              CurveTween(curve: easeInOut),
            ),
          ),
          child: child,
        );
      },
      transitionDuration: normal,
    );
  }
  
  // Micro-interactions
  static Widget scaleOnTap({
    required Widget child,
    required VoidCallback onTap,
    double scaleValue = 0.95,
  }) {
    return TapScaleAnimation(
      scaleValue: scaleValue,
      onTap: onTap,
      child: child,
    );
  }
}
```

### **Gesture Handling**
```dart
class GesturePatterns {
  // Swipe gesture handling
  static Widget swipeToDelete({
    required Widget child,
    required VoidCallback onDelete,
    Color backgroundColor = Colors.red,
  }) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: backgroundColor,
        padding: EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => onDelete(),
      child: child,
    );
  }
  
  // Pull to refresh
  static Widget pullToRefresh({
    required Widget child,
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.accentOrange,
      backgroundColor: AppTheme.secondaryBackground,
      child: child,
    );
  }
}
```

## Performance Architecture

### **Optimization Strategies**

#### **1. Widget Optimization**
```dart
class OptimizedListView extends StatelessWidget {
  final List<dynamic> items;
  final Widget Function(BuildContext, dynamic, int) itemBuilder;
  
  const OptimizedListView({
    required this.items,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // Only build visible items
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return RepaintBoundary(
          // Isolate repaints
          child: itemBuilder(context, item, index),
        );
      },
      // Performance optimizations
      cacheExtent: 200.0,
      physics: const BouncingScrollPhysics(),
    );
  }
}
```

#### **2. State Optimization**
```dart
class OptimizedProvider extends ChangeNotifier {
  Map<String, dynamic> _cache = {};
  
  T getCachedValue<T>(String key, T Function() computeValue) {
    if (_cache.containsKey(key)) {
      return _cache[key] as T;
    }
    
    final value = computeValue();
    _cache[key] = value;
    return value;
  }
  
  void invalidateCache([String? key]) {
    if (key != null) {
      _cache.remove(key);
    } else {
      _cache.clear();
    }
  }
  
  @override
  void notifyListeners() {
    invalidateCache(); // Clear cache on state changes
    super.notifyListeners();
  }
}
```

#### **3. Image Optimization**
```dart
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  
  const OptimizedImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => ShimmerPlaceholder(
        width: width,
        height: height,
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: Icon(Icons.error),
      ),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
    );
  }
}
```

## Testing Architecture

### **Testing Strategy**
```dart
// Widget Testing
class WidgetTestHelpers {
  static Widget wrapWithProviders(
    Widget widget, {
    List<ChangeNotifierProvider>? providers,
  }) {
    return MultiProvider(
      providers: providers ?? [
        ChangeNotifierProvider(create: (_) => MockAuthProvider()),
        ChangeNotifierProvider(create: (_) => MockNutritionProvider()),
      ],
      child: MaterialApp(home: widget),
    );
  }
  
  static Future<void> pumpAndSettle(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(wrapWithProviders(widget));
    await tester.pumpAndSettle();
  }
}

// Example Widget Test
void main() {
  group('MetricCard Widget Tests', () {
    testWidgets('displays title and value correctly', (tester) async {
      const title = 'Calories';
      const value = '1,250';
      
      await WidgetTestHelpers.pumpAndSettle(
        tester,
        MetricCard(
          title: title,
          value: value,
        ),
      );
      
      expect(find.text(title), findsOneWidget);
      expect(find.text(value), findsOneWidget);
    });
    
    testWidgets('handles tap events', (tester) async {
      bool tapped = false;
      
      await WidgetTestHelpers.pumpAndSettle(
        tester,
        MetricCard(
          title: 'Test',
          value: '123',
          onTap: () => tapped = true,
        ),
      );
      
      await tester.tap(find.byType(MetricCard));
      expect(tapped, isTrue);
    });
  });
}
```

## Accessibility Architecture

### **Accessibility Implementation**
```dart
class AccessibilityHelpers {
  static Widget semanticWrapper({
    required Widget child,
    required String label,
    String? hint,
    bool? focusable,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      focusable: focusable,
      onTap: onTap,
      child: child,
    );
  }
  
  static Widget accessibleCard({
    required String title,
    required String value,
    String? description,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return semanticWrapper(
      label: '$title: $value',
      hint: description,
      onTap: onTap,
      child: child,
    );
  }
}

// Usage in Components
class AccessibleMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AccessibilityHelpers.accessibleCard(
      title: title,
      value: value,
      description: description,
      onTap: onTap,
      child: Card(
        child: Column(
          children: [
            Text(title),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}
```

## Error Handling Architecture

### **Error Boundary Pattern**
```dart
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace stackTrace)? errorBuilder;
  
  const ErrorBoundary({
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? error;
  StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return widget.errorBuilder?.call(error!, stackTrace!) ?? 
        DefaultErrorWidget(error: error!, stackTrace: stackTrace!);
    }
    
    return ErrorWidget.builder = (FlutterErrorDetails details) {
      setState(() {
        error = details.exception;
        stackTrace = details.stack;
      });
      return Container();
    };
    
    return widget.child;
  }
}

// Global Error Handling
class ErrorService {
  static void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      _logError(details.exception, details.stack);
    };
    
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _logError(error, stack);
      return true;
    };
  }
  
  static void _logError(Object error, StackTrace? stack) {
    print('Error: $error');
    print('Stack: $stack');
    // Send to crash reporting service
  }
}
```

## Build & Deployment Architecture

### **Build Configuration**
```dart
class BuildConfig {
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.streaks.local',
  );
  
  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  
  // Feature flags
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: false,
  );
  
  static const bool enableCrashReporting = bool.fromEnvironment(
    'ENABLE_CRASH_REPORTING',
    defaultValue: false,
  );
}
```

### **Deployment Scripts**
```yaml
# build_config.yaml
environments:
  development:
    api_url: "https://api-dev.streaks.com"
    enable_logging: true
    enable_debug_tools: true
    
  staging:
    api_url: "https://api-staging.streaks.com"
    enable_logging: true
    enable_debug_tools: false
    
  production:
    api_url: "https://api.streaks.com"
    enable_logging: false
    enable_debug_tools: false
```

---

**Generated:** August 21, 2025  
**Author:** Claude Code Assistant  
**Project:** Streaks Flutter App  
**Status:** Architecture Documentation ✅