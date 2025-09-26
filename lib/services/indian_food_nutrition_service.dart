import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';

class IndianFoodNutritionService {
  // Google Gemini API - FREE tier (60 queries/minute)
  // IMPORTANT: Get your FREE key from https://makersuite.google.com/app/apikey
  static const String _geminiApiKey = 'AIzaSyBXSUv6Ff9unTCkCTvxsE0UaXWX24TVxCI';
  
  // Indian Food Composition Database (IFCT 2017) - DEPRECATED
  // We now use Gemini AI to calculate nutrition directly for better accuracy
  // Keeping this for reference/fallback only
  static final Map<String, Map<String, dynamic>> _indianFoodDatabase = {
    // Vegetables and Salads
    'mixed vegetables': {'calories': 50, 'protein': 2.5, 'carbs': 10.0, 'fat': 0.5, 'fiber': 3.0},
    'salad': {'calories': 50, 'protein': 2.5, 'carbs': 10.0, 'fat': 0.5, 'fiber': 3.0},
    'vegetable': {'calories': 50, 'protein': 2.5, 'carbs': 10.0, 'fat': 0.5, 'fiber': 3.0},
    // North Indian
    'roti': {'calories': 71, 'protein': 2.7, 'carbs': 15.7, 'fat': 0.4, 'fiber': 2.0},
    'chapati': {'calories': 71, 'protein': 2.7, 'carbs': 15.7, 'fat': 0.4, 'fiber': 2.0},
    'naan': {'calories': 262, 'protein': 8.7, 'carbs': 45.6, 'fat': 5.1, 'fiber': 2.2},
    'paratha': {'calories': 326, 'protein': 5.8, 'carbs': 37.6, 'fat': 17.8, 'fiber': 2.7},
    'dal': {'calories': 104, 'protein': 6.8, 'carbs': 16.3, 'fat': 0.9, 'fiber': 4.8},
    'dal tadka': {'calories': 120, 'protein': 6.8, 'carbs': 16.3, 'fat': 3.2, 'fiber': 4.8},
    'dal makhani': {'calories': 233, 'protein': 7.8, 'carbs': 21.2, 'fat': 13.2, 'fiber': 5.1},
    'rajma': {'calories': 140, 'protein': 7.6, 'carbs': 22.8, 'fat': 1.5, 'fiber': 6.3},
    'chole': {'calories': 210, 'protein': 8.4, 'carbs': 27.4, 'fat': 6.7, 'fiber': 7.2},
    'paneer butter masala': {'calories': 342, 'protein': 14.3, 'carbs': 9.8, 'fat': 28.1, 'fiber': 1.2},
    'palak paneer': {'calories': 284, 'protein': 12.4, 'carbs': 8.2, 'fat': 22.8, 'fiber': 3.4},
    'butter chicken': {'calories': 438, 'protein': 30.8, 'carbs': 14.0, 'fat': 28.1, 'fiber': 2.1},
    'chicken curry': {'calories': 243, 'protein': 25.9, 'carbs': 8.2, 'fat': 12.3, 'fiber': 1.8},
    'biryani': {'calories': 290, 'protein': 12.2, 'carbs': 38.3, 'fat': 9.5, 'fiber': 2.9},
    'pulao': {'calories': 205, 'protein': 4.3, 'carbs': 35.1, 'fat': 5.2, 'fiber': 1.8},
    
    // South Indian
    'dosa': {'calories': 133, 'protein': 3.9, 'carbs': 28.3, 'fat': 0.7, 'fiber': 1.5},
    'masala dosa': {'calories': 165, 'protein': 4.5, 'carbs': 32.3, 'fat': 1.8, 'fiber': 2.5},
    'idli': {'calories': 58, 'protein': 2.1, 'carbs': 12.3, 'fat': 0.2, 'fiber': 0.8},
    'vada': {'calories': 97, 'protein': 3.1, 'carbs': 10.9, 'fat': 4.5, 'fiber': 1.3},
    'uttapam': {'calories': 162, 'protein': 4.2, 'carbs': 26.7, 'fat': 3.8, 'fiber': 2.1},
    'sambar': {'calories': 65, 'protein': 3.4, 'carbs': 11.5, 'fat': 0.6, 'fiber': 3.2},
    'rasam': {'calories': 26, 'protein': 1.3, 'carbs': 5.1, 'fat': 0.1, 'fiber': 0.9},
    'pongal': {'calories': 207, 'protein': 5.1, 'carbs': 35.2, 'fat': 4.8, 'fiber': 2.3},
    'upma': {'calories': 192, 'protein': 5.4, 'carbs': 28.0, 'fat': 6.3, 'fiber': 2.8},
    'appam': {'calories': 120, 'protein': 1.8, 'carbs': 24.5, 'fat': 1.5, 'fiber': 1.2},
    
    // Rice & Bread
    'rice': {'calories': 130, 'protein': 2.4, 'carbs': 28.7, 'fat': 0.3, 'fiber': 0.4},
    'jeera rice': {'calories': 174, 'protein': 3.5, 'carbs': 32.1, 'fat': 3.5, 'fiber': 1.2},
    'fried rice': {'calories': 228, 'protein': 4.6, 'carbs': 35.4, 'fat': 7.3, 'fiber': 1.8},
    'lemon rice': {'calories': 185, 'protein': 3.2, 'carbs': 33.4, 'fat': 4.1, 'fiber': 1.5},
    'curd rice': {'calories': 154, 'protein': 3.8, 'carbs': 26.7, 'fat': 3.2, 'fiber': 0.8},
    
    // Snacks & Street Food
    'samosa': {'calories': 262, 'protein': 3.5, 'carbs': 23.8, 'fat': 17.5, 'fiber': 2.1},
    'pakora': {'calories': 255, 'protein': 5.3, 'carbs': 22.4, 'fat': 16.2, 'fiber': 3.4},
    'bhel puri': {'calories': 180, 'protein': 4.3, 'carbs': 31.5, 'fat': 4.2, 'fiber': 3.7},
    'pani puri': {'calories': 36, 'protein': 1.1, 'carbs': 7.6, 'fat': 0.2, 'fiber': 0.8},
    'vada pav': {'calories': 197, 'protein': 4.8, 'carbs': 28.1, 'fat': 7.4, 'fiber': 2.3},
    'pav bhaji': {'calories': 213, 'protein': 5.2, 'carbs': 33.5, 'fat': 6.8, 'fiber': 4.1},
    'chaat': {'calories': 153, 'protein': 4.1, 'carbs': 26.7, 'fat': 3.5, 'fiber': 3.2},
    'kachori': {'calories': 298, 'protein': 4.2, 'carbs': 27.8, 'fat': 19.1, 'fiber': 2.5},
    
    // Sweets & Desserts
    'gulab jamun': {'calories': 143, 'protein': 2.0, 'carbs': 23.0, 'fat': 5.0, 'fiber': 0.3},
    'rasgulla': {'calories': 106, 'protein': 3.1, 'carbs': 20.3, 'fat': 1.5, 'fiber': 0.0},
    'jalebi': {'calories': 150, 'protein': 1.0, 'carbs': 35.5, 'fat': 1.2, 'fiber': 0.3},
    'ladoo': {'calories': 185, 'protein': 3.5, 'carbs': 24.2, 'fat': 8.5, 'fiber': 1.8},
    'halwa': {'calories': 379, 'protein': 3.8, 'carbs': 57.7, 'fat': 15.0, 'fiber': 1.2},
    'kheer': {'calories': 153, 'protein': 3.8, 'carbs': 23.7, 'fat': 4.8, 'fiber': 0.2},
    'payasam': {'calories': 195, 'protein': 3.2, 'carbs': 31.5, 'fat': 6.2, 'fiber': 0.5},
    
    // Beverages
    'chai': {'calories': 37, 'protein': 0.7, 'carbs': 7.0, 'fat': 0.7, 'fiber': 0.0},
    'lassi': {'calories': 94, 'protein': 3.1, 'carbs': 15.2, 'fat': 2.1, 'fiber': 0.0},
    'mango lassi': {'calories': 154, 'protein': 3.5, 'carbs': 28.3, 'fat': 3.2, 'fiber': 0.8},
    'buttermilk': {'calories': 40, 'protein': 2.2, 'carbs': 4.8, 'fat': 1.1, 'fiber': 0.0},
  };
  
