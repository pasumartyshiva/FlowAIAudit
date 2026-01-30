# Salesforce Tooling API Setup Guide

## Overview

This guide walks you through setting up the Salesforce Tooling API integration for the Flow AI Audit Dashboard. The Tooling API allows the application to fetch flow metadata programmatically for analysis.

---

## Prerequisites

- Salesforce org with System Administrator access
- Connected App creation permissions
- Named Credential setup permissions

---

## Step 1: Create a Connected App

### 1.1 Navigate to Setup
1. Log into your Salesforce org
2. Go to **Setup** → **Apps** → **App Manager**
3. Click **New Connected App**

### 1.2 Configure Basic Information
- **Connected App Name**: `Tooling API Access`
- **API Name**: `Tooling_API_Access`
- **Contact Email**: Your email address

### 1.3 Enable OAuth Settings
Check the box **"Enable OAuth Settings"**

#### Callback URL:
```
https://YOUR_ORG_DOMAIN.my.salesforce.com/services/authcallback/ToolingAPILoopback
```

Replace `YOUR_ORG_DOMAIN` with your actual Salesforce domain (e.g., `trailsignup-c0713056990151`)

#### Selected OAuth Scopes:
Add the following scopes:
- ✅ **Access the identity URL service (id, profile, email, address, phone)**
- ✅ **Manage user data via APIs (api)**
- ✅ **Perform requests at any time (refresh_token, offline_access)**
- ✅ **Access custom permissions (custom_permissions)**

