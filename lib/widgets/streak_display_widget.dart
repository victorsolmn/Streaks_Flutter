import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/streak_provider.dart';
import '../utils/app_theme.dart';

class StreakDisplayWidget extends StatelessWidget {
  final bool isCompact;
  
  const StreakDisplayWidget({
    Key? key,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<StreakProvider>(
      builder: (context, streakProvider, child) {
        final stats = streakProvider.getStreakStats();
        final currentStreak = stats['current'] as int;
        final isActive = stats['isActive'] as bool;
        final todayProgress = stats['todayProgress'] as double;
        final goalsCompleted = stats['goalsCompleted'] as int;
        
        if (isCompact) {
          return _buildCompactView(context, currentStreak, isActive);
        }
        
        return _buildFullView(
          context,
          stats,
          currentStreak,
          isActive,
          todayProgress,
          goalsCompleted,
        );
      },
    );
  }
  
  Widget _buildCompactView(BuildContext context, int currentStreak, bool isActive) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: isActive ? AppTheme.primaryGradient : null,
        color: !isActive 
            ? (isDarkMode ? Colors.grey[800] : Colors.grey[200])
            : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            color: isActive ? Colors.white : Colors.grey,
            size: 20,
          ),
          SizedBox(width: 6),
          Text(
            '$currentStreak',
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFullView(
    BuildContext context,
    Map<String, dynamic> stats,
    int currentStreak,
    bool isActive,
    double todayProgress,
    int goalsCompleted,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final message = stats['message'] as String;
    final longestStreak = stats['longest'] as int;
    final totalDays = stats['total'] as int;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isActive ? AppTheme.primaryGradient : null,
        color: !isActive 
            ? (isDarkMode ? AppTheme.darkCardBackground : Colors.white)
            : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isActive 
                ? AppTheme.primaryAccent.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: isActive ? Colors.white : AppTheme.primaryAccent,
                    size: 32,
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Streak',
                        style: TextStyle(
                          color: isActive 
                              ? Colors.white70
                              : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$currentStreak days',
                        style: TextStyle(
                          color: isActive 
                              ? Colors.white
                              : (isDarkMode ? Colors.white : Colors.black),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _buildStreakBadge(currentStreak),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Today's Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Goals',
                    style: TextStyle(
                      color: isActive 
                          ? Colors.white70
                          : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$goalsCompleted/5 completed',
                    style: TextStyle(
                      color: isActive 
                          ? Colors.white
                          : AppTheme.primaryAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: todayProgress / 100,
                  minHeight: 8,
                  backgroundColor: isActive 
                      ? Colors.white24
                      : (isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    goalsCompleted == 5 
                        ? AppTheme.successGreen
                        : (isActive ? Colors.white : AppTheme.primaryAccent),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Motivational Message
          Text(
            message,
            style: TextStyle(
              color: isActive 
                  ? Colors.white
                  : (isDarkMode ? Colors.white : Colors.black87),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          SizedBox(height: 16),
          
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Longest',
                '$longestStreak days',
                Icons.emoji_events,
                isActive,
                isDarkMode,
              ),
              _buildStatItem(
                'Total Days',
                '$totalDays',
                Icons.calendar_today,
                isActive,
                isDarkMode,
              ),
              _buildStatItem(
                'This Month',
                '${_getMonthlyCount(totalDays)}',
                Icons.date_range,
                isActive,
                isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStreakBadge(int streak) {
    IconData icon;
    Color color;
    
    if (streak >= 100) {
      icon = Icons.local_fire_department;
      color = Colors.purple;
    } else if (streak >= 30) {
      icon = Icons.whatshot;
      color = Colors.orange;
    } else if (streak >= 7) {
      icon = Icons.star;
      color = Colors.amber;
    } else if (streak >= 3) {
      icon = Icons.trending_up;
      color = AppTheme.successGreen;
    } else {
      icon = Icons.schedule;
      color = Colors.grey;
    }
    
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }
  
  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    bool isActive,
    bool isDarkMode,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: isActive 
              ? Colors.white70
              : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          size: 20,
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isActive 
                ? Colors.white
                : (isDarkMode ? Colors.white : Colors.black),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isActive 
                ? Colors.white70
                : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  int _getMonthlyCount(int totalDays) {
    // This is a simplified calculation
    // In production, you'd query actual monthly data
    return totalDays > 30 ? 30 : totalDays;
  }
}