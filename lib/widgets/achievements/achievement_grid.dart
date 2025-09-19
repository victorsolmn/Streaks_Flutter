import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/achievement_model.dart';
import '../../providers/achievement_provider.dart';
import 'achievement_badge.dart';
import 'achievement_popup.dart';

class AchievementGrid extends StatefulWidget {
  const AchievementGrid({Key? key}) : super(key: key);

  @override
  State<AchievementGrid> createState() => _AchievementGridState();
}

class _AchievementGridState extends State<AchievementGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Create staggered animations for each badge
    _fadeAnimations = List.generate(15, (index) {
      final start = index * 0.05;
      final end = start + 0.3;
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations = List.generate(15, (index) {
      final start = index * 0.05;
      final end = start + 0.3;
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut),
        ),
      );
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showAchievementDetails(BuildContext context, Achievement achievement) {
    AchievementPopup.show(context, achievement);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AchievementProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading achievements',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => provider.loadAchievements(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final achievements = provider.achievements;

        // Ensure we have 15 achievements (fill with placeholders if needed)
        while (achievements.length < 15) {
          achievements.add(
            Achievement(
              id: 'placeholder_${achievements.length}',
              title: 'Coming Soon',
              description: 'New achievement coming soon!',
              requirementType: AchievementType.special,
              requirementValue: 0,
              iconName: 'lock',
              colorPrimary: '#9E9E9E',
              colorSecondary: '#757575',
              sortOrder: achievements.length,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress summary
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
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
                  // Circular progress
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      children: [
                        CircularProgressIndicator(
                          value: provider.overallProgress,
                          strokeWidth: 6,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            provider.overallProgress >= 0.5
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        Center(
                          child: Text(
                            '${(provider.overallProgress * 100).toInt()}%',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Achievement Badges',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.totalUnlocked} of ${achievements.length} badges earned',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Achievement grid - 3x5 categorized layout
            _buildCategorizedGrid(context, achievements),

            // Recent unlocks section
            if (provider.recentUnlocks.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                'Recent Unlocks',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.recentUnlocks.length,
                  itemBuilder: (context, index) {
                    final achievement = provider.recentUnlocks[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => _showAchievementDetails(context, achievement),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                achievement.primaryColor.withOpacity(0.1),
                                achievement.secondaryColor.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: achievement.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                achievement.icon,
                                color: achievement.primaryColor,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    achievement.title,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (achievement.unlockedAt != null)
                                    Text(
                                      _formatDate(achievement.unlockedAt!),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCategorizedGrid(BuildContext context, List<Achievement> achievements) {
    // Organize achievements into categories
    final categories = _organizeAchievements(achievements);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category 1: Streak Milestones
        Expanded(
          child: _buildCategoryColumn(
            context,
            'Streak\nMilestones',
            categories['milestones'] ?? [],
            Colors.orange.shade600,
          ),
        ),
        const SizedBox(width: 12),

        // Category 2: Elite Streaks
        Expanded(
          child: _buildCategoryColumn(
            context,
            'Elite\nStreaks',
            categories['elite'] ?? [],
            Colors.purple.shade600,
          ),
        ),
        const SizedBox(width: 12),

        // Category 3: Legends & Special
        Expanded(
          child: _buildCategoryColumn(
            context,
            'Legends &\nSpecial',
            categories['legends'] ?? [],
            Colors.teal.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryColumn(
    BuildContext context,
    String title,
    List<Achievement> achievements,
    Color accentColor,
  ) {
    return Column(
      children: [
        // Category header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: accentColor,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),

        // Achievements in this category
        ...achievements.asMap().entries.map((entry) {
          final index = entry.key;
          final achievement = entry.value;
          final globalIndex = _getGlobalIndex(achievement);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimations[globalIndex],
                  child: SlideTransition(
                    position: _slideAnimations[globalIndex],
                    child: Column(
                      children: [
                        AchievementBadge(
                          achievement: achievement,
                          onTap: () => _showAchievementDetails(context, achievement),
                          size: 65,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          achievement.title,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: achievement.isUnlocked
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: achievement.isUnlocked
                                ? Theme.of(context).textTheme.bodySmall?.color
                                : Colors.grey,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ],
    );
  }

  Map<String, List<Achievement>> _organizeAchievements(List<Achievement> achievements) {
    // Define achievement IDs for each category
    final milestoneIds = ['warm_up', 'no_excuses', 'sweat_starter', 'grind_machine', 'beast_mode'];
    final eliteIds = ['iron_month', 'quarter_crusher', 'half_year', 'year_one', 'streak_titan'];
    final legendsIds = ['immortal', 'comeback_kid', 'sweatflix', 'gym_goblin', 'no_days_off'];

    final categories = <String, List<Achievement>>{
      'milestones': [],
      'elite': [],
      'legends': [],
    };

    // Organize achievements by category, maintaining order
    for (final id in milestoneIds) {
      final achievement = achievements.firstWhere(
        (a) => a.id == id,
        orElse: () => _createPlaceholder(id, categories['milestones']!.length),
      );
      categories['milestones']!.add(achievement);
    }

    for (final id in eliteIds) {
      final achievement = achievements.firstWhere(
        (a) => a.id == id,
        orElse: () => _createPlaceholder(id, categories['elite']!.length + 5),
      );
      categories['elite']!.add(achievement);
    }

    for (final id in legendsIds) {
      final achievement = achievements.firstWhere(
        (a) => a.id == id,
        orElse: () => _createPlaceholder(id, categories['legends']!.length + 10),
      );
      categories['legends']!.add(achievement);
    }

    return categories;
  }

  Achievement _createPlaceholder(String id, int sortOrder) {
    return Achievement(
      id: 'placeholder_$id',
      title: 'Coming Soon',
      description: 'New achievement coming soon!',
      requirementType: AchievementType.special,
      requirementValue: 0,
      iconName: 'lock',
      colorPrimary: '#9E9E9E',
      colorSecondary: '#757575',
      sortOrder: sortOrder,
    );
  }

  int _getGlobalIndex(Achievement achievement) {
    // Map achievement ID to global index for animations
    final indexMap = {
      'warm_up': 0, 'no_excuses': 1, 'sweat_starter': 2, 'grind_machine': 3, 'beast_mode': 4,
      'iron_month': 5, 'quarter_crusher': 6, 'half_year': 7, 'year_one': 8, 'streak_titan': 9,
      'immortal': 10, 'comeback_kid': 11, 'sweatflix': 12, 'gym_goblin': 13, 'no_days_off': 14,
    };
    return indexMap[achievement.id] ?? 0;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}