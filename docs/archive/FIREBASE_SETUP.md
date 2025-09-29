# Firebase Integration Setup Guide

## Overview
This guide will help you set up Firebase services for your Streaks Flutter app, providing analytics, crash reporting, performance monitoring, and push notifications alongside your existing Supabase backend.

## Prerequisites
- Flutter development environment
- Google account for Firebase
- Xcode (for iOS setup)
- Android Studio (for Android setup)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click **Create a project** (or Add project)
3. Enter project name: `Streaks-Flutter` (or your preferred name)
4. Enable Google Analytics when prompted
5. Select or create a Google Analytics account
6. Click **Create project** and wait for it to complete

## Step 2: Configure Firebase for Your Flutter App

### Using FlutterFire CLI (Recommended)

1. Make sure you're in your project directory:
```bash
cd /Users/Vicky/Streaks_Flutter
```

2. Run the FlutterFire configure command:
```bash
flutterfire configure
```

3. Follow the prompts:
   - Select your Firebase project
   - Choose platforms: ✅ Android, ✅ iOS, ✅ Web
   - Enter Android package name (found in `android/app/build.gradle`): Usually `com.example.streaker_flutter`
   - Enter iOS bundle ID (found in Xcode): Usually `com.example.streakerFlutter`

4. The CLI will:
   - Register your apps with Firebase
   - Download configuration files
   - Generate `firebase_options.dart` file
   - Update your project files

### Manual Setup (Alternative)

If FlutterFire CLI doesn't work, follow these manual steps:

#### For Android:
1. In Firebase Console, click **Add app** → **Android**
2. Enter Android package name: `com.example.streaker_flutter`
3. Download `google-services.json`
4. Place it in `android/app/` directory
5. Update `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```
6. Update `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

#### For iOS:
1. In Firebase Console, click **Add app** → **iOS**
2. Enter iOS bundle ID: `com.example.streakerFlutter`
3. Download `GoogleService-Info.plist`
4. Open Xcode: `open ios/Runner.xcworkspace`
5. Drag `GoogleService-Info.plist` into Runner folder
6. Make sure "Copy items if needed" is checked

## Step 3: Update Firebase Configuration

After running `flutterfire configure`, update your imports in `main.dart`:

```dart
import 'firebase_options.dart'; // This file is auto-generated

// In main() function:
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

## Step 4: Configure Firebase Services

### Enable Crashlytics
1. Go to Firebase Console → **Crashlytics**
2. Click **Enable Crashlytics**
3. Follow the setup wizard

### Enable Cloud Messaging
1. Go to Firebase Console → **Cloud Messaging**
2. Note your Server Key and Sender ID for future use

### Enable Performance Monitoring
1. Go to Firebase Console → **Performance**
2. It's automatically enabled with the SDK

## Step 5: Platform-Specific Setup

### iOS Additional Setup

1. Enable Push Notifications capability:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner target
   - Go to **Signing & Capabilities**
   - Click **+ Capability**
   - Add **Push Notifications**
   - Add **Background Modes** and check:
     - Remote notifications
     - Background fetch

2. Update `ios/Runner/Info.plist`:
```xml
<key>FirebaseMessagingAutoInitEnabled</key>
<true/>
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

3. For iOS 10+ notification support, update `ios/Runner/AppDelegate.swift`:
```swift
import UIKit
import Flutter
import Firebase
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    
    // Register for push notifications
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Android Additional Setup

1. Update `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

<!-- Inside <application> tag -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/ic_notification" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/colorAccent" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="streaks_notifications" />
```

2. Create notification icon:
   - Create `android/app/src/main/res/drawable/ic_notification.png`
   - Use a white icon with transparent background
   - Recommended size: 24x24dp

## Step 6: Test Your Integration

### Test Analytics
```dart
// In any screen or widget
FirebaseAnalyticsService().logCustomEvent(
  name: 'test_event',
  parameters: {'test_param': 'test_value'},
);
```
Check Firebase Console → Analytics → DebugView

### Test Crashlytics
```dart
// Add a test crash button (remove in production!)
ElevatedButton(
  onPressed: () {
    FirebaseCrashlytics.instance.crash();
  },
  child: Text('Test Crash'),
)
```

### Test Push Notifications
1. Get your FCM token:
```dart
final token = await NotificationService().getFCMToken();
print('FCM Token: $token');
```

2. Send test message from Firebase Console:
   - Go to **Cloud Messaging**
   - Click **Send your first message**
   - Enter message details
   - Target your app
   - Send

## Step 7: Configure Notification Reminders

In your app settings or after onboarding, enable default reminders:

