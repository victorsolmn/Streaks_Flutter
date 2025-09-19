// Additional improvements for the Nutrition Module
// Run these changes after testing the basic fixes

// 1. ADD BATCH INSERT FOR BETTER PERFORMANCE
// File: lib/providers/nutrition_provider.dart
// Replace the individual saves in _syncToSupabase with:
/*
  Future<void> _syncToSupabase() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null || _isSyncing) return;

    _isSyncing = true;
    try {
      // Batch insert all entries at once
      final entriesToSync = _entries.map((entry) => {
        'user_id': userId,
        'food_name': entry.foodName,
        'calories': entry.calories,
        'protein': entry.protein,
        'carbs': entry.carbs,
        'fat': entry.fat,
        'fiber': entry.fiber,
        'quantity_grams': 100,
        'meal_type': 'snack',
      }).toList();

      if (entriesToSync.isNotEmpty) {
        await _supabaseService.supabase
            .from('nutrition_entries')
            .upsert(entriesToSync);
      }

      _lastSyncTime = DateTime.now();
    } catch (e) {
      debugPrint('Sync error: $e');
      // Add to offline queue
      _offlineQueue.addAll(_entries);
    } finally {
      _isSyncing = false;
    }
  }
*/

// 2. ADD OFFLINE QUEUE FOR FAILED SYNCS
// File: lib/providers/nutrition_provider.dart
// Add these members:
/*
  final List<NutritionEntry> _offlineQueue = [];
  Timer? _retryTimer;

  void _setupRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(Duration(minutes: 2), (timer) {
      if (_isOnline && _offlineQueue.isNotEmpty) {
        _retryOfflineQueue();
      }
    });
  }

  Future<void> _retryOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;

    final toRetry = List<NutritionEntry>.from(_offlineQueue);
    _offlineQueue.clear();

    for (final entry in toRetry) {
      try {
        await _supabaseService.saveNutritionEntry(
          userId: _supabaseService.currentUser!.id,
          foodName: entry.foodName,
          calories: entry.calories,
          protein: entry.protein,
          carbs: entry.carbs,
          fat: entry.fat,
          fiber: entry.fiber,
        );
      } catch (e) {
        _offlineQueue.add(entry);
      }
    }
  }
*/

// 3. REMOVE DUPLICATE PROVIDER
// Delete this file: lib/providers/supabase_nutrition_provider.dart
// Remove from main.dart:
/*
  // Remove this line:
  ChangeNotifierProvider(create: (_) => SupabaseNutritionProvider(supabaseService)),
*/

// 4. ADD DATA VALIDATION
// File: lib/providers/nutrition_provider.dart
// Add validation before saving:
/*
  bool _validateEntry(NutritionEntry entry) {
    if (entry.foodName.isEmpty) return false;
    if (entry.calories < 0 || entry.calories > 10000) return false;
    if (entry.protein < 0 || entry.protein > 500) return false;
    if (entry.carbs < 0 || entry.carbs > 500) return false;
    if (entry.fat < 0 || entry.fat > 500) return false;
    return true;
  }

  Future<void> addNutritionEntry(NutritionEntry entry) async {
    if (!_validateEntry(entry)) {
      _setError('Invalid nutrition data');
      return;
    }
    // ... rest of the method
  }
*/

// 5. ADD PROPER ERROR HANDLING WITH USER FEEDBACK
// File: lib/screens/main/nutrition_screen.dart
// Wrap data operations with try-catch and show snackbars:
/*
  void _addFood() async {
    try {
      final entry = await nutritionProvider.scanFood(imagePath);
      if (entry != null) {
        await nutritionProvider.addNutritionEntry(entry);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${entry.foodName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add food: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
*/

// 6. OPTIMIZE INDIAN FOOD SERVICE API KEY
// File: lib/services/indian_food_nutrition_service.dart
// Move API key to environment variables:
/*
  // Instead of hardcoded key:
  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // Empty default, must be provided at build time
  );

  // Build command:
  // flutter build apk --dart-define=GEMINI_API_KEY=your_actual_key
*/

// 7. ADD LOADING STATES TO UI
// File: lib/screens/main/nutrition_screen.dart
// Show loading indicator during sync:
/*
  @override
  Widget build(BuildContext context) {
    return Consumer<NutritionProvider>(
      builder: (context, nutritionProvider, _) {
        if (nutritionProvider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Syncing nutrition data...'),
              ],
            ),
          );
        }
        // ... rest of the UI
      },
    );
  }
*/

// 8. ADD MEAL TYPE SELECTION
// File: lib/providers/nutrition_provider.dart
// Add meal type to entries:
/*
  enum MealType { breakfast, lunch, dinner, snack }

  class NutritionEntry {
    // ... existing fields
    final MealType mealType;

    NutritionEntry({
      // ... existing parameters
      this.mealType = MealType.snack,
    });
  }
*/

// 9. IMPLEMENT DATA CACHING STRATEGY
// File: lib/providers/nutrition_provider.dart
// Cache only recent data:
/*
  Future<void> _cleanupOldData() async {
    final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
    _entries.removeWhere((entry) => entry.timestamp.isBefore(thirtyDaysAgo));
    await _saveNutritionData();
  }
*/

// 10. ADD NUTRITION GOALS TRACKING
// File: lib/models/nutrition_goals.dart
/*
  class NutritionGoals {
    final int dailyCalories;
    final double dailyProtein;
    final double dailyCarbs;
    final double dailyFat;
    final double dailyFiber;
    final double dailyWater;

    double get calorieProgress => todayCalories / dailyCalories;
    double get proteinProgress => todayProtein / dailyProtein;
    // ... etc
  }
*/

void main() {
  print('🚀 Nutrition Module Improvements Guide');
  print('=' * 50);
  print('\nThese improvements will:');
  print('1. Increase performance with batch operations');
  print('2. Handle network failures gracefully');
  print('3. Remove duplicate code');
  print('4. Add data validation');
  print('5. Improve user experience with feedback');
  print('6. Secure API keys');
  print('7. Add loading states');
  print('8. Track meals properly');
  print('9. Optimize storage');
  print('10. Add goal tracking');

  print('\n📝 Implementation Priority:');
  print('HIGH: Items 1, 2, 3, 4 - Core functionality');
  print('MEDIUM: Items 5, 6, 7 - User experience');
  print('LOW: Items 8, 9, 10 - Nice to have features');
}