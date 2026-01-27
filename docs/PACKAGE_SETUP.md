# Flow AI Audit - Package Setup Guide

This guide covers deploying Flow AI Audit and creating an unmanaged package.

---

## Deployment Inventory

Components should be deployed in this order:

| # | Type | Components | Count |
|---|------|------------|-------|
| 1 | Custom Objects | `Flow_Analysis__c`, `LLM_Configuration__mdt` | 2 |
| 2 | Custom Fields | Flow_Analysis__c (14), LLM_Configuration__mdt (9) | 23 |
| 3 | List Views | `Flow_Analysis__c.All` | 1 |
| 4 | Apex Classes | 7 main classes + 7 test classes | 14 |
| 5 | Visualforce Pages | `FlowAnalysisPDF`, `FlowAnalysisExport` | 2 |
| 6 | LWC | `flowAnalysisDashboard` | 1 |
| 7 | FlexiPage | `Flow_AI_Audit_Dashboard` | 1 |
| 8 | GenAI Prompt Template | `FlowAIAudit` | 1 |
| 9 | Report Type | `Flow_Analysis_Report` | 1 |
| 10 | Custom Metadata | 3 LLM configurations | 3 |
| 11 | Remote Site Settings | 4 settings | 4 |
| 12 | Layout | `Flow_Analysis__c-Flow Analysis Layout` | 1 |
| 13 | Permission Set | `Flow_AI_Audit_Access` | 1 |

**Total: ~55 components**

---

## Tooling API Setup

The Tooling API configuration requires manual steps because OAuth credentials are generated at runtime.

### Step 1: Create Connected App

1. **Setup → Apps → App Manager → New Connected App**
2. Fill in:
   - **Connected App Name**: `Tooling_API_Access`
   - **API Name**: `Tooling_API_Access`
   - **Contact Email**: Your email
3. Enable OAuth Settings:
   - **Enable OAuth Settings**: ✅ Checked
   - **Callback URL**: `https://YOUR_DOMAIN.my.salesforce.com/services/authcallback/ToolingAPILoopback`
   - **Selected OAuth Scopes**:
     - `Access the identity URL service (id)`
     - `Manage user data via APIs (api)`
     - `Perform requests at any time (refresh_token, offline_access)`
