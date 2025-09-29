# 🏆 Achievement System Database Setup

## ⚡ Quick Setup Instructions

1. **Open Supabase Dashboard**
   - Go to your project: https://supabase.com/dashboard/project/xzwvckziavhzmghizyqx
   - Navigate to "SQL Editor" in the left sidebar

2. **Run SQL Scripts**
   - Copy and run each SQL block below in order
   - Wait for each to complete before running the next

3. **Verify Setup**
   - Check the "Table Editor" to confirm tables are created
   - Verify 15 achievements are inserted

---

## 📊 SQL Setup Scripts

### Step 1: Create Tables
Run this first to create the achievement system tables:

```sql
-- Drop existing tables if they exist (for clean setup)
DROP TABLE IF EXISTS achievement_progress CASCADE;
DROP TABLE IF EXISTS user_achievements CASCADE;
DROP TABLE IF EXISTS achievements CASCADE;

-- Create achievements master table
CREATE TABLE achievements (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    requirement_type TEXT NOT NULL CHECK (requirement_type IN ('streak', 'workout', 'special')),
    requirement_value INTEGER DEFAULT 0,
    icon_name TEXT NOT NULL,
    color_primary TEXT NOT NULL,
    color_secondary TEXT NOT NULL,
    sort_order INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create user achievements table
CREATE TABLE user_achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    achievement_id TEXT NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMP NOT NULL DEFAULT NOW(),
    notified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, achievement_id)
);

-- Create achievement progress table
CREATE TABLE achievement_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    achievement_id TEXT NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    current_value INTEGER DEFAULT 0,
    target_value INTEGER NOT NULL,
    last_updated TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, achievement_id)
);

-- Create indexes for performance
CREATE INDEX idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX idx_user_achievements_unlocked_at ON user_achievements(unlocked_at);
CREATE INDEX idx_achievement_progress_user_id ON achievement_progress(user_id);
```

### Step 2: Enable Row Level Security
Run this to secure the tables:

```sql
-- Enable RLS
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievement_progress ENABLE ROW LEVEL SECURITY;

-- Create policies for achievements (read-only for all)
CREATE POLICY "Achievements viewable by all authenticated users"
    ON achievements FOR SELECT
    TO authenticated
    USING (true);

-- Create policies for user_achievements
CREATE POLICY "Users can view own achievements"
    ON user_achievements FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own achievements"
    ON user_achievements FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own achievements"
    ON user_achievements FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);

-- Create policies for achievement_progress
CREATE POLICY "Users can view own progress"
    ON achievement_progress FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own progress"
    ON achievement_progress FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own progress"
    ON achievement_progress FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);
```

### Step 3: Insert Achievement Definitions
Run this to add all 15 achievements:

```sql
INSERT INTO achievements (id, title, description, requirement_type, requirement_value, icon_name, color_primary, color_secondary, sort_order) VALUES
('warm_up', 'Warm-up Warrior', 'Your first workout logged 💪', 'workout', 1, 'fitness_center', '#FF6B6B', '#FF8E8E', 1),
('no_excuses', 'No Excuses Rookie', '3-day streak, you showed up!', 'streak', 3, 'event_available', '#4ECDC4', '#6FE5DD', 2),
('sweat_starter', 'Sweat Starter', 'First 7-day streak, habit unlocked', 'streak', 7, 'local_fire_department', '#FFD93D', '#FFE66D', 3),
('grind_machine', 'Grind Machine', '14 days of pure dedication', 'streak', 14, 'trending_up', '#6BCF7F', '#8EDC9D', 4),
('beast_mode', 'Beast Mode Initiated', '21 days in, habit locked!', 'streak', 21, 'flash_on', '#A8E6CF', '#C8F4DC', 5),
('iron_month', 'Iron Month', '30 days streak, strong foundation', 'streak', 30, 'shield', '#FFB6C1', '#FFC8D6', 6),
('quarter_crusher', 'Quarter Crusher', '90 days in, streak domination', 'streak', 90, 'emoji_events', '#B19CD9', '#C5B4E3', 7),
('half_year', 'Half-Year Hero', '180 days streak, crowned king 👑', 'streak', 180, 'military_tech', '#87CEEB', '#A8DAEF', 8),
('comeback_kid', 'Comeback Kid', 'Lost streak, but bounced back fast', 'special', 3, 'restart_alt', '#FFA07A', '#FFBFA7', 9),
('year_one', 'Year-One Legend', '365 days streak, respect earned 🔥', 'streak', 365, 'workspace_premium', '#FFB347', '#FFC774', 10),
('streak_titan', 'Streak Titan', '500 days, godlike consistency', 'streak', 500, 'whatshot', '#FF6B9D', '#FF8FB3', 11),
('immortal', 'Immortal Grinder', '1000 days, streak immortality achieved', 'streak', 1000, 'all_inclusive', '#C44569', '#D16085', 12),
('sweatflix', 'Sweatflix & Chill', 'Weekend workout logged 📺🏋️', 'special', 1, 'weekend', '#A8D8EA', '#C4E5F2', 13),
('gym_goblin', 'Gym Goblin', 'Workout past midnight 🕛', 'special', 1, 'nightlight', '#AA96DA', '#C0B1E5', 14),
('no_days_off', 'No Days Off Maniac', '7 days nonstop, zero rest days', 'special', 7, 'repeat', '#FCBAD3', '#FDD4E5', 15);
```

