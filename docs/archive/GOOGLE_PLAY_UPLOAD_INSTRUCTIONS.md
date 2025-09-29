# Google Play Console - Internal Testing Upload Instructions

## Release Details
- **Version:** 1.0.1 (Build #2)
- **AAB File Location:** `/Users/Vicky/Streaks_Flutter/build/app/outputs/bundle/release/app-release.aab`
- **File Size:** 49.2MB
- **Build Date:** 2025-09-19
- **Signing:** ✅ Properly signed with release key (not debug)

## What's New in This Release
- Added test data for 5 user personas (Elite Athlete, Busy Professional, Weekend Warrior, New Beginner, Comeback Hero)
- Updated user achievements based on streak levels
- Fixed onboarding back button functionality
- Integrated comprehensive nutrition entries and streak data

## Upload Steps

### 1. Access Google Play Console
1. Go to [Google Play Console](https://play.google.com/console)
2. Sign in with your developer account
3. Select your app "Streaker Flutter" (or create it if not yet created)

### 2. Navigate to Internal Testing
1. In the left menu, go to **Release** → **Testing** → **Internal testing**
2. Click on **Create new release** or **Manage** if you already have an internal testing track

### 3. Upload the AAB File
1. Click **Upload** button
2. Navigate to: `/Users/Vicky/Streaks_Flutter/build/app/outputs/bundle/release/`
3. Select `app-release.aab` (49.2MB)
4. Wait for the upload to complete

### 4. Add Release Notes
Copy and paste these release notes:

```
Version 1.0.1 (Build 2) - Internal Testing Release

What's New:
• Test data integration for 5 user personas
• Enhanced user achievements system
• Fixed onboarding navigation
• Improved nutrition tracking functionality

Test Focus Areas:
• User onboarding flow
• Nutrition entry creation
• Streak tracking
• Achievement unlocking
• Profile management
```

### 5. Configure Testing
1. **Testers**: Add tester email addresses or use existing tester lists
2. **Countries/Regions**: Select your target regions for testing
3. **Review and Rollout**: Click **Review release** then **Start rollout to Internal testing**

### 6. Share Testing Link
After rollout:
1. Copy the internal testing link from the console
2. Share with your testers (they need to be in your tester list)
3. Testers can join via the link and download from Play Store

## Testing Checklist
- [ ] Test with all 5 user personas
- [ ] Verify nutrition entry functionality
- [ ] Check streak calculations
- [ ] Validate achievement unlocking
- [ ] Test onboarding back navigation
- [ ] Verify Supabase data synchronization

## Quick Access via Terminal
To open the AAB file location directly:
```bash
open /Users/Vicky/Streaks_Flutter/build/app/outputs/bundle/release/
```

## Next Steps After Upload
1. Monitor crash reports in Play Console
2. Review tester feedback
3. Fix any critical issues before promoting to closed/open testing
4. Consider incrementing version for production release

## Support
If you encounter any issues during upload:
1. Ensure you're signed in with the correct Google developer account
2. Verify the app package name matches your Play Console app
3. Check that the version code (2) is higher than any previous releases