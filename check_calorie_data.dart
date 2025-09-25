import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://xzwvckziavhzmghizyqx.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6d3Zja3ppYXZoem1naGl6eXF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwOTk0NjIsImV4cCI6MjA3MzY3NTQ2Mn0.fUtnAzqNGzKvo-FTWqpemcf0wvdlC6gpUg_ZllXBulo',
  );

  try {
    // Get user ID for victorsolmn@gmail.com
    final userResponse = await supabase
        .from('profiles')
        .select('id')
        .eq('email', 'victorsolmn@gmail.com')
        .single();

    final userId = userResponse['id'];
    print('User ID: $userId');

    // Get health metrics for last 3 days
    final now = DateTime.now();
    final threeDaysAgo = now.subtract(Duration(days: 3));

    final healthResponse = await supabase
        .from('health_metrics')
        .select()
        .eq('user_id', userId)
        .gte('date', threeDaysAgo.toIso8601String().split('T')[0])
        .order('date', ascending: false)
        .order('updated_at', ascending: false);

    print('\n=== Health Metrics for last 3 days ===');
    for (var metric in healthResponse) {
      print('\nDate: ${metric['date']}');
      print('Calories Burned: ${metric['calories_burned']}');
      print('Steps: ${metric['steps']}');
      print('Updated At: ${metric['updated_at']}');
    }

    // Check today's specific data
    final todayStr = now.toIso8601String().split('T')[0];
    final todayResponse = await supabase
        .from('health_metrics')
        .select()
        .eq('user_id', userId)
        .eq('date', todayStr)
        .maybeSingle();

    if (todayResponse != null) {
      print('\n=== TODAY\'S DATA ($todayStr) ===');
      print('Calories: ${todayResponse['calories_burned']}');
      print('Steps: ${todayResponse['steps']}');
      print('Heart Rate: ${todayResponse['heart_rate']}');
      print('Sleep: ${todayResponse['sleep_hours']}');
      print('Updated: ${todayResponse['updated_at']}');
    } else {
      print('\nNo data found for today ($todayStr)');
    }

  } catch (e) {
    print('Error: $e');
  }
}