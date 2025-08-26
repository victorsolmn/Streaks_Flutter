import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/supabase_nutrition_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/circular_progress_widget.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Progress'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryAccent,
          labelColor: AppTheme.primaryAccent,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Streaks'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildStreaksTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer2<UserProvider, NutritionProvider>(
      builder: (context, userProvider, nutritionProvider, child) {
        final streakData = userProvider.streakData;
        final todayNutrition = nutritionProvider.todayNutrition;
        final weeklyActivity = userProvider.getWeeklyActivityCount();
        final monthlyActivity = userProvider.getMonthlyActivityCount();

        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current streak highlight
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryAccent,
                        Color(0xFFFF8F00),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        size: 48,
                      ),
                      SizedBox(height: 16),
                      
                      Text(
                        '${streakData?.currentStreak ?? 0}',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      
                      Text(
                        'Day Current Streak',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      
                      Text(
                        userProvider.getGoalDescription(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8) ?? Colors.grey.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Quick stats grid
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'This Week',
                        value: '$weeklyActivity',
                        subtitle: 'active days',
                        icon: Icons.calendar_view_week,
                        color: AppTheme.successGreen,
                      ),
                    ),
                    SizedBox(width: 16),
                    
                    Expanded(
                      child: StatCard(
                        label: 'This Month',
                        value: '$monthlyActivity',
                        subtitle: 'active days',
                        icon: Icons.calendar_month,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Best Streak',
                        value: '${streakData?.longestStreak ?? 0}',
                        subtitle: 'days',
                        icon: Icons.emoji_events,
                        color: Colors.amber,
                      ),
                    ),
                    SizedBox(width: 16),
                    
                    Expanded(
                      child: StatCard(
                        label: 'Today Calories',
                        value: '${todayNutrition.totalCalories}',
                        subtitle: 'logged',
                        icon: Icons.local_fire_department,
                        color: AppTheme.primaryAccent,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 32),
                
                // Progress towards goals
                Text(
                  'Today\'s Goals',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),
                
                ProgressMetricCard(
                  title: 'Calories',
                  current: todayNutrition.totalCalories.toDouble(),
                  target: nutritionProvider.calorieGoal.toDouble(),
                  unit: 'cal',
                  icon: Icons.local_fire_department,
                  color: AppTheme.primaryAccent,
                ),
                SizedBox(height: 12),
                
                ProgressMetricCard(
                  title: 'Protein',
                  current: todayNutrition.totalProtein,
                  target: nutritionProvider.proteinGoal,
                  unit: 'g',
                  icon: Icons.fitness_center,
                  color: AppTheme.successGreen,
                ),
                SizedBox(height: 12),
                
                ProgressMetricCard(
                  title: 'Water (Estimated)',
                  current: todayNutrition.entries.length * 0.5, // Mock water intake
                  target: 8.0,
                  unit: 'glasses',
                  icon: Icons.water_drop,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStreaksTab() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final streakData = userProvider.streakData;
        final activityDates = streakData?.activityDates ?? [];
        
        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Streak stats
                Row(
                  children: [
                    Expanded(
                      child: _StreakStatCard(
                        title: 'Current',
                        value: '${streakData?.currentStreak ?? 0}',
                        subtitle: 'days',
                        color: AppTheme.primaryAccent,
                        icon: Icons.local_fire_department,
                      ),
                    ),
                    SizedBox(width: 16),
                    
                    Expanded(
                      child: _StreakStatCard(
                        title: 'Best',
                        value: '${streakData?.longestStreak ?? 0}',
                        subtitle: 'days',
                        color: Colors.amber,
                        icon: Icons.emoji_events,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 32),
                
                // Weekly calendar view
                Text(
                  'This Week',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),
                
                _buildWeeklyCalendar(activityDates),
                
                SizedBox(height: 32),
                
                // Streak milestones
                Text(
                  'Streak Milestones',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),
                
                _MilestoneCard(
                  title: '7 Day Streak',
                  subtitle: 'Build the habit',
                  isCompleted: (streakData?.longestStreak ?? 0) >= 7,
                  icon: Icons.calendar_view_week,
                ),
                SizedBox(height: 12),
                
                _MilestoneCard(
                  title: '30 Day Streak',
                  subtitle: 'Consistency champion',
                  isCompleted: (streakData?.longestStreak ?? 0) >= 30,
                  icon: Icons.calendar_month,
                ),
                SizedBox(height: 12),
                
                _MilestoneCard(
                  title: '100 Day Streak',
                  subtitle: 'Fitness legend',
                  isCompleted: (streakData?.longestStreak ?? 0) >= 100,
                  icon: Icons.military_tech,
                ),
                
                SizedBox(height: 32),
                
                // Recent activity
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),
                
                if (activityDates.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.timeline_outlined,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No activity yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start logging meals to build your streak!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...activityDates.take(10).map((date) => _ActivityItem(date: date)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer2<UserProvider, NutritionProvider>(
      builder: (context, userProvider, nutritionProvider, child) {
        final weeklyNutrition = nutritionProvider.getWeeklyNutrition();
        
        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weekly nutrition chart
                Text(
                  'Weekly Nutrition',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Simple bar chart representation
                        ...weeklyNutrition.map((dailyNutrition) {
                          final dayName = _getDayName(dailyNutrition.date);
                          final calories = dailyNutrition.totalCalories;
                          final progress = nutritionProvider.calorieGoal > 0
                              ? (calories / nutritionProvider.calorieGoal).clamp(0.0, 1.0)
                              : 0.0;
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        dayName.substring(0, 3),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: AppTheme.borderColor,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: progress,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: _isToday(dailyNutrition.date) 
                                                  ? AppTheme.primaryAccent
                                                  : AppTheme.successGreen,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        '$calories',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Nutrition averages
                Text(
                  'Weekly Averages',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _AnalyticsCard(
                        title: 'Daily Calories',
                        value: '${_calculateWeeklyAverage(weeklyNutrition, 'calories')}',
                        unit: 'cal',
                        icon: Icons.local_fire_department,
                        color: AppTheme.primaryAccent,
                      ),
                    ),
                    SizedBox(width: 16),
                    
                    Expanded(
                      child: _AnalyticsCard(
                        title: 'Daily Protein',
                        value: '${_calculateWeeklyAverage(weeklyNutrition, 'protein')}',
                        unit: 'g',
                        icon: Icons.fitness_center,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _AnalyticsCard(
                        title: 'Daily Carbs',
                        value: '${_calculateWeeklyAverage(weeklyNutrition, 'carbs')}',
                        unit: 'g',
                        icon: Icons.grain,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(width: 16),
                    
                    Expanded(
                      child: _AnalyticsCard(
                        title: 'Daily Fat',
                        value: '${_calculateWeeklyAverage(weeklyNutrition, 'fat')}',
                        unit: 'g',
                        icon: Icons.opacity,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 24),
                
                // Insights
                Text(
                  'Insights',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),
                
                _buildInsights(userProvider, nutritionProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyCalendar(List<DateTime> activityDates) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: List.generate(7, (index) {
            final date = weekStart.add(Duration(days: index));
            final hasActivity = activityDates.any((activityDate) {
              return activityDate.year == date.year &&
                     activityDate.month == date.month &&
                     activityDate.day == date.day;
            });
            final isToday = _isToday(date);
            
            return Expanded(
              child: Column(
                children: [
                  Text(
                    ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: hasActivity 
                          ? AppTheme.primaryAccent
                          : isToday
                              ? AppTheme.primaryAccent.withOpacity(0.3)
                              : AppTheme.borderColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: hasActivity 
                              ? AppTheme.textPrimary
                              : isToday
                                  ? AppTheme.primaryAccent
                                  : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildInsights(UserProvider userProvider, NutritionProvider nutritionProvider) {
    final streakData = userProvider.streakData;
    final currentStreak = streakData?.currentStreak ?? 0;
    final todayNutrition = nutritionProvider.todayNutrition;
    
    final insights = <Widget>[];
    
    // Streak insights
    if (currentStreak >= 7) {
      insights.add(_InsightCard(
        title: 'Great consistency!',
        subtitle: 'You\'ve maintained a $currentStreak day streak. Keep it up!',
        icon: Icons.local_fire_department,
        color: AppTheme.successGreen,
      ));
    } else if (currentStreak >= 3) {
      insights.add(_InsightCard(
        title: 'Building momentum',
        subtitle: 'You\'re on a $currentStreak day streak. Aim for 7 days!',
        icon: Icons.trending_up,
        color: AppTheme.primaryAccent,
      ));
    }
    
    // Nutrition insights
    final calorieProgress = nutritionProvider.calorieGoal > 0
        ? todayNutrition.totalCalories / nutritionProvider.calorieGoal
        : 0.0;
    
    if (calorieProgress < 0.5) {
      insights.add(_InsightCard(
        title: 'Low calorie intake',
        subtitle: 'You\'ve only consumed ${(calorieProgress * 100).round()}% of your daily goal.',
        icon: Icons.warning,
        color: Colors.orange,
      ));
    } else if (calorieProgress > 1.2) {
      insights.add(_InsightCard(
        title: 'High calorie intake',
        subtitle: 'You\'ve exceeded your daily goal by ${((calorieProgress - 1) * 100).round()}%.',
        icon: Icons.info,
        color: Colors.blue,
      ));
    }
    
    if (insights.isEmpty) {
      insights.add(_InsightCard(
        title: 'Looking good!',
        subtitle: 'Keep tracking your nutrition and maintaining your fitness routine.',
        icon: Icons.thumb_up,
        color: AppTheme.successGreen,
      ));
    }
    
    return Column(
      children: insights.map((insight) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: insight,
      )).toList(),
    );
  }

  int _calculateWeeklyAverage(List<DailyNutrition> weeklyNutrition, String type) {
    if (weeklyNutrition.isEmpty) return 0;
    
    double total = 0;
    int daysWithData = 0;
    
    for (final day in weeklyNutrition) {
      if (day.entries.isNotEmpty) {
        daysWithData++;
        switch (type) {
          case 'calories':
            total += day.totalCalories;
            break;
          case 'protein':
            total += day.totalProtein;
            break;
          case 'carbs':
            total += day.totalCarbs;
            break;
          case 'fat':
            total += day.totalFat;
            break;
        }
      }
    }
    
    return daysWithData > 0 ? (total / daysWithData).round() : 0;
  }

  String _getDayName(DateTime date) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[date.weekday - 1];
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }
}

class _StreakStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _StreakStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 12),
          
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2),
          
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final IconData icon;

  const _MilestoneCard({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted 
            ? AppTheme.successGreen.withOpacity(0.1)
            : AppTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted 
              ? AppTheme.successGreen
              : AppTheme.borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted 
                  ? AppTheme.successGreen
                  : AppTheme.borderColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isCompleted 
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? AppTheme.successGreen : null,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final DateTime date;

  const _ActivityItem({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(date);
    String timeAgo;
    
    if (difference.inDays == 0) {
      timeAgo = 'Today';
    } else if (difference.inDays == 1) {
      timeAgo = 'Yesterday';
    } else {
      timeAgo = '${difference.inDays} days ago';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.successGreen,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          
          Expanded(
            child: Text(
              'Activity logged',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          
          Text(
            timeAgo,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 12),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _InsightCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}