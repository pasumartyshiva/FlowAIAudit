# Flow AI Audit Dashboard - Quick Start Guide

## Prerequisites

- Salesforce org with System Administrator access
- Einstein 1 license with Prompt Builder
- Salesforce CLI (`sf`) installed

```bash
# Verify CLI is installed
sf version
```

---

## Step 1: Deploy (5 minutes)

```bash
# Clone and deploy
git clone https://github.com/pasumartyshiva/FlowAIAudit.git
cd FlowAIAudit
sf org login web --alias my-org --set-default
sf project deploy start --source-dir force-app
```

---

## Step 2: Tooling API Setup (10 minutes)

The Tooling API allows the app to fetch flow metadata for analysis.

### 2.1 Create Connected App

1. **Setup → Apps → App Manager → New Connected App**
2. Configure:
   - **Name**: `Tooling_API_Access`
   - **Contact Email**: Your email
   - **Enable OAuth Settings**: ✅ Check
   - **Callback URL**: `https://YOUR_DOMAIN.my.salesforce.com/services/authcallback/ToolingAPILoopback`
   - **OAuth Scopes**: Add `api` and `refresh_token, offline_access`
3. **Save** → Copy Consumer Key and Consumer Secret

### 2.2 Create Auth Provider

1. **Setup → Identity → Auth. Providers → New**
2. Configure:
   - **Provider Type**: Salesforce
   - **Name**: `ToolingAPILoopback`
   - **URL Suffix**: `ToolingAPILoopback`
   - **Consumer Key/Secret**: Paste from step 2.1
   - **Default Scopes**: `api refresh_token`
3. **Save**

### 2.3 Create Named Credential

1. **Setup → Security → Named Credentials → New**
2. Configure:
   - **Label**: `Salesforce_Tooling_API`
   - **URL**: `https://YOUR_DOMAIN.my.salesforce.com`
   - **Identity Type**: Named Principal
   - **Authentication Protocol**: OAuth 2.0
   - **Authentication Provider**: ToolingAPILoopback
   - **Scope**: `api refresh_token`
   - ✅ **Start Authentication Flow on Save**
3. **Save** → Complete the OAuth flow → Verify status shows "Authenticated"

---

## Step 3: Einstein Configuration (2 minutes)

1. **Setup → Einstein → Prompt Templates**
2. Find **"FlowAIAudit"** template
3. Click **Edit** → Verify model is set (Claude Sonnet recommended)
4. Click **Activate**

---

## Step 4: Run Your First Analysis

1. **App Launcher** → Search "Flow AI Audit Dashboard"
2. Click **Sync Flows** to load your org's flows
3. Select a flow → Click **Re-analyze**
4. Wait 30-60 seconds for results
5. Click **View** to see the analysis

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **No flows in dropdown** | Verify Named Credential shows "Authenticated" |
| **Analysis stuck** | Check Einstein limits in Setup → Einstein → Usage |
| **Permission errors** | Assign permission set: `sf org assign permset --name Flow_AI_Audit_Dashboard_Access` |
| **PDF not downloading** | Allow pop-ups for your Salesforce domain |

---

## Understanding Results

| Score | Status | Action |
|-------|--------|--------|
| 70-100% | **PASS** | Minor improvements only |
| 40-69% | **NEEDS WORK** | Address recommendations |
| 0-39% | **FAIL** | Requires significant fixes |

### 12 Analysis Categories

1. Documentation & Naming
2. Logic Modularity & Reuse
3. Bulkification & Loop Efficiency
4. Defensive Design (Null Checks)
5. Data-Driven Design (No Hardcoding)
6. Error Handling & Fault Paths
7. Security & Permissions
8. Automation Strategy
9. Governor Limits & Batching
10. Sync vs Async Processing
11. Flow vs Apex Decision
12. Summary & Priorities

---

## Additional Resources

- **Detailed Tooling API Setup**: [docs/TOOLING_API_SETUP.md](docs/TOOLING_API_SETUP.md)
- **Reports Setup Guide**: [REPORTS_SETUP_GUIDE.md](REPORTS_SETUP_GUIDE.md)
- **GitHub Issues**: [Report bugs or request features](https://github.com/pasumartyshiva/FlowAIAudit/issues)

---

*Happy Flow Auditing!*
