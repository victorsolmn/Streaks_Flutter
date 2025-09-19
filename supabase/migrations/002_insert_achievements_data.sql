-- Insert 15 achievements with Material Icons and gradient colors
INSERT INTO achievements (id, title, description, requirement_type, requirement_value, icon_name, color_primary, color_secondary, sort_order) VALUES
-- Row 1 (Workout & Early Streak Achievements)
('warm_up', 'Warm-up Warrior', 'Your first workout logged 💪', 'workout', 1, 'fitness_center', '#FF6B6B', '#FF8E8E', 1),
('no_excuses', 'No Excuses Rookie', '3-day streak, you showed up!', 'streak', 3, 'event_available', '#4ECDC4', '#6FE5DD', 2),
('sweat_starter', 'Sweat Starter', 'First 7-day streak, habit unlocked', 'streak', 7, 'local_fire_department', '#FFD93D', '#FFE66D', 3),
('grind_machine', 'Grind Machine', '14 days of pure dedication', 'streak', 14, 'trending_up', '#6BCF7F', '#8EDC9D', 4),
('beast_mode', 'Beast Mode Initiated', '21 days in, habit locked!', 'streak', 21, 'flash_on', '#A8E6CF', '#C8F4DC', 5),

-- Row 2 (Mid-tier Streak Achievements)
('iron_month', 'Iron Month', '30 days streak, strong foundation', 'streak', 30, 'shield', '#FFB6C1', '#FFC8D6', 6),
('quarter_crusher', 'Quarter Crusher', '90 days in, streak domination', 'streak', 90, 'emoji_events', '#B19CD9', '#C5B4E3', 7),
('half_year', 'Half-Year Hero', '180 days streak, crowned king 👑', 'streak', 180, 'military_tech', '#87CEEB', '#A8DAEF', 8),
('comeback_kid', 'Comeback Kid', 'Lost streak, but bounced back fast', 'special', 3, 'restart_alt', '#FFA07A', '#FFBFA7', 9),
('year_one', 'Year-One Legend', '365 days streak, respect earned 🔥', 'streak', 365, 'workspace_premium', '#FFB347', '#FFC774', 10),

-- Row 3 (Elite & Special Achievements)
('streak_titan', 'Streak Titan', '500 days, godlike consistency', 'streak', 500, 'whatshot', '#FF6B9D', '#FF8FB3', 11),
('immortal', 'Immortal Grinder', '1000 days, streak immortality achieved', 'streak', 1000, 'all_inclusive', '#C44569', '#D16085', 12),
('sweatflix', 'Sweatflix & Chill', 'Weekend workout logged 📺🏋️', 'special', 1, 'weekend', '#A8D8EA', '#C4E5F2', 13),
('gym_goblin', 'Gym Goblin', 'Workout past midnight 🕛', 'special', 1, 'nightlight', '#AA96DA', '#C0B1E5', 14),
('no_days_off', 'No Days Off Maniac', '7 days nonstop, zero rest days', 'special', 7, 'repeat', '#FCBAD3', '#FDD4E5', 15);

-- Create a function to check and unlock achievements based on streak updates
CREATE OR REPLACE FUNCTION check_streak_achievements()
RETURNS TRIGGER AS $$
DECLARE
    achievement RECORD;
    comeback_check BOOLEAN;
