# SendGrid Setup for Supabase (5 Minutes)

## Step 1: Create SendGrid Account
1. Go to https://signup.sendgrid.com/
2. Sign up for FREE account (no credit card needed)
3. Verify your email address

## Step 2: Create API Key
1. Login to SendGrid Dashboard
2. Go to **Settings → API Keys**
3. Click **Create API Key**
4. Name it: "Supabase"
5. Select **Full Access**
6. Click **Create & View**
7. **COPY THE API KEY** (you'll see it only once!)

## Step 3: Configure Supabase
Go to Supabase Dashboard → Project Settings → Authentication → SMTP Settings

Enter these values:

```
SMTP Host: smtp.sendgrid.net
SMTP Port: 587
SMTP Username: apikey
SMTP Password: [Your SendGrid API Key from Step 2]
Sender Email: noreply@streaker.app (or any email)
Sender Name: Streaker
```

**IMPORTANT**: 
- Username is literally the word "apikey" (not your email)
- Password is your SendGrid API Key

## Step 4: Test
Click "Send Test Email" in Supabase

## That's it! 🎉

### Benefits over Gmail:
- No 2-factor auth issues
- No "less secure apps" problems
- Better deliverability
- Dedicated for transactional emails
- Free forever (100 emails/day)

### Your current issue will be fixed immediately!