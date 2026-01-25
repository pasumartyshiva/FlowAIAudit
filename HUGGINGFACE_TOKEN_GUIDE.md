# 🤗 How to Get Your Hugging Face Token (Step-by-Step)

## Step 1: Create Hugging Face Account

1. Go to: **https://huggingface.co/join**
2. You'll see a sign-up form with:
   - Email address field
   - Username field
   - Password field
3. Fill in your details
4. Click **"Sign Up"**
5. Check your email and verify your account

## Step 2: Navigate to Token Settings

**Option A - Direct Link (Easiest):**
1. Once logged in, go directly to: **https://huggingface.co/settings/tokens**

**Option B - Through Settings Menu:**
1. Go to: **https://huggingface.co**
2. Click your **profile picture** (top right corner)
3. Click **"Settings"** from the dropdown menu
4. In the left sidebar, click **"Access Tokens"**

## Step 3: Create a New Token

You should now see the "Access Tokens" page. Here's what to do:

1. Look for a button that says **"New token"** or **"Create new token"**
2. Click that button
3. You'll see a form with these fields:

### Token Details to Fill:

**Name:** 
- Enter: `Salesforce Flow Analysis`
- (This is just a label to remember what it's for)

**Role/Type:**
- Select: **"Read"** 
- (You might see options like: Read, Write, or Fine-grained)
- **Important:** You only need "Read" permissions!

**Token Scope (if asked):**
- Just leave default selections
- "Read" access is all you need

4. Click **"Generate token"** or **"Create token"**

## Step 4: Copy Your Token

After clicking generate:

1. You'll see your new token displayed on screen
2. It will look like: `hf_AbCdEfGhIjKlMnOpQrStUvWxYz1234567890`
3. **IMPORTANT:** Copy this token immediately!
4. Click the **"Copy"** button next to the token
5. **Save it somewhere safe** - you won't be able to see it again!

## Step 5: Paste Token in Salesforce

Now that you have your token:

1. In Salesforce, go to **Setup**
2. In Quick Find, search: **"Custom Metadata Types"**
3. Click **"Custom Metadata Types"**
4. Find **"LLM Configuration"** in the list
5. Click **"Manage Records"**
6. You'll see a list of configurations
7. Find **"HuggingFace Qwen 72B"**
8. Click **"Edit"** next to it
9. Scroll down to find **"API Key"** field
10. **Paste your token** (the one starting with `hf_...`)
11. Make sure **"Is Active"** checkbox is **checked** ✓
12. Click **"Save"**

## Verification

Your token should:
- ✅ Start with `hf_`
- ✅ Be around 40-50 characters long
- ✅ Contain letters and numbers
- ✅ Have NO spaces

Example valid token format:
```
hf_AbCdEfGhIjKlMnOpQrStUvWxYz1234567890
```

## What You'll See on Hugging Face Token Page

The Access Tokens page typically shows:

```
┌─────────────────────────────────────────────┐
│  Access Tokens                              │
│                                             │
│  [New token] button                         │
│                                             │
│  Your existing tokens (if any):             │
│  ┌───────────────────────────────────────┐ │
│  │ Token Name          │ Role  │ Actions │ │
│  │ Salesforce...       │ Read  │ [Delete]│ │
│  └───────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

## Troubleshooting

**Can't find "Access Tokens" in Settings?**
- Try this direct link: https://huggingface.co/settings/tokens
- Make sure you're logged in first

**Don't see "New token" button?**
- Make sure your account is verified (check email)
- Try refreshing the page
- Make sure you're on the correct page (should say "Access Tokens" at top)

**Token doesn't work?**
- Make sure you selected "Read" type
- Make sure you copied the ENTIRE token (including the `hf_` part)
- Try creating a new token

**Already created token but lost it?**
- You'll need to create a new one
- Delete the old one (click trash icon)
- Create a new token following steps above

## Alternative: Screenshot Guide

If you're still stuck, here's what each screen should look like:

### Screen 1: Hugging Face Homepage
- Top right corner has your profile picture
- Click it to see dropdown menu

### Screen 2: Settings Dropdown
- Options include: Profile, Settings, Sign Out
- Click "Settings"

### Screen 3: Settings Page (Left Sidebar)
- Account
- Profile  
- **Access Tokens** ← Click this one!
- Webhooks
- Billing

### Screen 4: Access Tokens Page
- Big button at top: "New token" or "Create new token"
- List of existing tokens below (if any)

### Screen 5: Create Token Form
- Name field (enter anything)
- Role dropdown (select "Read")
- Generate button at bottom

### Screen 6: Token Created
- Success message
- Your token displayed: `hf_...`
- Copy button next to token
- **Copy it now!**

## Quick Video Alternative

Can't find it? Try:
1. YouTube search: "How to get Hugging Face API token"
2. Look for recent videos (2024-2025)
3. Process hasn't changed much, should match above steps

## Need Help?

If you're still stuck:
1. Take a screenshot of where you're stuck
2. Show me the page you're on
3. I can give you more specific guidance!

## Once You Have Your Token

Run this in Salesforce Developer Console to test:

```apex
FlowAnalysisBatch.runBatch(1);
```

Then check results:

```apex
List<Flow_Analysis__c> results = [
    SELECT Id, Flow_API_Name__c, Status__c
    FROM Flow_Analysis__c
    ORDER BY CreatedDate DESC
    LIMIT 1
];
System.debug(results);
```

You should see analysis results!

---

**Remember:** Your token is like a password - keep it safe! ✅
