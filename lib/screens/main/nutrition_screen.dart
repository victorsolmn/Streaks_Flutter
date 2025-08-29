import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/nutrition_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/nutrition_card.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({Key? key}) : super(key: key);

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _scanFood() async {
    try {
      setState(() {
        _isScanning = true;
      });

      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        _showErrorDialog('Camera permission is required to scan food');
        return;
      }

      // Show camera options
      final source = await _showImageSourceDialog();
      if (source == null) return;

      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
      final entry = await nutritionProvider.scanFood(image.path);

      if (entry != null && mounted) {
        final shouldAdd = await _showNutritionPreview(entry);
        if (shouldAdd) {
          await nutritionProvider.addNutritionEntry(entry);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${entry.foodName} to your nutrition log'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to scan food: ${e.toString()}');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppTheme.darkCardBackground : AppTheme.cardBackgroundLight,
        title: Text(
          'Select Image Source',
          style: TextStyle(
            color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppTheme.primaryAccent),
              title: Text(
                'Camera',
                style: TextStyle(
                  color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                ),
              ),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppTheme.primaryAccent),
              title: Text(
                'Gallery',
                style: TextStyle(
                  color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                ),
              ),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showNutritionPreview(NutritionEntry entry) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppTheme.darkCardBackground : AppTheme.cardBackgroundLight,
        title: Text(
          'Confirm Food Entry',
          style: TextStyle(
            color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.foodName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            _NutritionDetailRow(label: 'Calories', value: '${entry.calories}', unit: 'cal'),
            _NutritionDetailRow(label: 'Protein', value: '${entry.protein.round()}', unit: 'g'),
            _NutritionDetailRow(label: 'Carbs', value: '${entry.carbs.round()}', unit: 'g'),
            _NutritionDetailRow(label: 'Fat', value: '${entry.fat.round()}', unit: 'g'),
            _NutritionDetailRow(label: 'Fiber', value: '${entry.fiber.round()}', unit: 'g'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Add to Log'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showErrorDialog(String message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppTheme.darkCardBackground : AppTheme.cardBackgroundLight,
        title: Text(
          'Error',
          style: TextStyle(
            color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog() {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();
    final fiberController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppTheme.darkCardBackground : AppTheme.cardBackgroundLight,
        title: Text(
          'Add Food Manually',
          style: TextStyle(
            color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
          ),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Food Name'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 16),
                
                TextFormField(
                  controller: caloriesController,
                  decoration: const InputDecoration(labelText: 'Calories'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 16),
                
                TextFormField(
                  controller: proteinController,
                  decoration: const InputDecoration(labelText: 'Protein (g)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 16),
                
                TextFormField(
                  controller: carbsController,
                  decoration: const InputDecoration(labelText: 'Carbs (g)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 16),
                
                TextFormField(
                  controller: fatController,
                  decoration: const InputDecoration(labelText: 'Fat (g)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 16),
                
                TextFormField(
                  controller: fiberController,
                  decoration: const InputDecoration(labelText: 'Fiber (g) - Optional'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final entry = NutritionEntry(
                  id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                  foodName: nameController.text,
                  calories: int.parse(caloriesController.text),
                  protein: double.parse(proteinController.text),
                  carbs: double.parse(carbsController.text),
                  fat: double.parse(fatController.text),
                  fiber: fiberController.text.isNotEmpty ? double.parse(fiberController.text) : 0.0,
                  timestamp: DateTime.now(),
                );

                final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
                await nutritionProvider.addNutritionEntry(entry);

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added ${entry.foodName} to your nutrition log'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nutrition'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryAccent,
          labelColor: AppTheme.primaryAccent,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'History'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'scan':
                  _scanFood();
                  break;
                case 'manual':
                  _showManualEntryDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'scan',
                child: ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Scan Food'),
                ),
              ),
              const PopupMenuItem(
                value: 'manual',
                child: ListTile(
                  leading: Icon(Icons.add),
                  title: Text('Add Manually'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildHistoryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? null : _scanFood,
        backgroundColor: _isScanning 
            ? AppTheme.borderColor 
            : AppTheme.primaryAccent,
        child: _isScanning
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              )
            : Icon(Icons.camera_alt),
      ),
    );
  }

  Widget _buildTodayTab() {
    return Consumer<NutritionProvider>(
      builder: (context, nutritionProvider, child) {
        final todayNutrition = nutritionProvider.todayNutrition;
        
        return RefreshIndicator(
          onRefresh: () async {
            // Refresh data
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nutrition overview
                NutritionOverviewCard(
                  dailyNutrition: todayNutrition,
                  calorieGoal: nutritionProvider.calorieGoal,
                  proteinGoal: nutritionProvider.proteinGoal,
                  carbGoal: nutritionProvider.carbGoal,
                  fatGoal: nutritionProvider.fatGoal,
                ),
                SizedBox(height: 24),
                
                // Macro breakdown
                MacroBreakdownCard(dailyNutrition: todayNutrition),
                SizedBox(height: 24),
                
                // Today's meals
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Meals',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${todayNutrition.entries.length} meals',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                if (todayNutrition.entries.isEmpty)
                  _buildEmptyState()
                else
                  ...todayNutrition.entries.map(
                    (entry) => NutritionEntryCard(
                      entry: entry,
                      onDelete: () async {
                        final confirm = await _showDeleteConfirmation();
                        if (confirm) {
                          await nutritionProvider.removeNutritionEntry(entry.id);
                        }
                      },
                    ),
                  ),
                
                SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<NutritionProvider>(
      builder: (context, nutritionProvider, child) {
        final weeklyNutrition = nutritionProvider.getWeeklyNutrition();
        
        return RefreshIndicator(
          onRefresh: () async {
            // Refresh data
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Overview',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),
                
                ...weeklyNutrition.map((dailyNutrition) {
                  final dayName = _getDayName(dailyNutrition.date);
                  final isToday = _isToday(dailyNutrition.date);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  dayName,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isToday ? AppTheme.primaryAccent : null,
                                  ),
                                ),
                                if (isToday) ...[
                                  SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Today',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.primaryAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                Text(
                                  '${dailyNutrition.totalCalories} cal',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            
                            Row(
                              children: [
                                Text(
                                  'P: ${dailyNutrition.totalProtein.round()}g',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text(
                                  'C: ${dailyNutrition.totalCarbs.round()}g',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text(
                                  'F: ${dailyNutrition.totalFat.round()}g',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${dailyNutrition.entries.length} meals',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                
                SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? AppTheme.darkCardBackground 
            : AppTheme.cardBackgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode 
              ? AppTheme.dividerDark 
              : AppTheme.dividerLight,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 40,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'No meals logged today',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the camera button to scan your first meal',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppTheme.darkCardBackground : AppTheme.cardBackgroundLight,
        title: Text(
          'Delete Entry',
          style: TextStyle(
            color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this nutrition entry?',
          style: TextStyle(
            color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _getDayName(DateTime date) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[date.weekday - 1];
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }
}

class _NutritionDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _NutritionDetailRow({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          Text(
            '$value $unit',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}