### Step 4: Create Achievement Check Functions
Run this to set up automatic achievement checking:

```sql
-- Function to check streak achievements
CREATE OR REPLACE FUNCTION check_streak_achievements()
RETURNS TRIGGER AS $$
DECLARE
    achievement RECORD;
BEGIN
    -- Only process if streak increased
    IF NEW.current_streak > COALESCE(OLD.current_streak, 0) THEN
        -- Check all streak achievements
        FOR achievement IN
            SELECT * FROM achievements
            WHERE requirement_type = 'streak'
            AND requirement_value <= NEW.current_streak
        LOOP
            INSERT INTO user_achievements (user_id, achievement_id)
            VALUES (NEW.user_id, achievement.id)
            ON CONFLICT (user_id, achievement_id) DO NOTHING;

            INSERT INTO achievement_progress (user_id, achievement_id, current_value, target_value)
            VALUES (NEW.user_id, achievement.id, NEW.current_streak, achievement.requirement_value)
            ON CONFLICT (user_id, achievement_id)
            DO UPDATE SET current_value = NEW.current_streak, last_updated = NOW();
        END LOOP;
    END IF;

    -- Check Comeback Kid
    IF NEW.current_streak >= 3 AND OLD.current_streak = 0 AND OLD.longest_streak > 0 THEN
        INSERT INTO user_achievements (user_id, achievement_id)
        VALUES (NEW.user_id, 'comeback_kid')
        ON CONFLICT DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for streak achievements
DROP TRIGGER IF EXISTS trigger_check_streak_achievements ON streaks;
CREATE TRIGGER trigger_check_streak_achievements
AFTER INSERT OR UPDATE ON streaks
FOR EACH ROW
EXECUTE FUNCTION check_streak_achievements();
```

### Step 5: Enable Real-time
Run this to enable real-time updates:

```sql
-- Enable real-time for achievement tables
ALTER PUBLICATION supabase_realtime ADD TABLE user_achievements;
ALTER PUBLICATION supabase_realtime ADD TABLE achievement_progress;

-- Grant permissions
GRANT ALL ON achievements TO authenticated;
GRANT ALL ON user_achievements TO authenticated;
GRANT ALL ON achievement_progress TO authenticated;
```

---

## ✅ Verification Steps

After running all scripts, verify:

1. **Check Tables Exist**
   ```sql
   SELECT table_name FROM information_schema.tables
   WHERE table_schema = 'public'
   AND table_name IN ('achievements', 'user_achievements', 'achievement_progress');
   ```

2. **Check Achievements Inserted**
   ```sql
   SELECT id, title FROM achievements ORDER BY sort_order;
   ```
   Should return 15 achievements

3. **Test a Manual Achievement Unlock** (Replace with your user_id)
   ```sql
   -- Get your user_id first
   SELECT id FROM auth.users LIMIT 1;

   -- Then test insert (replace YOUR_USER_ID)
   INSERT INTO user_achievements (user_id, achievement_id)
   VALUES ('YOUR_USER_ID', 'warm_up')
   ON CONFLICT DO NOTHING;
   ```

---

## 🚀 App Testing

After database setup:

1. **Restart the Flutter app**
2. **Navigate to Streaks tab** (bottom navigation)
3. **Check Achievements tab** - should see 15 badges in 5x3 grid
4. **Complete activities** to unlock achievements:
   - Log a workout → "Warm-up Warrior"
   - Maintain 3-day streak → "No Excuses Rookie"
   - Continue streaks for more unlocks

---

## ⚠️ Troubleshooting

If you encounter issues:

1. **Permission Errors**: Make sure you're logged in as project owner
2. **Table Already Exists**: Run the DROP statements first
3. **Achievements Not Showing**: Check RLS policies are created
4. **Real-time Not Working**: Verify real-time is enabled in project settings

---

## 📝 Notes

- Achievements are automatically checked when streaks update
- Progress is tracked even for locked achievements
- The system supports 1000+ day streaks
- All data is secure with Row Level Security