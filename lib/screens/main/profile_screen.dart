import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import '../../providers/supabase_auth_provider.dart';
import '../../providers/supabase_user_provider.dart';
import '../../providers/supabase_nutrition_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/health_provider.dart';
import '../../services/smartwatch_service.dart';
import '../../services/unified_health_service.dart';
import '../../services/bluetooth_smartwatch_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/weight_model.dart';
import '../../widgets/weight_progress_card.dart';
import '../../utils/app_theme.dart';
import '../auth/welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  
  // Sample weight data - in production this would come from provider
  late WeightProgress _weightProgress;

  @override
  void initState() {
    super.initState();
    _initializeWeightData();
  }

  void _initializeWeightData() {
    // Initialize with empty data - will be populated from user input
    _weightProgress = WeightProgress(
      startWeight: 0,
      currentWeight: 0,
      targetWeight: 0,
      entries: [], // Start with empty entries
      unit: 'kg',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildProfileInfo(),
              _buildWeightProgressSection(),
              _buildSettingsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCardBackground : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Profile',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          IconButton(
            onPressed: () {
              // Edit profile action
            },
            icon: Icon(
              Icons.edit,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final profile = userProvider.profile;
        
        return Container(
          color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCardBackground : Colors.white,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Profile Image
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryAccent.withOpacity(0.1),
                    border: Border.all(
                      color: AppTheme.primaryAccent,
                      width: 3,
                    ),
                    image: _profileImage != null
                        ? DecorationImage(
                            image: FileImage(_profileImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _profileImage == null
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: AppTheme.primaryAccent,
                        )
                      : null,
                ),
              ),
              SizedBox(width: 20),
              // Profile Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.name ?? 'John Doe',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildInfoRow(Icons.height, '${profile?.height ?? 175} cm'),
                    SizedBox(height: 4),
                    _buildInfoRow(Icons.cake, '${profile?.age ?? 28} years old'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).brightness == Brightness.dark 
              ? AppTheme.textSecondaryDark 
              : AppTheme.textSecondary,
        ),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.textSecondaryDark 
                : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightProgressSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCardBackground : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WeightProgressCard(
            weightProgress: _weightProgress,
            onTap: () => _showWeightChart(),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddWeightDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.add),
              label: Text(
                'Log Weight',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCardBackground : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 16),
          _buildThemeToggle(),
          const Divider(height: 32),
          _buildSettingItem(
            icon: Icons.watch,
            title: 'Smartwatch Integration',
            subtitle: 'Connect your fitness tracker',
            onTap: () => _showSmartwatchIntegrationDialog(),
          ),
          _buildSettingItem(
            icon: Icons.track_changes,
            title: 'Nutrition Goals',
            subtitle: 'Adjust your daily targets',
            onTap: () => _showNutritionGoalsDialog(),
          ),
          _buildSettingItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage your reminders',
            onTap: () => _showNotificationsDialog(),
          ),
          _buildSettingItem(
            icon: Icons.lock_outline,
            title: 'Privacy',
            subtitle: 'Privacy settings',
            onTap: () {},
          ),
          _buildSettingItem(
            icon: Icons.backup_outlined,
            title: 'Data Export',
            subtitle: 'Export your fitness data',
            onTap: () => _showDataExportDialog(),
          ),
          _buildSettingItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () => _showHelpDialog(),
          ),
          _buildSettingItem(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () => _showAboutDialog(),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorRed,
                side: const BorderSide(color: AppTheme.errorRed),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.logout),
              label: Text(
                'Sign Out',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: AppTheme.primaryAccent,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Switch between light and dark mode',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.textSecondaryDark 
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: themeProvider.isDarkMode,
            onChanged: (_) => themeProvider.toggleTheme(),
            activeColor: AppTheme.primaryAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryAccent.withOpacity(0.1), AppTheme.primaryHover.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryAccent,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.textSecondaryDark 
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppTheme.dividerDark 
                  : AppTheme.dividerLight,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  void _showWeightChart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Weight Progress',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: WeightChartView(
                  weightProgress: _weightProgress,
                  onDeleteEntry: (entry) {
                    setState(() {
                      _weightProgress = _weightProgress.copyWith(
                        entries: _weightProgress.entries
                            .where((e) => e.id != entry.id)
                            .toList(),
                      );
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWeightDialog() {
    final weightController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Weight'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Weight (${_weightProgress.unit})',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final weight = double.tryParse(weightController.text);
              if (weight != null) {
                final newEntry = WeightEntry(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  weight: weight,
                  timestamp: DateTime.now(),
                  note: noteController.text.isEmpty ? null : noteController.text,
                );
                
                setState(() {
                  final entries = List<WeightEntry>.from(_weightProgress.entries)
                    ..add(newEntry);
                  _weightProgress = _weightProgress.copyWith(
                    entries: entries,
                    currentWeight: weight,
                  );
                });
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Weight logged successfully!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryLight,
            ),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showNutritionGoalsDialog() {
    final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
    final calorieController = TextEditingController(text: nutritionProvider.calorieGoal.toString());
    final proteinController = TextEditingController(text: nutritionProvider.proteinGoal.toString());
    final carbController = TextEditingController(text: nutritionProvider.carbGoal.toString());
    final fatController = TextEditingController(text: nutritionProvider.fatGoal.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nutrition Goals'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: calorieController,
              decoration: const InputDecoration(labelText: 'Daily Calories'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              controller: proteinController,
              decoration: const InputDecoration(labelText: 'Protein (g)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 16),
            TextField(
              controller: carbController,
              decoration: const InputDecoration(labelText: 'Carbs (g)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 16),
            TextField(
              controller: fatController,
              decoration: const InputDecoration(labelText: 'Fat (g)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await nutritionProvider.updateGoals(
                calorieGoal: int.tryParse(calorieController.text),
                proteinGoal: double.tryParse(proteinController.text),
                carbGoal: double.tryParse(carbController.text),
                fatGoal: double.tryParse(fatController.text),
              );
              Navigator.of(context).pop();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notifications'),
        content: Text('Notification settings will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDataExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Data Export'),
        content: Text('Data export functionality will be added in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Help & Support'),
        content: Text('For support, please contact us at support@streaker.app\n\nWe\'re here to help you achieve your fitness goals!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About Streaker'),
        content: Text('Streaker v1.0.0\n\nYour personal fitness companion for tracking nutrition, building streaks, and achieving your health goals.\n\nBuilt with Flutter 💙'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final supabaseAuthProvider = Provider.of<SupabaseAuthProvider>(context, listen: false);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
              
              // Close dialog first
              Navigator.of(context).pop();
              
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              try {
                print('Starting logout process...');
                
                // Clear all provider data FIRST
                await userProvider.clearUserData();
                await nutritionProvider.clearNutritionData();
                
                // Sign out from both auth providers
                await authProvider.signOut();
                await supabaseAuthProvider.signOut();
                
                print('Logout successful, navigating to welcome screen...');
                
                // Close loading dialog and navigate to Welcome screen
                if (mounted) {
                  Navigator.of(context).pop(); // Close loading dialog
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                print('Logout error: $e');
                // Close loading dialog and still navigate
                if (mounted) {
                  Navigator.of(context).pop(); // Close loading dialog
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showSmartwatchIntegrationDialog() async {
    final healthProvider = Provider.of<HealthProvider>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Check current health source status
    final currentSource = healthProvider.dataSource;
    final isHealthConnected = healthProvider.isHealthSourceConnected;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? AppTheme.darkCardBackground : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.watch,
                      color: AppTheme.primaryAccent,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Smartwatch Integration',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                if (isHealthConnected) ...[
                  // Already connected - show current status
                  _buildCurrentConnectionStatus(healthProvider, isDarkMode),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await healthProvider.syncWithHealth();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Health data synced successfully!'),
                                backgroundColor: AppTheme.successGreen,
                              ),
                            );
                          },
                          icon: Icon(Icons.sync, size: 20),
                          label: Text('Sync Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryAccent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showBluetoothAlternativeDialog();
                          },
                          icon: Icon(Icons.bluetooth, size: 20),
                          label: Text('Use Bluetooth'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Not connected - show connection options
                  Text(
                    'Choose how to connect your smartwatch:',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Option 1: Health App Integration (Recommended)
                  _buildIntegrationOption(
                    context,
                    icon: Icons.favorite,
                    title: 'Connect via Health App',
                    subtitle: 'Recommended • Samsung Health, Apple Health',
                    description: 'Your watch stays connected to Samsung Health. We sync data automatically.',
                    isRecommended: true,
                    onTap: () async {
                      Navigator.pop(context);
                      _connectToHealthApp();
                    },
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 16),
                  
                  // Option 2: Direct Bluetooth Connection
                  _buildIntegrationOption(
                    context,
                    icon: Icons.bluetooth,
                    title: 'Direct Bluetooth Connection',
                    subtitle: 'For watches not using health apps',
                    description: 'Connect directly to your smartwatch via Bluetooth.',
                    isRecommended: false,
                    onTap: () {
                      Navigator.pop(context);
                      _showBluetoothScanDialog();
                    },
                    isDarkMode: isDarkMode,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _showDeviceSelectionDialog(List<Map<String, dynamic>> devices) {
    String? selectedDevice;
    bool isConnecting = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.watch, color: AppTheme.primaryAccent),
              SizedBox(width: 12),
              Text('Select Device'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Found ${devices.length} device${devices.length > 1 ? 's' : ''}:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 20),
                // Show discovered devices
                ...devices.map((device) => _buildDiscoveredDeviceOption(
                  icon: _getDeviceIcon(device['type']),
                  name: device['name'],
                  subtitle: 'Signal: ${device['rssi']} dBm',
                  isSelected: selectedDevice == device['id'],
                  deviceInfo: device,
                  onTap: () {
                    setState(() {
                      selectedDevice = device['id'];
                    });
                  },
                )),
                
                if (isConnecting) ...[
                  SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: AppTheme.primaryAccent,
                        ),
                        SizedBox(height: 12),
                        Text('Connecting...'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedDevice == null || isConnecting
                  ? null
                  : () async {
                      setState(() {
                        isConnecting = true;
                      });
                      
                      // Get selected device info
                      final deviceToConnect = devices.firstWhere(
                        (d) => d['id'] == selectedDevice,
                      );
                      
                      // Connect via Bluetooth service
                      final bluetoothService = BluetoothSmartwatchService();
                      bool connected = await bluetoothService.connectDevice(deviceToConnect);
                      
                      if (mounted) {
                        Navigator.of(context).pop();
                        
                        if (connected) {
                          // Update health provider to sync
                          final healthProvider = Provider.of<HealthProvider>(context, listen: false);
                          bluetoothService.setDataUpdateCallback((data) {
                            healthProvider.updateMetricsFromHealth(data);
                          });
                          
                          // Trigger immediate sync
                          await bluetoothService.syncNow();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Connected to ${deviceToConnect['name']}! Health data will now sync automatically.',
                              ),
                              backgroundColor: AppTheme.successGreen,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to connect to ${deviceToConnect['name']}. Please try again.',
                              ),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
              ),
              child: Text(
                isConnecting ? 'Connecting...' : 'Connect',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSmartwatchOption({
    required IconData icon,
    required String name,
    required String subtitle,
    required bool isSelected,
    required bool isAvailable,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected 
                  ? AppTheme.primaryAccent 
                  : isAvailable 
                      ? AppTheme.borderColor 
                      : AppTheme.borderColor.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected 
                ? AppTheme.primaryAccent.withOpacity(0.1)
                : isAvailable
                    ? Colors.transparent
                    : AppTheme.borderColor.withOpacity(0.05),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isAvailable
                      ? AppTheme.primaryAccent.withOpacity(0.1)
                      : AppTheme.borderColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isAvailable
                      ? AppTheme.primaryAccent
                      : AppTheme.textSecondary,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isAvailable
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : AppTheme.textSecondary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isAvailable)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Coming Soon',
                    style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryAccent,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getDeviceName(String deviceId) {
    switch (deviceId) {
      case 'apple_watch':
        return 'Apple Watch';
      case 'samsung_watch':
        return 'Samsung Galaxy Watch';
      case 'garmin':
        return 'Garmin';
      case 'fitbit':
        return 'Fitbit';
      case 'mi_band':
        return 'Xiaomi Mi Band';
      case 'amazfit':
        return 'Amazfit';
      case 'huawei':
        return 'Huawei Watch';
      case 'google_fit':
        return 'Google Fit';
      default:
        return 'Smartwatch';
    }
  }
  
  Widget _buildDiscoveredDeviceOption({
    required IconData icon,
    required String name,
    required String subtitle,
    required bool isSelected,
    required Map<String, dynamic> deviceInfo,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryAccent
                  : AppTheme.borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryAccent.withOpacity(0.1)
                      : AppTheme.borderColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: AppTheme.primaryAccent,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryAccent,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getDeviceIcon(String type) {
    switch (type) {
      case 'samsung_watch':
        return Icons.watch;
      case 'garmin':
        return Icons.directions_run;
      case 'fitbit':
        return Icons.favorite;
      case 'mi_band':
        return Icons.watch_outlined;
      case 'amazfit':
        return Icons.sports_score;
      case 'huawei':
        return Icons.watch;
      case 'apple_watch':
        return Icons.watch;
      default:
        return Icons.bluetooth;
    }
  }
  
  void _showConnectedDeviceDialog(Map<String, dynamic> deviceInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.bluetooth_connected, color: AppTheme.successGreen),
            SizedBox(width: 12),
            Text('Device Connected'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Currently connected to:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.successGreen),
              ),
              child: Row(
                children: [
                  Icon(
                    _getDeviceIcon(deviceInfo['type'] ?? 'generic_ble'),
                    color: AppTheme.successGreen,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      deviceInfo['name'] ?? 'Unknown Device',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Health data is syncing automatically every 5 minutes.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final bluetoothService = BluetoothSmartwatchService();
              await bluetoothService.disconnectDevice();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Device disconnected'),
                  backgroundColor: AppTheme.warningYellow,
                ),
              );
            },
            child: Text(
              'Disconnect',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final bluetoothService = BluetoothSmartwatchService();
              await bluetoothService.syncNow();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Syncing data...'),
                  backgroundColor: AppTheme.primaryAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAccent,
            ),
            child: Text(
              'Sync Now',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showNoDevicesFoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.bluetooth_disabled, color: AppTheme.warningYellow),
            SizedBox(width: 12),
            Text('No Devices Found'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No compatible smartwatches were found nearby.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16),
            Text(
              'Please ensure:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '\u2022 Your smartwatch is powered on\n'
              '\u2022 Bluetooth is enabled on the watch\n'
              '\u2022 The watch is in pairing mode\n'
              '\u2022 The watch is within range',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showSmartwatchIntegrationDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAccent,
            ),
            child: Text(
              'Try Again',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('Permissions Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bluetooth and location permissions are required to discover and connect to smartwatches.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16),
            Text(
              'Please grant the necessary permissions in your device settings.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Open app settings
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAccent,
            ),
            child: Text(
              'Open Settings',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('Connection Error'),
          ],
        ),
        content: Text(
          error,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAccent,
            ),
            child: Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build current connection status display
  Widget _buildCurrentConnectionStatus(HealthProvider healthProvider, bool isDarkMode) {
    String sourceName;
    IconData sourceIcon;
    Color sourceColor;
    
    switch (healthProvider.dataSource) {
      case HealthDataSource.healthKit:
        sourceName = 'Apple Health';
        sourceIcon = Icons.favorite;
        sourceColor = Colors.red;
        break;
      case HealthDataSource.healthConnect:
        sourceName = 'Samsung Health / Health Connect';
        sourceIcon = Icons.favorite;
        sourceColor = Colors.green;
        break;
      case HealthDataSource.bluetooth:
        sourceName = 'Direct Bluetooth';
        sourceIcon = Icons.bluetooth;
        sourceColor = Colors.blue;
        break;
      default:
        sourceName = 'Unknown';
        sourceIcon = Icons.help_outline;
        sourceColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.green.withOpacity(0.1) : Colors.green.withOpacity(0.05),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected to $sourceName',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your health data is being synced automatically',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(sourceIcon, color: sourceColor, size: 20),
        ],
      ),
    );
  }

  // Helper method to build integration option cards
  Widget _buildIntegrationOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required bool isRecommended,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isRecommended ? AppTheme.primaryAccent : Colors.grey.withOpacity(0.3),
            width: isRecommended ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isRecommended 
              ? AppTheme.primaryAccent.withOpacity(0.05) 
              : Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isRecommended ? AppTheme.primaryAccent : Colors.grey[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryAccent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'RECOMMENDED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isRecommended ? AppTheme.primaryAccent : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to connect to health app
  Future<void> _connectToHealthApp() async {
    final healthProvider = Provider.of<HealthProvider>(context, listen: false);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryAccent),
            const SizedBox(height: 16),
            Text('Connecting to health app...'),
          ],
        ),
      ),
    );

    try {
      // Initialize health service
      final success = await healthProvider.initializeHealth();
      
      // Close loading dialog
      Navigator.pop(context);
      
      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Successfully connected to health app!'),
                ),
              ],
            ),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Sync initial data
        await healthProvider.syncWithHealth();
      } else {
        _showHealthConnectionError();
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      _showHealthConnectionError();
    }
  }

  // Show health connection error dialog with retry options
  void _showHealthConnectionError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 12),
            Text('Connection Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unable to connect to your health app. This might be due to:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '• Permissions not granted\n• Health app not available\n• Device compatibility issues',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              _showBluetoothAlternativeDialog();
            },
            child: Text('Try Bluetooth'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _connectToHealthApp(); // Retry
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAccent,
            ),
            child: Text(
              'Try Again',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Show Bluetooth alternative dialog
  void _showBluetoothAlternativeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.bluetooth, color: AppTheme.primaryAccent),
            const SizedBox(width: 12),
            Text('Bluetooth Connection'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connect directly to your smartwatch via Bluetooth.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: You may need to disconnect your watch from other apps first.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showBluetoothScanDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAccent,
            ),
            child: Text(
              'Start Scan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Show Bluetooth scan dialog
  void _showBluetoothScanDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Text('Scanning for devices...'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Make sure your smartwatch is in pairing mode and close to your device.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bluetooth_searching, color: Colors.blue),
                      const SizedBox(width: 12),
                      Text(
                        'Searching for smartwatches...',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );

    // TODO: Implement actual Bluetooth scanning logic here
    // For now, show a timeout after 10 seconds
    Timer(Duration(seconds: 10), () {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
        _showNoDevicesFoundDialog();
      }
    });
  }

}