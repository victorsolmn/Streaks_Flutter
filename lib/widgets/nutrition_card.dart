import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../providers/nutrition_provider.dart';
import 'circular_progress_widget.dart';

class NutritionOverviewCard extends StatelessWidget {
  final DailyNutrition dailyNutrition;
  final int calorieGoal;
  final double proteinGoal;
  final double carbGoal;
  final double fatGoal;
  final VoidCallback? onTap;

  const NutritionOverviewCard({
    Key? key,
    required this.dailyNutrition,
    required this.calorieGoal,
    required this.proteinGoal,
    required this.carbGoal,
    required this.fatGoal,
    this.onTap,
  }) : super(key: key);

  double get calorieProgress => calorieGoal > 0 ? (dailyNutrition.totalCalories / calorieGoal).clamp(0.0, 1.0) : 0.0;
  double get proteinProgress => proteinGoal > 0 ? (dailyNutrition.totalProtein / proteinGoal).clamp(0.0, 1.0) : 0.0;
  double get carbProgress => carbGoal > 0 ? (dailyNutrition.totalCarbs / carbGoal).clamp(0.0, 1.0) : 0.0;
  double get fatProgress => fatGoal > 0 ? (dailyNutrition.totalFat / fatGoal).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.restaurant,
                    color: AppTheme.accentOrange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Text(
                      'Today\'s Nutrition',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppTheme.textSecondary,
                      size: 16,
                    ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Main calories progress
              Row(
                children: [
                  CircularProgressWidget(
                    progress: calorieProgress,
                    size: 80,
                    strokeWidth: 6,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${dailyNutrition.totalCalories}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'cal',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 24),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MacroProgressBar(
                          label: 'Protein',
                          current: dailyNutrition.totalProtein,
                          goal: proteinGoal,
                          unit: 'g',
                          progress: proteinProgress,
                          color: AppTheme.successGreen,
                        ),
                        const SizedBox(height: 12),
                        
                        _MacroProgressBar(
                          label: 'Carbs',
                          current: dailyNutrition.totalCarbs,
                          goal: carbGoal,
                          unit: 'g',
                          progress: carbProgress,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        
                        _MacroProgressBar(
                          label: 'Fat',
                          current: dailyNutrition.totalFat,
                          goal: fatGoal,
                          unit: 'g',
                          progress: fatProgress,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Remaining calories
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remaining',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '${(calorieGoal - dailyNutrition.totalCalories).round()} cal',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: calorieProgress >= 1.0 
                            ? AppTheme.errorRed 
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroProgressBar extends StatelessWidget {
  final String label;
  final double current;
  final double goal;
  final String unit;
  final double progress;
  final Color color;

  const _MacroProgressBar({
    required this.label,
    required this.current,
    required this.goal,
    required this.unit,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${current.round()}/${goal.round()}$unit',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.borderColor,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class NutritionEntryCard extends StatelessWidget {
  final NutritionEntry entry;
  final VoidCallback? onDelete;

  const NutritionEntryCard({
    Key? key,
    required this.entry,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.restaurant,
                color: AppTheme.accentOrange,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.foodName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  Row(
                    children: [
                      Text(
                        '${entry.calories} cal',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'P: ${entry.protein.round()}g',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'C: ${entry.carbs.round()}g',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'F: ${entry.fat.round()}g',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  color: AppTheme.errorRed,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MacroBreakdownCard extends StatelessWidget {
  final DailyNutrition dailyNutrition;

  const MacroBreakdownCard({
    Key? key,
    required this.dailyNutrition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalMacros = dailyNutrition.totalProtein + dailyNutrition.totalCarbs + dailyNutrition.totalFat;
    
    final proteinPercent = totalMacros > 0 ? (dailyNutrition.totalProtein / totalMacros) : 0.0;
    final carbPercent = totalMacros > 0 ? (dailyNutrition.totalCarbs / totalMacros) : 0.0;
    final fatPercent = totalMacros > 0 ? (dailyNutrition.totalFat / totalMacros) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Macro Breakdown',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: _MacroBreakdownItem(
                    label: 'Protein',
                    value: '${dailyNutrition.totalProtein.round()}g',
                    percentage: '${(proteinPercent * 100).round()}%',
                    color: AppTheme.successGreen,
                  ),
                ),
                Expanded(
                  child: _MacroBreakdownItem(
                    label: 'Carbs',
                    value: '${dailyNutrition.totalCarbs.round()}g',
                    percentage: '${(carbPercent * 100).round()}%',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _MacroBreakdownItem(
                    label: 'Fat',
                    value: '${dailyNutrition.totalFat.round()}g',
                    percentage: '${(fatPercent * 100).round()}%',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Visual breakdown bar
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: AppTheme.borderColor,
              ),
              child: Row(
                children: [
                  if (proteinPercent > 0)
                    Expanded(
                      flex: (proteinPercent * 100).round(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            bottomLeft: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  if (carbPercent > 0)
                    Expanded(
                      flex: (carbPercent * 100).round(),
                      child: Container(
                        color: Colors.blue,
                      ),
                    ),
                  if (fatPercent > 0)
                    Expanded(
                      flex: (fatPercent * 100).round(),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
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
}

class _MacroBreakdownItem extends StatelessWidget {
  final String label;
  final String value;
  final String percentage;
  final Color color;

  const _MacroBreakdownItem({
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        
        Text(
          percentage,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}