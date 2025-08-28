import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../services/nutrition_ai_service.dart';
import '../services/indian_food_nutrition_service.dart';
import '../services/realtime_sync_service.dart';

class NutritionEntry {
  final String id;
  final String foodName;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final DateTime timestamp;

  NutritionEntry({
    required this.id,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0.0,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foodName': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory NutritionEntry.fromJson(Map<String, dynamic> json) {
    return NutritionEntry(
      id: json['id'],
      foodName: json['foodName'],
      calories: json['calories'],
      protein: json['protein'].toDouble(),
      carbs: json['carbs'].toDouble(),
      fat: json['fat'].toDouble(),
      fiber: json['fiber']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class DailyNutrition {
  final DateTime date;
  final List<NutritionEntry> entries;
  
  DailyNutrition({required this.date, required this.entries});

  int get totalCalories => entries.fold(0, (sum, entry) => sum + entry.calories);
  double get totalProtein => entries.fold(0, (sum, entry) => sum + entry.protein);
  double get totalCarbs => entries.fold(0, (sum, entry) => sum + entry.carbs);
  double get totalFat => entries.fold(0, (sum, entry) => sum + entry.fat);
}

class NutritionProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  List<NutritionEntry> _entries = [];
  bool _isLoading = false;
  String? _error;
  final IndianFoodNutritionService _indianFoodService = IndianFoodNutritionService();
  final RealtimeSyncService _syncService = RealtimeSyncService();

  // Daily goals
  int _calorieGoal = 2000;
  double _proteinGoal = 150.0;
  double _carbGoal = 250.0;
  double _fatGoal = 67.0;

  NutritionProvider(this._prefs) {
    _loadNutritionData();
    _loadGoals();
  }

  List<NutritionEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  int get calorieGoal => _calorieGoal;
  double get proteinGoal => _proteinGoal;
  double get carbGoal => _carbGoal;
  double get fatGoal => _fatGoal;

  DailyNutrition get todayNutrition {
    final today = DateTime.now();
    final todayEntries = _entries.where((entry) {
      return entry.timestamp.year == today.year &&
             entry.timestamp.month == today.month &&
             entry.timestamp.day == today.day;
    }).toList();
    
    return DailyNutrition(date: today, entries: todayEntries);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> _loadNutritionData() async {
    try {
      final String? entriesJson = _prefs.getString('nutrition_entries');
      if (entriesJson != null) {
        final List<dynamic> decodedEntries = jsonDecode(entriesJson);
        _entries = decodedEntries.map((e) => NutritionEntry.fromJson(e)).toList();
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to load nutrition data');
    }
  }

  Future<void> _saveNutritionData() async {
    try {
      final String entriesJson = jsonEncode(_entries.map((e) => e.toJson()).toList());
      await _prefs.setString('nutrition_entries', entriesJson);
    } catch (e) {
      _setError('Failed to save nutrition data');
    }
  }

  Future<void> _loadGoals() async {
    _calorieGoal = _prefs.getInt('calorie_goal') ?? 2000;
    _proteinGoal = _prefs.getDouble('protein_goal') ?? 150.0;
    _carbGoal = _prefs.getDouble('carb_goal') ?? 250.0;
    _fatGoal = _prefs.getDouble('fat_goal') ?? 67.0;
    notifyListeners();
  }

  Future<void> updateGoals({
    int? calorieGoal,
    double? proteinGoal,
    double? carbGoal,
    double? fatGoal,
  }) async {
    if (calorieGoal != null) {
      _calorieGoal = calorieGoal;
      await _prefs.setInt('calorie_goal', calorieGoal);
    }
    if (proteinGoal != null) {
      _proteinGoal = proteinGoal;
      await _prefs.setDouble('protein_goal', proteinGoal);
    }
    if (carbGoal != null) {
      _carbGoal = carbGoal;
      await _prefs.setDouble('carb_goal', carbGoal);
    }
    if (fatGoal != null) {
      _fatGoal = fatGoal;
      await _prefs.setDouble('fat_goal', fatGoal);
    }
    notifyListeners();
  }

  Future<void> addNutritionEntry(NutritionEntry entry) async {
    _setLoading(true);
    _setError(null);

    try {
      _entries.add(entry);
      await _saveNutritionData();
      
      // Sync to Supabase immediately
      await _syncService.syncNutritionEntry(entry);
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to add nutrition entry');
      _setLoading(false);
    }
  }

  Future<void> removeNutritionEntry(String entryId) async {
    _setLoading(true);
    _setError(null);

    try {
      _entries.removeWhere((entry) => entry.id == entryId);
      await _saveNutritionData();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to remove nutrition entry');
      _setLoading(false);
    }
  }

  Future<NutritionEntry?> scanFood(String imagePath) async {
    _setLoading(true);
    _setError(null);

    try {
      // First try Indian food recognition for better accuracy
      final imageFile = File(imagePath);
      debugPrint('Analyzing with Indian Food Service first...');
      final indianResult = await _indianFoodService.analyzeIndianFood(imageFile);
      
      if (indianResult['success'] == true && indianResult['nutrition'] != null) {
        final nutrition = indianResult['nutrition'];
        final foods = indianResult['foods'] as List? ?? [];
        
        // Create nutrition entry from Indian food result
        final entry = NutritionEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          foodName: foods.isNotEmpty 
              ? foods.map((f) => f['name']).join(', ')
              : 'Indian Food',
          calories: nutrition['calories'] ?? 0,
          protein: (nutrition['protein'] ?? 0).toDouble(),
          carbs: (nutrition['carbs'] ?? 0).toDouble(),
          fat: (nutrition['fat'] ?? 0).toDouble(),
          fiber: (nutrition['fiber'] ?? 0).toDouble(),
          timestamp: DateTime.now(),
        );
        
        _setLoading(false);
        return entry;
      }
      
      // Fallback to original AI service (Edamam)
      debugPrint('Falling back to Edamam API...');
      final entry = await NutritionAIService.analyzeFood(imagePath);
      
      _setLoading(false);
      
      if (entry != null) {
        return entry;
      } else {
        _setError('Could not identify food. Please try again or enter manually.');
        return null;
      }
    } catch (e) {
      _setError('Failed to analyze food: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }
  
  // New method for text-based Indian food search
  Future<NutritionEntry?> searchIndianFood(String query) async {
    try {
      final result = await _indianFoodService.searchIndianFood(query);
      
      if (result['success'] == true && result['nutrition'] != null) {
        final nutrition = result['nutrition'];
        final foods = result['foods'] as List? ?? [];
        
        final entry = NutritionEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          foodName: foods.isNotEmpty 
              ? foods.map((f) => f['name']).join(', ')
              : query,
          calories: nutrition['calories'] ?? 0,
          protein: (nutrition['protein'] ?? 0).toDouble(),
          carbs: (nutrition['carbs'] ?? 0).toDouble(),
          fat: (nutrition['fat'] ?? 0).toDouble(),
          fiber: (nutrition['fiber'] ?? 0).toDouble(),
          timestamp: DateTime.now(),
        );
        
        return entry;
      }
    } catch (e) {
      debugPrint('Error searching Indian food: $e');
    }
    return null;
  }
  
  // Get list of all Indian foods for autocomplete
  List<String> getIndianFoodSuggestions() {
    return _indianFoodService.getAllIndianFoods();
  }

  List<DailyNutrition> getWeeklyNutrition() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    return List.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      final dayEntries = _entries.where((entry) {
        return entry.timestamp.year == date.year &&
               entry.timestamp.month == date.month &&
               entry.timestamp.day == date.day;
      }).toList();
      
      return DailyNutrition(date: date, entries: dayEntries);
    });
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> clearNutritionData() async {
    try {
      // Clear nutrition data from preferences
      await _prefs.remove('nutrition_entries');
      await _prefs.remove('calorie_goal');
      await _prefs.remove('protein_goal');
      await _prefs.remove('carb_goal');
      await _prefs.remove('fat_goal');
      
      // Reset state to defaults
      _entries.clear();
      _calorieGoal = 2000;
      _proteinGoal = 150.0;
      _carbGoal = 250.0;
      _fatGoal = 67.0;
      _error = null;
      _isLoading = false;
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear nutrition data';
      notifyListeners();
    }
  }
}