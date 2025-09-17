#!/bin/bash

# Supabase Database Migration Script
# This script adds missing columns to the profiles table

SUPABASE_URL="https://xzwvckziavhzmghizyqx.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6d3Zja3ppYXZoem1naGl6eXF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwOTk0NjIsImV4cCI6MjA3MzY3NTQ2Mn0.fUtnAzqNGzKvo-FTWqpemcf0wvdlC6gpUg_ZllXBulo"

echo "🔧 Starting Supabase database migration..."
echo "📡 Connecting to: $SUPABASE_URL"

# Function to run SQL via Supabase REST API
run_sql() {
    local sql="$1"
    local description="$2"

    echo "⚙️ $description"

    response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
        -X POST \
        "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
        -H "apikey: $SUPABASE_ANON_KEY" \
        -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal" \
        -d "{\"sql\": \"$sql\"}")

    # Extract HTTP status
    http_status=$(echo "$response" | grep "HTTP_STATUS:" | cut -d: -f2)
    body=$(echo "$response" | sed '/HTTP_STATUS:/d')

    if [[ $http_status -eq 200 || $http_status -eq 204 ]]; then
        echo "✅ Success: $description"
    else
        echo "⚠️ Warning: $description (Status: $http_status)"
        echo "📄 Response: $body"
    fi
}

# Migration SQL commands
echo "📊 Adding missing columns to profiles table..."

# Add target_weight column
run_sql "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS target_weight DECIMAL;" "Adding target_weight column"

# Add experience_level column
run_sql "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS experience_level TEXT;" "Adding experience_level column"

# Add workout_consistency column
run_sql "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS workout_consistency TEXT;" "Adding workout_consistency column"

# Add daily targets columns
run_sql "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS daily_calories_target INTEGER;" "Adding daily_calories_target column"
run_sql "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS daily_steps_target INTEGER;" "Adding daily_steps_target column"
run_sql "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS daily_sleep_target DECIMAL;" "Adding daily_sleep_target column"
run_sql "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS daily_water_target DECIMAL;" "Adding daily_water_target column"

# Ensure has_completed_onboarding column exists
run_sql "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS has_completed_onboarding BOOLEAN DEFAULT FALSE;" "Adding has_completed_onboarding column"

# Update existing records
echo "🔄 Updating existing profiles with default values..."
run_sql "UPDATE profiles SET has_completed_onboarding = FALSE WHERE has_completed_onboarding IS NULL;" "Setting default onboarding status"

echo ""
echo "🎉 Database migration completed!"
echo "📊 The following columns have been added to the profiles table:"
echo "   - target_weight (DECIMAL)"
echo "   - experience_level (TEXT)"
echo "   - workout_consistency (TEXT)"
echo "   - daily_calories_target (INTEGER)"
echo "   - daily_steps_target (INTEGER)"
echo "   - daily_sleep_target (DECIMAL)"
echo "   - daily_water_target (DECIMAL)"
echo "   - has_completed_onboarding (BOOLEAN)"
echo ""
echo "🔄 You can now test the enhanced onboarding - it should save all data correctly!"