import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/achievement_model.dart';

class AchievementBadge extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onTap;
  final double size;

  const AchievementBadge({
    Key? key,
    required this.achievement,
    this.onTap,
    this.size = 65,
  }) : super(key: key);

  @override
  State<AchievementBadge> createState() => _AchievementBadgeState();
}

class _AchievementBadgeState extends State<AchievementBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size * 0.85,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Badge shape with gradient
                  CustomPaint(
                    size: Size(widget.size, widget.size * 0.85),
                    painter: FlameBadgePainter(
                      primaryColor: widget.achievement.isUnlocked
                          ? widget.achievement.primaryColor
                          : Colors.grey.shade400,
                      secondaryColor: widget.achievement.isUnlocked
                          ? widget.achievement.secondaryColor
                          : Colors.grey.shade600,
                      isUnlocked: widget.achievement.isUnlocked,
                    ),
                  ),

                  // Icon in center
                  Positioned(
                    top: widget.size * 0.15,
                    left: 0,
                    right: 0,
                    child: Icon(
                      widget.achievement.icon,
                      size: widget.size * 0.35,
                      color: widget.achievement.isUnlocked
                          ? Colors.white
                          : Colors.grey.shade300,
                    ),
                  ),

                  // Checkmark for unlocked achievements
                  if (widget.achievement.isUnlocked)
                    Positioned(
                      bottom: widget.size * 0.05,
                      right: widget.size * 0.12,
                      child: Container(
                        width: widget.size * 0.2,
                        height: widget.size * 0.2,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check,
                          size: widget.size * 0.12,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // Progress bar for locked achievements
                  if (!widget.achievement.isUnlocked &&
                      widget.achievement.progressPercentage > 0)
                    Positioned(
                      bottom: widget.size * 0.02,
                      left: widget.size * 0.15,
                      right: widget.size * 0.15,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Colors.grey.shade300,
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: widget.achievement.progressPercentage,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: widget.achievement.isCloseToUnlock
                                  ? Colors.orange
                                  : Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // "Close to unlock" indicator
                  if (widget.achievement.isCloseToUnlock)
                    Positioned(
                      top: widget.size * 0.05,
                      right: widget.size * 0.1,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.star,
                          size: widget.size * 0.15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class FlameBadgePainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final bool isUnlocked;

  FlameBadgePainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.isUnlocked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final width = size.width;
    final height = size.height;
    final centerX = width / 2;
    final centerY = height / 2;
    final radius = math.min(width, height) * 0.4;

    // Create hexagonal path
    final hexPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi) / 3;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);

      if (i == 0) {
        hexPath.moveTo(x, y);
      } else {
        hexPath.lineTo(x, y);
      }
    }
    hexPath.close();

    // Draw multiple shadow layers for 3D depth
    if (isUnlocked) {
      // Deep shadow
      canvas.save();
      canvas.translate(3, 6);
      canvas.drawPath(
        hexPath,
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.restore();

      // Mid shadow
      canvas.save();
      canvas.translate(2, 4);
      canvas.drawPath(
        hexPath,
        Paint()
          ..color = Colors.black.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.restore();

      // Close shadow
      canvas.save();
      canvas.translate(1, 2);
      canvas.drawPath(
        hexPath,
        Paint()
          ..color = Colors.black.withOpacity(0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.restore();
    }

    // Main hexagon with 3D gradient
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isUnlocked ? [
        primaryColor.withOpacity(0.9),
        primaryColor,
        secondaryColor,
        primaryColor.withOpacity(0.7),
      ] : [
        Colors.grey.shade300,
        Colors.grey.shade400,
        Colors.grey.shade500,
        Colors.grey.shade600,
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    paint.shader = gradient.createShader(
      Rect.fromLTWH(0, 0, width, height),
    );

    canvas.drawPath(hexPath, paint);

    // Add 3D highlights and depth
    if (isUnlocked) {
      // Top highlight for 3D effect
      final topHighlight = Path();
      for (int i = 0; i < 3; i++) {
        final angle = (i * math.pi) / 3;
        final x = centerX + (radius * 0.8) * math.cos(angle);
        final y = centerY + (radius * 0.8) * math.sin(angle);

        if (i == 0) {
          topHighlight.moveTo(x, y);
        } else {
          topHighlight.lineTo(x, y);
        }
      }
      topHighlight.close();

      canvas.drawPath(
        topHighlight,
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.fill,
      );

      // Inner glow
      final innerHex = Path();
      for (int i = 0; i < 6; i++) {
        final angle = (i * math.pi) / 3;
        final x = centerX + (radius * 0.7) * math.cos(angle);
        final y = centerY + (radius * 0.7) * math.sin(angle);

        if (i == 0) {
          innerHex.moveTo(x, y);
        } else {
          innerHex.lineTo(x, y);
        }
      }
      innerHex.close();

      canvas.drawPath(
        innerHex,
        Paint()
          ..color = Colors.white.withOpacity(0.15)
          ..style = PaintingStyle.fill,
      );
    }

    // Outer border for definition
    canvas.drawPath(
      hexPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = isUnlocked
            ? Colors.white.withOpacity(0.4)
            : Colors.grey.shade300.withOpacity(0.6),
    );

    // Add subtle sparkle effects for unlocked badges
    if (isUnlocked) {
      final sparklePoints = [
        Offset(centerX - radius * 0.3, centerY - radius * 0.4),
        Offset(centerX + radius * 0.4, centerY - radius * 0.2),
        Offset(centerX - radius * 0.2, centerY + radius * 0.3),
        Offset(centerX + radius * 0.2, centerY + radius * 0.4),
      ];

      final sparklePaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      for (final point in sparklePoints) {
        canvas.drawCircle(point, 1.5, sparklePaint);
      }
    }
  }

  @override
  bool shouldRepaint(FlameBadgePainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.isUnlocked != isUnlocked;
  }
}