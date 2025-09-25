-- Create app_config table for force update management
CREATE TABLE IF NOT EXISTS public.app_config (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'all')),
  min_version TEXT NOT NULL,
  min_build_number INTEGER NOT NULL,
  force_update BOOLEAN DEFAULT true,
  update_message TEXT,
  update_url TEXT,
  maintenance_mode BOOLEAN DEFAULT false,
  maintenance_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  active BOOLEAN DEFAULT true,

  -- Additional fields for enhanced features
  recommended_version TEXT,
  features_list TEXT[], -- Array of new features
  update_severity TEXT CHECK (update_severity IN ('critical', 'required', 'recommended', 'optional')) DEFAULT 'required'
);

-- Create index for faster queries
CREATE INDEX idx_app_config_platform_active
ON public.app_config(platform, active);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_app_config_modtime
BEFORE UPDATE ON public.app_config
FOR EACH ROW EXECUTE FUNCTION update_modified_column();

-- Insert initial configuration for both platforms
INSERT INTO public.app_config (
  platform,
  min_version,
  min_build_number,
  recommended_version,
  force_update,
  update_message,
  update_url,
  update_severity,
  features_list
) VALUES
(
  'ios',
  '1.0.4',
  5,
  '1.0.5',
  false, -- Start with false, can be enabled when needed
  'A new version of Streaker is available with exciting features and improvements!',
  'https://apps.apple.com/app/streaker/id6737292817',
  'recommended',
  ARRAY['🚀 Improved performance', '🐛 Bug fixes', '✨ Enhanced UI']
),
(
  'android',
  '1.0.4',
  5,
  '1.0.5',
  false, -- Start with false, can be enabled when needed
  'A new version of Streaker is available with exciting features and improvements!',
  'https://play.google.com/store/apps/details?id=com.streaker.streaker',
  'recommended',
  ARRAY['🚀 Improved performance', '🐛 Bug fixes', '✨ Enhanced UI']
);

-- Create RLS policies
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

-- Allow public read access to app config
CREATE POLICY "Allow public read access to app_config"
ON public.app_config FOR SELECT
USING (true);

-- Only service role can modify
CREATE POLICY "Only service role can modify app_config"
ON public.app_config FOR ALL
USING (auth.role() = 'service_role')
WITH CHECK (auth.role() = 'service_role');

-- Create a view for easier querying
CREATE OR REPLACE VIEW public.current_app_config AS
SELECT * FROM public.app_config
WHERE active = true
ORDER BY created_at DESC;