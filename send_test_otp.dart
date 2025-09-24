import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  print('🚀 Sending OTP to victorsolmn@gmail.com...\n');

  final url = Uri.parse('https://xzwvckziavhzmghizyqx.supabase.co/auth/v1/otp');

  final headers = {
    'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6d3Zja3ppYXZoem1naGl6eXF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwOTk0NjIsImV4cCI6MjA3MzY3NTQ2Mn0.fUtnAzqNGzKvo-FTWqpemcf0wvdlC6gpUg_ZllXBulo',
    'Content-Type': 'application/json',
  };

  final body = json.encode({
    'email': 'victorsolmn@gmail.com',
    'create_user': true,
    'data': {},
  });

  try {
    print('📧 Attempting to send OTP to: victorsolmn@gmail.com');
    print('⏳ Please wait...\n');

    final response = await http.post(
      url,
      headers: headers,
      body: body,
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}\n');

    if (response.statusCode == 200) {
      print('✅ SUCCESS! OTP email sent to victorsolmn@gmail.com');
      print('📬 Please check your inbox (and spam folder)');
      print('⏰ The code will expire in 60 minutes');
      print('\nThe email should contain a 6-digit verification code.');
    } else if (response.statusCode == 429) {
      print('⚠️  Rate limited - too many OTP requests');
      print('Please wait a few minutes before trying again');
    } else if (response.statusCode == 400) {
      final error = json.decode(response.body);
      if (error['msg']?.contains('Email logins are disabled') ?? false) {
        print('❌ Email logins might still be disabled');
        print('Please verify the "Confirm email" toggle is ON in Supabase dashboard');
      } else {
        print('❌ Error: ${error['msg'] ?? error['message'] ?? 'Unknown error'}');
      }
    } else {
      print('❌ Failed to send OTP');
      print('Error details: ${response.body}');
    }
  } catch (e) {
    print('❌ Error sending OTP: $e');
    print('\nTroubleshooting:');
    print('1. Check your internet connection');
    print('2. Verify Supabase project is active');
    print('3. Ensure email provider is enabled in dashboard');
  }

  print('\n========================================');
  print('Test complete!');
}