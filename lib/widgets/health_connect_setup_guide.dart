import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';

class HealthConnectSetupGuide extends StatelessWidget {
  const HealthConnectSetupGuide({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.primaryAccent,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Setup Guide',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Text(
            'To sync your Samsung Watch data:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildStep(
            context,
            number: '1',
            title: 'Keep Watch Connected',
            subtitle: 'Your Samsung Watch should stay connected to Samsung Health',
            icon: Icons.watch,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          
          _buildStep(
            context,
            number: '2',
            title: 'Install Health Connect',
            subtitle: 'Download from Google Play Store if not installed',
            icon: Icons.download,
            isDarkMode: isDarkMode,
            action: TextButton(
              onPressed: () async {
                const url = 'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              },
              child: Text('Open Store', style: TextStyle(color: AppTheme.primaryAccent)),
            ),
          ),
          const SizedBox(height: 12),
          
          _buildStep(
            context,
            number: '3',
            title: 'Enable Samsung Health Sync',
            subtitle: 'Samsung Health → Settings → Connected Services → Health Connect',
            icon: Icons.sync,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          
          _buildStep(
            context,
            number: '4',
            title: 'Grant Permissions',
            subtitle: 'Allow Streaks to read health data from Health Connect',
            icon: Icons.security,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.infoBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.infoBlue.withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.infoBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Disconnection Needed!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your watch stays connected to Samsung Health. We read the data from there automatically.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white70 : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, 'continue');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                  ),
                  child: const Text('Continue Setup'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStep(
    BuildContext context, {
    required String number,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDarkMode,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDarkMode ? Colors.white10 : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryAccent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryAccent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: AppTheme.primaryAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? Colors.white70 : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }
}