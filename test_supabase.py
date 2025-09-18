#!/usr/bin/env python3
import requests
import json
import time

# Supabase configuration
SUPABASE_URL = "https://xzwvckziavhzmghizyqx.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6d3Zja3ppYXZoem1naGl6eXF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwOTk0NjIsImV4cCI6MjA3MzY3NTQ2Mn0.fUtnAzqNGzKvo-FTWqpemcf0wvdlC6gpUg_ZllXBulo"

def test_supabase_config():
    print("🔍 Testing Supabase Configuration\n")
    print("=" * 50)

    # Create test credentials
    test_email = f"test{int(time.time())}@example.com"
    test_password = "TestPassword123!"

    print(f"Test Email: {test_email}\n")

    # 1. Test Signup
    print("1️⃣ Testing Signup...")
    signup_url = f"{SUPABASE_URL}/auth/v1/signup"
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Content-Type": "application/json"
    }
    signup_data = {
        "email": test_email,
        "password": test_password
    }

    signup_response = requests.post(signup_url, json=signup_data, headers=headers)
    signup_result = signup_response.json()

    if signup_response.status_code == 200:
        print("   ✅ Signup successful!")
        user_id = signup_result.get("user", {}).get("id")
        print(f"   User ID: {user_id}")
    else:
        print(f"   ❌ Signup failed: {signup_result}")
        return

    # 2. Test immediate signin
    print("\n2️⃣ Testing Immediate Sign In...")
    signin_url = f"{SUPABASE_URL}/auth/v1/token?grant_type=password"
    signin_data = {
        "email": test_email,
        "password": test_password
    }

    signin_response = requests.post(signin_url, json=signin_data, headers=headers)

    if signin_response.status_code == 200:
        signin_result = signin_response.json()
        print("   ✅ Sign in successful! Session created.")
        print("   🎉 EMAIL CONFIRMATION IS DISABLED!")
        access_token = signin_result.get("access_token", "")[:50] + "..."
        print(f"   Access Token: {access_token}")

        # Store for later use
        auth_headers = {
            "apikey": SUPABASE_ANON_KEY,
            "Authorization": f"Bearer {signin_result.get('access_token')}",
            "Content-Type": "application/json"
        }
    else:
        signin_result = signin_response.json()
        if "email_not_confirmed" in str(signin_result):
            print("   ❌ EMAIL CONFIRMATION STILL REQUIRED!")
            print(f"   Error: {signin_result}")
        else:
            print(f"   ❌ Sign in failed: {signin_result}")
        return

    # 3. Test profile creation
    print("\n3️⃣ Testing Profile Operations...")
    profile_url = f"{SUPABASE_URL}/rest/v1/profiles"

    # Check if profile exists
    check_url = f"{profile_url}?id=eq.{user_id}"
    check_response = requests.get(check_url, headers=auth_headers)

    if check_response.status_code == 200:
        profiles = check_response.json()
        if profiles:
            print("   ✅ Profile exists (created by trigger)")
        else:
            print("   ⚠️ No profile found")

    # 4. Test updating profile with user data
    print("\n4️⃣ Testing Profile Update with User Data...")
    profile_data = {
        "id": user_id,
        "email": test_email,
        "name": "Test User",
        "age": 25,
        "height": 175.5,
        "weight": 70.0,
        "activity_level": "Moderately Active",
        "fitness_goal": "Lose Weight",
        "experience_level": "Intermediate",
        "workout_consistency": "1-2 years",
        "daily_calories_target": 2200,
        "daily_steps_target": 10000,
        "has_completed_onboarding": True
    }

    upsert_url = f"{profile_url}?on_conflict=id"
    upsert_response = requests.post(upsert_url, json=profile_data, headers=auth_headers)

    if upsert_response.status_code in [200, 201]:
        print("   ✅ Profile updated successfully with user data!")
    else:
        error = upsert_response.json()
        if "null value in column" in str(error):
            print(f"   ❌ NOT NULL constraints still active: {error}")
        else:
            print(f"   ❌ Profile update failed: {error}")

    # 5. Verify the data was saved
    print("\n5️⃣ Verifying Saved Data...")
    verify_response = requests.get(check_url, headers=auth_headers)
    if verify_response.status_code == 200:
        saved_profile = verify_response.json()
        if saved_profile:
            profile = saved_profile[0]
            print("   ✅ Profile data retrieved:")
            print(f"      Name: {profile.get('name')}")
            print(f"      Age: {profile.get('age')}")
            print(f"      Height: {profile.get('height')}")
            print(f"      Weight: {profile.get('weight')}")
            print(f"      Goal: {profile.get('fitness_goal')}")

    print("\n" + "=" * 50)
    print("✅ Test Complete!")

if __name__ == "__main__":
    test_supabase_config()