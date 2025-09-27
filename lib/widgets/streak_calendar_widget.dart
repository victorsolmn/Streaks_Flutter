import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/streak_provider.dart';
import '../utils/app_theme.dart';

class StreakCalendarWidget extends StatelessWidget {
  const StreakCalendarWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<StreakProvider>(
      builder: (context, streakProvider, child) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Streak Calendar',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildCalendarGrid(context, streakProvider),
              const SizedBox(height: 16),
              _buildLegend(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarGrid(BuildContext context, StreakProvider streakProvider) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    return Column(
      children: [
        // Days of week header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((day) => Text(
                    day,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),

        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: 42, // 6 weeks * 7 days
          itemBuilder: (context, index) {
            final dayIndex = index - startingWeekday + 1;

            if (dayIndex < 1 || dayIndex > daysInMonth) {
              return const SizedBox(); // Empty cell for days outside current month
            }

            final date = DateTime(now.year, now.month, dayIndex);
            final dayStatus = _getDayStatus(date, streakProvider);

            return _buildCalendarDay(
              context,
              dayIndex,
              dayStatus,
              date.isAtSameMomentAs(DateTime(now.year, now.month, now.day)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCalendarDay(
    BuildContext context,
    int day,
    DayStatus status,
    bool isToday,
  ) {
    Color backgroundColor;
    Color textColor;
    IconData? icon;

    switch (status) {
      case DayStatus.completed:
        backgroundColor = AppTheme.successGreen;
        textColor = Colors.white;
        icon = Icons.check;
        break;
      case DayStatus.graceUsed:
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        icon = Icons.schedule;
        break;
      case DayStatus.missed:
        backgroundColor = AppTheme.errorRed.withOpacity(0.3);
        textColor = AppTheme.errorRed;
        break;
      case DayStatus.future:
        backgroundColor = Colors.transparent;
        textColor = AppTheme.textSecondary;
        break;
      case DayStatus.today:
        backgroundColor = AppTheme.primaryAccent.withOpacity(0.2);
        textColor = AppTheme.primaryAccent;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: isToday ? Border.all(color: AppTheme.primaryAccent, width: 2) : null,
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, color: textColor, size: 16)
            : Text(
                '$day',
                style: TextStyle(
                  color: textColor,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem(
          context,
          Icons.check,
          'Completed',
          AppTheme.successGreen,
        ),
        _buildLegendItem(
          context,
          Icons.schedule,
          'Grace Day',
          Colors.orange,
        ),
        _buildLegendItem(
          context,
          Icons.close,
          'Missed',
          AppTheme.errorRed,
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  DayStatus _getDayStatus(DateTime date, StreakProvider streakProvider) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    // Future dates
    if (targetDate.isAfter(today)) {
      return DayStatus.future;
    }

    // Today
    if (targetDate.isAtSameMomentAs(today)) {
      return streakProvider.allGoalsAchievedToday
          ? DayStatus.completed
          : DayStatus.today;
    }

    // Past dates - check recent metrics
    final metricsForDate = streakProvider.recentMetrics.where((m) =>
      m.date.year == date.year &&
      m.date.month == date.month &&
      m.date.day == date.day
    ).toList();

    if (metricsForDate.isNotEmpty) {
      final metric = metricsForDate.first;
      return metric.allGoalsAchieved ? DayStatus.completed : DayStatus.missed;
    }

    // Check if it's within grace period based on streak history
    final userStreak = streakProvider.userStreak;
    if (userStreak != null && userStreak.isInGracePeriod) {
      // This is a simplified check - in a real app you'd want more detailed grace period tracking
      return DayStatus.graceUsed;
    }

    return DayStatus.missed;
  }
}

enum DayStatus {
  completed,
  graceUsed,
  missed,
  future,
  today,
}