4. **Save** and wait 2-10 minutes for activation
5. **Copy Consumer Key and Consumer Secret** (you'll need these)

### Step 2: Create Auth Provider

1. **Setup → Identity → Auth. Providers → New**
2. Fill in:
   - **Provider Type**: Salesforce
   - **Name**: `ToolingAPILoopback`
   - **URL Suffix**: `ToolingAPILoopback`
   - **Consumer Key**: (paste from Connected App)
   - **Consumer Secret**: (paste from Connected App)
   - **Default Scopes**: `api refresh_token`
3. **Save**

### Step 3: Create Named Credential

1. **Setup → Security → Named Credentials → New Legacy**
2. Fill in:
   - **Label**: `Salesforce_Tooling_API`
   - **Name**: `Salesforce_Tooling_API`
   - **URL**: `https://YOUR_DOMAIN.my.salesforce.com`
   - **Identity Type**: Named Principal
   - **Authentication Protocol**: OAuth 2.0
   - **Authentication Provider**: `ToolingAPILoopback`
   - **Scope**: `api refresh_token`
   - **Start Authentication Flow on Save**: ✅ Checked
3. **Save** → Click **Allow** when prompted
4. Verify status shows **"Authenticated"**

### Verify Setup

Run this in Developer Console (Execute Anonymous):

```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:Salesforce_Tooling_API/services/data/v65.0/tooling/query?q=SELECT+Id+FROM+Flow+LIMIT+1');
req.setMethod('GET');
Http http = new Http();
HttpResponse res = http.send(req);
System.debug('Status: ' + res.getStatusCode());
System.debug('Body: ' + res.getBody());
```

Expected: `Status: 200`

---

## Creating Unmanaged Package

### Step 1: Create Package

1. **Setup → Apps → Packaging → Package Manager**
2. Click **New**
3. Fill in:
   - **Package Name**: `Flow AI Audit`
   - **Description**: AI-powered Flow analysis tool using Einstein to evaluate flows against 12 best practices
4. **Save**

### Step 2: Add Components

Click **Add** and add components in this order:

#### Custom Objects (adds fields automatically)
- `Flow_Analysis__c`
- `LLM_Configuration__mdt`

#### Apex Classes
- `FlowAnalysisDashboardController`
- `FlowAnalysisService`
- `FlowAnalysisPDFController`
- `FlowAnalysisBatch`
- `FlowAnalysisQueueable`
- `ExternalLLMService`
- `PromptTemplateDebugger`
- `FlowAnalysisDashboardCtrlTest`
- `FlowAnalysisServiceTest`
- `FlowAnalysisPDFControllerTest`
- `FlowAnalysisBatchTest`
- `FlowAnalysisQueueableTest`
- `ExternalLLMServiceTest`
- `PromptTemplateDebuggerTest`

#### Visualforce Pages
- `FlowAnalysisPDF`
- `FlowAnalysisExport`

#### Lightning Components
- `flowAnalysisDashboard`

#### FlexiPages
- `Flow_AI_Audit_Dashboard`

#### GenAI Prompt Templates
- `FlowAIAudit`

#### Report Types
- `Flow_Analysis_Report`

#### Custom Metadata Records
- `LLM_Configuration.Anthropic_Claude_3_5_Sonnet`
- `LLM_Configuration.Google_Gemini_1_5_Pro`
- `LLM_Configuration.HuggingFace_Qwen_72B`

#### Remote Site Settings
- `Anthropic_API`
- `Google_Gemini`
- `HuggingFace_API`
- `Salesforce_Instance`

#### Layouts
- `Flow_Analysis__c-Flow Analysis Layout`

#### Permission Sets
- `Flow_AI_Audit_Access`

### Step 3: Upload Package

1. Click **Upload**
2. Fill in version info
3. Click **Upload**
4. Copy the installation URL

---

## Post-Install Steps (for package installers)

After installing the package:

1. **Assign Permission Set**: `Flow_AI_Audit_Access`
2. **Configure Tooling API**: Follow Steps 1-3 above
3. **Activate Prompt Template**: Setup → Einstein → Prompt Templates → Activate `FlowAIAudit`
4. **Add Dashboard to App**: Add `Flow_AI_Audit_Dashboard` to desired Lightning App

---

## CLI Deployment Commands

```bash
# Deploy everything except V2/V3 templates
sf project deploy start --source-dir force-app/main/default/objects --target-org YOUR_ORG
sf project deploy start --source-dir force-app/main/default/classes --source-dir force-app/main/default/pages --target-org YOUR_ORG
sf project deploy start --source-dir force-app/main/default/lwc --source-dir force-app/main/default/flexipages --target-org YOUR_ORG
sf project deploy start --source-dir force-app/main/default/genAiPromptTemplates/FlowAIAudit.genAiPromptTemplate-meta.xml --target-org YOUR_ORG
sf project deploy start --source-dir force-app/main/default/reportTypes --target-org YOUR_ORG
sf project deploy start --source-dir force-app/main/default/customMetadata --source-dir force-app/main/default/remoteSiteSettings --source-dir force-app/main/default/layouts --target-org YOUR_ORG
sf project deploy start --source-dir force-app/main/default/permissionsets --target-org YOUR_ORG

# Run tests
sf apex run test --class-names FlowAnalysisServiceTest --class-names FlowAnalysisPDFControllerTest --class-names FlowAnalysisDashboardCtrlTest --class-names FlowAnalysisQueueableTest --class-names FlowAnalysisBatchTest --class-names ExternalLLMServiceTest --class-names PromptTemplateDebuggerTest --result-format human --target-org YOUR_ORG --wait 10

# Assign permission set
sf org assign permset --name Flow_AI_Audit_Access --target-org YOUR_ORG
```

---

## Troubleshooting

### "No flows showing"
- Verify Named Credential shows "Authenticated"
- Re-authenticate if needed

### "Analysis stuck at Processing"
- Check Einstein limits in Setup
- Verify prompt template is Active

### "Insufficient Privileges"
- Assign `Flow_AI_Audit_Access` permission set

### Tests failing
- Ensure permission set is assigned to running user
- All 65 tests should pass at 100%
