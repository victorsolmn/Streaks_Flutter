import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/nutrition_provider.dart';
import '../../services/toast_service.dart';
import '../../services/popup_service.dart';
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
    // Initialize toast service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ToastService().initialize(context);
    });
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

      // Get food details from user
      final foodDetailsList = await _showFoodDetailsDialog();
      if (foodDetailsList == null || foodDetailsList.isEmpty) return;

      final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
      
      // Process each food item
      List<dynamic> processedEntries = [];
      bool hasErrors = false;
      
      for (int i = 0; i < foodDetailsList.length; i++) {
        final foodDetails = foodDetailsList[i];
        try {
          final entry = await nutritionProvider.scanFoodWithDetails(
            image.path,
            foodDetails['name']!,
            foodDetails['quantity']!,
          );
          if (entry != null) {
            processedEntries.add(entry);
          }
        } catch (e) {
          hasErrors = true;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to analyze ${foodDetails['name']}: ${e.toString()}'),
                backgroundColor: AppTheme.errorRed,
              ),
            );
          }
        }
      }
      
      if (processedEntries.isNotEmpty && mounted) {
        // Show preview for all processed entries
        final shouldAdd = await _showMultipleFoodPreview(processedEntries);
        if (shouldAdd) {
          for (var entry in processedEntries) {
            await nutritionProvider.addNutritionEntry(entry);
          }
          ToastService().showSuccess(
            processedEntries.length == 1 
              ? 'Added ${processedEntries[0].foodName} to your nutrition log! 🍎'
              : 'Added ${processedEntries.length} food items to your nutrition log! 🍎'
          );
        }
      } else if (!hasErrors) {
        if (mounted) {
          _showErrorDialog('Could not analyze any of the food items. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        PopupService.showNetworkError(
          context,
          onRetry: () => _scanFood(),
          customMessage: 'Failed to scan food: ${e.toString()}. Please check your connection and try again.',
        );
      }
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

  Future<bool> _showMultipleFoodPreview(List<dynamic> entries) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate total nutrition
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    
    for (var entry in entries) {
      totalCalories += entry.calories;
      totalProtein += entry.protein;
      totalCarbs += entry.carbs;
      totalFat += entry.fat;
    }
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppTheme.darkCardBackground : AppTheme.cardBackgroundLight,
        title: Row(
          children: [
            Icon(Icons.restaurant_menu, color: AppTheme.primaryAccent, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Confirm Food Entries',
                style: TextStyle(
                  color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${entries.length} item${entries.length > 1 ? 's' : ''}',
                style: TextStyle(
                  color: AppTheme.primaryAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary card
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics, color: AppTheme.primaryAccent, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Total Nutrition Summary',
                            style: TextStyle(
                              color: AppTheme.primaryAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNutritionStat('Calories', '${totalCalories.toInt()}', 'kcal'),
                          ),
                          Expanded(
                            child: _buildNutritionStat('Protein', '${totalProtein.toInt()}', 'g'),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNutritionStat('Carbs', '${totalCarbs.toInt()}', 'g'),
                          ),
                          Expanded(
                            child: _buildNutritionStat('Fat', '${totalFat.toInt()}', 'g'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                
                // Individual food items
                Text(
                  'Individual Food Items:',
                  style: TextStyle(
                    color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 12),
                
                ...entries.asMap().entries.map((entry) {
                  int index = entry.key;
                  var foodEntry = entry.value;
                  
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                        ? AppTheme.darkCardBackground.withOpacity(0.5)
                        : AppTheme.cardBackgroundLight.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (isDarkMode ? AppTheme.dividerDark : AppTheme.dividerLight).withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryAccent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                foodEntry.foodName,
                                style: TextStyle(
                                  color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${foodEntry.calories.toInt()} kcal',
                                style: TextStyle(
                                  color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              'P: ${foodEntry.protein.toInt()}g • C: ${foodEntry.carbs.toInt()}g • F: ${foodEntry.fat.toInt()}g',
                              style: TextStyle(
                                color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: Icon(Icons.add, size: 18),
            label: Text('Add All to Log'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildNutritionStat(String label, String value, String unit) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 2),
        RichText(
          text: TextSpan(
            text: value,
            style: TextStyle(
              color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            children: [
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                  fontWeight: FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<List<Map<String, String>>?> _showFoodDetailsDialog() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // List to hold multiple food items (max 4)
    List<Map<String, dynamic>> foodItems = [
      {
        'nameController': TextEditingController(),
        'quantityController': TextEditingController(text: '100'),
        'selectedUnit': 'grams',
      }
    ];

    return await showDialog<List<Map<String, String>>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDarkMode ? AppTheme.darkCardBackground : AppTheme.cardBackgroundLight,
          title: Row(
            children: [
              Icon(Icons.restaurant_menu, color: AppTheme.primaryAccent, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Food Details',
                  style: TextStyle(
                    color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${foodItems.length}/4 items',
                  style: TextStyle(
                    color: AppTheme.primaryAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.primaryAccent, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Add up to 4 different foods from your meal for better nutrition tracking',
                            style: TextStyle(
                              color: AppTheme.primaryAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Dynamic food items list
                  ...foodItems.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, dynamic> item = entry.value;
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode 
                          ? AppTheme.darkCardBackground.withOpacity(0.5)
                          : AppTheme.cardBackgroundLight.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryAccent.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with item number and delete button
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryAccent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Food Item ${index + 1}',
                                  style: TextStyle(
                                    color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (foodItems.length > 1)
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      item['nameController'].dispose();
                                      item['quantityController'].dispose();
                                      foodItems.removeAt(index);
                                    });
                                  },
                                  icon: Icon(
                                    Icons.remove_circle,
                                    color: AppTheme.errorRed,
                                    size: 20,
                                  ),
                                  constraints: BoxConstraints(),
                                  padding: EdgeInsets.all(4),
                                ),
                            ],
                          ),
                          SizedBox(height: 12),
                          
                          // Food name input
                          TextField(
                            controller: item['nameController'],
                            autofocus: index == 0,
                            decoration: InputDecoration(
                              labelText: 'Food Name',
                              hintText: 'e.g., Chicken Biryani, Apple, Sandwich',
                              prefixIcon: Icon(Icons.fastfood, color: AppTheme.primaryAccent, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppTheme.primaryAccent, width: 2),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            style: TextStyle(
                              color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 12),
                          
                          // Quantity and unit row
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: item['quantityController'],
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Quantity',
                                    prefixIcon: Icon(Icons.scale, color: AppTheme.primaryAccent, size: 20),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: AppTheme.primaryAccent, width: 2),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  style: TextStyle(
                                    color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isDarkMode ? AppTheme.dividerDark : AppTheme.dividerLight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: item['selectedUnit'],
                                      isExpanded: true,
                                      dropdownColor: isDarkMode ? AppTheme.darkCardBackground : AppTheme.cardBackgroundLight,
                                      style: TextStyle(
                                        color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                                        fontSize: 14,
                                      ),
                                      items: [
                                        'grams',
                                        'kg',
                                        'cups',
                                        'pieces',
                                        'servings',
                                        'plates',
                                        'bowls',
                                        'ml',
                                        'liters',
                                      ].map((unit) => DropdownMenuItem(
                                        value: unit,
                                        child: Text(unit),
                                      )).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          item['selectedUnit'] = value!;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  
                  // Add new food item button
                  if (foodItems.length < 4)
                    Center(
                      child: Container(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              foodItems.add({
                                'nameController': TextEditingController(),
                                'quantityController': TextEditingController(text: '100'),
                                'selectedUnit': 'grams',
                              });
                            });
                          },
                          icon: Icon(Icons.add_circle_outline, color: AppTheme.primaryAccent),
                          label: Text(
                            'Add Another Food Item',
                            style: TextStyle(color: AppTheme.primaryAccent),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppTheme.primaryAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: AppTheme.primaryAccent, size: 14),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Be specific with food names for better nutrition accuracy',
                            style: TextStyle(
                              color: AppTheme.primaryAccent,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Dispose controllers before closing
                for (var item in foodItems) {
                  item['nameController'].dispose();
                  item['quantityController'].dispose();
                }
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Validate all food items
                List<Map<String, String>> validFoodItems = [];
                bool hasErrors = false;
                
                for (int i = 0; i < foodItems.length; i++) {
                  var item = foodItems[i];
                  String name = item['nameController'].text.trim();
                  String quantity = item['quantityController'].text.trim();
                  
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please enter name for food item ${i + 1}'),
                        backgroundColor: AppTheme.errorRed,
                      ),
                    );
                    hasErrors = true;
                    break;
                  }
                  if (quantity.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please enter quantity for food item ${i + 1}'),
                        backgroundColor: AppTheme.errorRed,
                      ),
                    );
                    hasErrors = true;
                    break;
                  }
                  
                  validFoodItems.add({
                    'name': name,
                    'quantity': '$quantity ${item['selectedUnit']}',
                  });
                }
                
                if (!hasErrors) {
                  // Dispose controllers before closing
                  for (var item in foodItems) {
                    item['nameController'].dispose();
                    item['quantityController'].dispose();
                  }
                  Navigator.of(context).pop(validFoodItems);
                }
              },
              icon: Icon(Icons.analytics, size: 18),
              label: Text('Analyze Food${foodItems.length > 1 ? 's' : ''}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
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