### 1.4 Save and Get Consumer Key
1. Click **Save**
2. Click **Continue**
3. Copy the **Consumer Key** (you'll need this later)
4. Click **Click to reveal** and copy the **Consumer Secret** (keep this secure!)

Example Consumer Key:
```
3MVG9LjfaBmM3Lgto1b3nzdIHlbfZMOsSTLxe969TCnytlCLOo0LlYTjMbnir_ykJV6iyuRnSfIRRTeUDFt4g
```

---

## Step 2: Create Auth Provider

### 2.1 Navigate to Auth Providers
1. Go to **Setup** → **Identity** → **Auth. Providers**
2. Click **New**

### 2.2 Configure Auth Provider
- **Provider Type**: `Salesforce`
- **Name**: `ToolingAPILoopback`
- **URL Suffix**: `ToolingAPILoopback`
- **Consumer Key**: Paste the Consumer Key from Step 1.4
- **Consumer Secret**: Paste the Consumer Secret from Step 1.4
- **Authorize Endpoint URL**: Leave blank (defaults to Salesforce)
- **Token Endpoint URL**: Leave blank (defaults to Salesforce)
- **Default Scopes**: `full refresh_token offline_access`

### 2.3 Save and Note the Auth Provider ID
After saving, note the Auth Provider ID (format: `0SOXXXXXXXXXXXXXX`)

Example:
```
Auth Provider ID: 0SOKY000000ajPy4AI
```

---

## Step 3: Create Named Credential

### 3.1 Navigate to Named Credentials
1. Go to **Setup** → **Security** → **Named Credentials**
2. Click **New Named Credential**

### 3.2 Configure Named Credential
- **Label**: `Salesforce_Tooling_API`
- **Name**: `Salesforce_Tooling_API`
- **URL**: Your Salesforce instance URL
  ```
  https://YOUR_ORG_DOMAIN.my.salesforce.com
  ```
  Example: `https://trailsignup-c0713056990151.my.salesforce.com`

- **Identity Type**: `Named Principal`
- **Authentication Protocol**: `OAuth 2.0`
- **Authentication Provider**: Select `ToolingAPILoopback` (created in Step 2)
- **Scope**: `full refresh_token offline_access`
- **Start Authentication Flow on Save**: ✅ Check this box

### 3.3 Complete Authentication

⚠️ **Important**: Use an **incognito/private browser window** for OAuth authentication to avoid cookie conflicts.

1. Click **Save**
2. You'll be redirected to authenticate
3. You may encounter multiple login prompts (this is expected for loopback configuration):
   - **First login prompt** → Enter your Salesforce credentials and log in
   - **Authorization screen** → Click **Allow** to grant permissions
   - **Second login prompt may appear** → Log in again (same credentials)
   - **Final authorization screen** → Click **Allow**
4. You'll be redirected back to the Named Credential page

**Why Multiple Login Prompts?**
This behavior occurs because we're setting up an Auth Provider that points back to the same org (loopback configuration). The system needs to authenticate both the initial request and the callback.

### 3.4 Troubleshooting OAuth Authentication

#### Issue: Token Mismatch Error
**Solution**: If you see a "Token Mismatch" or similar error:
1. Refresh the browser page
2. Try the authentication flow again
3. Ensure you're using an incognito/private window

#### Issue: Authentication Fails or Loops
**Solution**:
1. Clear your browser cache and cookies
2. Open a new incognito/private window
3. Navigate to Setup → Named Credentials
4. Edit the Named Credential and restart the authentication flow

#### Issue: "Authentication Failed" After Clicking Allow
**Solution**: Temporarily extend OAuth scope to include `full` access:
1. Go to **Setup** → **Apps** → **App Manager**
2. Find your Connected App (`Tooling API Access`)
3. Click the dropdown → **Edit**
4. In **Selected OAuth Scopes**, ensure **Full access (full)** is included
5. Click **Save**
6. Return to Named Credential and retry authentication
7. **After successful authentication**, you can edit the Connected App to remove `full` scope and keep only: `api`, `refresh_token`, `offline_access`

#### Issue: Redirect Loop or "Invalid Grant" Error
**Solution**: Check that callback URL in Connected App matches exactly:
```
https://YOUR_ORG_DOMAIN.my.salesforce.com/services/authcallback/ToolingAPILoopback
```
- Ensure `YOUR_ORG_DOMAIN` matches your actual org domain
- The URL suffix `ToolingAPILoopback` must match the Auth Provider URL Suffix exactly

---

## Step 4: Verify Setup

### 4.1 Test Named Credential
1. Go to **Setup** → **Security** → **Named Credentials**
2. Find `Salesforce_Tooling_API`
3. Click **Edit**
4. Verify that **Authentication Status** shows as `Authenticated`

### 4.2 Test API Call (Developer Console)
Open Developer Console and run this anonymous Apex:

```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:Salesforce_Tooling_API/services/data/v65.0/tooling/query?q=SELECT+Id,DeveloperName+FROM+Flow+LIMIT+1');
req.setMethod('GET');

Http http = new Http();
HttpResponse res = http.send(req);

System.debug('Status Code: ' + res.getStatusCode());
System.debug('Response: ' + res.getBody());
```

Expected Response:
```json
{
  "size": 1,
  "totalSize": 1,
  "done": true,
  "queryLocator": null,
  "entityTypeName": "Flow",
  "records": [...]
}
```

---

## Step 5: Grant Permissions

### 5.1 Permission Set for Users
Create a Permission Set to grant access:

1. Go to **Setup** → **Users** → **Permission Sets**
2. Click **New**
3. **Label**: `Flow AI Audit Dashboard Access`
4. **API Name**: `Flow_AI_Audit_Dashboard_Access`
5. Click **Save**

### 5.2 Add Permissions
1. Click **Object Settings** → **Flow_Analysis__c**
2. Enable: Read, Create, Edit, Delete, View All, Modify All
3. Click **Save**

### 5.3 Assign Permission Set
1. Click **Manage Assignments**
2. Click **Add Assignments**
3. Select users who need access
4. Click **Assign**

---

## Step 6: Update Apex Class

Ensure your `FlowMetadataService` Apex class uses the correct Named Credential:

```apex
public class FlowMetadataService {
    private static final String NAMED_CREDENTIAL = 'callout:Salesforce_Tooling_API';

    public static String fetchFlowMetadata(String flowApiName) {
        String endpoint = NAMED_CREDENTIAL + '/services/data/v65.0/tooling/query?q=' +
            EncodingUtil.urlEncode('SELECT Id, Metadata FROM Flow WHERE DeveloperName = \'' +
            flowApiName + '\' ORDER BY VersionNumber DESC LIMIT 1', 'UTF-8');

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            return res.getBody();
        } else {
            throw new CalloutException('Failed to fetch flow metadata: ' + res.getBody());
        }
    }
}
```

---

## Additional Troubleshooting

### Issue: "Unauthorized endpoint" error

**Solution**: Add Remote Site Settings
1. Go to **Setup** → **Security** → **Remote Site Settings**
2. Click **New Remote Site**
3. **Name**: `Salesforce_Instance`
4. **URL**: Your Salesforce instance URL (e.g., `https://trailsignup-c0713056990151.my.salesforce.com`)
5. **Active**: ✅
6. Click **Save**

### Issue: "Session expired or invalid"

**Solution**: Re-authenticate the Named Credential
1. Go to **Setup** → **Security** → **Named Credentials**
2. Click **Edit** on `Salesforce_Tooling_API`
3. Check **Start Authentication Flow on Save**
4. Click **Save** (use incognito window)
5. Complete the authentication flow

### Issue: "Insufficient privileges"

**Solution**: Verify Connected App permissions
1. Go to **Setup** → **Apps** → **Connected Apps** → **Manage Connected Apps**
2. Click on your Connected App
3. Click **Edit Policies**
4. **Permitted Users**: `Admin approved users are pre-authorized`
5. **IP Relaxation**: `Relax IP restrictions`
6. Click **Save**

### Issue: API Calls Return 401 or 403 Errors

**Solution**: Verify OAuth scopes in Connected App
1. Go to **Setup** → **Apps** → **App Manager**
2. Edit your Connected App (`Tooling API Access`)
3. Ensure these scopes are enabled in **Selected OAuth Scopes**:
   - ✅ **Access the identity URL service (id, profile, email, address, phone)**
   - ✅ **Manage user data via APIs (api)**
   - ✅ **Perform requests at any time (refresh_token, offline_access)**
   - ✅ **Full access (full)** (can be removed after authentication succeeds)
4. Click **Save**
5. Re-authenticate the Named Credential if needed

---

## Configuration Summary

Once setup is complete, you should have:

| Component | Name | Purpose |
|-----------|------|---------|
| **Connected App** | Tooling API Access | OAuth authentication |
| **Auth Provider** | ToolingAPILoopback | Salesforce OAuth provider |
| **Named Credential** | Salesforce_Tooling_API | Secure API endpoint |
| **Permission Set** | Flow AI Audit Dashboard Access | User access control |

---

## Security Best Practices

1. **Never share Consumer Secret** - Keep it secure
2. **Use Permission Sets** - Control user access granularly
3. **Regular Audits** - Review who has access to the Named Credential
4. **IP Restrictions** - Consider adding IP restrictions to the Connected App in production
5. **Session Security** - Enable high assurance sessions for sensitive operations
6. **Reduce OAuth Scopes After Authentication** (Recommended for Production):
   - After successfully authenticating the Named Credential with `full refresh_token offline_access` scope
   - Edit the Connected App and remove the `full` scope
   - Keep only the minimum required scopes: `api`, `refresh_token`, `offline_access`, and `id`
   - The Named Credential will continue to work with the refresh token
   - This follows the principle of least privilege and reduces security risk

   **How to Reduce Scopes:**
   1. Go to **Setup** → **Apps** → **App Manager**
   2. Edit your Connected App (`Tooling API Access`)
   3. In **Selected OAuth Scopes**, remove **Full access (full)**
   4. Ensure these remain selected:
      - ✅ **Access the identity URL service (id, profile, email, address, phone)**
      - ✅ **Manage user data via APIs (api)**
      - ✅ **Perform requests at any time (refresh_token, offline_access)**
   5. Click **Save**
   6. The Named Credential authentication will persist using the refresh token

---

## Next Steps

After completing this setup:
1. ✅ Deploy the Flow AI Audit Dashboard components
2. ✅ Configure Einstein Prompt Templates
3. ✅ Test the flow analysis functionality
4. ✅ Grant users access via Permission Sets

---

## Additional Resources

- [Salesforce Named Credentials Documentation](https://help.salesforce.com/s/articleView?id=sf.named_credentials_about.htm)
- [Connected Apps and OAuth](https://help.salesforce.com/s/articleView?id=sf.connected_app_overview.htm)
- [Tooling API Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.api_tooling.meta/api_tooling/)

---

**Document Version**: 2.0
**Last Updated**: January 30, 2026
**Maintained By**: Flow AI Audit Dashboard Team

**Changelog v2.0:**
- Updated OAuth scopes to `full refresh_token offline_access` for initial authentication
- Added comprehensive OAuth troubleshooting section in Step 3
- Added guidance for using incognito/private windows during authentication
- Documented expected multiple login prompts for loopback configuration
- Added security best practice for reducing scopes after authentication
- Consolidated all troubleshooting steps into relevant sections
