// Direct OTP Test with Proper Headers
// Run: node test_direct_otp.js

const https = require('https');

async function testDirectOTP() {
  console.log('🧪 Testing Direct OTP Request...\n');
  
  const data = JSON.stringify({
    email: 'victorsolmn@gmail.com'
  });

  const options = {
    hostname: 'njlafkaqjjtozdbiwjtj.supabase.co',
    port: 443,
    path: '/auth/v1/otp',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qbGFma2Fxamp0b3pkYml3anRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYxMzIxMzEsImV4cCI6MjA3MTcwODEzMX0.lG-GbUmV3HoR9NwpTfDg98LFpeq6FzpsZLimy1PqmJQ'
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let responseData = '';

      res.on('data', (chunk) => {
        responseData += chunk;
      });

      res.on('end', () => {
        console.log(`Status: ${res.statusCode}`);
        console.log(`Response: ${responseData}\n`);
        
        try {
          const parsed = JSON.parse(responseData);
          
          if (res.statusCode === 200) {
            console.log('✅ SUCCESS: OTP request sent!');
            console.log('📧 Check victorsolmn@gmail.com for OTP email');
          } else {
            console.log('❌ FAILED:', parsed.message || parsed.msg);
            
            // Specific error handling
            if (parsed.message && parsed.message.includes('magic link')) {
              console.log('🔧 FIX NEEDED: Supabase is still configured for magic links');
              console.log('   → Go to Auth → Providers → Email');
              console.log('   → Disable "Confirm email"');
              console.log('   → Enable "Email OTP"');
            }
          }
        } catch (e) {
          console.log('Raw response:', responseData);
        }
        
        resolve();
      });
    });

    req.on('error', (error) => {
      console.error('Request failed:', error.message);
      reject(error);
    });

    req.write(data);
    req.end();
  });
}

testDirectOTP().catch(console.error);