// Test OTP Email Script
// Run: node test_otp_email.js

const https = require('https');

const CONFIG = {
  SUPABASE_URL: 'https://njlafkaqjjtozdbiwjtj.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qbGFma2Fxamp0b3pkYml3anRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYxMzIxMzEsImV4cCI6MjA3MTcwODEzMX0.lG-GbUmV3HoR9NwpTfDg98LFpeq6FzpsZLimy1PqmJQ'
};

async function testOTPEmail() {
  console.log('🧪 Testing OTP Email System...\n');
  
  const data = {
    email: 'victorsolmn@gmail.com',
    options: {
      shouldCreateUser: false,
      data: { test: 'otp_email_test' }
    }
  };

  const postData = JSON.stringify(data);

  const options = {
    hostname: 'njlafkaqjjtozdbiwjtj.supabase.co',
    port: 443,
    path: '/auth/v1/otp',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData),
      'apikey': CONFIG.SUPABASE_ANON_KEY,
      'Authorization': `Bearer ${CONFIG.SUPABASE_ANON_KEY}`
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        console.log(`✅ Response Status: ${res.statusCode}`);
        console.log(`📧 Response: ${data}\n`);
        
        if (res.statusCode === 200) {
          console.log('🎉 OTP Email request sent successfully!');
          console.log('📬 Check victorsolmn@gmail.com for the OTP email');
        } else {
          console.log('❌ Failed to send OTP email');
          console.log('🔍 Check Supabase configuration');
        }
        
        resolve();
      });
    });

    req.on('error', (error) => {
      console.error('❌ Error:', error);
      reject(error);
    });

    req.write(postData);
    req.end();
  });
}

// Run the test
testOTPEmail().catch(console.error);