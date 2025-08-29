# iOS App Distribution Guide for Streaks Flutter

## Option 1: Firebase App Distribution (Recommended)

### Prerequisites
- Apple Developer Account ($99/year)
- Firebase project setup
- Test devices' UDIDs

### Step 1: Build the IPA file

```bash
# Build release version
cd /Users/Vicky/Streaks_Flutter
flutter build ios --release

# Open Xcode
open ios/Runner.xcworkspace
```

### Step 2: Archive in Xcode
1. In Xcode, select "Any iOS Device" as the build target
2. Go to Product → Archive
3. Wait for the archive to complete
4. In the Archives organizer, select your archive
5. Click "Distribute App"
6. Choose "Ad Hoc" or "Development"
7. Follow the prompts to export the IPA file

### Step 3: Set up Firebase App Distribution

#### Install Firebase App Distribution plugin:
```bash
# If not already installed
firebase login
flutter pub add firebase_app_distribution
```

#### Enable App Distribution in Firebase Console:
1. Go to https://console.firebase.google.com
2. Select your project
3. Click "Release & Monitor" → "App Distribution"
4. Click "Get started"

### Step 4: Upload IPA to Firebase

#### Using Firebase CLI:
```bash
# Install the app distribution plugin
firebase apps:list

# Upload the IPA
firebase appdistribution:distribute /path/to/your/app.ipa \
  --app YOUR_FIREBASE_APP_ID \
  --groups "testers" \
  --release-notes "Latest build of Streaks Flutter"
```

#### Using Fastlane (Alternative):
```ruby
# In ios/fastlane/Fastfile
lane :distribute do
  build_app(scheme: "Runner")
  firebase_app_distribution(
    app: "YOUR_FIREBASE_APP_ID",
    groups: "testers",
    release_notes: "Latest build"
  )
end
```

### Step 5: Add Testers
1. In Firebase Console → App Distribution
2. Click "Testers & Groups"
3. Add tester emails
4. Testers will receive an invitation email

## Option 2: TestFlight (Official Apple)

### Step 1: Build and Archive
```bash
flutter build ios --release
open ios/Runner.xcworkspace
```

### Step 2: Upload to App Store Connect
1. In Xcode Archives, click "Distribute App"
2. Choose "App Store Connect"
3. Upload the build

### Step 3: Configure TestFlight
1. Go to https://appstoreconnect.apple.com
2. Select your app
3. Go to TestFlight tab
4. Add internal or external testers
5. Submit for review (external testers only)

## Option 3: Diawi (Quick & Simple)

### Step 1: Generate IPA
```bash
flutter build ios --release --no-codesign
```

### Step 2: Upload to Diawi
1. Go to https://www.diawi.com
2. Drag and drop your IPA file
3. Get the download link
4. Share with testers (link expires in 72 hours)

## Option 4: Direct Installation via Xcode

### For developers with Xcode access:
```bash
# Connect iPhone via USB
flutter run --release
```

### For testers:
1. Register device UDID in Apple Developer Portal
2. Update provisioning profile
3. Build IPA with device included
4. Install via Xcode or Apple Configurator

## Building IPA from Command Line

### Quick build script:
```bash
#!/bin/bash
# Save as build_ios.sh

echo "Building Flutter iOS app..."
flutter clean
flutter pub get
flutter build ios --release

echo "Creating IPA..."
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  archive

xcodebuild -exportArchive \
  -archivePath build/Runner.xcarchive \
  -exportPath build/ipa \
  -exportOptionsPlist ExportOptions.plist

echo "IPA created at: ios/build/ipa/Runner.ipa"
```

## Current Status

The app is ready for distribution but needs:
1. ✅ Code signing certificate (Apple Developer Account)
2. ✅ Provisioning profiles for test devices
3. ✅ Firebase App Distribution setup or TestFlight configuration

## Important Notes

- **Device Limit**: Ad Hoc distribution limited to 100 devices per year
- **TestFlight**: Best for large-scale beta testing (up to 10,000 testers)
- **Firebase**: Best for quick iterations with small test groups
- **Expiration**: Ad Hoc builds expire after 90 days

## Troubleshooting

### Common Issues:
1. **Code signing errors**: Ensure proper certificates in Xcode
2. **Device not authorized**: Add UDID to provisioning profile
3. **Build failures**: Check Flutter doctor and Xcode settings
4. **Firebase upload fails**: Verify app ID and authentication

### To Get Device UDID:
- Connect device to Mac
- Open Xcode → Window → Devices and Simulators
- Copy the identifier

## Next Steps

1. Choose your distribution method
2. Set up Apple Developer Account (if needed)
3. Configure code signing in Xcode
4. Build and distribute your app

For Firebase App Distribution specifically:
- Run: `firebase login` in terminal
- Enable App Distribution in Firebase Console
- Follow the upload steps above