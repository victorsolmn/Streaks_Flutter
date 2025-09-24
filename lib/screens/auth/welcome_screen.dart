import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../utils/app_theme.dart';
import 'signin_screen.dart';
import 'unified_auth_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 1),
              
              // Logo and title
              Column(
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: SvgPicture.asset(
                      'assets/images/streaker_logo.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  Text(
                    'Streaker',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  Text(
                    'Track your fitness journey,\nbuild lasting habits',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.normal,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              
              const Spacer(flex: 2),
              
              // Features list
              Column(
                children: [
                  _FeatureItem(
                    icon: Icons.timeline,
                    title: 'Track Progress',
                    subtitle: 'Monitor your daily fitness and nutrition goals',
                  ),
                  SizedBox(height: 24),
                  
                  _FeatureItem(
                    icon: Icons.camera_alt,
                    title: 'Smart Nutrition',
                    subtitle: 'Scan food with AI-powered recognition',
                  ),
                  SizedBox(height: 24),
                  
                  _FeatureItem(
                    icon: Icons.local_fire_department,
                    title: 'Build Streaks',
                    subtitle: 'Stay motivated with daily streak tracking',
                  ),
                ],
              ),
              
              const Spacer(flex: 2),
              
              // Action buttons
              Column(
                children: [
                  // Primary CTA - Unified auth with OTP
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const UnifiedAuthScreen(),
                          ),
                        );
                      },
                      child: Text('Get Started'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Secondary option - Traditional password login
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SignInScreen(),
                          ),
                        );
                      },
                      icon: Icon(Icons.lock_outline, size: 20),
                      label: Text('Sign In with Password'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryAccent.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),
        SizedBox(width: 16),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}