  // Gemini Vision for Indian food recognition
  GenerativeModel? _model;
  
  IndianFoodNutritionService() {
    // Initialize Gemini with the API key
    if (_geminiApiKey.isNotEmpty && _geminiApiKey.startsWith('AIza')) {
      try {
        _model = GenerativeModel(
          model: 'gemini-1.5-flash-latest', // Use latest stable version
          apiKey: _geminiApiKey,
        );
        debugPrint('✅ Gemini AI initialized successfully for Indian food recognition');
      } catch (e) {
        debugPrint('⚠️ Gemini initialization error: $e');
      }
    } else {
      debugPrint('⚠️ Invalid Gemini API key');
    }
  }
  
  // New method to analyze food with description instead of individual items
  Future<Map<String, dynamic>> analyzeWithDescription(
    File imageFile,
    String mealDescription,
  ) async {
    try {
      debugPrint('\n📸 Starting food analysis with description...');
      debugPrint('Description: $mealDescription');
      debugPrint('Image path: ${imageFile.path}');
      debugPrint('🔑 Gemini API Key Status: ${_geminiApiKey.isNotEmpty ? "Present" : "Missing"}');
      debugPrint('🔑 Gemini Model Status: ${_model != null ? "Initialized" : "Not Initialized"}');

      // Check if model is initialized
      if (_model == null) {
        debugPrint('⚠️ Gemini not initialized, using smart fallback');
        // Try to analyze using local database with description parsing
        // For generic image analysis, use default description
        final description = 'Mixed meal from image';
        return _analyzeWithLocalDatabase(description);
      }

      // Send image and description to Gemini for nutrition calculation
      final nutritionResult = await _calculateNutritionFromDescription(
        imageFile,
        mealDescription,
      );

      debugPrint('Final nutrition result from Gemini: ${nutritionResult['nutrition']}');
      return nutritionResult;
    } catch (e) {
      debugPrint('❌ Error in analyzeWithDescription: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Calculate nutrition from meal description
  Future<Map<String, dynamic>> _calculateNutritionFromDescription(
    File imageFile,
    String description,
  ) async {
    try {
      debugPrint('🤖 Asking Gemini to analyze meal from description...');

      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();

      // Create prompt for Gemini with description
      final prompt = '''
Analyze this food image and the provided description to calculate total nutrition.

Meal Description: $description

Important:
1. Look at the image to understand portion sizes and actual foods present
2. Use the description to identify specific items and quantities mentioned
3. Calculate total nutrition for the ENTIRE meal shown/described
4. Be accurate with Indian food nutritional values if applicable

Return ONLY a JSON object in this exact format (no markdown, no explanation):
{
  "foods": ["item1", "item2", "item3"],
  "total_calories": number,
  "total_protein": number (in grams),
  "total_carbs": number (in grams),
  "total_fat": number (in grams),
  "total_fiber": number (in grams)
}
''';

      // Create content with image and text
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      // Generate response from Gemini
      final response = await _model!.generateContent(content);
      final responseText = response.text?.trim() ?? '';

      debugPrint('Gemini raw response: $responseText');

      // Parse JSON response
      try {
        // Clean up response (remove any markdown formatting)
        String cleanJson = responseText;
        if (cleanJson.contains('```')) {
          cleanJson = cleanJson.replaceAll(RegExp(r'```[\w]*\n?'), '').trim();
        }

        final nutritionData = json.decode(cleanJson);

        return {
          'success': true,
          'foods': nutritionData['foods'] ?? [description],
          'nutrition': {
            'calories': (nutritionData['total_calories'] ?? 0).round(),
            'protein': (nutritionData['total_protein'] ?? 0).round(),
            'carbs': (nutritionData['total_carbs'] ?? 0).round(),
            'fat': (nutritionData['total_fat'] ?? 0).round(),
            'fiber': (nutritionData['total_fiber'] ?? 0).round(),
          },
          'confidence': 0.9,
        };
      } catch (parseError) {
        debugPrint('Error parsing Gemini response: $parseError');
        // Fallback to local database analysis
        return _analyzeWithLocalDatabase(description);
      }
    } catch (e) {
      debugPrint('Error with Gemini calculation: $e');
      debugPrint('Falling back to local database analysis');
      // Use local database as fallback - create description from available data
      final fallbackDescription = 'Mixed meal';
      return _analyzeWithLocalDatabase(fallbackDescription);
    }
  }

  // Main function to analyze food image with user-provided details
  Future<Map<String, dynamic>> analyzeIndianFoodWithDetails(
    File imageFile,
    String foodName,
    String quantity,
  ) async {
    try {
      debugPrint('\n📸 Starting Indian food analysis with Gemini AI...');
      debugPrint('User provided: $foodName, Quantity: $quantity');
      debugPrint('Image path: ${imageFile.path}');
      debugPrint('🔑 Gemini API Key Status: ${_geminiApiKey.isNotEmpty ? "Present" : "Missing"}');
      debugPrint('🔑 Gemini Model Status: ${_model != null ? "Initialized" : "Not Initialized"}');

      // Check if model is initialized
      if (_model == null) {
        debugPrint('⚠️ Gemini not initialized, using smart fallback');
        // Try to analyze using local database with description parsing
        // For generic image analysis, use default description
        final description = 'Mixed meal from image';
        return _analyzeWithLocalDatabase(description);
      }

      // Step 1: Send image and food details to Gemini for direct nutrition calculation
      final nutritionResult = await _calculateNutritionWithGemini(
        imageFile,
        foodName,
        quantity,
      );

      debugPrint('Final nutrition result from Gemini: ${nutritionResult['nutrition']}');
      return nutritionResult;
    } catch (e) {
      debugPrint('❌ Error in analyzeIndianFoodWithDetails: $e');
      debugPrint('Using local database fallback');
      // Combine foodName and quantity for fallback
      final description = '$quantity $foodName';
      return _analyzeWithLocalDatabase(description);
    }
  }
  
  // New method to calculate nutrition directly with Gemini
  Future<Map<String, dynamic>> _calculateNutritionWithGemini(
    File imageFile,
    String foodName,
    String quantity,
  ) async {
    try {
      debugPrint('🤖 Asking Gemini to calculate nutrition...');

      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();

      // Create prompt for Gemini
      final prompt = '''
Analyze this food image and calculate the nutrition information.

Food Name: $foodName
Quantity: $quantity

Please provide accurate nutritional information for this specific food item and quantity.
If the image shows Indian food, use appropriate Indian food nutritional databases.

Return ONLY a JSON object in this exact format (no markdown, no explanation):
{
  "food_name": "actual food name",
  "quantity": "quantity with unit",
  "calories": number,
  "protein": number (in grams),
  "carbs": number (in grams),
  "fat": number (in grams),
  "fiber": number (in grams)
}
''';

      // Create content with image and text
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      // Generate response from Gemini
      final response = await _model!.generateContent(content);
      final responseText = response.text?.trim() ?? '';

      debugPrint('Gemini raw response: $responseText');

      // Parse JSON response
      try {
        // Clean up response (remove any markdown formatting)
        String cleanJson = responseText;
        if (cleanJson.contains('```')) {
          cleanJson = cleanJson.replaceAll(RegExp(r'```[\w]*\n?'), '').trim();
        }

        final nutritionData = json.decode(cleanJson);

        return {
          'success': true,
          'foods': [nutritionData['food_name'] ?? foodName],
          'nutrition': {
            'calories': (nutritionData['calories'] ?? 0).round(),
            'protein': (nutritionData['protein'] ?? 0).round(),
            'carbs': (nutritionData['carbs'] ?? 0).round(),
            'fat': (nutritionData['fat'] ?? 0).round(),
            'fiber': (nutritionData['fiber'] ?? 0).round(),
          },
          'confidence': 0.9, // High confidence as Gemini calculated it directly
        };
      } catch (parseError) {
        debugPrint('Error parsing Gemini response: $parseError');
        // If parsing fails, try to extract numbers from text
        return _extractNutritionFromText(responseText, foodName);
      }
    } catch (e) {
      debugPrint('Error with Gemini calculation: $e');
      debugPrint('Falling back to local database analysis');
      // Use local database as fallback - create description from available data
      final fallbackDescription = 'Mixed meal';
      return _analyzeWithLocalDatabase(fallbackDescription);
    }
  }

  // Helper method to extract nutrition from text if JSON parsing fails
  Map<String, dynamic> _extractNutritionFromText(String text, String foodName) {
    try {
      // Try to extract numbers from text using regex
      final caloriesMatch = RegExp(r'calories?[:\s]*(\d+)', caseSensitive: false).firstMatch(text);
      final proteinMatch = RegExp(r'protein[:\s]*(\d+\.?\d*)', caseSensitive: false).firstMatch(text);
      final carbsMatch = RegExp(r'carb(?:ohydrate)?s?[:\s]*(\d+\.?\d*)', caseSensitive: false).firstMatch(text);
      final fatMatch = RegExp(r'fat[:\s]*(\d+\.?\d*)', caseSensitive: false).firstMatch(text);
      final fiberMatch = RegExp(r'fiber[:\s]*(\d+\.?\d*)', caseSensitive: false).firstMatch(text);

      return {
        'success': true,
        'foods': [foodName],
        'nutrition': {
          'calories': int.tryParse(caloriesMatch?.group(1) ?? '0') ?? 150,
          'protein': (double.tryParse(proteinMatch?.group(1) ?? '0') ?? 5).round(),
          'carbs': (double.tryParse(carbsMatch?.group(1) ?? '0') ?? 20).round(),
          'fat': (double.tryParse(fatMatch?.group(1) ?? '0') ?? 5).round(),
          'fiber': (double.tryParse(fiberMatch?.group(1) ?? '0') ?? 2).round(),
        },
        'confidence': 0.7,
      };
    } catch (e) {
      return _getDefaultNutrition();
    }
  }

  // Helper method to parse quantity string
  Map<String, dynamic> _parseQuantity(String quantity) {
    // Extract number and unit from quantity string like "100 grams" or "2 cups"
    final parts = quantity.split(' ');
    double value = 100; // default
    String unit = 'grams'; // default

    if (parts.isNotEmpty) {
      value = double.tryParse(parts[0]) ?? 100;
      if (parts.length > 1) {
        unit = parts.sublist(1).join(' ');
      }
    }

    return {'value': value, 'unit': unit};
  }
  
  // Adjust nutrition values based on quantity
  Map<String, dynamic> _adjustNutritionForQuantity(
    Map<String, dynamic> nutritionData,
    double quantity,
    String unit,
  ) {
    if (!nutritionData['success']) return nutritionData;
    
    // Convert quantity to grams if needed
    double gramsMultiplier = 1.0;
    
    switch (unit.toLowerCase()) {
      case 'kg':
      case 'kilogram':
      case 'kilograms':
        gramsMultiplier = quantity * 1000 / 100; // Convert to grams then to per 100g
        break;
      case 'g':
      case 'gram':
      case 'grams':
        gramsMultiplier = quantity / 100; // Nutrition is per 100g
        break;
      case 'cup':
      case 'cups':
        gramsMultiplier = quantity * 250 / 100; // Approximate 1 cup = 250g
        break;
      case 'bowl':
      case 'bowls':
        gramsMultiplier = quantity * 300 / 100; // Approximate 1 bowl = 300g
        break;
      case 'plate':
      case 'plates':
        gramsMultiplier = quantity * 400 / 100; // Approximate 1 plate = 400g
        break;
      case 'serving':
      case 'servings':
        gramsMultiplier = quantity * 150 / 100; // Approximate 1 serving = 150g
        break;
      case 'piece':
      case 'pieces':
        gramsMultiplier = quantity * 100 / 100; // Approximate 1 piece = 100g
        break;
      case 'ml':
      case 'milliliter':
      case 'milliliters':
        gramsMultiplier = quantity / 100; // Approximate 1ml = 1g for liquids
        break;
      case 'l':
      case 'liter':
      case 'liters':
        gramsMultiplier = quantity * 1000 / 100; // 1L = 1000ml = 1000g approx
        break;
      default:
        gramsMultiplier = quantity / 100; // Default assumption
    }
    
    // Adjust all nutrition values
    if (nutritionData['nutrition'] != null) {
      final nutrition = nutritionData['nutrition'] as Map<String, dynamic>;
      nutritionData['nutrition'] = {
        'calories': ((nutrition['calories'] ?? 0) * gramsMultiplier).round(),
        'protein': ((nutrition['protein'] ?? 0) * gramsMultiplier).round(),
        'carbs': ((nutrition['carbs'] ?? 0) * gramsMultiplier).round(),
        'fat': ((nutrition['fat'] ?? 0) * gramsMultiplier).round(),
        'fiber': ((nutrition['fiber'] ?? 0) * gramsMultiplier).round(),
      };
    }
    
    return nutritionData;
  }
  
  // Main function to analyze food image
  Future<Map<String, dynamic>> analyzeIndianFood(File imageFile) async {
    try {
      debugPrint('\n📸 Starting Indian food analysis with Gemini AI...');
      debugPrint('Image path: ${imageFile.path}');

      // Check if model is initialized
      if (_model == null) {
        debugPrint('⚠️ Gemini not initialized, using smart fallback');
        // Try to analyze using local database with description parsing
        // For generic image analysis, use default description
        final description = 'Mixed meal from image';
        return _analyzeWithLocalDatabase(description);
      }

      // Let Gemini analyze the image and calculate nutrition directly
      // Default to 100 grams if no quantity specified
      final nutritionResult = await _calculateNutritionWithGemini(
        imageFile,
        'food item', // Generic name, Gemini will identify
        '100 grams', // Default quantity
      );

      debugPrint('Final nutrition result from Gemini: ${nutritionResult['nutrition']}');
      return nutritionResult;
    } catch (e) {
      debugPrint('Error analyzing Indian food: $e');
      debugPrint('Using local database fallback');
      // Fallback to estimated nutrition for generic food
      return _analyzeWithLocalDatabase('Mixed meal');
    }
  }
  
  // Use Google Gemini Vision (FREE tier: 60 requests/minute)
  Future<List<String>> _identifyFoodWithGemini(File imageFile) async {
    // Check if model is initialized
    if (_model == null) {
      debugPrint('Gemini not initialized, using pattern matching');
      return await _identifyFoodByPatternMatching(imageFile);
    }
    
    try {
      final imageBytes = await imageFile.readAsBytes();
      
      // Create the prompt for Indian food recognition
      final prompt = '''
You are an expert in Indian cuisine. Analyze this food image and identify ONLY the Indian food items you can see.

IMPORTANT RULES:
1. Only identify foods that are clearly visible in the image
2. Use exact names from this list when possible:
   - roti, chapati, naan, paratha
   - dal, dal tadka, dal makhani, rajma, chole
   - paneer butter masala, palak paneer
   - butter chicken, chicken curry
   - biryani, pulao, rice, jeera rice, fried rice
   - dosa, masala dosa, idli, vada, uttapam
   - sambar, rasam, pongal, upma
   - samosa, pakora, bhel puri, pani puri
   - gulab jamun, rasgulla, jalebi, ladoo

3. Return ONLY a JSON object (no other text):
{
  "foods": ["exact_food_name_1", "exact_food_name_2"],
  "confidence": 0.85
}

4. If you're not sure, return:
{
  "foods": ["rice"],
  "confidence": 0.3
}

Analyze the image now:
''';
      
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];
      
      debugPrint('📤 Sending request to Gemini API...');
      final response = await _model!.generateContent(content);
      final responseText = response.text ?? '';

      // Log the full Gemini response for debugging
      debugPrint('=== GEMINI RESPONSE START ===');
      debugPrint('Response received: ${responseText.isNotEmpty ? "Yes" : "No"}');
      debugPrint('Response length: ${responseText.length} characters');
      if (responseText.isNotEmpty) {
        debugPrint(responseText.substring(0, responseText.length > 200 ? 200 : responseText.length));
      } else {
        debugPrint('⚠️ Empty response from Gemini');
      }
      debugPrint('=== GEMINI RESPONSE END ===');
      
      // Parse the JSON response (handle multi-line JSON)
      final jsonMatch = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}', multiLine: true, dotAll: true).firstMatch(responseText);
      if (jsonMatch != null) {
        try {
          final jsonString = jsonMatch.group(0)!;
          debugPrint('Extracted JSON: $jsonString');
          final jsonData = json.decode(jsonString);
          final foods = List<String>.from(jsonData['foods'] ?? []);
          final confidence = jsonData['confidence'] ?? 0.0;
          
          debugPrint('Identified foods: $foods');
          debugPrint('Confidence: $confidence');
          
          // Normalize food names to match our database
          final normalizedFoods = foods.map((food) => _normalizeFoodName(food)).toList();
          debugPrint('Normalized foods: $normalizedFoods');
          
          return normalizedFoods;
        } catch (e) {
          debugPrint('JSON parsing error: $e');
        }
      }
      
      debugPrint('No JSON found, extracting from text...');
      // If JSON parsing fails, try to extract food names from text
      final extractedFoods = _extractFoodNames(responseText);
      debugPrint('Extracted foods from text: $extractedFoods');
      return extractedFoods;
      
    } catch (e) {
      debugPrint('❌ Gemini Vision error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Stack trace: ${StackTrace.current}');
      return [];
    }
  }
  
  // Normalize food names to match database keys
  String _normalizeFoodName(String foodName) {
    return foodName
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();
  }
  
  // Extract food names from text response
  List<String> _extractFoodNames(String text) {
    final foods = <String>[];
    final lowerText = text.toLowerCase();
    
    // Check for known food items in the response
    for (final foodName in _indianFoodDatabase.keys) {
      if (lowerText.contains(foodName)) {
        foods.add(foodName);
      }
    }
    
    return foods;
  }
  
  // Get nutrition data from database
  Map<String, dynamic> _getNutritionFromDatabase(List<String> foodItems) {
    if (foodItems.isEmpty) return _getDefaultNutrition();
    
    debugPrint('\n📊 Looking up nutrition for: $foodItems');
    
    // Aggregate nutrition for all identified foods
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    
    final identifiedFoods = <Map<String, dynamic>>[];
    final notFoundFoods = <String>[];
    
    for (final food in foodItems) {
      final nutrition = _indianFoodDatabase[food];
      if (nutrition != null) {
        debugPrint('✅ Found in database: $food -> $nutrition');
        totalCalories += nutrition['calories'] ?? 0;
        totalProtein += nutrition['protein'] ?? 0;
        totalCarbs += nutrition['carbs'] ?? 0;
        totalFat += nutrition['fat'] ?? 0;
        totalFiber += nutrition['fiber'] ?? 0;
        
        identifiedFoods.add({
          'name': food,
          'calories': nutrition['calories'],
          'confidence': 0.85,
        });
      } else {
        debugPrint('❌ Not found in database: $food');
        notFoundFoods.add(food);
      }
    }
    
    if (notFoundFoods.isNotEmpty) {
      debugPrint('⚠️ Foods not in database: $notFoundFoods');
      debugPrint('Available foods in database: ${_indianFoodDatabase.keys.take(10).toList()}...');
    }
    
    return {
      'success': true,
      'foods': identifiedFoods,
      'nutrition': {
        'calories': totalCalories.round(),
        'protein': totalProtein.round(),
        'carbs': totalCarbs.round(),
        'fat': totalFat.round(),
        'fiber': totalFiber.round(),
      },
      'source': 'Indian Food Database (IFCT 2017)',
    };
  }
  
  // Fallback: Use free Spoonacular API (150 requests/day)
  Future<Map<String, dynamic>> _fallbackAnalysis(File imageFile) async {
    try {
      // Spoonacular FREE tier: 150 points/day
      const apiKey = 'YOUR_SPOONACULAR_API_KEY'; // Get from spoonacular.com/food-api
      const url = 'https://api.spoonacular.com/food/images/analyze';
      
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['apiKey'] = apiKey;
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = json.decode(responseData);
        
        // Convert Spoonacular response to our format
        return {
          'success': true,
          'nutrition': {
            'calories': data['nutrition']['calories'] ?? 0,
            'protein': data['nutrition']['protein'] ?? 0,
            'carbs': data['nutrition']['carbs'] ?? 0,
            'fat': data['nutrition']['fat'] ?? 0,
            'fiber': data['nutrition']['fiber'] ?? 0,
          },
          'source': 'Spoonacular API',
        };
      }
    } catch (e) {
      debugPrint('Spoonacular fallback error: $e');
    }
    
    return _getDefaultNutrition();
  }
  
