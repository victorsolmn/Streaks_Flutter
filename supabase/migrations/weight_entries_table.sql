-- Weight entries table for tracking weight history
CREATE TABLE IF NOT EXISTS weight_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  weight DECIMAL(5,2) NOT NULL CHECK (weight > 0 AND weight <= 500),
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  note TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ensure unique weight entry per timestamp for each user
ALTER TABLE weight_entries
ADD CONSTRAINT unique_user_timestamp UNIQUE (user_id, timestamp);

-- Add indexes for faster queries
CREATE INDEX idx_weight_entries_user_id ON weight_entries(user_id);
CREATE INDEX idx_weight_entries_user_timestamp ON weight_entries(user_id, timestamp DESC);

-- Add RLS (Row Level Security) policies
ALTER TABLE weight_entries ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own weight entries
CREATE POLICY "Users can view own weight entries" ON weight_entries
  FOR SELECT USING (auth.uid() = user_id);

-- Policy: Users can insert their own weight entries
CREATE POLICY "Users can insert own weight entries" ON weight_entries
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own weight entries
CREATE POLICY "Users can update own weight entries" ON weight_entries
  FOR UPDATE USING (auth.uid() = user_id);

-- Policy: Users can delete their own weight entries
CREATE POLICY "Users can delete own weight entries" ON weight_entries
  FOR DELETE USING (auth.uid() = user_id);

-- Add weight_unit column to profiles if it doesn't exist
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS weight_unit VARCHAR(10) DEFAULT 'kg' CHECK (weight_unit IN ('kg', 'lbs'));

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER update_weight_entries_updated_at
    BEFORE UPDATE ON weight_entries
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to get latest weight for a user
CREATE OR REPLACE FUNCTION get_latest_weight(p_user_id UUID)
RETURNS DECIMAL AS $$
BEGIN
    RETURN (
        SELECT weight
        FROM weight_entries
        WHERE user_id = p_user_id
        ORDER BY timestamp DESC
        LIMIT 1
    );
END;
$$ LANGUAGE plpgsql;

-- Function to update profile weight when new entry is added
CREATE OR REPLACE FUNCTION update_profile_weight()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the weight in profiles table with the new weight
    UPDATE profiles
    SET weight = NEW.weight,
        updated_at = NOW()
    WHERE user_id = NEW.user_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to sync weight with profile
CREATE TRIGGER sync_weight_to_profile
    AFTER INSERT ON weight_entries
    FOR EACH ROW
    EXECUTE FUNCTION update_profile_weight();