import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';
import '../models/nutrition_model.dart';

class SupabaseNutritionProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  final Map<String, DayNutritionData> _nutritionCache = {};
  bool _isLoading = false;
  String? _error;
  int _currentStreak = 0;
  int _longestStreak = 0;

  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;

  DayNutritionData getTodayNutrition() {
    final today = _getDateString(DateTime.now());
    return _nutritionCache[today] ?? DayNutritionData.empty(today);
  }

  DayNutritionData getNutritionForDate(DateTime date) {
    final dateStr = _getDateString(date);
    return _nutritionCache[dateStr] ?? DayNutritionData.empty(dateStr);
  }

  Future<void> loadNutritionData() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Load today's nutrition
      final today = _getDateString(DateTime.now());
      // TODO: Fix this when method is available
      final Map<String, dynamic>? todayData = null; 
      /* await _supabaseService.getNutritionEntry(
        userId: userId,
        date: today,
      ); */

      if (todayData != null) {
        _nutritionCache[today] = _parseNutritionData(todayData, today);
      }

      // Load recent history for streak calculation
      final history = await _supabaseService.getNutritionHistory(
        userId: userId,
        days: 30,
      );

      for (final entry in history) {
        final date = entry['date'] as String;
        _nutritionCache[date] = _parseNutritionData(entry, date);
      }

      // Load and update streaks
      // await _loadStreaks(); // TODO: Implement streak loading
    } catch (e) {
      _error = e.toString();
      print('Error loading nutrition data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  DayNutritionData _parseNutritionData(Map<String, dynamic> data, String date) {
    return DayNutritionData(
      date: date,
      consumed: NutritionData(
        calories: data['calories'] ?? 0,
        protein: (data['protein'] ?? 0).toDouble(),
        carbs: (data['carbs'] ?? 0).toDouble(),
        fat: (data['fat'] ?? 0).toDouble(),
      ),
      goals: NutritionGoals(
        calories: 2000, // Default, should come from user profile
        protein: 150,
        carbs: 250,
        fat: 65,
      ),
      foods: [], // Load individual entries if needed
    );
  }

  Future<void> addFood({
    required String name,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    final today = _getDateString(DateTime.now());
    final todayNutrition = getTodayNutrition();

    // Update local cache
    final updatedNutrition = DayNutritionData(
      date: today,
      consumed: NutritionData(
        calories: (todayNutrition.consumed.calories + calories).toDouble(),
        protein: todayNutrition.consumed.protein + protein,
        carbs: todayNutrition.consumed.carbs + carbs,
        fat: todayNutrition.consumed.fat + fat,
      ),
      goals: todayNutrition.goals,
      foods: [
        ...todayNutrition.foods,
        FoodEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          time: DateTime.now().toString(),
          nutrition: NutritionData(
            calories: calories.toDouble(),
            protein: protein,
            carbs: carbs,
            fat: fat,
          ),
        ),
      ],
    );

    _nutritionCache[today] = updatedNutrition;
    notifyListeners();

    // Save to Supabase
    try {
      /* await _supabaseService.saveNutritionEntry(
        userId: userId,
        // date: today, // TODO: Fix method signature
        /* nutritionData: {
          'calories': updatedNutrition.consumed.calories,
          'protein': updatedNutrition.consumed.protein,
          'carbs': updatedNutrition.consumed.carbs,
          'fat': updatedNutrition.consumed.fat,
          'water': 0, // Water intake tracked separately for now
        }, */
      );

      // Update streaks
      await _updateStreaks();
    } catch (e) {
      _error = e.toString();
      print('Error saving nutrition: $e');
    }
  }

  Future<void> updateWaterIntake(int glasses) async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    final today = _getDateString(DateTime.now());
    final todayNutrition = getTodayNutrition();

    // Update local cache with water (stored separately for now)
    final updatedNutrition = DayNutritionData(
      date: today,
      consumed: todayNutrition.consumed,
      goals: todayNutrition.goals,
      foods: todayNutrition.foods,
    );

    _nutritionCache[today] = updatedNutrition;
    notifyListeners();

    // Save to Supabase
    try {
      /* await _supabaseService.saveNutritionEntry(
        userId: userId,
        // date: today, // TODO: Fix method signature
        /* nutritionData: {
          'calories': updatedNutrition.consumed.calories,
          'protein': updatedNutrition.consumed.protein,
          'carbs': updatedNutrition.consumed.carbs,
          'fat': updatedNutrition.consumed.fat,
          'water': glasses,
        }, */
      ); */
    } catch (e) {
      _error = e.toString();
      print('Error updating water intake: $e');
    }
  }

  Future<void> _loadStreaks() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    try {
      final streakData = await _supabaseService.getStreak(userId);
      if (streakData != null) {
        _currentStreak = streakData['current_streak'] ?? 0;
        _longestStreak = streakData['longest_streak'] ?? 0;
      } else {
        _calculateStreaksFromCache();
      }
    } catch (e) {
      print('Error loading streaks: $e');
      _calculateStreaksFromCache();
    }
  }

  void _calculateStreaksFromCache() {
    int currentStreak = 0;
    int tempStreak = 0;
    int longest = 0;
    
    final sortedDates = _nutritionCache.keys.toList()..sort();
    DateTime? lastDate;

    for (final dateStr in sortedDates.reversed) {
      final date = DateTime.parse(dateStr);
      final nutrition = _nutritionCache[dateStr]!;
      
      if (nutrition.consumed.calories > 0) {
        if (lastDate == null || 
            lastDate.difference(date).inDays == 1 ||
            lastDate.difference(date).inDays == 0) {
          tempStreak++;
          if (tempStreak > longest) {
            longest = tempStreak;
          }
          if (currentStreak == 0) {
            currentStreak = tempStreak;
          }
        } else {
          tempStreak = 1;
        }
        lastDate = date;
      } else {
        tempStreak = 0;
      }
    }

    _currentStreak = currentStreak;
    _longestStreak = longest;
  }

  Future<void> _updateStreaks() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    _calculateStreaksFromCache();

    try {
      await _supabaseService.updateStreak(
        userId: userId,
        currentStreak: _currentStreak,
        longestStreak: _longestStreak,
      ); */
    } catch (e) {
      print('Error updating streaks: $e');
    }
  }

  List<DayNutritionData> getWeeklyData() {
    final List<DayNutritionData> weekData = [];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      weekData.add(getNutritionForDate(date));
    }
    
    return weekData;
  }

  Map<String, double> getWeeklyAverage() {
    final weekData = getWeeklyData();
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    int daysWithData = 0;

    for (final day in weekData) {
      if (day.consumed.calories > 0) {
        totalCalories += day.consumed.calories;
        totalProtein += day.consumed.protein;
        totalCarbs += day.consumed.carbs;
        totalFat += day.consumed.fat;
        daysWithData++;
      }
    }

    if (daysWithData == 0) {
      return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
    }

    return {
      'calories': totalCalories / daysWithData,
      'protein': totalProtein / daysWithData,
      'carbs': totalCarbs / daysWithData,
      'fat': totalFat / daysWithData,
    };
  }

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void clearNutritionData() {
    _nutritionCache.clear();
    _currentStreak = 0;
    _longestStreak = 0;
    _error = null;
    notifyListeners();
  }
}