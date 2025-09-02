// Clear all Supabase data using JavaScript
// You can run this with Node.js after installing @supabase/supabase-js

const { createClient } = require('@supabase/supabase-js');

// Replace with your Supabase credentials
const supabaseUrl = 'https://vjubxqaizjcplbxtldqn.supabase.co';
const supabaseKey = 'YOUR_SUPABASE_ANON_KEY'; // Use your service role key for admin access

const supabase = createClient(supabaseUrl, supabaseKey);

async function clearAllData() {
  console.log('Starting to clear all Supabase data...\n');

  try {
    // Clear tables in order (to handle foreign key dependencies)
    const tables = [
      'workouts',
      'activities',
      'weight_logs',
      'health_metrics',
      'nutrition_entries',
      'profiles'
    ];

    for (const table of tables) {
      console.log(`Clearing table: ${table}`);
      
      const { data, error } = await supabase
        .from(table)
        .delete()
        .neq('id', '00000000-0000-0000-0000-000000000000'); // Delete all records
      
      if (error) {
        console.error(`Error clearing ${table}:`, error.message);
      } else {
        console.log(`✓ Table ${table} cleared successfully`);
      }
    }

    // Optional: Clear all user accounts (WARNING: This will require all users to re-register)
    // Uncomment the following if you want to clear auth.users as well
    /*
    console.log('\nClearing auth.users...');
    const { data: users, error: fetchError } = await supabase.auth.admin.listUsers();
    
    if (fetchError) {
      console.error('Error fetching users:', fetchError.message);
    } else {
      for (const user of users.users) {
        const { error: deleteError } = await supabase.auth.admin.deleteUser(user.id);
        if (deleteError) {
          console.error(`Error deleting user ${user.email}:`, deleteError.message);
        } else {
          console.log(`✓ User ${user.email} deleted`);
        }
      }
    }
    */

    console.log('\n✅ All data has been cleared successfully!');
    
    // Verify by counting remaining records
    console.log('\nVerifying data clearance:');
    for (const table of tables) {
      const { count, error } = await supabase
        .from(table)
        .select('*', { count: 'exact', head: true });
      
      if (!error) {
        console.log(`${table}: ${count || 0} records remaining`);
      }
    }

  } catch (error) {
    console.error('Unexpected error:', error);
  }
}

// Run the clear function
clearAllData()
  .then(() => {
    console.log('\nProcess completed.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
  });