```dart
// Schedule all default reminders
await NotificationService().scheduleStreakReminder();
await NotificationService().scheduleMorningMotivation();
await NotificationService().scheduleWaterReminder();
await NotificationService().scheduleLunchReminder();
await NotificationService().scheduleWorkoutReminder();
```

## Step 8: Implement Analytics Tracking

Add analytics throughout your app:

```dart
// On sign up
await FirebaseAnalyticsService().logSignUp('email');

// On food added
await FirebaseAnalyticsService().logFoodAdded(
  foodName: 'Apple',
  calories: 95,
  mealType: 'snack',
);

// On streak achievement
await FirebaseAnalyticsService().logStreakAchieved(7);

// On screen views
await FirebaseAnalyticsService().logScreenView('nutrition_screen');
```

## Step 9: Production Configuration

### For App Store/Play Store Release:

1. **Enable Proguard** (Android):
   - In `android/app/build.gradle`:
   ```gradle
   buildTypes {
       release {
           minifyEnabled true
           proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
       }
   }
   ```

2. **Upload dSYM files** (iOS):
   - Enable automatic dSYM upload in Xcode
   - Or manually upload from Firebase Console

3. **Set up APNs certificates** (iOS):
   - Generate APNs certificate in Apple Developer Portal
   - Upload to Firebase Console → Project Settings → Cloud Messaging

## Monitoring Your App

### Analytics Dashboard
- **Real-time**: See active users right now
- **Events**: Track custom events and conversions
- **Audiences**: Create user segments
- **Funnels**: Analyze user journeys

### Crashlytics Dashboard
- **Crash-free rate**: Monitor app stability
- **Issues**: Prioritized list of crashes
- **Velocity alerts**: Get notified of regression

### Performance Dashboard
- **App start time**: Monitor cold/warm starts
- **Screen rendering**: Track slow frames
- **Network requests**: Monitor API latency

### Cloud Messaging Dashboard
- **Campaigns**: Create notification campaigns
- **Analytics**: Track open rates
- **A/B Testing**: Test different messages

## Security Rules

Since we're using Supabase for data, Firebase security is mainly for:
- Analytics data (automatic)
- Crash reports (automatic)
- Performance metrics (automatic)
- FCM tokens (if storing in Firestore)

## Troubleshooting

### Common Issues:

1. **"No Firebase App has been created"**
   - Make sure `Firebase.initializeApp()` is called before using any Firebase service
   - Check that `firebase_options.dart` exists

2. **Push notifications not working on iOS**
   - Verify APNs certificates are uploaded
   - Check Capabilities in Xcode
   - Test on real device (not simulator)

3. **Analytics not showing data**
   - Wait 24 hours for first data
   - Use DebugView for real-time testing
   - Check that events are being logged

4. **Crashlytics not reporting**
   - Force a crash and restart app
   - Check that Crashlytics is enabled in Console
   - Verify dSYM upload (iOS)

## Best Practices

1. **Analytics Events**:
   - Use consistent naming convention
   - Limit to 500 unique event names
   - Keep parameter names under 40 characters

2. **Push Notifications**:
   - Don't over-notify users
   - Allow users to customize frequency
   - Use topics for segmentation

3. **Crashlytics**:
   - Log user IDs (anonymized)
   - Add custom keys for context
   - Use non-fatal logging for handled errors

4. **Performance**:
   - Monitor app start time
   - Track critical user journeys
   - Set up alerts for regression

## Cost Considerations

### Free Tier Limits:
- **Analytics**: Unlimited events
- **Crashlytics**: Unlimited crash reports
- **Cloud Messaging**: Unlimited notifications
- **Performance**: Unlimited monitoring

### When You Might Pay:
- Cloud Functions (if added)
- Cloud Storage (if added)
- Firestore (if you migrate from Supabase)
- Phone Authentication (beyond free tier)

## Next Steps

1. **Test all features** in development
2. **Set up staging environment** in Firebase
3. **Configure production environment** separately
4. **Set up monitoring alerts** for production
5. **Plan notification campaigns** for user engagement

## Integration Checklist

- [ ] Firebase project created
- [ ] FlutterFire CLI configured
- [ ] Firebase initialized in app
- [ ] Analytics working
- [ ] Crashlytics reporting
- [ ] Push notifications working (iOS)
- [ ] Push notifications working (Android)
- [ ] Local notifications scheduled
- [ ] Performance monitoring active
- [ ] Production configuration ready

## Support Resources

- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com)
- [Firebase Status](https://status.firebase.google.com/)
- [Stack Overflow Firebase Tag](https://stackoverflow.com/questions/tagged/firebase)

---

**Note:** Keep your `google-services.json` and `GoogleService-Info.plist` files secure. Add them to `.gitignore` if sharing code publicly.