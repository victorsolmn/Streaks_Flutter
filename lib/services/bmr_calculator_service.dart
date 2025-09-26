/// BMR Calculator Service
/// Calculates Basal Metabolic Rate and Total Daily Energy Expenditure
/// Uses clinically validated Mifflin-St Jeor equation

import 'package:flutter/foundation.dart';
import '../models/profile_model.dart';

class BMRCalculatorService {
  /// Calculate daily BMR using Mifflin-St Jeor equation
  /// This is the gold standard for BMR calculation
  ///
  /// Formula:
  /// Men: BMR = (10 × weight kg) + (6.25 × height cm) - (5 × age years) + 5
  /// Women: BMR = (10 × weight kg) + (6.25 × height cm) - (5 × age years) - 161
  static double calculateDailyBMR({
    required int age,
    required double weight, // kg
    required double height, // cm
    required String gender,
  }) {
    // Input validation
    if (age <= 0 || weight <= 0 || height <= 0) {
      debugPrint('BMRCalculator: Invalid input parameters, using defaults');
      return _getDefaultDailyBMR(gender);
    }

    // Mifflin-St Jeor equation
    double baseBMR = (10 * weight) + (6.25 * height) - (5 * age);

    if (gender.toLowerCase().contains('male') && !gender.toLowerCase().contains('female')) {
      // Male
      return baseBMR + 5;
    } else {
      // Female (default for all non-male entries)
      return baseBMR - 161;
    }
  }

  /// Calculate BMR from user profile with comprehensive validation and fallbacks
  static double calculateDailyBMRFromProfile(ProfileModel? profile) {
    if (profile == null) {
      debugPrint('BMRCalculator: No profile provided, using default male BMR (1800 kcal)');
      return _getDefaultDailyBMR('male');
    }

    // Get comprehensive validation status
    final bmrStatus = profile.getBMRCalculationStatus();
    final isReady = bmrStatus['isReady'] as bool;
    final missingFields = bmrStatus['missingFields'] as List<String>;
    final validatedGender = bmrStatus['validatedGender'] as String?;

    debugPrint('BMRCalculator: Profile BMR Status - Ready: $isReady, Missing: $missingFields');

    // If profile has complete valid data, use it directly
    if (isReady) {
      debugPrint('BMRCalculator: Using complete profile data for accurate BMR calculation');
      return calculateDailyBMR(
        age: profile.age!,
        weight: profile.weight!,
        height: profile.height!,
        gender: validatedGender!,
      );
    }

    // Smart fallback strategy based on available data
    debugPrint('BMRCalculator: Incomplete profile data, applying smart fallbacks');

    // Strategy 1: If we have most data, use smart defaults for missing fields
    if (missingFields.length <= 2) {
      final age = _getValidatedAge(profile.age);
      final weight = _getValidatedWeight(profile.weight, validatedGender);
      final height = _getValidatedHeight(profile.height, validatedGender);
      final gender = validatedGender ?? _inferGenderFromProfile(profile) ?? 'male';

      debugPrint('BMRCalculator: Using smart fallbacks - Age: $age, Weight: $weight, Height: $height, Gender: $gender');

      return calculateDailyBMR(
        age: age,
        weight: weight,
        height: height,
        gender: gender,
      );
    }

    // Strategy 2: Use demographic-based defaults with any available profile data
    final demographicGender = validatedGender ?? _inferGenderFromProfile(profile) ?? 'male';
    final baselineBMR = _getDefaultDailyBMR(demographicGender);

    debugPrint('BMRCalculator: Using demographic fallback for gender: $demographicGender (${baselineBMR.toInt()} kcal)');
    return baselineBMR;
  }

  /// Calculate BMR for current day portion (midnight to now)
  /// This gives us the BMR calories burned so far today
  static double calculateTodayBMR({
    required int age,
    required double weight,
    required double height,
    required String gender,
  }) {
    final dailyBMR = calculateDailyBMR(
      age: age,
      weight: weight,
      height: height,
      gender: gender,
    );

    return _calculateTodayPortion(dailyBMR);
  }

