# Flow AI Audit - Deployment Guide

Deploy Flow AI Audit Dashboard to any Salesforce org in minutes.

---

## Prerequisites

- Salesforce CLI installed ([Download](https://developer.salesforce.com/tools/salesforcecli))
- Git installed
- Salesforce org with Einstein Prompt Template API enabled
- System Administrator access

---

## Quick Deploy

### 1. Clone and Authenticate

```bash
git clone https://github.com/pasumartyshiva/FlowAIAudit.git
cd FlowAIAudit

# Authenticate to your org
sf org login web --alias my-org
```

### 2. Deploy Metadata

```bash
sf project deploy start --source-dir force-app/main/default --target-org my-org
```

### 3. Configure Tooling API Access

Create the Named Credential for flow metadata access:

**Setup → Named Credentials → New**

```
Label: Salesforce_Tooling_API
Name: Salesforce_Tooling_API  
URL: https://YOUR_INSTANCE.my.salesforce.com
Identity Type: Named Principal
Authentication Protocol: OAuth 2.0
```

**Setup → Auth. Providers → New → Salesforce**

```
Name: SalesforceToolingAuthProvider
Authorize Endpoint: https://login.salesforce.com/services/oauth2/authorize
Token Endpoint: https://login.salesforce.com/services/oauth2/token
Default Scopes: api web refresh_token
```

**Setup → App Manager → New Connected App**

```
Connected App Name: Flow_AI_Audit_Tooling_API
Enable OAuth Settings: ✓
Callback URL: <from Auth Provider>
OAuth Scopes: api, refresh_token, id
```

Link them together and authenticate the Named Credential.

### 4. Grant Access

**Setup → Permission Sets → New**

```
Label: Flow_AI_Audit_User
Grant access to:
- Flow_Analysis__c object (CRUD + View/Modify All)
- Apex classes: FlowAnalysis*, ToolingAPIService, ExternalLLMService
- Visualforce page: FlowAnalysisExport
```

Assign to users.

### 5. Verify

Navigate to **Flow AI Audit Dashboard** tab → Click **Fetch All Flows**

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Tooling API connection failed | Re-authenticate Named Credential |
| No flows appear | Check browser console, verify Tooling API access |
| Einstein API error | Verify Einstein is enabled and you have credits |
| Deployment fails | Update API version in sfdx-project.json |

---

## Upgrading

```bash
git pull origin main
sf project deploy start --source-dir force-app/main/default --target-org my-org
```

---

## Support

- **Issues**: https://github.com/pasumartyshiva/FlowAIAudit/issues
- **Documentation**: README.md

