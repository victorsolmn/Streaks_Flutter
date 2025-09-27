import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/streak_provider.dart';
import '../utils/app_theme.dart';
import 'dart:math' as math;

class MilestoneProgressRing extends StatefulWidget {
  final double size;
  final double strokeWidth;

  const MilestoneProgressRing({
    Key? key,
    this.size = 120,
    this.strokeWidth = 12,
  }) : super(key: key);

  @override
  State<MilestoneProgressRing> createState() => _MilestoneProgressRingState();
}

class _MilestoneProgressRingState extends State<MilestoneProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StreakProvider>(
      builder: (context, streakProvider, child) {
        final currentStreak = streakProvider.currentStreak;
        final milestoneInfo = _getMilestoneInfo(currentStreak);

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
                'Next Milestone',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: MilestoneRingPainter(
                      progress: milestoneInfo.progress * _progressAnimation.value,
                      strokeWidth: widget.strokeWidth,
                      backgroundColor: AppTheme.borderColor,
                      progressColor: milestoneInfo.color,
                    ),
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            milestoneInfo.icon,
                            color: milestoneInfo.color,
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${milestoneInfo.remaining}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: milestoneInfo.color,
                            ),
                          ),
                          Text(
                            'days left',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                milestoneInfo.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: milestoneInfo.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                milestoneInfo.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  MilestoneInfo _getMilestoneInfo(int currentStreak) {
    if (currentStreak < 7) {
      return MilestoneInfo(
        title: 'First Week',
        description: 'Build your habit foundation',
        icon: Icons.star,
        color: AppTheme.primaryAccent,
        target: 7,
        current: currentStreak,
      );
    } else if (currentStreak < 30) {
      return MilestoneInfo(
        title: 'Monthly Master',
        description: 'Achieve consistency',
        icon: Icons.calendar_month,
        color: Colors.orange,
        target: 30,
        current: currentStreak,
      );
    } else if (currentStreak < 100) {
      return MilestoneInfo(
        title: 'Century Club',
        description: 'Join the elite',
        icon: Icons.emoji_events,
        color: Colors.purple,
        target: 100,
        current: currentStreak,
      );
    } else {
      final nextHundred = ((currentStreak ~/ 100) + 1) * 100;
      return MilestoneInfo(
        title: '${nextHundred}-Day Legend',
        description: 'Legendary consistency',
        icon: Icons.diamond,
        color: Colors.deepPurple,
        target: nextHundred,
        current: currentStreak,
      );
    }
  }
}

class MilestoneInfo {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int target;
  final int current;

  MilestoneInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.target,
    required this.current,
  });

  double get progress => current / target;
  int get remaining => math.max(0, target - current);
}

class MilestoneRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  MilestoneRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );

    // Add subtle glow effect
    if (progress > 0) {
      final glowPaint = Paint()
        ..color = progressColor.withOpacity(0.3)
        ..strokeWidth = strokeWidth + 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is MilestoneRingPainter &&
        (oldDelegate.progress != progress ||
            oldDelegate.progressColor != progressColor);
  }
}