  /// Calculate today's BMR from profile
  static double calculateTodayBMRFromProfile(ProfileModel? profile) {
    final dailyBMR = calculateDailyBMRFromProfile(profile);
    return _calculateTodayPortion(dailyBMR);
  }

  /// Calculate TDEE (Total Daily Energy Expenditure)
  /// TDEE = BMR + Active Calories
  static double calculateTDEE({
    required double bmrCalories,
    required double activeCalories,
  }) {
    return bmrCalories + activeCalories;
  }

  /// Calculate today's TDEE from profile and active calories
  static double calculateTodayTDEE({
    required ProfileModel? profile,
    required double activeCalories,
  }) {
    final todayBMR = calculateTodayBMRFromProfile(profile);
    return calculateTDEE(
      bmrCalories: todayBMR,
      activeCalories: activeCalories,
    );
  }

  /// Get estimated daily BMR for adults based on gender
  static double _getDefaultDailyBMR(String gender) {
    if (gender.toLowerCase().contains('male') && !gender.toLowerCase().contains('female')) {
      return 1800; // Average male BMR
    } else {
      return 1500; // Average female BMR
    }
  }

  /// Get validated age with smart fallbacks
  static int _getValidatedAge(int? profileAge) {
    if (profileAge != null && profileAge > 0 && profileAge <= 120) {
      return profileAge;
    }

    // Smart age defaults based on typical app demographics
    // Most fitness app users are in 25-35 age range
    return 30;
  }

  /// Get validated weight with gender-aware fallbacks
  static double _getValidatedWeight(double? profileWeight, String? gender) {
    if (profileWeight != null && profileWeight > 0 && profileWeight <= 500) {
      return profileWeight;
    }

    // Gender-aware weight defaults (kg) based on WHO data
    if (gender != null && gender.toLowerCase().contains('male') && !gender.toLowerCase().contains('female')) {
      return 75.0; // Average adult male weight
    } else {
      return 65.0; // Average adult female weight
    }
  }

  /// Get validated height with gender-aware fallbacks
  static double _getValidatedHeight(double? profileHeight, String? gender) {
    if (profileHeight != null && profileHeight > 0 && profileHeight <= 300) {
      return profileHeight;
    }

    // Gender-aware height defaults (cm) based on WHO data
    if (gender != null && gender.toLowerCase().contains('male') && !gender.toLowerCase().contains('female')) {
      return 175.0; // Average adult male height
    } else {
      return 165.0; // Average adult female height
    }
  }

  /// Infer gender from profile data (name analysis, etc.)
  static String? _inferGenderFromProfile(ProfileModel profile) {
    // First check if gender is provided but just needs validation
    if (profile.gender != null && profile.gender!.isNotEmpty) {
      final normalized = profile.gender!.toLowerCase().trim();
      if (normalized.contains('male') && !normalized.contains('female')) {
        return 'male';
      } else if (normalized.contains('female')) {
        return 'female';
      }
    }

    // For privacy reasons, avoid name-based gender inference
    // Return null to use demographic fallback
    return null;
  }

  /// Calculate what portion of daily BMR has been burned today
  /// Based on time from midnight to now
  static double _calculateTodayPortion(double dailyBMR) {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    // Calculate elapsed hours since midnight
    final elapsedMinutes = now.difference(midnight).inMinutes;
    final elapsedHours = elapsedMinutes / 60.0;

    // Calculate BMR for elapsed portion of the day
    final todayBMR = (dailyBMR / 24.0) * elapsedHours;

    debugPrint('BMRCalculator: Daily BMR: ${dailyBMR.toInt()}, Elapsed hours: ${elapsedHours.toStringAsFixed(1)}, Today BMR: ${todayBMR.toInt()}');

    return todayBMR;
  }

