import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:streaks_flutter/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Chat feature end-to-end test', (WidgetTester tester) async {
    // Start the app
    app.main();
    await tester.pumpAndSettle();

    print('🧪 Testing Chat Feature End-to-End...\n');

    // Navigate to chat screen (4th tab - Workouts)
    print('📱 Step 1: Navigating to Chat screen...');
    final workoutTab = find.byIcon(Icons.fitness_center_outlined);
    expect(workoutTab, findsOneWidget);
    await tester.tap(workoutTab);
    await tester.pumpAndSettle();
    print('✅ Navigated to Chat screen\n');

    // Check if welcome screen is displayed
    print('👀 Step 2: Verifying welcome screen...');
    final hiText = find.textContaining('Hi,');
    expect(hiText, findsOneWidget);
    print('✅ Welcome screen displayed\n');

    // Test quick prompt - Workout Plan
    print('💬 Step 3: Testing quick prompt...');
    final workoutPrompt = find.text('Workout Plan');
    if (workoutPrompt.evaluate().isNotEmpty) {
      await tester.tap(workoutPrompt);
      await tester.pumpAndSettle();
      print('✅ Tapped Workout Plan prompt\n');

      // Wait for AI response
      print('⏳ Step 4: Waiting for AI response...');
      await tester.pump(Duration(seconds: 3));

      // Look for typing indicator
      final thinkingIndicator = find.text('Thinking...');
      if (thinkingIndicator.evaluate().isNotEmpty) {
        print('✅ AI is processing request\n');
      }

      // Wait for response to complete
      await tester.pumpAndSettle(Duration(seconds: 5));
    }

    // Test manual message input
    print('⌨️ Step 5: Testing manual message input...');
    final textField = find.byType(TextField);
    if (textField.evaluate().isNotEmpty) {
      await tester.enterText(textField, 'What exercises help with weight loss?');
      await tester.pump();

      // Find and tap send button
      final sendButton = find.byIcon(Icons.send);
      await tester.tap(sendButton);
      await tester.pumpAndSettle();
      print('✅ Sent manual message\n');

      // Wait for response
      await tester.pump(Duration(seconds: 3));
      await tester.pumpAndSettle(Duration(seconds: 5));
    }

    // Test ending session
    print('💾 Step 6: Testing session save...');
    final saveButton = find.byIcon(Icons.save_alt);
    if (saveButton.evaluate().isNotEmpty) {
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      print('✅ Initiated session save\n');

      // Wait for save to complete
      await tester.pump(Duration(seconds: 3));

      // Check for success message
      final successSnackbar = find.text('Chat session saved successfully!');
      if (successSnackbar.evaluate().isNotEmpty) {
        print('✅ Session saved successfully!\n');
      }
    }

    // Test history view
    print('📜 Step 7: Testing history view...');
    final historyButton = find.byIcon(Icons.history);
    if (historyButton.evaluate().isNotEmpty) {
      await tester.tap(historyButton);
      await tester.pumpAndSettle();
      print('✅ Opened history panel\n');

      // Check if history items are displayed
      final historyItems = find.textContaining('messages');
      if (historyItems.evaluate().isNotEmpty) {
        print('✅ History items displayed\n');
      }

      // Close history panel
      final closeButton = find.byIcon(Icons.close);
      await tester.tap(closeButton.first);
      await tester.pumpAndSettle();
    }

    print('🎉 Chat Feature Test Complete!');
  });
}