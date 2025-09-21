# Streaks Flutter App - Knowledge Base

## Project Overview
Streaks Flutter is a comprehensive health and fitness tracking application that integrates with Samsung Health and Google Fit to provide users with real-time health metrics, nutrition tracking, and achievement systems.

## Recent Critical Fixes (September 2025)

### 1. UI Overflow Issue Fix
**Problem:** Persistent 6.8px right overflow next to steps progress circle on Samsung devices (720x1544 resolution)

**Solution:**
- Replaced rigid Row layout with Flexible widgets
- Used `MainAxisAlignment.spaceEvenly` for better distribution
- Added horizontal padding and proper constraints
- Reduced icon sizes (24px → 20px) and font sizes
- Implemented `TextOverflow.ellipsis` for long text
- Changed from fixed widths to responsive design

**Key Code Location:** `/lib/screens/main/home_screen_clean.dart:362-480`

### 2. Nutrition Duplicate Entries Fix
**Problem:** Nutrition entries were being duplicated on every app sync/restart

**Root Cause:** `saveNutritionEntry` was using `.insert()` without checking for existing entries

**Solution:**
- Added duplicate detection before insertion
- Check for existing entries within 5-second timestamp window
- Pass timestamp through sync process for proper deduplication
- Modified `/lib/services/supabase_service.dart:189-238`
- Updated `/lib/providers/nutrition_provider.dart:355-364`

### 3. Health Data Sync Issues
**Problem:** Steps showing 0 in Supabase after app restart

**Solutions Implemented:**
- Changed initial values from 0 to -1 to track unloaded state
- Added validation to prevent saving uninitialized data
- Load Supabase data BEFORE initializing health services
- Implemented native Android deduplication for proper step counting
- Samsung Health now properly prioritized over Google Fit
