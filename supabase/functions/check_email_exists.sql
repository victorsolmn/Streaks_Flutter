-- This function should be added to your Supabase database
-- Go to Supabase Dashboard > SQL Editor and run this query

CREATE OR REPLACE FUNCTION check_email_exists(email_input TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  email_count INT;
BEGIN
  -- Check if email exists in auth.users table
  SELECT COUNT(*)
  INTO email_count
  FROM auth.users
  WHERE LOWER(email) = LOWER(email_input);
  
  RETURN email_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated and anon users
GRANT EXECUTE ON FUNCTION check_email_exists(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION check_email_exists(TEXT) TO anon;