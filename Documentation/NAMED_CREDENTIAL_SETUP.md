# Named Credential Setup for Salesforce Tooling API

This guide shows how to create a Named Credential that allows Apex to call the Salesforce Tooling API in the same org.

---

## Why We Need This

When making HTTP callouts from Apex to the same org's Tooling API, using `UserInfo.getSessionId()` results in a **401 Unauthorized** error. The solution is to use a **Named Credential** that properly handles authentication.

---

## Setup Steps

### Step 1: Create External Credential

1. **Navigate to Setup**
2. **Search for:** "Named Credentials"
3. **Click:** "External Credentials" tab
4. **Click:** "New"

5. **Fill in the form:**
   - **Label:** `Salesforce Session Auth`
   - **Name:** `Salesforce_Session_Auth`
   - **Authentication Protocol:** Select **"Salesforce"**
   - **Authentication Flow Type:** Select **"User Context"**

6. **Click:** "Save"

7. **Under "Permission Set Mappings" section:**
   - **Click:** "New"
   - **Select your admin permission set** or create a new one
   - **Identity Type:** "Per User"
   - **Click:** "Save"

---

### Step 2: Create Named Credential

1. **Navigate to Setup**
2. **Search for:** "Named Credentials"
3. **Click:** "Named Credentials" tab
4. **Click:** "New" → "New Legacy"

5. **Fill in the form:**
   - **Label:** `Salesforce_Tooling_API`
   - **Name:** `Salesforce_Tooling_API`
   - **URL:** `{!$Api.Partner_Server_URL_600}`
     - This is a merge field that resolves to your org's domain
   - **Identity Type:** "Named Principal"
   - **Authentication Protocol:** "OAuth 2.0"
   - **Authentication Provider:** (Leave blank for same-org)
   - **Scope:** (Leave blank)
   - **Generate Authorization Header:** ✅ **Checked**
   - **Allow Merge Fields in HTTP Header:** ✅ **Checked**
   - **Allow Merge Fields in HTTP Body:** ❌ **Unchecked**

6. **Click:** "Save"

---

### Step 3: Authorize Access

After creating the Named Credential, you may need to authorize it:

1. **Go back to the Named Credential you just created**
2. **Click:** "Edit"
3. **Look for an "Authenticate" button** at the bottom
4. **Click it and complete the OAuth flow** if prompted

---

## Alternative: Simple Session-Based Approach

If the above doesn't work, use this simpler approach:

1. **Navigate to Setup → Named Credentials**
2. **Click:** "New Legacy"
3. **Fill in:**
   - **Label:** `Salesforce_Tooling_API`
   - **Name:** `Salesforce_Tooling_API`
   - **URL:** `https://yourinstance.my.salesforce.com`
     - Replace with your actual org URL (get from `URL.getOrgDomainUrl().toExternalForm()`)
   - **Identity Type:** "Anonymous"
   - **Authentication Protocol:** "No Authentication"
   - **Generate Authorization Header:** ❌ **Unchecked**
   - **Allow Merge Fields in HTTP Header:** ✅ **Checked**
   - **Allow Merge Fields in HTTP Body:** ❌ **Unchecked**

4. **Click:** "Save"

---

## Testing the Named Credential

Run this in Execute Anonymous to test:

```apex
String endpoint = 'callout:Salesforce_Tooling_API/services/data/v64.0/tooling/query?q=' +
    EncodingUtil.urlEncode('SELECT Id FROM Flow LIMIT 1', 'UTF-8');

HttpRequest req = new HttpRequest();
req.setEndpoint(endpoint);
req.setMethod('GET');
req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
req.setHeader('Content-Type', 'application/json');

Http http = new Http();
HttpResponse res = http.send(req);

System.debug('Status Code: ' + res.getStatusCode());
System.debug('Status: ' + res.getStatus());
System.debug('Body: ' + res.getBody());
```

**Expected Result:** Status Code 200 with JSON response containing flow data

---

## Troubleshooting

### Error: "Unauthorized endpoint"
- **Solution:** Add Remote Site Setting for your org URL
- Setup → Remote Site Settings → New
- URL: Your org domain (e.g., `https://yourinstance.my.salesforce.com`)

### Error: "401 Unauthorized"
- **Solution:** Check Named Credential authentication settings
- Verify "Generate Authorization Header" is enabled
- Try the Alternative Simple Session-Based Approach above

### Error: "Named Credential not found"
- **Solution:** Verify the Named Credential API name matches exactly: `Salesforce_Tooling_API`
- Check spelling and underscores

---

## Next Steps

After setting up the Named Credential:

1. **Update Apex code** to use `callout:Salesforce_Tooling_API` instead of direct URL
2. **Test the reanalyzeFlow method** from the dashboard
3. **Verify full flow metadata** is being retrieved

---

## Benefits of This Approach

✅ **No session ID issues** - Named Credential handles auth properly
✅ **Full flow metadata** - Gets complete flow structure from Tooling API
✅ **Works synchronously** - Maintains user session context for Einstein
✅ **Secure** - Proper OAuth-based authentication
✅ **Maintainable** - Easy to update endpoint or auth settings

---

**Once this is set up, the flow analysis will have access to the complete flow metadata for accurate Einstein-powered analysis!**
