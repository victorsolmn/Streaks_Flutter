import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/health_metric_model.dart';
import '../utils/app_theme.dart';

class HealthMetricCard extends StatelessWidget {
  final MetricType metricType;
  final HealthMetricSummary? summary;
  final TimePeriod selectedPeriod;
  final Function(TimePeriod) onPeriodChanged;
  final String title;
  final String icon;
  final VoidCallback? onTap;

  const HealthMetricCard({
    super.key,
    required this.metricType,
    this.summary,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.title,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildPeriodChips(context),
            if (summary != null) ...[
              _buildMetricValue(context),
              if (summary!.goalValue != null) _buildProgressBar(context),
              _buildMiniChart(context),
            ] else
              _buildLoadingState(context),
            if (summary?.error != null) _buildErrorState(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          if (summary?.lastSynced != null)
            Icon(
              Icons.sync,
              size: 16,
              color: Colors.grey[600],
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodChips(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: TimePeriod.values.map((period) {
          final isSelected = period == selectedPeriod;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: ChoiceChip(
                label: Text(
                  _getPeriodLabel(period),
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => onPeriodChanged(period),
                selectedColor: AppTheme.primaryAccent,
                backgroundColor: AppTheme.primaryBackground,
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryAccent : AppTheme.borderColor,
                  width: 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricValue(BuildContext context) {
    if (summary == null || summary!.isLoading) {
      return _buildLoadingState(context);
    }

    String displayValue;
    String unit;

    switch (metricType) {
      case MetricType.sleep:
        final hours = summary!.currentValue ~/ 60;
        final minutes = (summary!.currentValue % 60).toInt();
        displayValue = '${hours}h ${minutes}m';
        unit = '';
        break;
      case MetricType.caloriesIntake:
      case MetricType.steps:
        displayValue = summary!.currentValue.toInt().toString();
        unit = metricType == MetricType.caloriesIntake ? ' kcal' : ' steps';
        break;
      case MetricType.restingHeartRate:
        displayValue = summary!.currentValue.toInt().toString();
        unit = ' bpm';
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              displayValue,
              key: ValueKey(displayValue),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          const Spacer(),
          if (summary!.averageValue != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Avg',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  _formatValue(summary!.averageValue!),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    if (summary == null || summary!.goalValue == null) return const SizedBox();

    final progress = summary!.progress;
    final goalAchieved = summary!.goalAchieved;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Goal: ${_formatValue(summary!.goalValue!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
              Text(
                summary!.progressPercentage,
                style: TextStyle(
                  fontSize: 12,
                  color: goalAchieved ? AppTheme.successGreen : AppTheme.primaryAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                goalAchieved ? AppTheme.successGreen : AppTheme.primaryAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChart(BuildContext context) {
    if (summary == null || summary!.dataPoints.isEmpty) {
      return const SizedBox();
    }

    final spots = _generateChartSpots();
    if (spots.isEmpty) return const SizedBox();

    return Container(
      height: 60,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.primaryAccent.withOpacity(0.8),
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryAccent.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateChartSpots() {
    if (summary == null || summary!.dataPoints.isEmpty) return [];

    final points = summary!.dataPoints;
    final spots = <FlSpot>[];

    for (int i = 0; i < points.length && i < 10; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].value));
    }

    return spots;
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.errorRed, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              summary?.error ?? 'Failed to load data',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.errorRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel(TimePeriod period) {
    switch (period) {
      case TimePeriod.daily:
        return 'Daily';
      case TimePeriod.weekly:
        return 'Weekly';
      case TimePeriod.monthly:
        return 'Monthly';
      case TimePeriod.yearly:
        return 'Yearly';
    }
  }

  String _formatValue(double value) {
    switch (metricType) {
      case MetricType.sleep:
        final hours = value ~/ 60;
        final minutes = (value % 60).toInt();
        return '${hours}h ${minutes}m';
      case MetricType.caloriesIntake:
      case MetricType.steps:
      case MetricType.restingHeartRate:
        return value.toInt().toString();
    }
  }
}