BEGIN
    -- Only process if streak increased
    IF NEW.current_streak > COALESCE(OLD.current_streak, 0) THEN
        -- Check all streak-based achievements
        FOR achievement IN
            SELECT * FROM achievements
            WHERE requirement_type = 'streak'
            AND requirement_value <= NEW.current_streak
            ORDER BY requirement_value
        LOOP
            -- Insert achievement if not already unlocked
            INSERT INTO user_achievements (user_id, achievement_id, unlocked_at)
            VALUES (NEW.user_id, achievement.id, NOW())
            ON CONFLICT (user_id, achievement_id) DO NOTHING;

            -- Update progress
            INSERT INTO achievement_progress (user_id, achievement_id, current_value, target_value)
            VALUES (NEW.user_id, achievement.id, NEW.current_streak, achievement.requirement_value)
            ON CONFLICT (user_id, achievement_id)
            DO UPDATE SET
                current_value = NEW.current_streak,
                last_updated = NOW();
        END LOOP;
    END IF;

    -- Check for Comeback Kid achievement
    IF NEW.current_streak >= 3 AND OLD.current_streak = 0 AND OLD.longest_streak > 0 THEN
        INSERT INTO user_achievements (user_id, achievement_id, unlocked_at)
        VALUES (NEW.user_id, 'comeback_kid', NOW())
        ON CONFLICT (user_id, achievement_id) DO NOTHING;
    END IF;

    -- Update progress for all streak achievements
    FOR achievement IN
        SELECT * FROM achievements WHERE requirement_type = 'streak'
    LOOP
        INSERT INTO achievement_progress (user_id, achievement_id, current_value, target_value)
        VALUES (NEW.user_id, achievement.id, NEW.current_streak, achievement.requirement_value)
        ON CONFLICT (user_id, achievement_id)
        DO UPDATE SET
            current_value = NEW.current_streak,
            last_updated = NOW();
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to check achievements when streak updates
CREATE TRIGGER trigger_check_streak_achievements
AFTER INSERT OR UPDATE ON streaks
FOR EACH ROW
EXECUTE FUNCTION check_streak_achievements();

-- Function to check workout-based achievements
CREATE OR REPLACE FUNCTION check_workout_achievements()
RETURNS TRIGGER AS $$
DECLARE
    workout_count INTEGER;
    day_of_week INTEGER;
    hour_of_day INTEGER;
    consecutive_days INTEGER;
BEGIN
    -- Get total workout count for user
    SELECT COUNT(*) INTO workout_count
    FROM health_metrics
    WHERE user_id = NEW.user_id
    AND workouts > 0;

    -- Check Warm-up Warrior (first workout)
    IF workout_count = 1 AND NEW.workouts > 0 THEN
        INSERT INTO user_achievements (user_id, achievement_id, unlocked_at)
        VALUES (NEW.user_id, 'warm_up', NOW())
        ON CONFLICT (user_id, achievement_id) DO NOTHING;
    END IF;

    -- Check Sweatflix & Chill (weekend workout)
    day_of_week := EXTRACT(DOW FROM NEW.date);
    IF NEW.workouts > 0 AND (day_of_week = 0 OR day_of_week = 6) THEN
        INSERT INTO user_achievements (user_id, achievement_id, unlocked_at)
        VALUES (NEW.user_id, 'sweatflix', NOW())
        ON CONFLICT (user_id, achievement_id) DO NOTHING;
    END IF;

    -- Check Gym Goblin (midnight workout)
    hour_of_day := EXTRACT(HOUR FROM NEW.created_at);
    IF NEW.workouts > 0 AND (hour_of_day >= 0 AND hour_of_day <= 3) THEN
        INSERT INTO user_achievements (user_id, achievement_id, unlocked_at)
        VALUES (NEW.user_id, 'gym_goblin', NOW())
        ON CONFLICT (user_id, achievement_id) DO NOTHING;
    END IF;

    -- Check No Days Off Maniac (7 consecutive workout days)
    SELECT COUNT(DISTINCT date) INTO consecutive_days
    FROM health_metrics
    WHERE user_id = NEW.user_id
    AND workouts > 0
    AND date >= CURRENT_DATE - INTERVAL '6 days';

    IF consecutive_days >= 7 THEN
        INSERT INTO user_achievements (user_id, achievement_id, unlocked_at)
        VALUES (NEW.user_id, 'no_days_off', NOW())
        ON CONFLICT (user_id, achievement_id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to check workout achievements when health metrics update
CREATE TRIGGER trigger_check_workout_achievements
AFTER INSERT OR UPDATE ON health_metrics
FOR EACH ROW
WHEN (NEW.workouts > 0)
EXECUTE FUNCTION check_workout_achievements();

-- Grant necessary permissions
GRANT ALL ON achievements TO authenticated;
GRANT ALL ON user_achievements TO authenticated;
GRANT ALL ON achievement_progress TO authenticated;