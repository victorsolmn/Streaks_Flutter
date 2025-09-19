-- Chat Sessions Table for Streaks Flutter
-- Stores session summaries only (not full conversations)
-- Created: September 2025

-- Drop existing tables if they exist
DROP TABLE IF EXISTS public.chat_messages CASCADE;
DROP TABLE IF EXISTS public.chat_sessions CASCADE;

-- Create chat_sessions table
CREATE TABLE public.chat_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Session metadata
  session_date DATE NOT NULL DEFAULT CURRENT_DATE,
  session_number INTEGER NOT NULL DEFAULT 1, -- Number of session for that day
  session_title TEXT, -- Auto-generated title based on first topic

  -- Summary information (the key feature - only storing summaries)
  session_summary TEXT NOT NULL, -- One-liner summary of conversation
  topics_discussed TEXT[], -- Array of main topics covered

  -- Context for AI
  user_goals_discussed TEXT, -- Any goals mentioned
  recommendations_given TEXT, -- Key recommendations provided
  user_sentiment TEXT CHECK (user_sentiment IN ('positive', 'neutral', 'negative', 'mixed')),

  -- Metrics
  message_count INTEGER DEFAULT 0,
  duration_minutes INTEGER, -- Approximate conversation duration

  -- Timestamps
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Ensure unique session numbers per user per day
  UNIQUE(user_id, session_date, session_number)
);

-- Create indexes for performance
CREATE INDEX idx_chat_sessions_user_id ON public.chat_sessions(user_id);
CREATE INDEX idx_chat_sessions_session_date ON public.chat_sessions(session_date DESC);
CREATE INDEX idx_chat_sessions_user_date ON public.chat_sessions(user_id, session_date DESC);
CREATE INDEX idx_chat_sessions_created_at ON public.chat_sessions(created_at DESC);

-- Enable Row Level Security
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own chat sessions"
  ON public.chat_sessions
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own chat sessions"
  ON public.chat_sessions
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own chat sessions"
  ON public.chat_sessions
  FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own chat sessions"
  ON public.chat_sessions
  FOR DELETE
  USING (auth.uid() = user_id);

-- Function to get next session number for a user on a given date
CREATE OR REPLACE FUNCTION public.get_next_session_number(p_user_id UUID, p_date DATE)
RETURNS INTEGER AS $$
DECLARE
  next_number INTEGER;
BEGIN
  SELECT COALESCE(MAX(session_number), 0) + 1
  INTO next_number
  FROM public.chat_sessions
  WHERE user_id = p_user_id
    AND session_date = p_date;

  RETURN next_number;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's chat context (last 5 sessions)
CREATE OR REPLACE FUNCTION public.get_user_chat_context(p_user_id UUID)
RETURNS TABLE (
  session_date DATE,
  session_summary TEXT,
  topics_discussed TEXT[],
  user_goals_discussed TEXT,
  recommendations_given TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    cs.session_date,
    cs.session_summary,
    cs.topics_discussed,
    cs.user_goals_discussed,
    cs.recommendations_given
  FROM public.chat_sessions cs
  WHERE cs.user_id = p_user_id
  ORDER BY cs.session_date DESC, cs.session_number DESC
  LIMIT 5;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.get_next_session_number TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_chat_context TO authenticated;

-- Add trigger for updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER handle_chat_sessions_updated_at
  BEFORE UPDATE ON public.chat_sessions
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Chat sessions table created successfully!';
  RAISE NOTICE 'This table stores only session summaries, not full conversations.';
  RAISE NOTICE 'Each session has a one-liner summary for efficient storage and quick context retrieval.';
END $$;