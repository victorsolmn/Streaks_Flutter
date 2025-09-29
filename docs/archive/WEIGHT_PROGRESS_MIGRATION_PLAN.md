# 📊 Weight Progress Migration & Line Graph Implementation Plan

## Executive Summary
Detailed plan to move Weight Progress from Profile screen to Progress screen (Streaks tab) and transform it from a progress bar to an interactive line graph similar to the weekly progress chart.

---

## 🎯 Current State Analysis

### **Current Location:**
- **Profile Screen** (`profile_screen.dart`)
- Displayed as a simple progress bar with Start/Current/Target values
- Uses `WeightProgressCard` widget with linear progress indicator
- Modal bottom sheet with `WeightChartView` (already has line graph!)

### **Current Implementation:**
```dart
// Profile Screen (Current)
WeightProgressCard(
  weightProgress: weightProgress,
  onTap: () => showWeightProgressDetails(),
)

// Shows: [Start: 80kg] [Current: 75kg] [Target: 70kg]
// Progress bar: ████████░░ 50%
```

### **Target Location:**
- **Progress Screen** (`progress_screen_new.dart`) - 2nd tab
- Position: Below "Weekly Progress" chart
- Before "Milestone Progress Ring"

---

## 📐 Detailed Implementation Plan

### **Phase 1: UI/UX Design Decision**

#### **Option A: Compact Integration** (RECOMMENDED)
```
Progress Screen Layout:
┌─────────────────────────────┐
│ Streak Display Widget       │
│                             │
│ Today's Summary            │
│ [3 metric cards]           │
│                             │
│ Weekly Progress            │
│ [Calories chart]           │
│                             │
│ Weight Progress (NEW)      │ ← Insert here
│ [Weight line graph]        │
│                             │
│ Milestone Progress Ring    │
└─────────────────────────────┘
```

#### **Option B: Tabbed Charts**
```
Progress Screen:
┌─────────────────────────────┐
│ Streak Display             │
│ Today's Summary            │
│                             │
│ ┌──────┬──────┬──────┐    │
│ │Weekly│Weight│ BMI  │     │ ← Tab selector
│ └──────┴──────┴──────┘    │
│ [Chart Area - Swipeable]   │
│                             │
│ Milestone Progress Ring    │
└─────────────────────────────┘
```

**RECOMMENDATION: Use Option A for better visibility and direct access**

---

## 🏗️ Technical Implementation Details

### **Step 1: Create Weight Progress Chart Widget**

```dart
// lib/widgets/weight_progress_chart.dart

class WeightProgressChart extends StatefulWidget {
  final bool isCompact; // For progress screen (compact) vs full view

  @override
  _WeightProgressChartState createState() => _WeightProgressChartState();
}

class _WeightProgressChartState extends State<WeightProgressChart> {
  WeightProgress? weightProgress;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeightData();
  }

  Future<void> _loadWeightData() async {
    // Load from Supabase
    final data = await SupabaseService().getWeightProgress();
    setState(() {
      weightProgress = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoadingState();
    if (weightProgress == null) return _buildEmptyState();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        SizedBox(height: 16),
        _buildChart(),
        if (!widget.isCompact) _buildLegend(),
      ],
    );
  }

  Widget _buildChart() {
    return Container(
      height: widget.isCompact ? 200 : 250,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: _buildLineChart(),
    );
  }
}
```

### **Step 2: Line Chart Implementation**

