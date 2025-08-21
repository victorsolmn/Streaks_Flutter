import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/app_theme.dart';

class CircularProgressWidget extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;
  final Widget? child;
  final bool animate;
  final Duration animationDuration;

  const CircularProgressWidget({
    Key? key,
    required this.progress,
    this.size = 120.0,
    this.strokeWidth = 8.0,
    this.progressColor = AppTheme.accentOrange,
    this.backgroundColor = AppTheme.borderColor,
    this.child,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 1000),
  }) : super(key: key);

  @override
  State<CircularProgressWidget> createState() => _CircularProgressWidgetState();
}

class _CircularProgressWidgetState extends State<CircularProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.animate) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(CircularProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));

      if (widget.animate) {
        _animationController.reset();
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: widget.animate
          ? AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: CircularProgressPainter(
                    progress: _animation.value,
                    progressColor: widget.progressColor,
                    backgroundColor: widget.backgroundColor,
                    strokeWidth: widget.strokeWidth,
                  ),
                  child: widget.child != null
                      ? Center(child: widget.child)
                      : null,
                );
              },
            )
          : CustomPaint(
              painter: CircularProgressPainter(
                progress: widget.progress,
                progressColor: widget.progressColor,
                backgroundColor: widget.backgroundColor,
                strokeWidth: widget.strokeWidth,
              ),
              child: widget.child != null
                  ? Center(child: widget.child)
                  : null,
            ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Add gradient effect
      final gradient = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + (2 * math.pi * progress),
        colors: [
          progressColor,
          progressColor.withOpacity(0.7),
          progressColor,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      progressPaint.shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

      final rect = Rect.fromCircle(center: center, radius: radius);
      final startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate is CircularProgressPainter &&
        (oldDelegate.progress != progress ||
            oldDelegate.progressColor != progressColor ||
            oldDelegate.backgroundColor != backgroundColor ||
            oldDelegate.strokeWidth != strokeWidth);
  }
}

class CircularProgressIndicatorWithLabel extends StatelessWidget {
  final double progress;
  final String label;
  final String value;
  final String? unit;
  final double size;
  final Color progressColor;

  const CircularProgressIndicatorWithLabel({
    Key? key,
    required this.progress,
    required this.label,
    required this.value,
    this.unit,
    this.size = 120.0,
    this.progressColor = AppTheme.accentOrange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressWidget(
          progress: progress,
          size: size,
          progressColor: progressColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (unit != null)
                Text(
                  unit!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class MiniCircularProgress extends StatelessWidget {
  final double progress;
  final Color color;
  final double size;

  const MiniCircularProgress({
    Key? key,
    required this.progress,
    this.color = AppTheme.accentOrange,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircularProgressWidget(
      progress: progress,
      size: size,
      strokeWidth: 3.0,
      progressColor: color,
      animate: false,
    );
  }
}