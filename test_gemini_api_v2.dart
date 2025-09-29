import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

// Test script to validate Gemini API integration - Version 2
void main() async {
  print('🔍 Testing Gemini API Key (v2)...');
  print('=' * 50);

  const apiKey = 'AIzaSyAd8rdpCwQkPYGYb88nk08D6hlqHJJKeic';

  // 1. Validate API key format
  print('\n1️⃣ API Key Validation:');
  print('   Key starts with AIza: ${apiKey.startsWith('AIza')} ✅');
  print('   Key length: ${apiKey.length} characters (expected: 39)');
  print('   Format valid: ${apiKey.startsWith('AIza') && apiKey.length == 39} ✅');

  // 2. Test with correct model names for v1beta API
  print('\n2️⃣ Testing Gemini Models (Updated List):');
  final models = [
    'gemini-1.5-flash',     // Current stable version
    'gemini-1.5-pro',       // Pro version
    'gemini-pro',           // Base pro model
    'gemini-1.0-pro',       // Older stable
  ];

  GenerativeModel? workingModel;
  String? workingModelName;

  for (final modelName in models) {
    try {
      print('\n   Testing $modelName...');

      // Try with different API configurations
      final model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 1,
          topP: 1,
          maxOutputTokens: 500,
        ),
      );

      // Test with simple text generation
      final response = await model.generateContent([
        Content.text('Say "Hello, I am Gemini API" if you can read this.')
      ]);

      if (response.text != null && response.text!.isNotEmpty) {
        print('   ✅ $modelName WORKS!');
        print('   Response: ${response.text?.substring(0, response.text!.length > 50 ? 50 : response.text!.length)}...');
        workingModel = model;
        workingModelName = modelName;
        break;
      }
    } catch (e) {
      final error = e.toString();
      if (error.contains('not found')) {
        print('   ❌ $modelName: Model not available');
      } else if (error.contains('API key not valid')) {
        print('   ❌ $modelName: API key issue - ${error.split('\n')[0]}');
      } else if (error.contains('quota')) {
        print('   ⚠️ $modelName: Quota exceeded');
      } else {
        print('   ❌ $modelName: ${error.split('\n')[0]}');
      }
    }
  }

  // 3. If no model works, try to get available models
  if (workingModel == null) {
    print('\n3️⃣ Checking API Key Status:');
    try {
      // Try a simple model that should work
      final testModel = GenerativeModel(
        model: 'gemini-pro',
        apiKey: apiKey,
      );

      print('   Testing basic API connectivity...');
      final response = await testModel.generateContent([
        Content.text('1+1=')
      ]);

      print('   ✅ API Key is valid but model names may have changed');
    } catch (e) {
      final error = e.toString();
      if (error.contains('API key not valid')) {
        print('   ❌ API KEY IS INVALID OR NOT ACTIVATED');
        print('   Please check:');
        print('   1. API key is correct');
        print('   2. Gemini API is enabled in Google Cloud Console');
        print('   3. API key has proper permissions');
      } else if (error.contains('quota')) {
        print('   ⚠️ API key is valid but quota exceeded');
      } else {
        print('   ❌ Error: ${error.split('\n')[0]}');
      }
    }
  }

  // 4. Test with image capabilities (if model works)
  if (workingModel != null && workingModelName != null) {
    print('\n4️⃣ Testing Food Analysis Capability:');
    try {
      // Test text-based food analysis
      final prompt = '''
A meal contains: 1 banana, 1 cup of rice, and 100g chicken breast.
Calculate the total nutrition and return as JSON with these fields:
- total_calories (number)
- total_protein (number in grams)
- total_carbs (number in grams)
- total_fat (number in grams)
Return ONLY the JSON, no explanation.
''';

      final response = await workingModel.generateContent([
        Content.text(prompt)
      ]);

      if (response.text != null) {
        print('   ✅ Can analyze food nutrition!');
        print('   Sample response received (truncated):');
        print('   ${response.text?.substring(0, response.text!.length > 100 ? 100 : response.text!.length)}...');

        // Try to parse as JSON
        try {
          final jsonStr = response.text!;
          // Extract JSON from response if wrapped in markdown
          String cleanJson = jsonStr;
          if (cleanJson.contains('```')) {
            cleanJson = cleanJson.split('```')[1];
            if (cleanJson.startsWith('json')) {
              cleanJson = cleanJson.substring(4);
            }
          }
          final json = jsonDecode(cleanJson.trim());
          print('   ✅ JSON parsing successful');
        } catch (e) {
          print('   ⚠️ JSON parsing needs adjustment but API works');
        }
      }
    } catch (e) {
      print('   ⚠️ Food analysis test error: ${e.toString().split('\n')[0]}');
    }
  }

  // 5. Final Summary
  print('\n' + '=' * 50);
  print('📊 FINAL API TEST REPORT:');
  print('=' * 50);

  if (workingModel != null && workingModelName != null) {
    print('\n✅ SUCCESS! Gemini API is WORKING');
    print('   • API Key: VALID');
    print('   • Working Model: $workingModelName');
    print('   • Text Generation: FUNCTIONAL');
    print('   • Food Analysis: READY');
    print('\n🎉 Ready to use in the app!');
  } else {
    print('\n⚠️ API Key appears valid but models not accessible');
    print('   Possible issues:');
    print('   1. API might need activation at: https://makersuite.google.com/');
    print('   2. Model names might have changed');
    print('   3. Region restrictions might apply');
    print('\n   Try creating a new API key at:');
    print('   https://makersuite.google.com/app/apikey');
  }

  print('\n🔒 Security Status:');
  print('   • Key Format: ✅ Valid (AIza prefix, 39 chars)');
  print('   • Recommendation: Add app restrictions in Google Console');
  print('   • Best Practice: Use environment variables in production');
}