```dart
Widget _buildLineChart() {
  final entries = weightProgress!.entries;
  if (entries.isEmpty) return _buildNoDataState();

  // Sort entries by date
  final sortedEntries = List<WeightEntry>.from(entries)
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  // Calculate date range
  final firstDate = sortedEntries.first.timestamp;
  final lastDate = sortedEntries.last.timestamp;
  final daysDiff = lastDate.difference(firstDate).inDays;

  // Determine appropriate scale
  final minWeight = _calculateMinWeight(sortedEntries);
  final maxWeight = _calculateMaxWeight(sortedEntries);

  return LineChart(
    LineChartData(
      // Grid configuration
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: _calculateInterval(maxWeight - minWeight),
        verticalInterval: _calculateDateInterval(daysDiff),
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppTheme.borderColor.withOpacity(0.3),
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: AppTheme.borderColor.withOpacity(0.2),
          strokeWidth: 0.5,
          dashArray: [5, 3],
        ),
      ),

      // Titles configuration
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) => _buildDateLabel(value, sortedEntries),
            interval: _calculateDateLabelInterval(daysDiff),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (value, meta) => _buildWeightLabel(value),
            interval: _calculateWeightInterval(maxWeight - minWeight),
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),

      // Border
      borderData: FlBorderData(show: false),

      // Bounds
      minX: 0,
      maxX: sortedEntries.length - 1.0,
      minY: minWeight,
      maxY: maxWeight,

      // Lines data
      lineBarsData: [
        // Actual weight line
        LineChartBarData(
          spots: _generateWeightSpots(sortedEntries),
          isCurved: true,
          curveSmoothness: 0.3,
          color: AppTheme.primaryAccent,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              // Highlight today's weight
              final isToday = _isToday(sortedEntries[index].timestamp);
              return FlDotCirclePainter(
                radius: isToday ? 5 : 3,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: isToday ? Colors.green : AppTheme.primaryAccent,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryAccent.withOpacity(0.2),
                AppTheme.primaryAccent.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Target weight line (dashed)
        LineChartBarData(
          spots: [
            FlSpot(0, weightProgress!.targetWeight),
            FlSpot(sortedEntries.length - 1.0, weightProgress!.targetWeight),
          ],
          isCurved: false,
          color: Colors.green,
          barWidth: 2,
          dashArray: [8, 4],
          dotData: FlDotData(show: false),
        ),

        // Trend line (optional - shows projected progress)
        if (_shouldShowTrendLine(sortedEntries))
          LineChartBarData(
            spots: _generateTrendLine(sortedEntries),
            isCurved: false,
            color: Colors.blue.withOpacity(0.5),
            barWidth: 1,
            dashArray: [5, 5],
            dotData: FlDotData(show: false),
          ),
      ],

      // Touch interactions
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
          tooltipRoundedRadius: 8,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final entry = sortedEntries[spot.spotIndex];
              return LineTooltipItem(
                '${entry.weight.toStringAsFixed(1)} ${weightProgress!.unit}\n${DateFormat('MMM dd').format(entry.timestamp)}',
                TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
      ),
    ),
  );
}
```

### **Step 3: Smart Features**

#### **3.1 Intelligent Y-Axis Scaling**
```dart
double _calculateMinWeight(List<WeightEntry> entries) {
  final weights = entries.map((e) => e.weight).toList();
  weights.add(weightProgress!.targetWeight);
  final min = weights.reduce((a, b) => a < b ? a : b);

  // Add 5% padding below
  return min * 0.95;
}

double _calculateMaxWeight(List<WeightEntry> entries) {
  final weights = entries.map((e) => e.weight).toList();
  weights.add(weightProgress!.startWeight);
  final max = weights.reduce((a, b) => a > b ? a : b);

  // Add 5% padding above
  return max * 1.05;
}
```

#### **3.2 Dynamic Date Labels**
```dart
Widget _buildDateLabel(double value, List<WeightEntry> entries) {
  final index = value.toInt();
  if (index >= 0 && index < entries.length) {
    final date = entries[index].timestamp;
    final daysDiff = entries.last.timestamp.difference(entries.first.timestamp).inDays;

    // Adaptive formatting based on date range
    String format;
    if (daysDiff <= 7) {
      format = 'EEE'; // Mon, Tue
    } else if (daysDiff <= 30) {
      format = 'MM/dd'; // 03/15
    } else if (daysDiff <= 90) {
      format = 'MMM dd'; // Mar 15
    } else {
      format = 'MMM'; // Mar
    }

    return Text(
      DateFormat(format).format(date),
      style: TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 10,
      ),
    );
  }
  return SizedBox.shrink();
}
```

#### **3.3 Progress Indicators**
```dart
Widget _buildHeader() {
  final progress = weightProgress!;
  final trend = _calculateTrend();

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weight Progress',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          SizedBox(height: 4),
          Text(
            _getProgressSummary(),
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),

      // Quick stats badges
      Row(
        children: [
          _buildStatBadge(
            label: 'Current',
            value: '${progress.currentWeight.toStringAsFixed(1)} ${progress.unit}',
            color: AppTheme.primaryAccent,
          ),
          SizedBox(width: 8),
          _buildStatBadge(
            label: 'Goal',
            value: '${progress.targetWeight.toStringAsFixed(1)} ${progress.unit}',
            color: Colors.green,
          ),
          if (trend != null) ...[
            SizedBox(width: 8),
            _buildTrendIndicator(trend),
          ],
        ],
      ),
    ],
  );
}

Widget _buildTrendIndicator(WeightTrend trend) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: trend.isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: trend.isPositive ? Colors.green : Colors.red,
        width: 0.5,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          trend.isPositive ? Icons.trending_down : Icons.trending_up,
          size: 14,
          color: trend.isPositive ? Colors.green : Colors.red,
        ),
        SizedBox(width: 4),
        Text(
          '${trend.weeklyAverage.abs().toStringAsFixed(1)} ${weightProgress!.unit}/week',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: trend.isPositive ? Colors.green : Colors.red,
          ),
        ),
      ],
    ),
  );
}
```

