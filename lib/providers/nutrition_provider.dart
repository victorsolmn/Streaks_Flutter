import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NutritionEntry {
  final String id;
  final String foodName;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime timestamp;

  NutritionEntry({
    required this.id,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
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
      // Simulate AI food recognition
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock response based on common foods
      final mockFoods = [
        {'name': 'Apple', 'calories': 95, 'protein': 0.5, 'carbs': 25.0, 'fat': 0.3},
        {'name': 'Chicken Breast', 'calories': 165, 'protein': 31.0, 'carbs': 0.0, 'fat': 3.6},
        {'name': 'Brown Rice', 'calories': 216, 'protein': 5.0, 'carbs': 45.0, 'fat': 1.8},
        {'name': 'Broccoli', 'calories': 55, 'protein': 3.7, 'carbs': 11.0, 'fat': 0.6},
        {'name': 'Salmon', 'calories': 206, 'protein': 22.0, 'carbs': 0.0, 'fat': 12.0},
      ];
      
      final random = DateTime.now().millisecond % mockFoods.length;
      final food = mockFoods[random];
      
      final entry = NutritionEntry(
        id: 'nutrition_${DateTime.now().millisecondsSinceEpoch}',
        foodName: food['name'] as String,
        calories: food['calories'] as int,
        protein: food['protein'] as double,
        carbs: food['carbs'] as double,
        fat: food['fat'] as double,
        timestamp: DateTime.now(),
      );
      
      _setLoading(false);
      return entry;
    } catch (e) {
      _setError('Failed to scan food');
      _setLoading(false);
      return null;
    }
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
}