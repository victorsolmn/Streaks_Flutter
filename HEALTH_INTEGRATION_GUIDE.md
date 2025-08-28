# Health Data Integration Guide - Streaks Flutter

## Overview
The Streaks Flutter app now features a comprehensive cross-platform health data integration that automatically syncs with existing health apps and smartwatches.

## Supported Data Sources

### iOS (Apple Devices)
- **Apple Health (HealthKit)** - Primary source for iOS devices
- **Apple Watch** - Data synced via Apple Health
- **Bluetooth LE devices** - Direct connection fallback

### Android Devices
- **Health Connect** - Google's unified health platform
- **Samsung Health** - Via Health Connect integration
- **Google Fit** - Via Health Connect integration
- **Bluetooth LE devices** - Direct connection fallback

## How It Works

### Automatic Detection
The app automatically detects the best available health data source:
1. **Platform health APIs first** (Apple Health/Health Connect)
2. **Bluetooth devices second** (if no health app connection)
3. **Manual entry last** (if no data source available)

### No Disconnection Required
- Your Samsung Watch can remain connected to Samsung Health
- Your Apple Watch stays connected to Apple Health
- The app reads data from these health apps directly
- No need to disconnect and reconnect devices

## Features

### Health Data Synced
- **Steps** - Daily step count
- **Heart Rate** - Latest heart rate readings
- **Calories** - Active and basal calories burned
- **Distance** - Walking/running distance
- **Sleep** - Sleep duration and quality
- **Water** - Hydration tracking
- **Weight** - Latest weight measurements
- **Blood Oxygen** - SpO2 levels
- **Blood Pressure** - Systolic/diastolic readings
- **Workouts** - Exercise sessions
- **Active Minutes** - Exercise time

### Visual Indicators
The app shows your current health data source with visual indicators:
- 🍎 Apple Health (iOS)
- 🤖 Health Connect/Samsung Health (Android)
- ⌚ Bluetooth Device (Direct connection)
- ❌ No Source (Tap to connect)

### Sync Status
- **Green cloud ✓** - Synced and up-to-date
- **Blue sync icon** - Currently syncing
- **Orange warning** - Connection needed
- **Badge count** - Number of pending sync operations

## Setup Instructions

### For iOS Users

1. **First Launch**
   - The app will automatically request HealthKit permissions
   - Tap "Allow" to grant access to health data
   - Select which data types to share

2. **Apple Watch Users**
   - Ensure your Apple Watch is paired with your iPhone
   - Data will sync automatically via Apple Health
   - No additional setup required

### For Android Users

1. **Install Health Connect** (if not already installed)
   - Open Google Play Store
   - Search for "Health Connect"
   - Install the app from Google

2. **First Launch**
   - The app will request Health Connect permissions
   - Tap "Allow" to grant access
   - Select which data types to share

3. **Samsung Galaxy Watch Users**
   - Keep your watch connected to Samsung Health
   - Ensure Samsung Health syncs with Health Connect:
     - Open Samsung Health
     - Go to Settings → Connected Services
     - Enable Health Connect sync
   - Data will flow: Watch → Samsung Health → Health Connect → Streaks

4. **Other Android Smartwatches**
   - Ensure your device's health app syncs with Health Connect
   - Or use Bluetooth direct connection as fallback

## Troubleshooting

### "No health data showing"
1. Check permissions in device settings
2. Ensure health apps are installed and running
3. Try manual sync by tapping the health source indicator

### "Samsung Watch not detected"
- Your watch doesn't need to be detected directly
- Data flows through Samsung Health → Health Connect
- Check Samsung Health is syncing properly

### "Sync not working"
1. iOS: Check Settings → Privacy → Health → Streaker
2. Android: Check Settings → Apps → Health Connect → App Permissions
3. Ensure internet connection for cloud sync

### "Want to use Bluetooth instead"
1. Tap the health source indicator
2. Select "Use Bluetooth Instead"
3. Follow device pairing instructions
4. Note: Health app integration is recommended for better battery life

## Privacy & Security

- Health data is stored locally on your device
- Cloud sync uses encrypted connections
- You control which data types to share
- Revoke permissions anytime in device settings

## Benefits of This Approach

### Better Battery Life
- No continuous Bluetooth scanning
- Uses existing health app connections
- Syncs periodically instead of constantly

### Richer Data
- Access to historical health data
- More accurate measurements
- Aggregated data from multiple sources

### Seamless Experience
- No device switching required
- Works with your existing setup
- Automatic background sync

## Technical Details

### Data Flow Architecture
```
Smartwatch → Platform Health App → Streaks App
     ↓              ↓                    ↓
  Samsung       Health Connect     Local Storage
   Health        /HealthKit             ↓
                                   Supabase Cloud
```

### Sync Frequency
- **Automatic sync**: Every 5 minutes when app is open
- **Background sync**: Periodic when app is in background
- **Manual sync**: Tap sync button anytime
- **Real-time sync**: For Bluetooth connections

### Supported Devices
- **iOS**: iPhone 8+ with iOS 13+
- **Android**: Android 8+ with Health Connect support
- **Smartwatches**: Any device that syncs with platform health apps

## FAQ

**Q: Do I need to disconnect my watch from Samsung Health?**
A: No! Keep your watch connected. The app reads data from Samsung Health.

**Q: Will this drain my battery?**
A: No, it's more efficient than direct Bluetooth connections.

**Q: Can I use multiple data sources?**
A: The app automatically selects the best available source.

**Q: Is my health data secure?**
A: Yes, data is encrypted and stored locally with optional cloud backup.

**Q: What if I don't have a smartwatch?**
A: The app works with phone sensors and manual entry too.

## Support

For issues or questions about health integration:
1. Check the troubleshooting section above
2. Ensure all apps are updated
3. Contact support with your device model and iOS/Android version

---

*Last Updated: August 2025*
*Version: 1.0.0*