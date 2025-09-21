import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/user_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/fitness_goal_summary_dialog.dart';
import '../../widgets/health_permission_dialog.dart';
import '../../widgets/streak_display_widget.dart';
import '../../widgets/sync_status_indicator.dart';
import '../../providers/streak_provider.dart';
import '../../services/health_onboarding_service.dart';
import 'dart:math' as math;
import '../../services/toast_service.dart';

class HomeScreenClean extends StatefulWidget {
  const HomeScreenClean({Key? key}) : super(key: key);

  @override
  State<HomeScreenClean> createState() => _HomeScreenCleanState();
}

class _HomeScreenCleanState extends State<HomeScreenClean>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  HealthOnboardingService? _healthOnboardingService;
  bool _hasCheckedHealthPermission = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<UserProvider>(context, listen: false).logActivity();
      await _initializeHealthData();
      await _checkAndShowHealthPermissionDialog();
      _checkAndShowFitnessGoalSummary();
    });
  }

  Future<void> _initializeHealthData() async {
    // Sync metrics to streak provider only once
    await _syncMetricsToStreak();

    // Note: Health initialization and syncing is already handled by MainScreen
    // We only need to ensure the provider is initialized
    final healthProvider = Provider.of<HealthProvider>(context, listen: false);
    if (!healthProvider.isInitialized) {
      await healthProvider.initialize();
    }

    // Don't sync here - MainScreen already handles this
    debugPrint('Home page: Health data ready - Steps: ${healthProvider.todaySteps}, Calories: ${healthProvider.todayCaloriesBurned}');
  }

  Future<void> _checkAndShowFitnessGoalSummary() async {
    await Future.delayed(Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final profile = userProvider.profile;
    
    // Only show dialog if user just completed onboarding and hasn't seen the summary yet
    if (profile != null && 
        userProvider.justCompletedOnboarding && 
        !profile.hasSeenFitnessGoalSummary) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => FitnessGoalSummaryDialog(
          onAgree: () async {
            await userProvider.updateProfile(
              hasSeenFitnessGoalSummary: true,
            );
            // Clear the temporary flag after showing the dialog
            userProvider.clearJustCompletedOnboardingFlag();
          },
        ),
      );
    }
  }

  Future<void> _checkAndShowHealthPermissionDialog() async {
    // Avoid showing multiple times in same session
    if (_hasCheckedHealthPermission) return;
    _hasCheckedHealthPermission = true;

    // Initialize health onboarding service if not already done
    if (_healthOnboardingService == null) {
      final prefs = await SharedPreferences.getInstance();
      final healthProvider = Provider.of<HealthProvider>(context, listen: false);
      _healthOnboardingService = HealthOnboardingService(
        prefs: prefs,
        healthProvider: healthProvider,
      );
    }

    // Check if we should show the health permission dialog
    final shouldShow = await _healthOnboardingService!.shouldShowHealthPrompt();
    if (shouldShow && mounted) {
      // Small delay to ensure the home screen is fully rendered
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      // Check if it's a re-engagement
      final healthProvider = Provider.of<HealthProvider>(context, listen: false);
      final isReengagement = await SharedPreferences.getInstance()
          .then((prefs) => prefs.getBool('health_prompt_shown') ?? false);

      // Show the health permission dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => HealthPermissionDialog(
          isReengagement: isReengagement,
          onConnect: () async {
            Navigator.of(context).pop();
            await _handleHealthPermissionRequest();
          },
          onDismiss: () async {
            Navigator.of(context).pop();
            await _healthOnboardingService!.markHealthPromptDismissed();

            // Show a subtle reminder
            if (mounted) {
              ToastService().showInfo('You can connect health data anytime from Settings');
            }
          },
        ),
      );

      // Mark that we've shown the prompt
      await _healthOnboardingService!.markHealthPromptShown();
    }
    // Note: Auto-sync is already handled by MainScreen, no need to sync here
  }

  Future<void> _handleHealthPermissionRequest() async {
    final result = await _healthOnboardingService!.requestHealthPermissions(context);

    if (result.success) {
      // Show success message
      if (mounted) {
        ToastService().showSuccess(result.message);
      }

      // Refresh the UI to show real data
      await _refreshHealthData();
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.message),
                if (result.actionRequired != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    result.actionRequired!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _syncMetricsToStreak() async {
    final streakProvider = Provider.of<StreakProvider>(context, listen: false);
    final healthProvider = Provider.of<HealthProvider>(context, listen: false);
    final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Sync all metrics to streak provider
    await streakProvider.syncMetricsFromProviders(
      healthProvider,
      nutritionProvider,
      userProvider,
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshHealthData() async {
    final healthProvider = Provider.of<HealthProvider>(context, listen: false);
    
    // Initialize health if not already done
    if (!healthProvider.isInitialized) {
      await healthProvider.initializeHealth();
    }
    
    // Sync with health sources
    await healthProvider.syncWithHealth();
    
    // Force a rebuild to show updated data
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Consumer4<UserProvider, HealthProvider, NutritionProvider, StreakProvider>(
            builder: (context, userProvider, healthProvider, nutritionProvider, streakProvider, child) {
              // Note: Do NOT call _syncMetricsToStreak() here - it causes infinite rebuilds
              // Sync is already handled in initState and _initializeHealthData
              return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(), // Changed from AlwaysScrollableScrollPhysics to prevent pull-to-refresh
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personalized Greeting
                    _buildGreeting(userProvider, isDarkMode),

                    const SizedBox(height: 20),
                    
                    // Steps Circle and Water/Calories Icons Row
                    _buildTopSection(healthProvider, nutritionProvider, isDarkMode),
                    
                    const SizedBox(height: 16),
                    
                    // Motivational message
                    Center(
                      child: Text(
                        'Every step counts towards your fitness journey!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Metrics Grid
                    _buildMetricsGrid(healthProvider, nutritionProvider, isDarkMode),
                    
                    const SizedBox(height: 32),
                    
                    // Your Insights Section
                    _buildInsightsSection(healthProvider, nutritionProvider, userProvider, isDarkMode),
                  ],
                  ),
                );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(UserProvider userProvider, bool isDarkMode) {
    final profile = userProvider.profile;
    String userName = profile?.name ?? '';

    // If name is empty or just whitespace, fallback to 'User'
    if (userName.trim().isEmpty) {
      userName = 'User';
    }

    // Get first name from full name
    String displayName = userName.split(' ').first;

    // Handle long names - truncate if needed
    if (displayName.length > 15) {
      displayName = displayName.substring(0, 14) + '...';
    }

    // Get time-based greeting
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello $displayName 👋',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              Text(
                greeting,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        // Sync status indicator removed - already shown in main_screen.dart
        // to avoid duplicate indicators
      ],
    );
  }

  Widget _buildTopSection(HealthProvider healthProvider, NutritionProvider nutritionProvider, bool isDarkMode) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final profile = userProvider.profile;
    
    final steps = healthProvider.todaySteps.toInt();
    final stepsGoal = profile?.dailyStepsTarget ?? 10000;
    final progress = (steps / stepsGoal).clamp(0.0, 1.0);
    
    // Get water intake (using 0 for now as we don't have water tracking yet)
    final waterGlasses = 0;
    final waterGoal = profile?.dailyWaterTarget?.toInt() ?? 8;
    
    // Get calories burned
    final caloriesBurned = healthProvider.todayCaloriesBurned.toInt();
    final caloriesGoal = profile?.dailyCaloriesTarget ?? 2000;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Water glasses counter
          Flexible(
            flex: 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_drink,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$waterGlasses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '/$waterGoal',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Steps Circle
          Container(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(140, 140),
                  painter: CircularProgressPainter(
                    progress: progress,
                    backgroundColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                    progressColor: Colors.blue,
                    strokeWidth: 10,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      steps.toString(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'of $stepsGoal',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Calories counter
          Flexible(
            flex: 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        '$caloriesBurned',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ],
                ),
                Text(
                  '/$caloriesGoal',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(HealthProvider healthProvider, NutritionProvider nutritionProvider, bool isDarkMode) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final profile = userProvider.profile;
    final caloriesGoal = profile?.dailyCaloriesTarget ?? 2000;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Calories',
                icon: Icons.local_fire_department,
                iconColor: Colors.orange,
                value: healthProvider.todayCaloriesBurned.toInt().toString(),
                subtitle: '/ ${caloriesGoal}',
                isDarkMode: isDarkMode,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                title: 'Avg Heart Rate',
                icon: Icons.favorite,
                iconColor: Colors.red,
                value: healthProvider.todayHeartRate.toInt().toString(),
                subtitle: 'bpm',
                statusText: _getHeartRateStatus(healthProvider.todayHeartRate.toInt()),
                statusColor: _getHeartRateStatusColor(healthProvider.todayHeartRate.toInt()),
                isDarkMode: isDarkMode,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Sleep',
                icon: Icons.bedtime,
                iconColor: Colors.purple,
                value: healthProvider.todaySleep.toStringAsFixed(1),
                subtitle: 'hrs',
                isDarkMode: isDarkMode,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                title: 'Calories Left',
                icon: Icons.restaurant,
                iconColor: Colors.green,
                value: _calculateCaloriesLeft(nutritionProvider).toString(),
                subtitle: 'kcal',
                isDarkMode: isDarkMode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String subtitle,
    String? statusText,
    Color? statusColor,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          value,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (statusText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        statusText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: statusColor ?? (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(HealthProvider healthProvider, NutritionProvider nutritionProvider, UserProvider userProvider, bool isDarkMode) {
    final insights = _generateInsights(healthProvider, nutritionProvider, userProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Insights',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...insights.map((insight) => _buildInsightItem(
          icon: insight['icon'] as IconData,
          iconColor: insight['iconColor'] as Color,
          text: insight['text'] as String,
          isDarkMode: isDarkMode,
        )).toList(),
      ],
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required Color iconColor,
    required String text,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateInsights(
    HealthProvider healthProvider, 
    NutritionProvider nutritionProvider,
    UserProvider userProvider,
  ) {
    final insights = <Map<String, dynamic>>[];
    final profile = userProvider.profile;
    final stepsGoal = profile?.dailyStepsTarget ?? 10000;
    final steps = healthProvider.todaySteps.toInt();
    final todayNutrition = nutritionProvider.todayNutrition;
    
    // Steps insight
    if (steps < 5000) {
      insights.add({
        'icon': Icons.directions_walk,
        'iconColor': Colors.orange,
        'text': 'Time to move! You\'re at $steps steps today →',
      });
    } else if (steps >= stepsGoal) {
      insights.add({
        'icon': Icons.celebration,
        'iconColor': Colors.green,
        'text': 'Great job! You\'ve hit your daily step goal!',
      });
    } else {
      insights.add({
        'icon': Icons.trending_up,
        'iconColor': Colors.blue,
        'text': 'Keep going! ${stepsGoal - steps} steps to reach your goal',
      });
    }
    
    // Protein insight
    if (todayNutrition != null && todayNutrition.totalProtein < 50) {
      insights.add({
        'icon': Icons.restaurant,
        'iconColor': Colors.red,
        'text': 'Protein intake is low (${todayNutrition.totalProtein.toStringAsFixed(0)}g). Aim for at least 50g',
      });
    }
    
    // Sleep insight
    final sleep = healthProvider.todaySleep;
    if (sleep > 0 && sleep < 7) {
      insights.add({
        'icon': Icons.bedtime,
        'iconColor': Colors.purple,
        'text': 'Only ${sleep.toStringAsFixed(1)} hours of sleep. Try to get 7-9 hours',
      });
    }
    
    // Heart rate insight
    final heartRate = healthProvider.todayHeartRate.toInt();
    if (heartRate > 0 && heartRate > 100) {
      insights.add({
        'icon': Icons.favorite,
        'iconColor': Colors.red,
        'text': 'Your resting heart rate is elevated at $heartRate bpm',
      });
    }
    
    return insights;
  }

  String _getHeartRateStatus(int heartRate) {
    if (heartRate == 0) return 'No data';
    if (heartRate < 60) return 'Below normal';
    if (heartRate <= 100) return 'Normal';
    return 'Above normal';
  }

  Color _getHeartRateStatusColor(int heartRate) {
    if (heartRate == 0) return Colors.grey;
    if (heartRate < 60) return Colors.blue;
    if (heartRate <= 100) return Colors.green;
    return Colors.orange;
  }

  int _calculateCaloriesLeft(NutritionProvider nutritionProvider) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final profile = userProvider.profile;
    final todayNutrition = nutritionProvider.todayNutrition;
    final caloriesConsumed = todayNutrition?.totalCalories ?? 0;
    final dailyGoal = profile?.dailyCaloriesTarget ?? 2000;
    return (dailyGoal - caloriesConsumed).clamp(0, dailyGoal);
  }


}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progressAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}