### **Step 4: State Management Integration**

#### **4.1 Create Weight Provider**
```dart
// lib/providers/weight_provider.dart

class WeightProvider extends ChangeNotifier {
  WeightProgress? _weightProgress;
  bool _isLoading = false;
  String? _error;

  WeightProgress? get weightProgress => _weightProgress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadWeightData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      // Load from Supabase
      final response = await supabase
          .from('weight_entries')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: true);

      final entries = (response as List)
          .map((e) => WeightEntry.fromJson(e))
          .toList();

      // Get user profile for target weight
      final profileResponse = await supabase
          .from('profiles')
          .select('weight, target_weight, weight_unit')
          .eq('user_id', userId)
          .single();

      _weightProgress = WeightProgress(
        startWeight: entries.isNotEmpty ? entries.first.weight : profileResponse['weight'] ?? 0,
        currentWeight: profileResponse['weight'] ?? 0,
        targetWeight: profileResponse['target_weight'] ?? 0,
        entries: entries,
        unit: profileResponse['weight_unit'] ?? 'kg',
      );

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addWeightEntry(double weight, String? note) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final entry = WeightEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        weight: weight,
        timestamp: DateTime.now(),
        note: note,
      );

      // Save to Supabase
      await supabase.from('weight_entries').insert({
        'user_id': userId,
        'weight': weight,
        'timestamp': entry.timestamp.toIso8601String(),
        'note': note,
      });

      // Update current weight in profile
      await supabase.from('profiles').update({
        'weight': weight,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);

      // Reload data
      await loadWeightData();

    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteWeightEntry(String entryId) async {
    try {
      await supabase
          .from('weight_entries')
          .delete()
          .eq('id', entryId);

      await loadWeightData();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
```

### **Step 5: Database Schema**

```sql
-- Supabase migration for weight tracking

-- Weight entries table
CREATE TABLE IF NOT EXISTS weight_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  weight DECIMAL(5,2) NOT NULL,
  timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
  note TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, timestamp)
);

-- Add index for faster queries
CREATE INDEX idx_weight_entries_user_timestamp
ON weight_entries(user_id, timestamp DESC);

-- Update profiles table if needed
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS target_weight DECIMAL(5,2),
ADD COLUMN IF NOT EXISTS weight_unit VARCHAR(10) DEFAULT 'kg';
```

### **Step 6: Integration into Progress Screen**

```dart
// lib/screens/main/progress_screen_new.dart

// Add to imports
import '../../providers/weight_provider.dart';
import '../../widgets/weight_progress_chart.dart';

// Modify the Consumer to include WeightProvider
Consumer5<UserProvider, NutritionProvider, HealthProvider, StreakProvider, WeightProvider>(
  builder: (context, userProvider, nutritionProvider, healthProvider, streakProvider, weightProvider, child) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildProgressTab(userProvider, nutritionProvider, healthProvider, streakProvider, weightProvider),
        _buildAchievementsTab(userProvider, nutritionProvider, healthProvider, streakProvider),
      ],
    );
  },
)

// Update _buildProgressTab
Widget _buildProgressTab(
  UserProvider userProvider,
  NutritionProvider nutritionProvider,
  HealthProvider healthProvider,
  StreakProvider streakProvider,
  WeightProvider weightProvider,
) {
  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.all(20.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StreakDisplayWidget(isCompact: false),
        const SizedBox(height: 20),

        if (streakProvider.isInGracePeriod)
          _buildGracePeriodWarning(streakProvider),

        Text('Today\'s Summary', ...),
        const SizedBox(height: 20),
        _buildSummarySection(...),
        const SizedBox(height: 32),

        // Weekly Progress Chart
        _buildWeeklyProgressChart(nutritionProvider, healthProvider, streakProvider),
        const SizedBox(height: 32),

        // NEW: Weight Progress Chart
        if (weightProvider.weightProgress != null &&
            weightProvider.weightProgress!.entries.isNotEmpty)
          Column(
            children: [
              WeightProgressChart(
                isCompact: true,
                onTap: () => _navigateToFullWeightView(context),
              ),
              const SizedBox(height: 32),
            ],
          ),

        // Milestone Progress Ring
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: const MilestoneProgressRing(size: 160, strokeWidth: 16),
          ),
        ),
      ],
    ),
  );
}

// Navigation to full weight view
void _navigateToFullWeightView(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => WeightDetailsScreen(),
    ),
  );
}
```

