import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Streaker Terms & Conditions',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryAccent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateTime.now().toString().substring(0, 10)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              context,
              '1. Acceptance of Terms',
              'By downloading, installing, or using the Streaker fitness tracking application, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our service.',
            ),

            _buildSection(
              context,
              '2. Description of Service',
              'Streaker is a comprehensive fitness tracking application that helps you:\n\n'
              '• Monitor your daily activity, steps, and workouts\n'
              '• Track nutrition through meal photo analysis\n'
              '• Set and achieve fitness goals\n'
              '• Sync with health platforms like Health Connect and HealthKit\n'
              '• Access personalized fitness insights and recommendations',
            ),

            _buildSection(
              context,
              '3. User Accounts and Registration',
              'To use certain features of our service, you must:\n\n'
              '• Provide accurate and complete registration information\n'
              '• Maintain the security of your account credentials\n'
              '• Be at least 13 years of age\n'
              '• Use the service only for lawful purposes\n'
              '• Not share your account with others',
            ),

            _buildSection(
              context,
              '4. Health and Safety Disclaimer',
              'IMPORTANT: Streaker is designed for general fitness tracking and is not a medical device or service.\n\n'
              '• Always consult healthcare professionals before starting any fitness program\n'
              '• Our app provides estimates and should not replace professional medical advice\n'
              '• We are not responsible for health decisions made based on app data\n'
              '• Use the app at your own risk and within your physical capabilities',
            ),

            _buildSection(
              context,
              '5. User Content and Data',
              'You retain ownership of the content you provide, including:\n\n'
              '• Photos of meals and food items\n'
              '• Personal fitness data and measurements\n'
              '• Profile information and preferences\n\n'
              'By using our service, you grant us permission to process this data to provide our fitness tracking features.',
            ),

            _buildSection(
              context,
              '6. Acceptable Use Policy',
              'You agree not to:\n\n'
              '• Use the service for any illegal or unauthorized purpose\n'
              '• Upload inappropriate, offensive, or copyrighted content\n'
              '• Attempt to hack, reverse engineer, or compromise the service\n'
              '• Share false or misleading health information\n'
              '• Interfere with other users\' access to the service',
            ),

            _buildSection(
              context,
              '7. Third-Party Integrations',
              'Our app integrates with various third-party services:\n\n'
              '• Health Connect (Android) and HealthKit (iOS) for health data sync\n'
              '• Google AI services for nutrition analysis\n'
              '• Cloud storage services for data backup\n\n'
              'These integrations are subject to their respective terms of service and privacy policies.',
            ),

            _buildSection(
              context,
              '8. Subscription and Payments',
              'Some features may require a subscription:\n\n'
              '• Subscription fees are charged in advance\n'
              '• You can cancel your subscription at any time\n'
              '• Refunds are subject to applicable app store policies\n'
              '• Pricing may change with 30 days notice',
            ),

            _buildSection(
              context,
              '9. Limitation of Liability',
              'To the maximum extent permitted by law:\n\n'
              '• We provide the service "as is" without warranties\n'
              '• We are not liable for any health issues or injuries\n'
              '• Our liability is limited to the amount you paid for the service\n'
              '• We are not responsible for third-party service outages or data loss',
            ),

            _buildSection(
              context,
              '10. Data Backup and Loss',
              'While we strive to protect your data:\n\n'
              '• We recommend regular backups of important information\n'
              '• We are not liable for data loss due to technical issues\n'
              '• Service interruptions may occur for maintenance\n'
              '• You should not rely solely on our service for critical health records',
            ),

            _buildSection(
              context,
              '11. Termination',
              'Either party may terminate the service:\n\n'
              '• You can delete your account at any time\n'
              '• We may suspend accounts for terms violations\n'
              '• Upon termination, your data will be deleted according to our privacy policy\n'
              '• These terms survive termination where applicable',
            ),

            _buildSection(
              context,
              '12. Changes to Terms',
              'We may update these terms from time to time:\n\n'
              '• Significant changes will be communicated in-app\n'
              '• Continued use constitutes acceptance of new terms\n'
              '• You can review the latest version in the app settings',
            ),

            _buildSection(
              context,
              '13. Governing Law',
              'These terms are governed by the laws of [Your Jurisdiction]. Any disputes will be resolved through binding arbitration or in the courts of [Your Jurisdiction].',
            ),

            _buildSection(
              context,
              '14. Contact Information',
              'For questions about these terms, contact us:\n\n'
              'Email: legal@streaker.app\n'
              'Address: [Your Business Address]\n\n'
              'We will respond to your inquiries within 5 business days.',
            ),

            const SizedBox(height: 32),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryAccent.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Questions?',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.primaryAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'If you have any questions about these terms or need clarification on any point, please don\'t hesitate to contact our support team.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}