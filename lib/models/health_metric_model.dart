enum MetricType { steps, caloriesIntake, sleep, restingHeartRate }

class HealthMetric {
  final double value;
  final DateTime timestamp;
  final MetricType type;
  final double? currentValue;
  final double? goalValue;

  HealthMetric({
    required this.value,
    required this.timestamp,
    required this.type,
    this.currentValue,
    this.goalValue,
  });
}