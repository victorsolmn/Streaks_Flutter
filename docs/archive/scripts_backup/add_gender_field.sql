-- ================================================
-- ADD GENDER FIELD TO PROFILES TABLE
-- ================================================
-- Date: September 19, 2025
-- This script adds a gender field to the existing profiles table

-- Add gender column to profiles table
ALTER TABLE public.profiles
ADD COLUMN gender TEXT
CHECK (gender IN ('Male', 'Female', 'Other', 'Prefer not to say'));