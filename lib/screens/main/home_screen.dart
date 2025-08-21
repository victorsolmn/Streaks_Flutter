import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/nutrition_card.dart';
import '../../widgets/circular_progress_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Log activity when home screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).logActivity();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Refresh data
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 24),
                
                // Streak section
                _buildStreakSection(),
                const SizedBox(height: 24),
                
                // Quick stats
                _buildQuickStats(),
                const SizedBox(height: 24),
                
                // Nutrition overview
                _buildNutritionOverview(),
                const SizedBox(height: 24),
                
                // Quick actions
                _buildQuickActions(),
                const SizedBox(height: 24),
                
                // Recent activity or tips
                _buildRecentActivity(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final profile = userProvider.profile;
        final hour = DateTime.now().hour;
        String greeting;
        
        if (hour < 12) {
          greeting = 'Good Morning';
        } else if (hour < 17) {
          greeting = 'Good Afternoon';
        } else {
          greeting = 'Good Evening';
        }

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile?.name ?? 'Welcome back!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentOrange.withOpacity(0.3),
                ),
              ),
              child: Icon(
                Icons.person,
                color: AppTheme.accentOrange,
                size: 24,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStreakSection() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final streakData = userProvider.streakData;
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.accentOrange,
                Color(0xFFFF8F00),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(
                Icons.local_fire_department,
                color: AppTheme.textPrimary,
                size: 48,
              ),
              const SizedBox(height: 16),
              
              Text(
                '${streakData?.currentStreak ?? 0}',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                'Day Streak',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              
              Text(
                'Keep it going! You\'re doing great.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStats() {
    return Consumer2<UserProvider, NutritionProvider>(
      builder: (context, userProvider, nutritionProvider, child) {
        final streakData = userProvider.streakData;
        final todayNutrition = nutritionProvider.todayNutrition;
        final calorieProgress = nutritionProvider.calorieGoal > 0 
            ? (todayNutrition.totalCalories / nutritionProvider.calorieGoal).clamp(0.0, 1.0)
            : 0.0;
        
        return Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Weekly Active',
                value: '${userProvider.getWeeklyActivityCount()}',
                subtitle: '7 days',
                icon: Icons.calendar_today,
                color: AppTheme.successGreen,
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: StatCard(
                label: 'Calories',
                value: '${todayNutrition.totalCalories}',
                subtitle: '${nutritionProvider.calorieGoal} goal',
                icon: Icons.local_fire_department,
                color: AppTheme.accentOrange,
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: StatCard(
                label: 'Best Streak',
                value: '${streakData?.longestStreak ?? 0}',
                subtitle: 'days',
                icon: Icons.emoji_events,
                color: Colors.amber,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNutritionOverview() {
    return Consumer<NutritionProvider>(
      builder: (context, nutritionProvider, child) {
        final todayNutrition = nutritionProvider.todayNutrition;
        
        return NutritionOverviewCard(
          dailyNutrition: todayNutrition,
          calorieGoal: nutritionProvider.calorieGoal,
          proteinGoal: nutritionProvider.proteinGoal,
          carbGoal: nutritionProvider.carbGoal,
          fatGoal: nutritionProvider.fatGoal,
          onTap: () {
            // Navigate to nutrition tab
            DefaultTabController.of(context)?.animateTo(2);
          },
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        QuickActionCard(
          title: 'Log Food',
          subtitle: 'Scan or add meals to track nutrition',
          icon: Icons.camera_alt,
          color: AppTheme.accentOrange,
          onTap: () {
            // Navigate to nutrition screen
            DefaultTabController.of(context)?.animateTo(2);
          },
        ),
        const SizedBox(height: 12),
        
        QuickActionCard(
          title: 'Chat with Coach',
          subtitle: 'Get personalized fitness advice',
          icon: Icons.chat,
          color: AppTheme.successGreen,
          onTap: () {
            // Navigate to chat screen
            DefaultTabController.of(context)?.animateTo(3);
          },
        ),
        const SizedBox(height: 12),
        
        QuickActionCard(
          title: 'View Progress',
          subtitle: 'Check your fitness analytics',
          icon: Icons.analytics,
          color: Colors.blue,
          onTap: () {
            // Navigate to progress screen
            DefaultTabController.of(context)?.animateTo(1);
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Consumer<NutritionProvider>(
      builder: (context, nutritionProvider, child) {
        final recentEntries = nutritionProvider.entries
            .where((entry) {
              final today = DateTime.now();
              return entry.timestamp.year == today.year &&
                     entry.timestamp.month == today.month &&
                     entry.timestamp.day == today.day;
            })
            .take(3)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Meals',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (recentEntries.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      // Navigate to nutrition screen
                      DefaultTabController.of(context)?.animateTo(2);
                    },
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: AppTheme.accentOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (recentEntries.isEmpty)
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
                      Icons.restaurant_outlined,
                      color: AppTheme.textSecondary,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No meals logged today',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start tracking your nutrition to see your progress',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...recentEntries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: NutritionEntryCard(entry: entry),
              )),
          ],
        );
      },
    );
  }
}