  // Search by text (when image recognition fails)
  Future<Map<String, dynamic>> searchIndianFood(String query) async {
    final normalizedQuery = _normalizeFoodName(query);
    final words = normalizedQuery.split(' ');
    
    // Try exact match first
    if (_indianFoodDatabase.containsKey(normalizedQuery)) {
      return _getNutritionFromDatabase([normalizedQuery]);
    }
    
    // Try partial matches
    final matches = <String>[];
    for (final foodName in _indianFoodDatabase.keys) {
      // Check if any word in query matches food name
      for (final word in words) {
        if (foodName.contains(word) && word.length > 2) {
          matches.add(foodName);
          break;
        }
      }
    }
    
    if (matches.isNotEmpty) {
      return _getNutritionFromDatabase(matches);
    }
    
    // Use Gemini to understand the query
    return await _searchWithGemini(query);
  }
  
  // Pattern matching fallback when Gemini is not available
  Future<List<String>> _identifyFoodByPatternMatching(File imageFile) async {
    // This is a simplified fallback - in production, you could use
    // image analysis libraries or other techniques
    debugPrint('Using pattern matching fallback for food identification');
    
    // For demo purposes, return common foods based on file name or random selection
    // In a real app, you might use image color analysis, ML models, etc.
    final fileName = imageFile.path.toLowerCase();
    
    // Check if filename contains food hints
    for (final foodName in _indianFoodDatabase.keys) {
      if (fileName.contains(foodName.replaceAll(' ', ''))) {
        return [foodName];
      }
    }
    
    // Return some common foods as suggestions for testing
    return ['dal', 'rice', 'chapati'];
  }
  
