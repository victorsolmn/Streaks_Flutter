import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'supabase_service.dart';

class AppConfig {
  final String platform;
  final String minVersion;
  final int minBuildNumber;
  final String? recommendedVersion;
  final bool forceUpdate;
  final String? updateMessage;
  final String? updateUrl;
  final bool maintenanceMode;
  final String? maintenanceMessage;
  final String updateSeverity;
  final List<String> featuresList;

  AppConfig({
    required this.platform,
    required this.minVersion,
    required this.minBuildNumber,
    this.recommendedVersion,
    required this.forceUpdate,
    this.updateMessage,
    this.updateUrl,
    required this.maintenanceMode,
    this.maintenanceMessage,
    required this.updateSeverity,
    required this.featuresList,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      platform: json['platform'] ?? 'all',
      minVersion: json['min_version'] ?? '1.0.0',
      minBuildNumber: json['min_build_number'] ?? 0,
      recommendedVersion: json['recommended_version'],
      forceUpdate: json['force_update'] ?? false,
      updateMessage: json['update_message'],
      updateUrl: json['update_url'],
      maintenanceMode: json['maintenance_mode'] ?? false,
      maintenanceMessage: json['maintenance_message'],
      updateSeverity: json['update_severity'] ?? 'optional',
      featuresList: List<String>.from(json['features_list'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'min_version': minVersion,
      'min_build_number': minBuildNumber,
      'recommended_version': recommendedVersion,
      'force_update': forceUpdate,
      'update_message': updateMessage,
      'update_url': updateUrl,
      'maintenance_mode': maintenanceMode,
      'maintenance_message': maintenanceMessage,
      'update_severity': updateSeverity,
      'features_list': featuresList,
    };
  }
}

class UpdateCheckResult {
  final bool updateRequired;
  final bool forceUpdate;
  final bool maintenanceMode;
  final String? updateMessage;
  final String? maintenanceMessage;
  final String? updateUrl;
  final String updateSeverity;
  final List<String> features;
  final String? currentVersion;
  final String? requiredVersion;

  UpdateCheckResult({
    required this.updateRequired,
    required this.forceUpdate,
    required this.maintenanceMode,
    this.updateMessage,
    this.maintenanceMessage,
    this.updateUrl,
    required this.updateSeverity,
    required this.features,
    this.currentVersion,
    this.requiredVersion,
  });
}

class VersionManagerService {
  static final VersionManagerService _instance = VersionManagerService._internal();
  factory VersionManagerService() => _instance;
  VersionManagerService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  static const String _cacheKey = 'cached_app_config';
  static const String _lastCheckKey = 'last_version_check';
  static const Duration _cacheExpiry = Duration(hours: 12);

  AppConfig? _cachedConfig;
  DateTime? _lastCheckTime;

  /// Check if an update is required
  Future<UpdateCheckResult> checkForUpdate({bool skipCache = false}) async {
    try {
      if (kDebugMode) {
        print('🔍 Checking for app updates...');
      }

      // Get local version info
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      if (kDebugMode) {
        print('📱 Current version: $currentVersion (Build: $currentBuildNumber)');
      }

      // Get remote config
      final config = await _getAppConfig(skipCache: skipCache);

      if (config == null) {
        if (kDebugMode) {
          print('⚠️ No app config found, allowing app to continue');
        }
        return UpdateCheckResult(
          updateRequired: false,
          forceUpdate: false,
          maintenanceMode: false,
          updateSeverity: 'optional',
          features: [],
          currentVersion: currentVersion,
        );
      }

      // Check maintenance mode first
      if (config.maintenanceMode) {
        if (kDebugMode) {
          print('🔧 App is in maintenance mode');
        }
        return UpdateCheckResult(
          updateRequired: false,
          forceUpdate: false,
          maintenanceMode: true,
          maintenanceMessage: config.maintenanceMessage ?? 'The app is currently under maintenance. Please try again later.',
          updateSeverity: 'critical',
          features: [],
          currentVersion: currentVersion,
        );
      }

      // Compare versions
      final versionComparison = _compareVersions(currentVersion, config.minVersion);
      final buildComparison = currentBuildNumber < config.minBuildNumber;

      // Determine if update is required
      final updateRequired = versionComparison < 0 || buildComparison;

      // Check if it's a recommended update
      bool recommendedUpdate = false;
      if (!updateRequired && config.recommendedVersion != null) {
        recommendedUpdate = _compareVersions(currentVersion, config.recommendedVersion!) < 0;
      }

      if (kDebugMode) {
        print('📊 Version comparison: current=$currentVersion, required=${config.minVersion}');
        print('📊 Build comparison: current=$currentBuildNumber, required=${config.minBuildNumber}');
        print('📊 Update required: $updateRequired, Force: ${config.forceUpdate}');
        print('📊 Recommended update: $recommendedUpdate');
      }

      // Return result
      return UpdateCheckResult(
        updateRequired: updateRequired || recommendedUpdate,
        forceUpdate: updateRequired && config.forceUpdate, // Force only if below minimum
        maintenanceMode: false,
        updateMessage: config.updateMessage,
        updateUrl: config.updateUrl,
        updateSeverity: updateRequired
            ? (config.forceUpdate ? 'critical' : 'required')
            : (recommendedUpdate ? 'recommended' : 'optional'),
        features: config.featuresList,
        currentVersion: currentVersion,
        requiredVersion: updateRequired ? config.minVersion : config.recommendedVersion,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error checking for updates: $e');
        print(stackTrace);
      }
      // On error, allow app to continue
      return UpdateCheckResult(
        updateRequired: false,
        forceUpdate: false,
        maintenanceMode: false,
        updateSeverity: 'optional',
        features: [],
      );
    }
  }

  /// Get app config from Supabase or cache
  Future<AppConfig?> _getAppConfig({bool skipCache = false}) async {
    try {
      // Check cache first unless skipped
      if (!skipCache) {
        final cachedConfig = await _getCachedConfig();
        if (cachedConfig != null) {
          if (kDebugMode) {
            print('📦 Using cached app config');
          }
          return cachedConfig;
        }
      }

      // Fetch from Supabase
      if (kDebugMode) {
        print('🌐 Fetching app config from server...');
      }

      final platform = Platform.isIOS ? 'ios' : 'android';

      // Query for platform-specific or 'all' config
      final response = await _supabaseService.client
          .from('app_config')
          .select('*')
          .eq('active', true)
          .or('platform.eq.$platform,platform.eq.all')
          .order('created_at', ascending: false)
          .limit(1);

      if (response == null || (response as List).isEmpty) {
        if (kDebugMode) {
          print('⚠️ No app config found in database');
        }
        return null;
      }

      final configData = response[0];
      final config = AppConfig.fromJson(configData);

      // Cache the config
      await _cacheConfig(config);

      if (kDebugMode) {
        print('✅ App config fetched and cached');
      }

      return config;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching app config: $e');
      }
      // Try to use cached config on error
      return await _getCachedConfig();
    }
  }

  /// Cache app config locally
  Future<void> _cacheConfig(AppConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = config.toJson();
      await prefs.setString(_cacheKey, json.encode(configJson));
      await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());
      _cachedConfig = config;
      _lastCheckTime = DateTime.now();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error caching app config: $e');
      }
    }
  }

  /// Get cached app config
  Future<AppConfig?> _getCachedConfig() async {
    try {
      // Check memory cache first
      if (_cachedConfig != null && _lastCheckTime != null) {
        final timeSinceLastCheck = DateTime.now().difference(_lastCheckTime!);
        if (timeSinceLastCheck < _cacheExpiry) {
          return _cachedConfig;
        }
      }

      // Check persistent cache
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString(_cacheKey);
      final lastCheckString = prefs.getString(_lastCheckKey);

      if (cachedString == null || lastCheckString == null) {
        return null;
      }

      // Check if cache is expired
      final lastCheck = DateTime.parse(lastCheckString);
      final timeSinceLastCheck = DateTime.now().difference(lastCheck);

      if (timeSinceLastCheck > _cacheExpiry) {
        if (kDebugMode) {
          print('⏰ Cached config expired');
        }
        return null;
      }

      // Parse cached config
      final Map<String, dynamic> configMap = json.decode(cachedString);
      final config = AppConfig.fromJson(configMap);

      // Update memory cache
      _cachedConfig = config;
      _lastCheckTime = lastCheck;

      return config;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting cached config: $e');
      }
      return null;
    }
  }

  /// Compare semantic versions
  /// Returns: -1 if v1 < v2, 0 if v1 == v2, 1 if v1 > v2
  int _compareVersions(String v1, String v2) {
    try {
      final parts1 = v1.split('.').map(int.parse).toList();
      final parts2 = v2.split('.').map(int.parse).toList();

      // Pad with zeros to make equal length
      while (parts1.length < parts2.length) {
        parts1.add(0);
      }
      while (parts2.length < parts1.length) {
        parts2.add(0);
      }

      // Compare each part
      for (int i = 0; i < parts1.length; i++) {
        if (parts1[i] < parts2[i]) {
          return -1;
        } else if (parts1[i] > parts2[i]) {
          return 1;
        }
      }

      return 0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error comparing versions: $e');
      }
      return 0; // Assume equal on error
    }
  }

  /// Open app store for updates
  Future<void> openAppStore({String? customUrl}) async {
    try {
      String storeUrl = customUrl ?? '';

      if (storeUrl.isEmpty) {
        if (Platform.isIOS) {
          // Default iOS App Store URL
          storeUrl = 'https://apps.apple.com/app/streaker/id6737292817';
        } else if (Platform.isAndroid) {
          // Default Google Play Store URL
          storeUrl = 'https://play.google.com/store/apps/details?id=com.streaker.streaker';
        }
      }

      if (kDebugMode) {
        print('🛍️ Opening store: $storeUrl');
      }

      final uri = Uri.parse(storeUrl);

      // Try to launch the URL
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (kDebugMode) {
          print('❌ Could not launch store URL: $storeUrl');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error opening app store: $e');
      }
    }
  }

  /// Clear cached config (useful for testing)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_lastCheckKey);
      _cachedConfig = null;
      _lastCheckTime = null;
      if (kDebugMode) {
        print('🗑️ Version cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing cache: $e');
      }
    }
  }

  /// Check if we should skip version check (for development)
  bool shouldSkipVersionCheck() {
    // Skip in debug mode unless explicitly testing
    if (kDebugMode) {
      // You can add a flag here to enable testing in debug mode
      return false; // Set to true to skip version checks during development
    }
    return false;
  }
}