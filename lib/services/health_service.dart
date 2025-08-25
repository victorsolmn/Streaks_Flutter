// Health service temporarily disabled for build compatibility
class HealthService {
  static Future<void> requestAuthorization() async {
    // Temporarily disabled
  }
  
  Future<List<dynamic>> getMetrics(DateTime startDate, DateTime endDate) async {
    return [];
  }
}