  // Use Gemini for text-based food search
  Future<Map<String, dynamic>> _searchWithGemini(String query) async {
    // Check if model is initialized
    if (_model == null) {
      // Fallback to direct database search
      return searchIndianFood(query);
    }
    
    try {
      final prompt = '''
      The user is searching for nutrition information about: "$query"
      
      This is likely an Indian food item. Based on your knowledge, provide:
      1. The most likely Indian food item they're referring to
      2. Estimated nutrition per serving (100g or 1 piece):
         - Calories
         - Protein (g)
         - Carbs (g)
         - Fat (g)
         - Fiber (g)
      
      Return as JSON:
      {
        "food": "identified food name",
        "calories": 200,
        "protein": 10,
        "carbs": 30,
        "fat": 5,
        "fiber": 3
      }
      ''';
      
      final response = await _model!.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';
      
      final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(responseText);
      if (jsonMatch != null) {
        final data = json.decode(jsonMatch.group(0)!);
        return {
          'success': true,
          'foods': [{
            'name': data['food'],
            'confidence': 0.75,
          }],
          'nutrition': {
            'calories': data['calories'] ?? 0,
            'protein': data['protein'] ?? 0,
            'carbs': data['carbs'] ?? 0,
            'fat': data['fat'] ?? 0,
            'fiber': data['fiber'] ?? 0,
          },
          'source': 'AI Estimation (Gemini)',
        };
      }
    } catch (e) {
      debugPrint('Gemini search error: $e');
    }
    
    return _getDefaultNutrition();
  }
  
