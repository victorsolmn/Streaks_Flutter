import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/user_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/health_provider.dart';
import '../../models/health_metric_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/circular_progress_widget.dart';
// import 'dart:math' as math; // Not needed anymore - no random data

class ProgressScreenNew extends StatefulWidget {
  const ProgressScreenNew({Key? key}) : super(key: key);

  @override
  State<ProgressScreenNew> createState() => _ProgressScreenNewState();
}

class _ProgressScreenNewState extends State<ProgressScreenNew>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Progress',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryAccent,
          labelColor: AppTheme.primaryAccent,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Progress'),
            Tab(text: 'Achievements'),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer3<UserProvider, NutritionProvider, HealthProvider>(
          builder: (context, userProvider, nutritionProvider, healthProvider, child) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildProgressTab(userProvider, nutritionProvider, healthProvider),
                _buildAchievementsTab(userProvider, nutritionProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressTab(UserProvider userProvider, NutritionProvider nutritionProvider, HealthProvider healthProvider) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Summary',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 20),
          _buildSummarySection(userProvider, nutritionProvider, healthProvider),
          const SizedBox(height: 32),
          _buildWeeklyProgressChart(nutritionProvider, healthProvider),
          const SizedBox(height: 32),
          _buildGoalProgressSection(nutritionProvider, userProvider),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab(UserProvider userProvider, NutritionProvider nutritionProvider) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStreakStatsSection(userProvider),
          const SizedBox(height: 32),
          _buildWeeklyPerformance(userProvider, nutritionProvider),
          const SizedBox(height: 32),
          _buildMotivationalMessage(userProvider),
          const SizedBox(height: 32),
          _buildAchievementBadges(userProvider),
        ],
      ),
    );
  }


  Widget _buildSummarySection(UserProvider userProvider, NutritionProvider nutritionProvider, HealthProvider healthProvider) {
    final todayNutrition = nutritionProvider.todayNutrition;
    final caloriesConsumed = todayNutrition.totalCalories;
    
    // Get actual calories burned from health provider
    final caloriesBurned = healthProvider.todayCaloriesBurned.toInt();
    final activeStreak = userProvider.streakData?.currentStreak ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            value: caloriesBurned.toString(),
            label: 'Calories\nBurned',
            color: AppTheme.primaryAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            value: caloriesConsumed.toString(),
            label: 'Calories\nConsumed',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            value: activeStreak.toString(),
            label: 'Active\nStreak',
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
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
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressChart(NutritionProvider nutritionProvider, HealthProvider healthProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Progress',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 200,
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
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 500,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppTheme.borderColor,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Mon'];
                      if (value.toInt() >= 0 && value.toInt() < days.length) {
                        return Text(
                          days[value.toInt()],
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1000,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const Text('0');
                      if (value == 1000) return const Text('1000');
                      if (value == 2000) return const Text('2000');
                      if (value == 3000) return const Text('3000');
                      return const Text('');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 7,
              minY: 0,
              maxY: 3000,
              lineBarsData: [
                // Calories Burned Line
                LineChartBarData(
                  spots: _generateWeeklyData(true),
                  isCurved: true,
                  color: AppTheme.primaryAccent,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.primaryAccent.withOpacity(0.1),
                  ),
                ),
                // Calories Consumed Line
                LineChartBarData(
                  spots: _generateWeeklyData(false),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Calories Burned', AppTheme.primaryAccent),
            const SizedBox(width: 24),
            _buildLegendItem('Calories Consumed', Colors.blue),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  List<FlSpot> _generateWeeklyData(bool isBurned) {
    // Start with zero data - will be populated from actual tracking
    return List.generate(8, (index) {
      // Return 0 for all days initially
      return FlSpot(index.toDouble(), 0);
    });
  }

  Widget _buildGoalProgressSection(NutritionProvider nutritionProvider, UserProvider userProvider) {
    final todayNutrition = nutritionProvider.todayNutrition;
    final caloriesProgress = todayNutrition.totalCalories / nutritionProvider.calorieGoal;
    final proteinProgress = todayNutrition.totalProtein / nutritionProvider.proteinGoal;
    
    // Start with zero workouts - will track actual workouts
    final workoutsCompleted = 0;
    final workoutsGoal = 7;
    final workoutProgress = workoutsCompleted / workoutsGoal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goal Progress',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 20),
        Container(
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
            children: [
              _buildProgressItem(
                'Caloric Intake',
                todayNutrition.totalCalories,
                nutritionProvider.calorieGoal,
                'kcal',
                caloriesProgress,
                AppTheme.primaryAccent,
              ),
              const SizedBox(height: 20),
              _buildProgressItem(
                'Protein',
                todayNutrition.totalProtein.toInt(),
                nutritionProvider.proteinGoal.toInt(),
                'g',
                proteinProgress,
                Colors.green,
              ),
              const SizedBox(height: 20),
              _buildProgressItem(
                'Workouts',
                workoutsCompleted,
                workoutsGoal,
                '',
                workoutProgress,
                Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressItem(
    String label,
    int current,
    int goal,
    String unit,
    double progress,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '$current / $goal $unit',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.borderColor,
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
      ],
    );
  }

  Widget _buildStreakStatsSection(UserProvider userProvider) {
    final streakData = userProvider.streakData;
    final currentStreak = streakData?.currentStreak ?? 0;
    final bestStreak = streakData?.longestStreak ?? 0;
    final goalsCompleted = 0; // Start from zero

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Streak Statistics',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                value: currentStreak.toString(),
                label: 'Current\nstreak',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                value: bestStreak.toString(),
                label: 'Best\nstreak',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                value: goalsCompleted.toString(),
                label: 'Goals\ncompleted',
              ),
            ),
            const SizedBox(width: 12),
            Container(
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
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: AppTheme.primaryAccent,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '4530',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'kcal',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({required String value, required String label}) {
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
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyPerformance(UserProvider userProvider, NutritionProvider nutritionProvider) {
    final totalStreakDays = userProvider.streakData?.currentStreak ?? 0;
    final caloriesBurnedThisWeek = 0; // Start from zero
    final hoursWorkedOut = 0; // Start from zero
    final performancePercentage = 0; // Start from zero

    return Container(
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
      child: Row(
        children: [
          // Circular Progress
          CircularProgressWidget(
            progress: performancePercentage / 100,
            size: 100,
            strokeWidth: 10,
            progressColor: AppTheme.primaryAccent,
            backgroundColor: AppTheme.borderColor,
            child: Text(
              '$performancePercentage%',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 24),
          
          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Performance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPerformanceItem('$totalStreakDays', 'Total streak days'),
                const SizedBox(height: 8),
                _buildPerformanceItem('$caloriesBurnedThisWeek', 'Calories burned this week'),
                const SizedBox(height: 8),
                _buildPerformanceItem('$hoursWorkedOut', 'Hours worked out'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceItem(String value, String label) {
    return Row(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMotivationalMessage(UserProvider userProvider) {
    final currentStreak = userProvider.streakData?.currentStreak ?? 0;
    final daysToNextMilestone = 7 - (currentStreak % 7);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryAccent.withOpacity(0.1),
            AppTheme.primaryAccent.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryAccent.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Text(
            '🔥',
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'You\'re on a $currentStreak-day streak! Just $daysToNextMilestone more days to unlock Build the Habit!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadges(UserProvider userProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 20),
        
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.8, // Increased to prevent overflow
          children: [
            _buildAchievementCard(
              title: 'Build the Habit',
              subtitle: '5 Day Streak',
              icon: Icons.hotel_class,
              isUnlocked: true,
              isGrey: true,
            ),
            _buildAchievementCard(
              title: 'Consistency Champion',
              subtitle: '20 Day Streak',
              icon: Icons.emoji_events,
              isUnlocked: true,
              isGold: true,
            ),
            _buildAchievementCard(
              title: 'Fitness Legend',
              subtitle: '100 Day Streak',
              icon: Icons.star,
              isUnlocked: false,
            ),
            _buildAchievementCard(
              title: 'Fitness Legend',
              subtitle: '100 Day Streak',
              icon: Icons.star,
              isUnlocked: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isUnlocked,
    bool isGold = false,
    bool isGrey = false,
  }) {
    Color bgColor;
    Color iconColor;
    
    if (isUnlocked) {
      if (isGold) {
        bgColor = Colors.orange.withOpacity(0.2);
        iconColor = Colors.orange;
      } else if (isGrey) {
        bgColor = Colors.grey.withOpacity(0.2);
        iconColor = Colors.grey[600]!;
      } else {
        bgColor = AppTheme.successGreen.withOpacity(0.2);
        iconColor = AppTheme.successGreen;
      }
    } else {
      bgColor = AppTheme.borderColor;
      iconColor = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? iconColor.withOpacity(0.3) : AppTheme.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40, // Reduced icon container size
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20, // Reduced icon size
            ),
          ),
          const SizedBox(height: 8), // Reduced spacing
          Flexible( // Added Flexible to prevent text overflow
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith( // Changed to bodyMedium
                fontWeight: FontWeight.w600,
                fontSize: 13, // Explicit font size
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2), // Reduced spacing
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 11, // Explicit smaller font size
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}