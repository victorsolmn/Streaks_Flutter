import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/weight_model.dart';
import 'package:intl/intl.dart';

class WeightProgressCard extends StatelessWidget {
  final WeightProgress weightProgress;
  final VoidCallback onTap;

  const WeightProgressCard({
    Key? key,
    required this.weightProgress,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weight Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeightColumn('Start', weightProgress.startWeight, Colors.grey),
                _buildWeightColumn('Current', weightProgress.currentWeight, const Color(0xFF6C63FF)),
                _buildWeightColumn('Target', weightProgress.targetWeight, const Color(0xFF10B981)),
              ],
            ),
            const SizedBox(height: 20),
            _buildProgressBar(),
            const SizedBox(height: 12),
            Center(
              child: Text(
                weightProgress.progressText,
                style: TextStyle(
                  fontSize: 14,
                  color: weightProgress.isGoalAchieved 
                    ? const Color(0xFF10B981)
                    : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightColumn(String label, double weight, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${weight.toStringAsFixed(1)} ${weightProgress.unit}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${weightProgress.progressPercentage.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C63FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: weightProgress.progress,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              weightProgress.isGoalAchieved 
                ? const Color(0xFF10B981)
                : const Color(0xFF6C63FF),
            ),
          ),
        ),
      ],
    );
  }
}

class WeightChartView extends StatelessWidget {
  final WeightProgress weightProgress;
  final Function(WeightEntry) onDeleteEntry;

  const WeightChartView({
    Key? key,
    required this.weightProgress,
    required this.onDeleteEntry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sortedEntries = List<WeightEntry>.from(weightProgress.entries)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Column(
      children: [
        Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: sortedEntries.isEmpty 
            ? _buildEmptyChart()
            : _buildChart(sortedEntries),
        ),
        const SizedBox(height: 20),
        _buildEntryList(sortedEntries),
      ],
    );
  }

  Widget _buildEmptyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 48,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No weight entries yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first weight entry to see the chart',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<WeightEntry> entries) {
    final minWeight = entries.map((e) => e.weight).reduce((a, b) => a < b ? a : b) - 2;
    final maxWeight = entries.map((e) => e.weight).reduce((a, b) => a > b ? a : b) + 2;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < entries.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MM/dd').format(entries[index].timestamp),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: entries.length - 1.0,
        minY: minWeight,
        maxY: maxWeight,
        lineBarsData: [
          LineChartBarData(
            spots: entries.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.weight);
            }).toList(),
            isCurved: true,
            color: const Color(0xFF6C63FF),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: const Color(0xFF6C63FF),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF6C63FF).withOpacity(0.1),
            ),
          ),
          // Target weight line
          LineChartBarData(
            spots: [
              FlSpot(0, weightProgress.targetWeight),
              FlSpot(entries.length - 1.0, weightProgress.targetWeight),
            ],
            isCurved: false,
            color: const Color(0xFF10B981),
            barWidth: 2,
            isStrokeCapRound: true,
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryList(List<WeightEntry> entries) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Weight History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3142),
              ),
            ),
          ),
          const Divider(height: 1),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No entries yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            ...entries.reversed.take(10).map((entry) => _buildEntryItem(entry)),
        ],
      ),
    );
  }

  Widget _buildEntryItem(WeightEntry entry) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => onDeleteEntry(entry),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.weight.toStringAsFixed(1)} ${weightProgress.unit}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.formattedDateTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (entry.note != null && entry.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.note!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}