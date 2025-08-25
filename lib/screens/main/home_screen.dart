import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/health_provider.dart';
import '../../models/health_metric_model.dart';
import '../../widgets/dashboard_metric_card.dart';
import '../../utils/app_theme.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  TimePeriod _selectedPeriod = TimePeriod.daily;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).logActivity();
      _initializeHealthData();
    });
  }

  Future<void> _initializeHealthData() async {
    final healthProvider = Provider.of<HealthProvider>(context, listen: false);
    if (!healthProvider.isInitialized) {
      await healthProvider.initialize();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<HealthProvider>(
          builder: (context, healthProvider, child) {
            if (!healthProvider.isInitialized && healthProvider.error == null) {
              return _buildPermissionRequest(healthProvider);
            }

            return Column(
              children: [
                _buildHeader(),
                _buildTimePeriodTabs(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      HapticFeedback.lightImpact();
                      await healthProvider.refreshMetrics();
                    },
                    color: AppTheme.primaryAccent,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildMetricsGrid(healthProvider),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCardBackground : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Dashboard',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  // Notification action
                },
                icon: Stack(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      size: 28,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // Menu action
                },
                icon: Icon(
                  Icons.menu,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePeriodTabs() {
    return Container(
      height: 50,
      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCardBackground : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildPeriodTab('Today', TimePeriod.daily),
          _buildPeriodTab('Week', TimePeriod.weekly),
          _buildPeriodTab('Month', TimePeriod.monthly),
          _buildPeriodTab('3 Month', TimePeriod.yearly),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String label, TimePeriod period) {
    final isSelected = _selectedPeriod == period;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = period;
          });
          HapticFeedback.selectionClick();
          
          // Update all metrics to the selected period
          final healthProvider = Provider.of<HealthProvider>(context, listen: false);
          for (final metricType in MetricType.values) {
            healthProvider.updatePeriod(metricType, period);
          }
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppTheme.primaryAccent : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppTheme.textPrimary : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(HealthProvider healthProvider) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(20),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: [
        _buildHeartRateCard(healthProvider),
        _buildStepsCard(healthProvider),
        _buildWaterCard(healthProvider),
        _buildSleepCard(healthProvider),
        _buildTrainingCard(healthProvider),
        _buildCaloriesCard(healthProvider),
      ],
    );
  }

  Widget _buildHeartRateCard(HealthProvider healthProvider) {
    final heartRateData = healthProvider.metrics[MetricType.restingHeartRate];
    final value = heartRateData?.currentValue ?? 0;
    
    // Generate sample heart rate data for visualization
    final List<double> heartRateValues = List.generate(
      7, 
      (index) => 60 + math.Random().nextDouble() * 40,
    );

    return DashboardMetricCard(
      title: 'Heart',
      value: value.toInt().toString(),
      unit: 'bpm',
      iconColor: AppTheme.primaryAccent,
      icon: Icons.favorite,
      chart: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            MiniBarChart(
              values: heartRateValues,
              barColor: AppTheme.primaryAccent,
            ),
            SizedBox(height: 4),
            Text(
              '${value.toInt()} bpm',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
      onTap: () => _showMetricDetails(context, MetricType.restingHeartRate, heartRateData),
    );
  }

  Widget _buildStepsCard(HealthProvider healthProvider) {
    final stepsData = healthProvider.metrics[MetricType.steps];
    final value = stepsData?.currentValue ?? 0;
    final goal = stepsData?.goalValue ?? 10000;

    return DashboardMetricCard(
      title: 'Steps',
      value: value.toInt().toString(),
      unit: 'Steps',
      iconColor: const Color(0xFF6C63FF),
      icon: Icons.directions_walk,
      chart: CircularProgressChart(
        value: value,
        maxValue: goal,
        displayValue: value.toInt().toString(),
        unit: 'Steps',
        progressColor: const Color(0xFF6C63FF),
      ),
      onTap: () => _showMetricDetails(context, MetricType.steps, stepsData),
    );
  }

  Widget _buildWaterCard(HealthProvider healthProvider) {
    // Water intake is not directly available in health data, so we'll simulate it
    final waterIntake = 6;
    final waterGoal = 8;
    
    final List<double> waterValues = List.generate(
      8, 
      (index) => index < waterIntake ? 1.0 : 0.3,
    );

    return DashboardMetricCard(
      title: 'Water',
      value: waterIntake.toString(),
      unit: 'Cups',
      iconColor: const Color(0xFF4FC3F7),
      icon: Icons.water_drop,
      chart: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: waterValues.map((value) {
                  return Container(
                    width: 8,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Color(0xFF4FC3F7).withOpacity(value),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 4),
            Text(
              '$waterIntake Cups',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepCard(HealthProvider healthProvider) {
    final sleepData = healthProvider.metrics[MetricType.sleep];
    final minutes = sleepData?.currentValue ?? 0;
    final hours = minutes ~/ 60;
    final mins = (minutes % 60).toInt();

    return DashboardMetricCard(
      title: 'Sleep',
      value: '$hours:${mins.toString().padLeft(2, '0')}',
      unit: 'Hours',
      iconColor: const Color(0xFFFFB74D),
      icon: Icons.bedtime,
      onTap: () => _showMetricDetails(context, MetricType.sleep, sleepData),
    );
  }

  Widget _buildTrainingCard(HealthProvider healthProvider) {
    // Training/workout time - simulated
    const trainingHours = 1;
    const trainingMinutes = 30;

    return DashboardMetricCard(
      title: 'Training',
      value: '$trainingHours:${trainingMinutes.toString().padLeft(2, '0')}',
      unit: 'Hours',
      iconColor: const Color(0xFF9575CD),
      icon: Icons.fitness_center,
    );
  }

  Widget _buildCaloriesCard(HealthProvider healthProvider) {
    final caloriesData = healthProvider.metrics[MetricType.caloriesIntake];
    final value = caloriesData?.currentValue ?? 0;
    final goal = caloriesData?.goalValue ?? 2000;

    return DashboardMetricCard(
      title: 'Calories',
      value: value.toInt().toString(),
      unit: 'kcal',
      iconColor: AppTheme.primaryAccent,
      icon: Icons.local_fire_department,
      chart: SemiCircularProgressChart(
        value: value,
        maxValue: goal,
        displayValue: value.toInt().toString(),
        unit: 'kcal',
        progressColor: AppTheme.primaryAccent,
      ),
      onTap: () => _showMetricDetails(context, MetricType.caloriesIntake, caloriesData),
    );
  }

  Widget _buildPermissionRequest(HealthProvider healthProvider) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.health_and_safety,
                  size: 50,
                  color: AppTheme.primaryAccent,
                ),
              ),
              SizedBox(height: 32),
              Text(
                'Connect Your Health Data',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Sync with Apple Health, Google Fit, and other fitness devices to track your metrics in real-time',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: healthProvider.isLoading
                    ? null
                    : () async {
                        HapticFeedback.mediumImpact();
                        await healthProvider.requestPermissions();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: healthProvider.isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Grant Permission',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              if (healthProvider.error != null) ...[
                SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          healthProvider.error!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showMetricDetails(BuildContext context, MetricType type, HealthMetricSummary? summary) {
    if (summary == null) return;
    
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCardBackground : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getMetricTitle(type),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: 24),
                  _buildDetailRow('Current', _formatValue(type, summary.currentValue), true),
                  if (summary.goalValue != null)
                    _buildDetailRow('Goal', _formatValue(type, summary.goalValue!), false),
                  if (summary.averageValue != null)
                    _buildDetailRow('Average', _formatValue(type, summary.averageValue!), false),
                  if (summary.minValue != null)
                    _buildDetailRow('Minimum', _formatValue(type, summary.minValue!), false),
                  if (summary.maxValue != null)
                    _buildDetailRow('Maximum', _formatValue(type, summary.maxValue!), false),
                  SizedBox(height: 24),
                  if (summary.dataPoints.isNotEmpty && summary.dataPoints.first.source != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.source, size: 20, color: Colors.grey[600]),
                          SizedBox(width: 12),
                          Text(
                            'Source: ${summary.dataPoints.first.source}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool highlight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 20 : 16,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              color: highlight ? AppTheme.textPrimary : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  String _getMetricTitle(MetricType type) {
    switch (type) {
      case MetricType.caloriesIntake:
        return 'Calories Intake';
      case MetricType.steps:
        return 'Steps';
      case MetricType.restingHeartRate:
        return 'Heart Rate';
      case MetricType.sleep:
        return 'Sleep';
    }
  }

  String _formatValue(MetricType type, double value) {
    switch (type) {
      case MetricType.sleep:
        final hours = value ~/ 60;
        final minutes = (value % 60).toInt();
        return '${hours}h ${minutes}m';
      case MetricType.caloriesIntake:
        return '${value.toInt()} kcal';
      case MetricType.steps:
        return '${value.toInt()} steps';
      case MetricType.restingHeartRate:
        return '${value.toInt()} bpm';
    }
  }
}