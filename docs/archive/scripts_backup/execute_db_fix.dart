import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://nabbszewwrjrphpvfaze.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5hYmJzemV3d3JqcnBocHZmYXplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjgwMjMxNDUsImV4cCI6MjA0MzU5OTE0NX0.TZdwALPcal6pihX8kqHSj5JTgmPfRedQ9dR9Gc5gH1k',
  );

  final supabase = Supabase.instance.client;

  try {
    print('Executing database fixes...\n');

    // Step 1: Remove column defaults
    print('Step 1: Removing column defaults...');
    await supabase.rpc('query', params: {
      'query': '''
        ALTER TABLE public.profiles
          ALTER COLUMN age DROP DEFAULT,
          ALTER COLUMN height DROP DEFAULT,
          ALTER COLUMN weight DROP DEFAULT,
          ALTER COLUMN activity_level DROP DEFAULT,
          ALTER COLUMN fitness_goal DROP DEFAULT;
      '''
    }).execute();
    print('✅ Column defaults removed');

    // Step 2: Update handle_new_user function
    print('\nStep 2: Updating handle_new_user function...');
    await supabase.rpc('query', params: {
      'query': '''
        CREATE OR REPLACE FUNCTION public.handle_new_user()
        RETURNS trigger AS \$\$
        BEGIN
          INSERT INTO public.profiles (id, email, created_at, updated_at)
          VALUES (
            new.id,
            new.email,
            now(),
            now()
          )
          ON CONFLICT (id) DO UPDATE SET
            email = EXCLUDED.email,
            updated_at = now();
          RETURN new;
        END;
        \$\$ LANGUAGE plpgsql SECURITY DEFINER;
      '''
    }).execute();
    print('✅ handle_new_user function updated');

    print('\n✅ All database fixes applied successfully!');
  } catch (e) {
    print('❌ Error executing fixes: $e');
  }
}