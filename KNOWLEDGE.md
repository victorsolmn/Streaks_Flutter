# Streaks Flutter - Project Knowledge Base

## Project Overview
**Project Name:** Streaker Flutter  
**Description:** A comprehensive fitness tracking application built with Flutter that helps users monitor their health metrics, nutrition, and maintain fitness streaks with AI-powered personalized coaching.  
**Repository:** https://github.com/victorsolmn/Streaks_Flutter.git  
**Version:** 1.0.0+1  
**Flutter SDK:** 3.35.2 (Dart 3.9.0)  
**Last Updated:** September 12, 2025

## Current App Status

### Latest Release Build
- **APK Built:** September 12, 2025
- **File Size:** 59.0MB
- **Location:** `build/app/outputs/flutter-apk/app-release.apk`
- **Features:** Complete fitness tracking with AI chat, health integration, nutrition tracking, and streak system

### Technology Stack
- **Frontend:** Flutter 3.35.2
- **Backend:** Supabase (PostgreSQL)
- **Authentication:** Supabase Auth (Email/Password + Google OAuth)
- **AI Integration:** Grok API via X.AI
- **Health Data:** Native Health Connect (Android), Apple Health (iOS)
- **State Management:** Provider pattern
- **Local Storage:** SharedPreferences + Flutter Secure Storage
- **Image Processing:** Camera + ImagePicker plugins

## Authentication Journey & Lessons Learned

### Initial Requirement
- Replace email/password authentication with email OTP for better UX
- Add Google SSO as an alternative login method
- Maintain existing user data and app functionality

### Technical Challenges Faced

#### 1. Email OTP Implementation Issues
**Problem**: Supabase was sending magic links instead of OTP codes despite configuration attempts
- **Root Cause**: SMTP configuration issues with Supabase's built-in email service
- **Attempted Solutions**:
  - Multiple Supabase dashboard configurations
  - Custom email templates
  - SendGrid SMTP integration
  - Direct API testing with custom scripts
  
**Result**: Persistent 500 errors - "Error sending magic link email"

#### 2. Magic Link vs OTP Confusion
- Supabase's `signInWithOtp()` method actually sends magic links by default
- True OTP requires custom email templates and additional configuration
- The distinction between magic links and OTP codes wasn't clear in documentation

#### 3. SMTP Configuration Complexity
**SendGrid Setup Attempted**:
```
Host: smtp.sendgrid.net
Port: 587
Username: apikey (literal string)
Password: [SendGrid API Key]
```
- Even with proper credentials, email delivery failed
- Supabase's email integration has undocumented quirks

### Final Solution: Password Authentication
After extensive debugging, switched back to traditional email/password authentication:
- More reliable and predictable
- Better error handling
- No external dependencies
- Works consistently across platforms

### Google OAuth Integration
**Successfully Implemented**:
- Client ID: [REDACTED].apps.googleusercontent.com
- Redirect URI: com.streaker.streaker://callback
- Works seamlessly on both iOS and Android
- Proper deep linking configuration required

## Key Implementation Files

### Authentication Provider
`lib/providers/supabase_auth_provider.dart`
- Central authentication state management
- Handles sign up, sign in, Google OAuth
- User session management
- Error handling and loading states

### Authentication Screens
- `lib/screens/auth/signin_screen.dart` - Login interface
- `lib/screens/auth/signup_screen.dart` - Registration with password
- `lib/screens/auth/otp_verification_screen.dart` - Legacy OTP verification (deprecated)

## Critical Lessons Learned

1. **Email Service Complexity**: Third-party email services have hidden complexities
2. **Magic Links vs OTP**: Understand the distinction
3. **Authentication Flexibility**: Always implement multiple auth methods
4. **Error Handling**: Comprehensive error handling is crucial
5. **Testing Strategy**: Test authentication flows early and often
