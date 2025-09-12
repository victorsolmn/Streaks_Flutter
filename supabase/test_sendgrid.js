const https = require('https');

const SUPABASE_URL = 'njlafkaqjjtozdbiwjtj.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qbGFma2Fxamp0b3pkYml3anRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYxMzIxMzEsImV4cCI6MjA3MTcwODEzMX0.lG-GbUmV3HoR9NwpTfDg98LFpeq6FzpsZLimy1PqmJQ';

console.log('🧪 Testing SendGrid Integration with Supabase\n');
console.log('=' .repeat(50));

// Test different email addresses to bypass any rate limits
const timestamp = Date.now();
const testEmail = `test${timestamp}@example.com`;

console.log('Testing with fresh email:', testEmail);

const data = JSON.stringify({
  email: testEmail,
  options: {
    shouldCreateUser: true
  }
});

const options = {
  hostname: SUPABASE_URL,
  port: 443,
  path: '/auth/v1/otp',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'apikey': ANON_KEY
  }
};

const req = https.request(options, (res) => {
  let responseData = '';

  res.on('data', (chunk) => {
    responseData += chunk;
  });

  res.on('end', () => {
    console.log(`\nStatus: ${res.statusCode}`);
    console.log(`Response: ${responseData}\n`);
    
    if (res.statusCode === 200) {
      console.log('✅ SUCCESS! SendGrid is working!');
      console.log('📧 Magic link email sent successfully');
    } else {
      console.log('❌ Still failing. Checking SendGrid configuration...\n');
      console.log('Please verify in Supabase Dashboard:');
      console.log('1. SMTP Username is exactly: apikey');
      console.log('2. SMTP Password is your SendGrid API key');
      console.log('3. SMTP Host: smtp.sendgrid.net');
      console.log('4. SMTP Port: 587');
      console.log('5. Click "Save" after making changes');
      console.log('\nAlso check SendGrid Dashboard:');
      console.log('- Go to SendGrid → Settings → Sender Authentication');
      console.log('- You might need to verify a sender email');
    }
  });
});

req.on('error', (error) => {
  console.error('Request failed:', error.message);
});

req.write(data);
req.end();