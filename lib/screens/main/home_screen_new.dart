import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../models/health_metric_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/circular_progress_widget.dart';
import 'dart:math' as math;

class HomeScreenNew extends StatefulWidget {
  const HomeScreenNew({Key? key}) : super(key: key);

  @override
  State<HomeScreenNew> createState() => _HomeScreenNewState();
}

class _HomeScreenNewState extends State<HomeScreenNew>
    with SingleTickerProviderStateMixin {
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getMotivationalMessage(int steps, int stepsGoal) {
    final remaining = stepsGoal - steps;
    if (remaining <= 0) {
      return 'Amazing! You\'ve reached your daily goal! 🎉';
    } else if (remaining <= 500) {
      return 'You\'re just $remaining steps away from your daily goal!';
    } else if (remaining <= 2000) {
      return 'Keep going! You\'re making great progress today!';
    } else {
      return 'Every step counts towards your fitness journey!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Consumer3<UserProvider, HealthProvider, NutritionProvider>(
                builder: (context, userProvider, healthProvider, nutritionProvider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(userProvider),
                      const SizedBox(height: 24),
                      _buildMotivationalSection(healthProvider),
                      const SizedBox(height: 32),
                      _buildPrimaryMetrics(healthProvider, nutritionProvider),
                      const SizedBox(height: 24),
                      _buildSecondaryMetrics(healthProvider),
                      const SizedBox(height: 32),
                      _buildInsightsSection(healthProvider, nutritionProvider, userProvider),
                      const SizedBox(height: 24),
                      _buildActionSection(nutritionProvider),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserProvider userProvider) {
    final profile = userProvider.profile;
    final userName = profile?.name ?? 'Victor';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreeting()}, $userName 👋',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
          ],
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            Icons.notifications_outlined,
            color: AppTheme.primaryAccent,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildMotivationalSection(HealthProvider healthProvider) {
    final stepsData = healthProvider.metrics[MetricType.steps];
    final steps = stepsData?.currentValue?.toInt() ?? 7700;
    final stepsGoal = stepsData?.goalValue?.toInt() ?? 10000;
    
    return Text(
      _getMotivationalMessage(steps, stepsGoal),
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: AppTheme.textSecondary,
        fontSize: 16,
        height: 1.4,
      ),
    );
  }

  Widget _buildPrimaryMetrics(HealthProvider healthProvider, NutritionProvider nutritionProvider) {
    final stepsData = healthProvider.metrics[MetricType.steps];
    final steps = stepsData?.currentValue?.toInt() ?? 7700;
    final stepsGoal = stepsData?.goalValue?.toInt() ?? 10000;
    
    final dailyNutrition = nutritionProvider.todayNutrition;
    final calories = dailyNutrition.totalCalories.toInt();
    final caloriesGoal = nutritionProvider.calorieGoal;
    final caloriesRemaining = caloriesGoal - calories;

    return Row(
      children: [
        // Steps Circle
        Expanded(
          flex: 1,
          child: Container(
            height: 200,
            child: Center(
              child: CircularProgressWidget(
                progress: steps / stepsGoal,
                size: 160,
                strokeWidth: 12,
                progressColor: Colors.blue,
                backgroundColor: Colors.grey[300]!,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      steps.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                      ),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                    Text(
                      'of ${stepsGoal.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                      )}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Steps',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 24),
        
        // Right side metrics
        Expanded(
          flex: 1,
          child: Column(
            children: [
              // Calories
              _buildMetricCard(
                'Calories',
                '$calories',
                '${caloriesRemaining > 0 ? caloriesRemaining : 0} kcal',
                AppTheme.primaryAccent,
                calories / caloriesGoal,
              ),
              
              const SizedBox(height: 16),
              
              // Heart Rate
              _buildHeartRateCard(healthProvider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, Color color, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateCard(HealthProvider healthProvider) {
    final heartRateData = healthProvider.metrics[MetricType.restingHeartRate];
    final heartRate = heartRateData?.currentValue?.toInt() ?? 68;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
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
            'Heart Rate',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // Heart rate wave
          Container(
            height: 40,
            width: double.infinity,
            child: CustomPaint(
              painter: HeartRateWavePainter(),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '$heartRate bpm',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryMetrics(HealthProvider healthProvider) {
    final sleepData = healthProvider.metrics[MetricType.sleep];
    final sleepMinutes = sleepData?.currentValue ?? 450; // 7.5 hours
    final sleepHours = (sleepMinutes / 60).toStringAsFixed(1);
    
    return Row(
      children: [
        // Sleep
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
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
                  'Sleep',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    CircularProgressWidget(
                      progress: 0.85,
                      size: 60,
                      strokeWidth: 6,
                      progressColor: Colors.purple[400]!,
                      backgroundColor: Colors.grey[300]!,
                      child: Container(),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sleepHours,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Hours',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Streak/Calories burned
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
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
                  'Your',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.local_fire_department,
                        color: AppTheme.primaryAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '18',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Calories',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  '229',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Calories left',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsSection(HealthProvider healthProvider, NutritionProvider nutritionProvider, UserProvider userProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Insights',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildInsightCard(
          '🔥',
          'You burned 450 kcal more than yesterday',
          '👏',
        ),
        
        const SizedBox(height: 12),
        
        _buildInsightCard(
          '😴',
          'Your sleep dropped by 1.5 hours last night',
          '',
        ),
        
        const SizedBox(height: 12),
        
        _buildInsightCard(
          '💧',
          'Water intake looks low — drink 2 more cups',
          '💧',
        ),
      ],
    );
  }

  Widget _buildInsightCard(String leadingIcon, String text, String trailingIcon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            leadingIcon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.4,
              ),
            ),
          ),
          if (trailingIcon.isNotEmpty)
            Text(
              trailingIcon,
              style: const TextStyle(fontSize: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildActionSection(NutritionProvider nutritionProvider) {
    return Center(
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppTheme.primaryAccent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryAccent.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              // Navigate to add food or nutrition screen
              HapticFeedback.mediumImpact();
            },
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}

class HeartRateWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final waveHeight = size.height * 0.3;
    final centerY = size.height / 2;

    path.moveTo(0, centerY);

    // Create heart rate wave pattern
    for (double x = 0; x < size.width; x += size.width / 8) {
      final y1 = centerY + math.sin(x / size.width * 4 * math.pi) * waveHeight;
      final y2 = centerY + math.sin((x + size.width / 16) / size.width * 4 * math.pi) * waveHeight * 0.7;
      
      path.lineTo(x, y1);
      path.lineTo(x + size.width / 16, y2);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}