  /// Get comprehensive BMR breakdown information for UI display
  static Map<String, dynamic> getBMRBreakdown({
    required ProfileModel? profile,
    required double activeCalories,
  }) {
    final todayBMR = calculateTodayBMRFromProfile(profile);
    final dailyBMR = calculateDailyBMRFromProfile(profile);
    final tdee = calculateTDEE(bmrCalories: todayBMR, activeCalories: activeCalories);

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final elapsedHours = now.difference(midnight).inMinutes / 60.0;

    // Get detailed profile validation status
    final bmrStatus = profile?.getBMRCalculationStatus() ?? {
      'isReady': false,
      'hasAge': false,
      'hasGender': false,
      'hasHeight': false,
      'hasWeight': false,
      'validatedGender': null,
      'missingFields': ['age', 'gender', 'height', 'weight'],
    };

    final isAccurate = bmrStatus['isReady'] as bool;
    final missingFields = bmrStatus['missingFields'] as List<String>;
    final calculationMethod = _getCalculationMethod(profile, missingFields);

    return {
      // Core calculation values
      'todayBMR': todayBMR,
      'dailyBMR': dailyBMR,
      'activeCalories': activeCalories,
      'tdee': tdee,
      'elapsedHours': elapsedHours,

      // Validation and accuracy information
      'hasCompleteProfile': isAccurate,
      'isEstimated': !isAccurate,
      'isAccurate': isAccurate,
      'calculationMethod': calculationMethod,
      'missingFields': missingFields,
      'profileValidation': bmrStatus,

      // User-friendly status messages
      'statusMessage': _getStatusMessage(isAccurate, missingFields),
      'accuracyLevel': _getAccuracyLevel(missingFields),
    };
  }

  /// Check if profile has complete data for accurate BMR calculation
  /// DEPRECATED: Use profile.hasBMRCalculationData() instead
  static bool _hasCompleteProfile(ProfileModel? profile) {
    return profile?.hasBMRCalculationData() ?? false;
  }

  /// Get calculation method description based on available profile data
  static String _getCalculationMethod(ProfileModel? profile, List<String> missingFields) {
    if (profile == null) {
      return 'Demographic Default';
    }

    if (missingFields.isEmpty) {
      return 'Mifflin-St Jeor Formula';
    } else if (missingFields.length <= 2) {
      return 'Smart Fallback Formula';
    } else {
      return 'Demographic Estimate';
    }
  }

  /// Get user-friendly status message about BMR calculation accuracy
  static String _getStatusMessage(bool isAccurate, List<String> missingFields) {
    if (isAccurate) {
      return 'Accurate calculation using your profile data';
    }

    if (missingFields.isEmpty) {
      return 'Accurate calculation using your profile data';
    } else if (missingFields.length == 1) {
      return 'Good estimate (missing ${missingFields.first})';
    } else if (missingFields.length <= 2) {
      return 'Estimate using averages for missing data';
    } else {
      return 'General estimate - complete your profile for accuracy';
    }
  }

  /// Get accuracy level rating based on missing fields
  static String _getAccuracyLevel(List<String> missingFields) {
    if (missingFields.isEmpty) {
      return 'High'; // 95%+ accuracy
    } else if (missingFields.length == 1) {
      return 'Good'; // 80-90% accuracy
    } else if (missingFields.length <= 2) {
      return 'Fair'; // 60-80% accuracy
    } else {
      return 'Low';  // 40-60% accuracy
    }
  }

  /// Get user-friendly explanation of TDEE calculation
  static String getTDEEExplanation({
    required double bmrCalories,
    required double activeCalories,
    required double elapsedHours,
  }) {
    return 'Total Daily Energy: ${bmrCalories.toInt()} BMR + ${activeCalories.toInt()} Active = ${(bmrCalories + activeCalories).toInt()} calories (${elapsedHours.toStringAsFixed(1)}h elapsed today)';
  }
}