-- Fix the update_profile_weight trigger function
-- This fixes the incorrect column reference in the profiles table update
-- The profiles table uses 'id' as the primary key, not 'user_id'

CREATE OR REPLACE FUNCTION update_profile_weight()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the weight in profiles table with the new weight
    UPDATE profiles
    SET weight = NEW.weight,
        updated_at = NOW()
    WHERE id = NEW.user_id;  -- Fixed: was 'WHERE user_id = NEW.user_id'

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Note: The trigger 'sync_weight_to_profile' already exists and doesn't need to be recreated
-- It will automatically use this updated function