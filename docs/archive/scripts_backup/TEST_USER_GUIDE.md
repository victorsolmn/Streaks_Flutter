# Test User Personas Guide

## 🎭 7 Unique Test Personas for Comprehensive App Testing

### Quick Setup Instructions

1. **Create User Accounts** through your app's sign-up flow (use these emails):
2. **Get User IDs** from Supabase Auth dashboard
3. **Replace placeholders** in `test_data_personas.sql`
4. **Run SQL** in Supabase SQL Editor

---

## 📋 Test User Accounts

### 1. 🏆 **The Consistent Achiever**
**Email:** `consistent@test.com`
**Password:** `Test123!`
**Profile:** Alex Johnson, 28
**Characteristics:**
- ✅ 7-day perfect streak
- ✅ Logs all meals daily
- ✅ Works out daily
- ✅ Has unlocked "Warm Up" achievement
- **Test Focus:** Achievement system, streak maintenance

---

### 2. 💪 **The Comeback Kid**
**Email:** `comeback@test.com`
**Password:** `Test123!`
**Profile:** Sarah Martinez, 32**Characteristics:**
- 🔄 Had 2-day streak, lost it, restarted 2 days ago
- 🔄 Current streak: 2 days
- 🔄 Sporadic workout pattern
- **Test Focus:** Streak recovery, motivation features

---

### 3. 🏃 **The Weekend Warrior**
**Email:** `weekend@test.com`
**Password:** `Test123!`
**Profile:** Mike Chen, 35**Characteristics:**
- 📅 Only active on weekends
- 📅 Logs meals Saturday/Sunday only
- 📅 Sports activities on weekends
- 📅 Current streak: 0 (breaks during weekdays)
- **Test Focus:** Partial engagement patterns

---

### 4. 🌱 **The Beginner**
**Email:** `beginner@test.com`
**Password:** `Test123!`
**Profile:** Emma Wilson, 24**Characteristics:**
- 🆕 Just started 3 days ago
- 🆕 Current streak: 3 days
- 🆕 Limited data entries
- 🆕 One workout attempt
- **Test Focus:** Onboarding experience, beginner guidance

---

### 5. 🏅 **The Veteran**
**Email:** `veteran@test.com`
**Password:** `Test123!`
**Profile:** David Thompson, 42**Characteristics:**
- 🔥 368-day streak!
- 🔥 9 achievements unlocked
- 🔥 Detailed daily logging
- 🔥 Very active (daily workouts)
- 🔥 Near 1-year achievement
- **Test Focus:** Advanced features, long-term engagement

---

### 6. 📊 **The Data Enthusiast**
**Email:** `dataenthusiast@test.com`
**Password:** `Test123!`
**Profile:** Robert Kim, 31**Characteristics:**
- 📈 42-day streak
- 📈 Logs EVERYTHING (even water, supplements)
- 📈 Detailed workout notes
- 📈 Tracks all macros precisely
- 📈 15+ entries per day
- **Test Focus:** Data visualization, detailed tracking

---

### 7. 🎲 **The Irregular User**
**Email:** `irregular@test.com`
**Password:** `Test123!`
**Profile:** Lisa Brown, 29**Characteristics:**
- 📉 Sporadic usage (once a week)
- 📉 Current streak: 1 day
- 📉 Longest streak: 3 days
- 📉 Incomplete data entries
- **Test Focus:** Re-engagement features, reminders

---

## 🚀 Setup Process

### Step 1: Create Accounts
Sign up in your app with each email above using password `Test123!`

### Step 2: Get User IDs
Run this query in Supabase SQL Editor:
```sql
SELECT id, email FROM auth.users WHERE email IN (
    'consistent@test.com',
    'comeback@test.com',
    'weekend@test.com',
    'beginner@test.com',
    'veteran@test.com',
    'irregular@test.com',
    'dataenthusiast@test.com'
);
```

### Step 3: Update SQL File
Open `test_data_personas.sql` and replace:
- `USER_ID_1` with consistent@test.com's ID
- `USER_ID_2` with comeback@test.com's ID
- `USER_ID_3` with weekend@test.com's ID
- `USER_ID_4` with beginner@test.com's ID
- `USER_ID_5` with veteran@test.com's ID
- `USER_ID_6` with irregular@test.com's ID
- `USER_ID_7` with dataenthusiast@test.com's ID

### Step 4: Run the SQL
Copy the updated SQL and run it in Supabase SQL Editor

---

## 🧪 Testing Scenarios

### Streak Testing
- **Consistent:** Should show 7-day streak with "Warm Up" badge
- **Veteran:** Should show 368-day streak with multiple badges
- **Comeback:** Should show streak recovery UI elements
- **Weekend:** Test how app handles broken streaks

### Achievement Testing
- **Veteran:** Has 9 achievements - test display and UI
- **Consistent:** Just unlocked first achievement
- **Beginner:** All achievements locked but showing progress
- **Data Enthusiast:** 4 achievements, progressing to 50-day

### Nutrition Testing
- **Data Enthusiast:** Complex meal entries with detailed macros
- **Weekend:** Gaps in data - test summary views
- **Irregular:** Very sparse data - test empty states

### Goals Testing
- **Veteran:** Multiple active goals near completion
- **Beginner:** Basic weight loss goal just started
- **Data Enthusiast:** Precise macro goals being tracked

### UI/UX Testing
- **Beginner:** Onboarding and tutorial features
- **Veteran:** Advanced features and data-rich views
- **Irregular:** Re-engagement prompts and notifications
- **Weekend:** Partial week summaries

---

## 📊 Expected Results After Setup

| User | Current Streak | Total Days | Achievements | Workouts (Last 7 days) |
|------|---------------|------------|--------------|------------------------|
| Consistent | 7 | 7 | 1 | 7 |
| Comeback | 2 | 4 | 0 | 2 |
| Weekend | 0 | 6 | 0 | 2 |
| Beginner | 3 | 3 | 0 | 1 |
| Veteran | 368 | 380 | 9 | 7 |
| Irregular | 1 | 8 | 0 | 1 |
| Data Enthusiast | 42 | 42 | 4 | 4 |

---

## 💡 Testing Tips

1. **Test Achievement Unlocking:** Log in as Beginner and complete activities to see achievements unlock
2. **Test Streak Loss:** Use Weekend Warrior to test streak breaking/recovery flows
3. **Test Data Visualization:** Use Data Enthusiast for rich data displays
4. **Test Motivation:** Use Comeback Kid to test motivational features
5. **Test Long-term User:** Use Veteran to ensure app handles large data sets
6. **Test Re-engagement:** Use Irregular to test notification and reminder systems

---

## 🔧 Troubleshooting

### If accounts won't create:
- Check Supabase Auth settings
- Ensure email confirmation is disabled for testing
- Check for existing accounts with these emails

### If data won't insert:
- Verify user IDs are correct UUIDs
- Check RLS policies are disabled (cleanup script should handle this)
- Look for foreign key constraint errors

### To reset and try again:
1. Run the cleanup script first
2. Delete test accounts from Supabase Auth
3. Start fresh with account creation

---

Last Updated: September 19, 2025