  // Smart fallback: Analyze meal using local database
  Future<Map<String, dynamic>> _analyzeWithLocalDatabase(String description) async {
    try {
      debugPrint('🔍 Analyzing with local database: $description');

      // Convert description to lowercase for matching
      final lowerDesc = description.toLowerCase();

      // Extract quantities and food items from description
      final foods = <String>[];
      final quantities = <String, int>{};

      // Common quantity patterns
      final quantityPatterns = [
        RegExp(r'(\d+)\s*(?:piece|pcs|pc|nos|number)?\s*(?:of)?\s*(\w+)', caseSensitive: false),
        RegExp(r'(\d+)\s*(\w+)', caseSensitive: false),
        RegExp(r'(one|two|three|four|five|half|quarter)\s+(\w+)', caseSensitive: false),
      ];

      // Number word mapping
      final numberWords = {
        'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
        'half': 0.5, 'quarter': 0.25, 'single': 1, 'double': 2,
      };

      // Search for known foods in the description
      for (final foodName in _indianFoodDatabase.keys) {
        if (lowerDesc.contains(foodName)) {
          foods.add(foodName);

          // Try to extract quantity for this food
          for (final pattern in quantityPatterns) {
            final matches = pattern.allMatches(lowerDesc);
            for (final match in matches) {
              final matchedFood = match.group(2)?.toLowerCase() ?? '';
              if (foodName.contains(matchedFood) || matchedFood.contains(foodName.split(' ').first)) {
                final quantityStr = match.group(1)?.toLowerCase() ?? '1';
                final quantity = numberWords[quantityStr] ??
                                 (double.tryParse(quantityStr) ?? 1.0);
                quantities[foodName] = quantity.round();
                break;
              }
            }
          }

          // Default quantity if not found
          quantities[foodName] ??= 1;
        }
      }

      // If no foods found, try partial matching
      if (foods.isEmpty) {
        final words = lowerDesc.split(RegExp(r'[\s,;.]+'));
        for (final word in words) {
          if (word.length > 3) {
            for (final foodName in _indianFoodDatabase.keys) {
              if (foodName.contains(word) || word.contains(foodName.split(' ').first)) {
                foods.add(foodName);
                quantities[foodName] = 1;
                break;
              }
            }
          }
        }
      }

      // If still no foods found, provide estimated nutrition
      if (foods.isEmpty) {
        debugPrint('No specific foods found, providing estimated nutrition');
        return _getEstimatedNutrition(description);
      }

      // Calculate total nutrition
      int totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;
      double totalFiber = 0;

      for (final food in foods) {
        final nutrition = _indianFoodDatabase[food]!;
        final quantity = quantities[food] ?? 1;

        totalCalories += (nutrition['calories'] as int) * quantity;
        totalProtein += (nutrition['protein'] as double) * quantity;
        totalCarbs += (nutrition['carbs'] as double) * quantity;
        totalFat += (nutrition['fat'] as double) * quantity;
        totalFiber += (nutrition['fiber'] as double) * quantity;
      }

      debugPrint('✅ Local database analysis complete:');
      debugPrint('   Foods found: $foods');
      debugPrint('   Total calories: $totalCalories');

      return {
        'success': true,
        'foods': foods,
        'nutrition': {
          'calories': totalCalories,
          'protein': totalProtein.round(),
          'carbs': totalCarbs.round(),
          'fat': totalFat.round(),
          'fiber': totalFiber.round(),
        },
        'confidence': 0.7,
        'source': 'Local Database',
      };
    } catch (e) {
      debugPrint('Error in local database analysis: $e');
      return _getEstimatedNutrition(description);
    }
  }

