const https = require('https');

const SUPABASE_URL = 'njlafkaqjjtozdbiwjtj.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qbGFma2Fxamp0b3pkYml3anRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYxMzIxMzEsImV4cCI6MjA3MTcwODEzMX0.lG-GbUmV3HoR9NwpTfDg98LFpeq6FzpsZLimy1PqmJQ';

console.log('🔍 COMPLETE EMAIL/OTP AUTHENTICATION DEBUG\n');
console.log('=' .repeat(50));

async function makeRequest(path, method, data) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: SUPABASE_URL,
      port: 443,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'apikey': ANON_KEY,
        'Authorization': `Bearer ${ANON_KEY}`
      }
    };

    const req = https.request(options, (res) => {
      let responseData = '';
      res.on('data', (chunk) => responseData += chunk);
      res.on('end', () => {
        resolve({
          status: res.statusCode,
          headers: res.headers,
          data: responseData
        });
      });
    });

    req.on('error', reject);
    if (data) req.write(JSON.stringify(data));
    req.end();
  });
}

async function runTests() {
  // Test 1: Check Auth Settings
  console.log('\n1️⃣ Testing Auth Configuration Status:');
  const authSettings = await makeRequest('/auth/v1/settings', 'GET');
  console.log(`   Status: ${authSettings.status}`);
  if (authSettings.data) {
    try {
      const settings = JSON.parse(authSettings.data);
      console.log('   Email Provider:', settings.external?.email?.enabled ? '✅ Enabled' : '❌ Disabled');
      console.log('   Magic Link:', settings.disable_signup ? '❌ Signup Disabled' : '✅ Signup Enabled');
    } catch (e) {
      console.log('   Response:', authSettings.data.substring(0, 100));
    }
  }

  // Test 2: Try signInWithOtp
  console.log('\n2️⃣ Testing signInWithOtp endpoint:');
  const otpTest = await makeRequest('/auth/v1/otp', 'POST', {
    email: 'test@example.com',
    create_user: false
  });
  console.log(`   Status: ${otpTest.status}`);
  console.log(`   Response: ${otpTest.data.substring(0, 200)}`);

  // Test 3: Try Magic Link with redirect
  console.log('\n3️⃣ Testing Magic Link with redirect:');
  const magicLink = await makeRequest('/auth/v1/magiclink', 'POST', {
    email: 'test@example.com',
    redirect_to: 'com.streaker.streaker://callback'
  });
  console.log(`   Status: ${magicLink.status}`);
  console.log(`   Response: ${magicLink.data.substring(0, 200)}`);

  // Test 4: Try signup
  console.log('\n4️⃣ Testing Signup endpoint:');
  const timestamp = Date.now();
  const signup = await makeRequest('/auth/v1/signup', 'POST', {
    email: `test${timestamp}@example.com`,
    password: `temp_password_${timestamp}`,
    email_redirect_to: 'com.streaker.streaker://callback'
  });
  console.log(`   Status: ${signup.status}`);
  console.log(`   Response: ${signup.data.substring(0, 200)}`);

  // Test 5: Check if issue is SMTP
  console.log('\n5️⃣ Checking Error Details:');
  console.log('   Common causes:');
  console.log('   - SMTP credentials incorrect');
  console.log('   - Email sender not verified');
  console.log('   - Rate limiting on email provider');
  console.log('   - Email templates misconfigured');
  console.log('   - Domain verification issues');
}

runTests().then(() => {
  console.log('\n' + '=' .repeat(50));
  console.log('🏁 Debug Complete\n');
  
  console.log('📋 RECOMMENDATIONS:');
  console.log('1. Check Supabase Dashboard → Project Settings → Authentication → SMTP Settings');
  console.log('2. Verify SMTP credentials (username, password, host, port)');
  console.log('3. Check email sender is verified with your SMTP provider');
  console.log('4. Review rate limits on your email provider');
  console.log('5. Consider using a different SMTP provider (SendGrid, Mailgun, etc.)');
}).catch(console.error);