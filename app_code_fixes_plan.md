# Flutter App Code Fixes Plan
**Phase 2: Application Code Updates**

Based on the integration test results and database schema analysis, the following Flutter app code fixes are required:

## 🎯 **Critical Issues to Fix**

### 1. **Nutrition Provider Type Casting (Priority: Critical)**
**File:** `lib/providers/supabase_nutrition_provider.dart`
**Error:** `type 'String' is not a subtype of type 'List<dynamic>' in type cast`

**Root Cause:**
- App expects JSON array data but database returns string
- Inconsistent data serialization/deserialization

**Solution:**
```dart
// Fix JSON parsing in nutrition data
Map<String, dynamic> parseNutritionData(dynamic data) {
  if (data is String) {
    try {
      return json.decode(data);
    } catch (e) {
      // Handle malformed JSON
      return {};
    }
  }
  return data as Map<String, dynamic>;
}

// Update all nutrition data handlers
List<dynamic> parseIngredientsList(dynamic ingredients) {
  if (ingredients == null) return [];
  if (ingredients is String) {
    try {
      return json.decode(ingredients);
    } catch (e) {
      return [ingredients]; // Treat as single ingredient
    }
  }
  if (ingredients is List) return ingredients;
  return [ingredients.toString()];
}
```

### 2. **Health Metrics Constraint Handling (Priority: High)**
**File:** `lib/services/enhanced_supabase_service.dart`
**Error:** Heart rate constraint violations (40-200 BPM too restrictive)

**Solution:**
```dart
Future<void> saveHealthMetrics({
  // ... existing parameters
  int? heartRate,
}) async {
  try {
    final data = <String, dynamic>{
      'user_id': userId,
      'date': (date ?? DateTime.now()).toIso8601String().split('T')[0],
    };

    // Validate heart rate before saving
    if (heartRate != null) {
      if (heartRate >= 30 && heartRate <= 250) {
        data['heart_rate'] = heartRate;
      } else {
        debugPrint('⚠️ Invalid heart rate: $heartRate BPM. Skipping...');
        // Don't include invalid heart rate data
      }
    }

    // ... rest of the method
  } catch (e) {
    debugPrint('❌ Error saving health metrics: $e');

    // Add specific handling for constraint violations
    if (e.toString().contains('heart_rate_check')) {
      debugPrint('🔄 Retrying without heart rate data...');
      // Retry without heart rate if constraint fails
      final retryData = Map<String, dynamic>.from(data);
      retryData.remove('heart_rate');
      await _supabase.from('health_metrics').upsert(retryData);
      return;
    }

    rethrow;
  }
}
```

### 3. **Streaks Table Reference Fix (Priority: High)**
**File:** `lib/services/enhanced_supabase_service.dart`
**Error:** App expects 'user_streaks' but database has 'streaks'

**Solution:** Update all references to use 'streaks' (database has the view alias)
```dart
// Current (line 331):
await _supabase.from('streaks').upsert(data);

// Update references consistently:
Future<void> updateStreak({...}) async {
  try {
    // Use 'streaks' table name consistently
    await _supabase.from('streaks').upsert(data);
    debugPrint('✅ Streak updated: $streakType');
  } catch (e) {
    debugPrint('❌ Error updating streak: $e');

    // Add specific handling for constraint errors
    if (e.toString().contains('unique constraint')) {
      debugPrint('🔄 Retrying with conflict resolution...');
      // Handle unique constraint violations
    }

    rethrow;
  }
}
```

### 4. **Error Handling Circuit Breaker (Priority: High)**
**Files:** All providers and services
**Error:** Infinite retry loops causing battery drain

**Solution:** Implement circuit breaker pattern
```dart
class CircuitBreaker {
  static const int maxFailures = 3;
  static const Duration cooldownPeriod = Duration(minutes: 5);

  static final Map<String, CircuitBreakerState> _states = {};

  static Future<T> execute<T>(
    String operationId,
    Future<T> Function() operation,
  ) async {
    final state = _states.putIfAbsent(
      operationId,
      () => CircuitBreakerState(),
    );

    if (state.isOpen &&
        DateTime.now().difference(state.lastFailure) < cooldownPeriod) {
      throw CircuitBreakerException('Circuit breaker is open for $operationId');
    }

    try {
      final result = await operation();
      state.reset(); // Reset on success
      return result;
    } catch (e) {
      state.recordFailure();
      rethrow;
    }
  }
}

class CircuitBreakerState {
  int failures = 0;
  DateTime lastFailure = DateTime.now();

  bool get isOpen => failures >= CircuitBreaker.maxFailures;

  void recordFailure() {
    failures++;
    lastFailure = DateTime.now();
  }

  void reset() {
    failures = 0;
  }
}
```

### 5. **Profile Management Daily Calories Target (Priority: Medium)**
**File:** `lib/services/enhanced_supabase_service.dart`
**Error:** Missing `daily_calories_target` column access

