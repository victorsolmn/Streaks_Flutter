import 'package:flutter/material.dart';
import 'dart:io';
import '../utils/app_theme.dart';

class HealthPermissionDialog extends StatelessWidget {
  final VoidCallback onConnect;
  final VoidCallback onDismiss;
  final bool isReengagement;

  const HealthPermissionDialog({
    Key? key,
    required this.onConnect,
    required this.onDismiss,
    this.isReengagement = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 40,
                  color: AppTheme.primaryAccent,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                isReengagement
                  ? 'Your Health Data is Ready!'
                  : 'Connect Your Health Data',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                isReengagement
                  ? 'Unlock real insights from your fitness tracker'
                  : 'Sync your ${Platform.isIOS ? 'Apple Watch' : 'smartwatch'} data for accurate tracking',
                style: TextStyle(
                  fontSize: 15,
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Benefits list
              _buildBenefitItem(
                icon: Icons.watch,
                text: 'Real-time smartwatch data',
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),
              _buildBenefitItem(
                icon: Icons.insights,
                text: 'Accurate progress tracking',
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),
              _buildBenefitItem(
                icon: Icons.auto_graph,
                text: 'Personalized insights',
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 28),

              // Connect button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onConnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Platform.isIOS ? Icons.health_and_safety : Icons.favorite,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Platform.isIOS
                          ? 'Connect Apple Health'
                          : 'Connect Health Connect',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Maybe later button
              TextButton(
                onPressed: onDismiss,
                child: Text(
                  isReengagement ? 'Not Now' : 'Maybe Later',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white60 : Colors.grey[600],
                    fontSize: 15,
                  ),
                ),
              ),

              // Privacy note
              if (!isReengagement) ...[
                const SizedBox(height: 8),
                Text(
                  '🔒 Your health data is private and secure',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white38 : Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String text,
    required bool isDarkMode,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.successGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppTheme.successGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}