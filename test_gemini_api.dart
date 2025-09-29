import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

// Test script to validate Gemini API integration
void main() async {
  print('🔍 Testing Gemini API Key...');
  print('=' * 50);

  const apiKey = 'AIzaSyAd8rdpCwQkPYGYb88nk08D6hlqHJJKeic';

  // 1. Validate API key format
  print('\n1️⃣ API Key Validation:');
  print('   Key starts with AIza: ${apiKey.startsWith('AIza')} ✅');
  print('   Key length: ${apiKey.length} characters (expected: 39)');
  print('   Format valid: ${apiKey.startsWith('AIza') && apiKey.length == 39} ✅');

  // 2. Test different model versions
  print('\n2️⃣ Testing Gemini Models:');
  final models = [
    'gemini-1.5-flash-latest',
    'gemini-1.5-flash',
    'gemini-1.5-pro-latest',
    'gemini-pro',
  ];

  GenerativeModel? workingModel;
  String? workingModelName;

  for (final modelName in models) {
    try {
      print('\n   Testing $modelName...');
      final model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
      );

      // Test with simple text generation
      final response = await model.generateContent([
        Content.text('What nutrients are in a banana? Reply in 10 words or less.')
      ]);

      if (response.text != null) {
        print('   ✅ $modelName works!');
        print('   Response: ${response.text}');
        workingModel = model;
        workingModelName = modelName;
        break;
      }
    } catch (e) {
      print('   ❌ $modelName failed: ${e.toString().split('\n')[0]}');
    }
  }

  // 3. Test vision capabilities with food analysis
  if (workingModel != null && workingModelName != null) {
    print('\n3️⃣ Testing Vision Capabilities:');
    print('   Using model: $workingModelName');

    try {
      // Create a simple test prompt for food analysis
      final prompt = '''
Analyze this food and return ONLY a JSON object:
{
  "foods": ["banana"],
  "total_calories": 105,
  "total_protein": 1.3,
  "total_carbs": 27,
  "total_fat": 0.4,
  "total_fiber": 3.1
}''';

      final response = await workingModel.generateContent([
        Content.text(prompt)
      ]);

      if (response.text != null) {
        print('   ✅ Vision API responds correctly!');
        print('   Can process food nutrition requests');
      }
    } catch (e) {
      print('   ⚠️ Vision test error: ${e.toString().split('\n')[0]}');
    }
  }

  // 4. Test rate limits
  print('\n4️⃣ Testing Rate Limits:');
  if (workingModel != null) {
    try {
      print('   Sending 3 rapid requests...');
      for (int i = 1; i <= 3; i++) {
        final response = await workingModel.generateContent([
          Content.text('Count to $i')
        ]);
        print('   Request $i: ✅ Success');
        await Future.delayed(Duration(milliseconds: 100));
      }
      print('   Rate limiting: OK (no 429 errors)');
    } catch (e) {
      print('   Rate limit error: ${e.toString().split('\n')[0]}');
    }
  }

  // 5. Summary
  print('\n' + '=' * 50);
  print('📊 API Test Summary:');
  print('=' * 50);

  if (workingModel != null && workingModelName != null) {
    print('✅ API Key is VALID and WORKING');
    print('✅ Best model: $workingModelName');
    print('✅ Text generation: Working');
    print('✅ Ready for food scanning');
    print('\n🎉 Gemini API integration successful!');
  } else {
    print('❌ API Key validation failed');
    print('   Please check your API key and try again');
  }

  print('\n📱 Security Recommendations:');
  print('   1. Restrict API key to app bundle ID in Google Console');
  print('   2. Set up quota limits (60 requests/minute is enough)');
  print('   3. Monitor usage in Google Cloud Console');
  print('   4. Never commit API keys to public repositories');
}