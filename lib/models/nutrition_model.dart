class NutritionData {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  NutritionData({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory NutritionData.empty() {
    return NutritionData(
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
    );
  }

  factory NutritionData.fromJson(Map<String, dynamic> json) {
    return NutritionData(
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  NutritionData operator +(NutritionData other) {
    return NutritionData(
      calories: calories + other.calories,
      protein: protein + other.protein,
      carbs: carbs + other.carbs,
      fat: fat + other.fat,
    );
  }
}

class NutritionGoals {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  NutritionGoals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory NutritionGoals.defaults() {
    return NutritionGoals(
      calories: 2000,
      protein: 150,
      carbs: 250,
      fat: 67,
    );
  }

  factory NutritionGoals.fromJson(Map<String, dynamic> json) {
    return NutritionGoals(
      calories: (json['calories'] ?? 2000).toDouble(),
      protein: (json['protein'] ?? 150).toDouble(),
      carbs: (json['carbs'] ?? 250).toDouble(),
      fat: (json['fat'] ?? 67).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}

class FoodEntry {
  final String id;
  final String name;
  final String time;
  final NutritionData nutrition;
  final String? imageUri;
  final bool isFromCamera;

  FoodEntry({
    required this.id,
    required this.name,
    required this.time,
    required this.nutrition,
    this.imageUri,
    this.isFromCamera = false,
  });

  factory FoodEntry.fromJson(Map<String, dynamic> json) {
    return FoodEntry(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? '',
      time: json['time'] ?? '',
      nutrition: NutritionData.fromJson(json['nutrition'] ?? {}),
      imageUri: json['imageUri'],
      isFromCamera: json['isFromCamera'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'time': time,
      'nutrition': nutrition.toJson(),
      'imageUri': imageUri,
      'isFromCamera': isFromCamera,
    };
  }
}

class DayNutritionData {
  final String date;
  final NutritionData consumed;
  final NutritionGoals goals;
  final List<FoodEntry> foods;

  DayNutritionData({
    required this.date,
    required this.consumed,
    required this.goals,
    required this.foods,
  });

  factory DayNutritionData.empty(String date) {
    return DayNutritionData(
      date: date,
      consumed: NutritionData.empty(),
      goals: NutritionGoals.defaults(),
      foods: [],
    );
  }

  factory DayNutritionData.fromJson(Map<String, dynamic> json) {
    return DayNutritionData(
      date: json['date'] ?? '',
      consumed: NutritionData.fromJson(json['consumed'] ?? {}),
      goals: NutritionGoals.fromJson(json['goals'] ?? {}),
      foods: (json['foods'] as List<dynamic>?)
              ?.map((e) => FoodEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'consumed': consumed.toJson(),
      'goals': goals.toJson(),
      'foods': foods.map((e) => e.toJson()).toList(),
    };
  }
}