**Solution:**
```dart
Future<void> updateUserProfile({
  required String userId,
  // ... existing parameters
  int? dailyCaloriesTarget, // Add this parameter
}) async {
  try {
    final updates = <String, dynamic>{};
    // ... existing updates
    if (dailyCaloriesTarget != null) updates['daily_calories_target'] = dailyCaloriesTarget;

    await _supabase
        .from('profiles')
        .update(updates)
        .eq('id', userId);

    debugPrint('✅ Profile updated for user: $userId');
  } catch (e) {
    debugPrint('❌ Error updating profile: $e');
    rethrow;
  }
}
```

## 🔧 **Implementation Strategy**

### **Step 1: Create Enhanced Error Handler**
```dart
// lib/utils/error_handler.dart
class DatabaseErrorHandler {
  static Future<T> safeExecute<T>(
    String operation,
    Future<T> Function() function,
    {T? fallback}
  ) async {
    try {
      return await CircuitBreaker.execute(operation, function);
    } on CircuitBreakerException catch (e) {
      debugPrint('🔄 Circuit breaker active: $e');
      if (fallback != null) return fallback;
      rethrow;
    } catch (e) {
      debugPrint('❌ Database error in $operation: $e');

      // Handle specific error types
      if (e.toString().contains('schema cache')) {
        debugPrint('🔄 Schema cache error - retrying...');
        await Future.delayed(Duration(seconds: 2));
        return await function(); // Single retry
      }

      if (fallback != null) return fallback;
      rethrow;
    }
  }
}
```

### **Step 2: Update All Provider Classes**
1. **SupabaseNutritionProvider**: Fix type casting
2. **HealthProvider**: Add constraint validation
3. **StreakProvider**: Fix table references
4. **All providers**: Add circuit breaker

### **Step 3: Update Service Layer**
1. **EnhancedSupabaseService**: Apply all fixes
2. Add comprehensive error handling
3. Implement retry logic with exponential backoff

### **Step 4: State Management Fixes**
```dart
// Prevent setState during build exceptions
class SafeStateNotifier extends ChangeNotifier {
  bool _isNotifying = false;

  @override
  void notifyListeners() {
    if (_isNotifying) return; // Prevent recursive calls
    _isNotifying = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      super.notifyListeners();
      _isNotifying = false;
    });
  }
}
```

## 📋 **File-by-File Changes Required**

### **1. lib/services/enhanced_supabase_service.dart**
- ✅ Add heart rate validation (lines 242-261)
- ✅ Fix nutrition data type handling (lines 131-190)
- ✅ Add circuit breaker to all methods
- ✅ Add daily_calories_target support (lines 97-125)

### **2. lib/providers/supabase_nutrition_provider.dart**
- ✅ Fix JSON parsing for ingredient lists
- ✅ Add type casting safety
- ✅ Implement error boundaries

### **3. lib/providers/health_provider.dart**
- ✅ Add health metric validation
- ✅ Handle constraint violations gracefully

### **4. lib/providers/streak_provider.dart**
- ✅ Update table references
- ✅ Fix unique constraint handling

### **5. lib/utils/error_handler.dart** (New file)
- ✅ Circuit breaker implementation
- ✅ Database error categorization
- ✅ Retry logic with backoff

## 🧪 **Testing Strategy After Fixes**

### **Unit Testing:**
1. Test type casting with various data formats
2. Validate constraint handling edge cases
3. Test circuit breaker functionality

### **Integration Testing:**
1. Run all CRUD operations with fixed code
2. Test with 10 dummy accounts
3. Verify no infinite retry loops
4. Monitor battery usage during sync

### **Performance Testing:**
1. Measure response times before/after fixes
2. Test offline/online sync scenarios
3. Validate memory usage stability

## ⚡ **Expected Outcomes After Fixes**

| Module | Current Success | Target Success | Key Improvement |
|--------|----------------|----------------|-----------------|
| Profile Management | 70% | 95% | daily_calories_target fix |
| Nutrition Tracking | 30% | 90% | Type casting fixes |
| Health Metrics | 20% | 85% | Constraint handling |
| Streaks Management | 10% | 90% | Table reference fixes |
| Goals System | 60% | 95% | Error handling improvements |

**Overall Target: 90%+ functionality across all modules**

## 📝 **Implementation Timeline**

- **Step 1-2:** 2-3 hours (Core fixes)
- **Step 3-4:** 1-2 hours (Error handling)
- **Testing:** 1-2 hours (Validation)
- **Total:** 4-7 hours

## 🔄 **Rollback Plan**

If issues arise:
1. Revert to previous commit (11d6a08)
2. Apply database rollback (documented in migrations.sql)
3. Test with original integration test framework

---

**Next Step:** Apply these fixes systematically and test each module individually before proceeding to full integration testing.