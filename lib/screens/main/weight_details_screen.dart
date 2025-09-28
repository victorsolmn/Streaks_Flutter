import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/weight_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/weight_progress_chart.dart';
import '../../models/weight_model.dart';

class WeightDetailsScreen extends StatefulWidget {
  const WeightDetailsScreen({Key? key}) : super(key: key);

  @override
  State<WeightDetailsScreen> createState() => _WeightDetailsScreenState();
}

class _WeightDetailsScreenState extends State<WeightDetailsScreen> {
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Weight Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddWeightDialog(context),
          ),
        ],
      ),
      body: Consumer<WeightProvider>(
        builder: (context, weightProvider, child) {
          if (weightProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => weightProvider.loadWeightData(forceRefresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weight Progress Chart (Full View)
                  const WeightProgressChart(
                    isCompact: false,
                  ),
                  const SizedBox(height: 32),

                  // Quick Stats
                  _buildQuickStats(weightProvider),
                  const SizedBox(height: 32),

                  // Weight Entries List
                  _buildWeightEntriesList(weightProvider),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWeightDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Weight'),
        backgroundColor: AppTheme.primaryAccent,
      ),
    );
  }

  Widget _buildQuickStats(WeightProvider provider) {
    if (provider.weightProgress == null) return const SizedBox.shrink();

    final progress = provider.weightProgress!;
    final trend = provider.weeklyTrend;
    final projectedDate = provider.getProjectedGoalDate();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Progress',
                value: '${progress.progressPercentage.toStringAsFixed(1)}%',
                subtitle: '${progress.remainingLoss.abs().toStringAsFixed(1)} ${progress.unit} to go',
                color: Colors.blue,
                icon: Icons.trending_down,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Total Change',
                value: '${progress.totalLoss.abs().toStringAsFixed(1)} ${progress.unit}',
                subtitle: progress.totalLoss > 0 ? 'Lost' : 'Gained',
                color: progress.totalLoss > 0 ? Colors.green : Colors.orange,
                icon: progress.totalLoss > 0 ? Icons.arrow_downward : Icons.arrow_upward,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (trend != null)
          _buildStatCard(
            title: 'Weekly Trend',
            value: '${trend.abs().toStringAsFixed(2)} ${progress.unit}/week',
            subtitle: trend < 0 ? 'Losing weight' : 'Gaining weight',
            color: trend < 0 ? Colors.green : Colors.orange,
            icon: trend < 0 ? Icons.trending_down : Icons.trending_up,
          ),
        if (projectedDate != null) ...[
          const SizedBox(height: 16),
          _buildStatCard(
            title: 'Projected Goal Date',
            value: DateFormat('MMM dd, yyyy').format(projectedDate),
            subtitle: 'At current rate',
            color: Colors.purple,
            icon: Icons.flag,
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightEntriesList(WeightProvider provider) {
    final entries = provider.entries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Weight History',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${entries.length} entries',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.monitor_weight_outlined,
                    size: 64,
                    color: AppTheme.textSecondary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No weight entries yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first entry',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...entries.map((entry) => _buildWeightEntryCard(entry, provider)),
      ],
    );
  }

  Widget _buildWeightEntryCard(WeightEntry entry, WeightProvider provider) {
    final progress = provider.weightProgress;
    final isToday = _isToday(entry.timestamp);

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.red,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Entry'),
              content: Text('Delete weight entry from ${DateFormat('MMM dd, yyyy').format(entry.timestamp)}?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        final success = await provider.deleteWeightEntry(entry.id);
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'Failed to delete entry'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday
                ? AppTheme.primaryAccent.withOpacity(0.3)
                : AppTheme.borderColor.withOpacity(0.2),
            width: isToday ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.weight.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryAccent,
                      ),
                    ),
                    Text(
                      progress?.unit ?? 'kg',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryAccent.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isToday ? 'Today' : DateFormat('MMM dd, yyyy').format(entry.timestamp),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Latest',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(entry.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary.withOpacity(0.7),
                    ),
                  ),
                  if (entry.note != null && entry.note!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        entry.note!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWeightDialog(BuildContext context) {
    final provider = context.read<WeightProvider>();
    final currentWeight = provider.weightProgress?.currentWeight;
    final unit = provider.weightProgress?.unit ?? 'kg';

    // Pre-fill with current weight if available
    if (currentWeight != null) {
      _weightController.text = currentWeight.toStringAsFixed(1);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Weight Entry'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Weight ($unit)',
                    hintText: 'Enter your weight',
                    prefixIcon: const Icon(Icons.monitor_weight),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your weight';
                    }
                    final weight = double.tryParse(value);
                    if (weight == null || weight <= 0 || weight > 500) {
                      return 'Please enter a valid weight (1-500)';
                    }
                    return null;
                  },
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'Add a note',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _weightController.clear();
                _noteController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final weight = double.parse(_weightController.text);
                  final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

                  final success = await provider.addWeightEntry(weight, note: note);

                  if (success && mounted) {
                    _weightController.clear();
                    _noteController.clear();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Weight entry added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (!success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.error ?? 'Failed to add weight entry'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}