### **Step 7: Removal from Profile Screen**

```dart
// lib/screens/main/profile_screen.dart

// Remove weight progress section
// Delete lines 504-514 (Weight Progress container)

// Add navigation button instead
ListTile(
  leading: Icon(Icons.show_chart, color: AppTheme.primaryAccent),
  title: Text('Weight Progress'),
  subtitle: Text('Track your weight journey'),
  trailing: Icon(Icons.arrow_forward_ios, size: 16),
  onTap: () {
    // Navigate to Progress tab
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => MainScreen(initialIndex: 1), // Progress tab
      ),
      (route) => false,
    );
  },
),
```

---

## 🎨 Visual Design Specifications

### **Chart Colors & Styling**
```dart
// Color scheme
Primary line: AppTheme.primaryAccent (#FF6B1A)
Target line: Colors.green (#48BB78)
Trend line: Colors.blue.withOpacity(0.5)
Grid: AppTheme.borderColor.withOpacity(0.3)
Background: Theme.of(context).cardColor

// Line styles
Actual weight: 3px solid, curved
Target weight: 2px dashed
Trend: 1px dashed, semi-transparent

// Dots
Regular: 3px radius, white center
Today: 5px radius, green border
Hover: Expanded with tooltip
```

### **Responsive Behavior**
```
Phone (< 400px): Compact view, simplified labels
Tablet (> 600px): Full view with all features
Dark mode: Adjusted colors for visibility
```

---

## 📊 Advanced Features

### **1. Quick Add Weight**
```dart
FloatingActionButton(
  mini: true,
  onPressed: () => _showQuickAddDialog(),
  child: Icon(Icons.add),
)
```

### **2. BMI Indicator**
```dart
// Show BMI alongside weight
Text('BMI: ${_calculateBMI()} (${_getBMICategory()})')
```

### **3. Goal Projection**
```dart
// Calculate expected date to reach goal
Text('Goal date: ${_projectGoalDate()}')
```

### **4. Weekly/Monthly Averages**
```dart
// Toggle between daily points and weekly averages
ToggleButtons(
  children: [Text('Daily'), Text('Weekly'), Text('Monthly')],
  onPressed: (index) => setState(() => viewMode = index),
)
```

---

## 🔧 Implementation Timeline

### **Phase 1: Core Migration (Day 1-2)**
- [ ] Create `WeightProvider` class
- [ ] Create `weight_progress_chart.dart` widget
- [ ] Implement basic line chart
- [ ] Add to Progress screen

### **Phase 2: Data Integration (Day 3)**
- [ ] Connect to Supabase
- [ ] Implement data loading
- [ ] Add error handling
- [ ] Test with real data

### **Phase 3: Polish & Features (Day 4-5)**
- [ ] Add touch interactions
- [ ] Implement trend calculation
- [ ] Add quick entry dialog
- [ ] Remove from Profile screen
- [ ] Add navigation links

### **Phase 4: Testing (Day 6)**
- [ ] Test with empty state
- [ ] Test with single entry
- [ ] Test with many entries
- [ ] Test dark mode
- [ ] Test different screen sizes

---

## ⚡ Performance Optimizations

1. **Data Caching**
```dart
// Cache weight data for 5 minutes
static final _cache = TimedCache<WeightProgress>(
  duration: Duration(minutes: 5),
);
```

2. **Lazy Loading**
```dart
// Only load when tab is visible
if (_tabController.index == 0) {
  context.read<WeightProvider>().loadWeightData();
}
```

3. **Chart Optimization**
```dart
// Limit data points for performance
if (entries.length > 365) {
  entries = _sampleDataPoints(entries, maxPoints: 100);
}
```

---

## 🎯 Success Metrics

- Chart loads in < 500ms
- Smooth 60fps scrolling
- Touch response < 100ms
- Data syncs automatically
- No UI jank when switching tabs

---

## ✅ Pre-Implementation Checklist

Before starting:
- [ ] Confirm chart position (below Weekly Progress)
- [ ] Approve visual design
- [ ] Confirm data retention from Profile
- [ ] Decide on advanced features
- [ ] Set up Supabase tables
- [ ] Review with team

**This plan ensures a smooth migration with enhanced visualization while maintaining all existing functionality.**