// Check Supabase's built-in email service configuration
const https = require('https');

const SUPABASE_URL = 'njlafkaqjjtozdbiwjtj.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qbGFma2Fxamp0b3pkYml3anRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYxMzIxMzEsImV4cCI6MjA3MTcwODEzMX0.lG-GbUmV3HoR9NwpTfDg98LFpeq6FzpsZLimy1PqmJQ';

console.log('🔍 CHECKING SUPABASE BUILT-IN EMAIL SERVICE\n');
console.log('=' .repeat(50));

async function checkEmailService() {
  // Test with a simple magic link request
  console.log('\n1️⃣ Testing with Supabase\'s default email service:');
  console.log('   (No custom SMTP, using Supabase\'s built-in service)\n');
  
  const testData = JSON.stringify({
    email: 'victorsolmn@gmail.com',
    options: {
      emailRedirectTo: 'com.streaker.streaker://callback',
      shouldCreateUser: true,
      data: {
        name: 'Test User'
      }
    }
  });

  const options = {
    hostname: SUPABASE_URL,
    port: 443,
    path: '/auth/v1/otp',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': ANON_KEY,
      'Authorization': `Bearer ${ANON_KEY}`
    }
  };

  return new Promise((resolve) => {
    const req = https.request(options, (res) => {
      let responseData = '';

      res.on('data', (chunk) => {
        responseData += chunk;
      });

      res.on('end', () => {
        console.log(`   Status: ${res.statusCode}`);
        console.log(`   Response: ${responseData}\n`);
        
        if (res.statusCode === 200) {
          console.log('✅ SUCCESS! Email should be sent!');
          console.log('📧 Check victorsolmn@gmail.com inbox');
        } else if (res.statusCode === 422) {
          console.log('❌ OTP/Magic links are disabled in Supabase');
          console.log('\n🔧 TO FIX IN SUPABASE (without external SMTP):');
          console.log('1. Go to Supabase Dashboard');
          console.log('2. Authentication → Providers → Email');
          console.log('3. Make sure "Enable Email Provider" is ON');
          console.log('4. TURN OFF "Confirm email" toggle');
          console.log('5. Check if there\'s a "Enable Magic Link" or "Enable OTP" option');
          console.log('6. Save changes');
        } else if (res.statusCode === 500) {
          console.log('❌ Email service error - Supabase can\'t send emails');
          console.log('\n🔧 POSSIBLE FIXES:');
          console.log('Option 1: Reset to Supabase default email');
          console.log('   - Clear all SMTP settings (leave them empty)');
          console.log('   - Supabase will use their built-in service');
          console.log('   - Limited to 3 emails/hour on free tier');
          console.log('\nOption 2: Fix custom SMTP');
          console.log('   - Verify all SMTP credentials');
          console.log('   - Or use SendGrid (easier)');
        }
        
        console.log('\n' + '=' .repeat(50));
        console.log('📋 SUPABASE FREE TIER LIMITS:');
        console.log('• Without SMTP: 3 emails per hour (rate limited)');
        console.log('• With custom SMTP: Unlimited (depends on your provider)');
        console.log('\nThis might be why emails aren\'t sending - rate limit hit!');
        resolve();
      });
    });

    req.on('error', (error) => {
      console.error('Request failed:', error.message);
      resolve();
    });

    req.write(testData);
    req.end();
  });
}

checkEmailService();