  // Provide estimated nutrition when all else fails
  Map<String, dynamic> _getEstimatedNutrition(String description) {
    debugPrint('📊 Providing estimated nutrition');

    // Estimate based on typical meal sizes
    final lowerDesc = description.toLowerCase();
    int estimatedCalories = 300; // Default medium meal

    // Adjust based on meal size indicators
    if (lowerDesc.contains('large') || lowerDesc.contains('big') ||
        lowerDesc.contains('heavy') || lowerDesc.contains('full')) {
      estimatedCalories = 500;
    } else if (lowerDesc.contains('small') || lowerDesc.contains('light') ||
               lowerDesc.contains('snack') || lowerDesc.contains('mini')) {
      estimatedCalories = 150;
    }

    // Typical macro distribution
    final protein = (estimatedCalories * 0.20 / 4).round(); // 20% from protein
    final carbs = (estimatedCalories * 0.50 / 4).round();   // 50% from carbs
    final fat = (estimatedCalories * 0.30 / 9).round();     // 30% from fat
    final fiber = (estimatedCalories * 0.02).round();       // Rough estimate

    return {
      'success': true,
      'foods': ['Mixed meal'],
      'nutrition': {
        'calories': estimatedCalories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
      },
      'confidence': 0.5,
      'source': 'Estimated',
      'message': 'Nutrition values are estimated. For accurate tracking, please use manual entry.',
    };
  }

  // Get default nutrition when all methods fail
  Map<String, dynamic> _getDefaultNutrition() {
    return {
      'success': false,
      'foods': [],
      'nutrition': {
        'calories': 0,
        'protein': 0,
        'carbs': 0,
        'fat': 0,
        'fiber': 0,
      },
      'source': 'No data available',
    };
  }
  
  // Get all available Indian foods (for autocomplete)
  List<String> getAllIndianFoods() {
    return _indianFoodDatabase.keys.toList()..sort();
  }
  
  // Get nutrition for specific food
  Map<String, dynamic>? getNutritionForFood(String foodName) {
    final normalized = _normalizeFoodName(foodName);
    return _indianFoodDatabase[normalized];
  }
}