# Streaker App

A comprehensive health and fitness tracking Flutter application with real-time health data integration.

## Features

- **Unified OTP Authentication** - Passwordless login with 6-digit codes
- **Health Data Integration** - Samsung Health, Google Fit, Apple HealthKit
- **Nutrition Tracking** - AI food recognition, barcode scanning, Indian food database
- **Achievement & Streak System** - Dynamic achievements, streak tracking
- **Profile Management** - Photo upload, complete profile editing

## Tech Stack

- **Framework**: Flutter 3.35.3
- **Backend**: Supabase
- **State Management**: Provider pattern (MVVM architecture)
- **UI**: Material Design 3

## Project Structure

```
lib/
├── screens/       # UI screens
├── providers/     # State management
├── services/      # Business logic
├── models/        # Data models
├── utils/         # Utilities
└── widgets/       # Reusable components
```

## Getting Started

1. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

## Build

- **iOS**: `./build_ios_ipa.sh`
- **Android**: `flutter build apk`
- **Distribution**: `./build_and_distribute.sh`

## Documentation

All documentation has been organized in the `docs/` folder.

## Version

Current version: 1.0.4