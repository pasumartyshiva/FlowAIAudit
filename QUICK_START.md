# 🚀 Flow AI Audit Dashboard - Complete Quick Start Guide

## 📋 Table of Contents

1. [Prerequisites](#-prerequisites)
2. [Installation](#-installation-15-minutes)
3. [Tooling API Setup](#-tooling-api-setup-10-minutes)
4. [Einstein Configuration](#-einstein-configuration-5-minutes)
5. [First Flow Analysis](#-first-flow-analysis-2-minutes)
6. [Executive Reports Setup](#-executive-reports-setup-optional-5-minutes)
7. [Troubleshooting](#-troubleshooting)

---

## ✅ Prerequisites

### Required Access:
- ✅ Salesforce org (Developer, Sandbox, or Production)
- ✅ System Administrator permissions
- ✅ Einstein 1 license with Prompt Builder
- ✅ API Enabled for your user
- ✅ Customize Application permission

### Required Software:
- ✅ Salesforce CLI (`sf`) version 2.0+
  - Install: `npm install -g @salesforce/cli`
  - Verify: `sf version`
- ✅ Git (for cloning repository)
  - Verify: `git --version`

### Check Your Environment:
```bash
# Verify Salesforce CLI
sf version

# Verify Git
git --version

# Verify org access
sf org list
```

---

## 📦 Installation (15 minutes)

### Option 1: Clone from GitHub (Recommended)

```bash
# 1. Clone the repository
git clone https://github.com/pasumartyshiva/FlowAIAudit.git
cd FlowAIAudit

# 2. Authenticate with your Salesforce org
sf org login web --alias my-flow-audit-org --set-default

# 3. Verify connection
sf org display

# 4. Deploy all metadata
sf project deploy start --source-dir force-app

# 5. Verify deployment
sf project deploy report
```

**Expected Output:**
```
✓ Deploy Succeeded
Components Deployed: 127
Tests Run: 8
Test Success Rate: 100%
```

### Option 2: Manual Deployment

1. Download ZIP from: https://github.com/pasumartyshiva/FlowAIAudit/archive/refs/heads/main.zip
2. Extract to your local machine
3. Open VS Code
4. Install Salesforce Extensions for VS Code
5. Right-click `force-app` folder → "SFDX: Deploy Source to Org"

---

## 🔧 Tooling API Setup (10 minutes)

**Why needed**: The Tooling API allows the app to fetch flow metadata for analysis.

### Step 1: Create Connected App (3 minutes)

1. **Navigate to Setup**:
   - Setup → Apps → App Manager
   - Click **"New Connected App"**

2. **Basic Information**:
   ```
   Connected App Name: Tooling_API_Access
   API Name: Tooling_API_Access
   Contact Email: your-email@example.com
   ```

3. **Enable OAuth Settings**:
   - ✅ Check "Enable OAuth Settings"

4. **Callback URL** (IMPORTANT - Replace YOUR_DOMAIN):
   ```
   https://YOUR_DOMAIN.my.salesforce.com/services/authcallback/ToolingAPILoopback
   ```

   **How to find YOUR_DOMAIN**:
   - Look at your browser URL when logged into Salesforce
   - Example: `https://trailsignup-c0713056990151.my.salesforce.com`
   - Use the part before `.my.salesforce.com`

5. **Selected OAuth Scopes** (Add these):
   - ✅ Access the identity URL service (id, profile, email, address, phone)
   - ✅ Manage user data via APIs (api)
   - ✅ Perform requests at any time (refresh_token, offline_access)

6. **Save and Get Keys**:
   - Click **Save**
   - Click **Continue**
   - Copy **Consumer Key** → Save it in a secure note
   - Click **"Click to reveal"** → Copy **Consumer Secret** → Save it securely

   Example Consumer Key: `3MVG9LjfaBmM3Lgto1b...`

### Step 2: Create Auth Provider (2 minutes)

1. **Navigate**:
   - Setup → Identity → Auth. Providers
   - Click **"New"**

2. **Configure**:
   ```
   Provider Type: Salesforce
   Name: ToolingAPILoopback
   URL Suffix: ToolingAPILoopback
   Consumer Key: [Paste from Step 1]
   Consumer Secret: [Paste from Step 1]
   Authorize Endpoint URL: [Leave blank]
   Token Endpoint URL: [Leave blank]
   Default Scopes: api refresh_token
   ```

3. **Save** and note the Auth Provider ID (starts with `0SO`)

### Step 3: Create Named Credential (3 minutes)

1. **Navigate**:
   - Setup → Security → Named Credentials
   - Click **"New Named Credential"**

2. **Configure**:
   ```
   Label: Salesforce_Tooling_API
   Name: Salesforce_Tooling_API
   ```

3. **URL** (IMPORTANT - Use YOUR org's domain):
   ```
   https://YOUR_DOMAIN.my.salesforce.com
   ```

   **Example**: `https://trailsignup-c0713056990151.my.salesforce.com`

4. **Authentication Settings**:
   ```
   Identity Type: Named Principal
   Authentication Protocol: OAuth 2.0
   Authentication Provider: ToolingAPILoopback
   Scope: api refresh_token
   ```

   ✅ Check **"Start Authentication Flow on Save"**

5. **Authenticate**:
   - Click **Save**
   - You'll be redirected to authorize
   - Click **Allow**
   - Return to Named Credential page
   - Verify **Authentication Status: Authenticated** ✅

### Step 4: Verify Setup (2 minutes)

Open Developer Console and run:

```apex
// Test Tooling API Access
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:Salesforce_Tooling_API/services/data/v65.0/tooling/query?q=SELECT+Id,DeveloperName+FROM+Flow+LIMIT+1');
req.setMethod('GET');

Http http = new Http();
HttpResponse res = http.send(req);

System.debug('Status: ' + res.getStatusCode());
System.debug('Response: ' + res.getBody());
```

**Expected Output** (check Debug Logs):
```
Status: 200
Response: {"size":1,"totalSize":1,"done":true,"records":[...]}
```

If you see `Status: 200` → ✅ Success! Tooling API is working.

---

## 🤖 Einstein Configuration (5 minutes)

### Step 1: Navigate to Prompt Builder

1. Setup → Einstein → Prompt Templates
2. You should see: **"Flow_Best_Practices_Analysis"**

### Step 2: Configure Template

1. Click on **"Flow_Best_Practices_Analysis"**
2. Click **Edit**
3. Configure settings:
   ```
   Name: Flow_Best_Practices_Analysis
   Model: Claude Sonnet 3.7 (or Claude Sonnet 4.5)
   Response Format: JSON
   Response Structure: [Leave blank]
   ```

4. **Verify Prompt Content**:
   - The prompt should already be populated from deployment
   - It should mention "12 categories"
   - It should reference `{!$Input:FlowMetadata}`

5. **Save and Activate**:
   - Click **Save**
   - Click **Activate**

### Step 3: Test Einstein (Optional)

Run in Developer Console:

```apex
// Quick Einstein test
ConnectApi.EinsteinPromptTemplateGenerationsInput input =
    new ConnectApi.EinsteinPromptTemplateGenerationsInput();
input.isPreview = true;

Map<String, ConnectApi.WrappedValue> inputs = new Map<String, ConnectApi.WrappedValue>();
ConnectApi.WrappedValue flowMetadata = new ConnectApi.WrappedValue();
flowMetadata.value = '{"test":"data"}';
inputs.put('FlowMetadata', flowMetadata);
input.inputParams = inputs;

try {
    ConnectApi.EinsteinPromptTemplateGenerationsRepresentation result =
        ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
            'Flow_Best_Practices_Analysis',
            input
        );
    System.debug('Einstein connected successfully!');
} catch (Exception e) {
    System.debug('Error: ' + e.getMessage());
}
```

---

## 🎯 First Flow Analysis (2 minutes)

### Step 1: Open the Dashboard

1. **App Launcher** (9 dots icon)
2. Search: **"Flow AI Audit Dashboard"**
3. Click to open

### Step 2: Run Your First Analysis

1. **Select a Flow**:
   - Click the dropdown: "Select a Flow"
   - Choose a simple flow to test (not a complex one first)

2. **Run Analysis**:
   - Click **"Run Analysis"** button
   - Wait 30-60 seconds
   - Watch the status change to "Completed"

3. **View Results**:
   - Click **"View"** button
   - See the formatted analysis with:
     - Overall Score (0-100%)
     - 12 Category Cards
     - Status Badges
     - Recommendations

4. **Export PDF** (Optional):
   - Click **"Export PDF"** button
   - Download opens automatically

### Step 3: Analyze Multiple Flows (Batch)

1. Click **"Select Multiple Flows"** button
2. Choose 3-5 flows (start small)
3. Click **"Analyze Selected Flows"**
4. Watch progress in the table
5. View individual results as they complete

### Step 4: Create Executive Reports (Optional - 5 minutes)

For leadership visibility, create Salesforce reports:

1. **Go to Reports Tab**:
   - Click Reports tab in Salesforce
   - Click **"New Report"**

2. **Select Report Type**:
   - Search for **"Flow Analysis Reports"**
   - Click Continue

3. **Create Your First Report** (Flow Analysis Summary):
   ```
   Format: Summary Report
   Group By: Overall Status
   Filters: Status = Completed
   Columns: Flow Label, Overall Score, Status, Last Modified Date
   Add Chart: Horizontal Bar (Status vs Count)
   ```

4. **Save Report**:
   - Name: "Flow Analysis Summary"
   - Folder: Create "Flow Analysis Reports" (Public)
   - Click Save

5. **Create More Reports** (Optional):
   - **Flows Needing Attention**: Flows scoring < 80%
   - **Flow Score Trends**: Track improvements over time
   - See detailed instructions in **REPORTS_SETUP_GUIDE.md**

6. **Build Executive Dashboard** (Optional):
   - Dashboards tab → New Dashboard
   - Add your reports as components
   - Share with leadership

**Why Use Reports?**
- ✅ Real-time data (always current)
- ✅ Schedule automated emails
- ✅ Executive dashboards
- ✅ Export to Excel/PDF anytime
- ✅ Mobile access via Salesforce app
- ✅ Track trends and KPIs

**📘 Detailed Guide**: See **REPORTS_SETUP_GUIDE.md** for complete step-by-step instructions, sample SOQL queries, and dashboard design tips.

---

## 📊 Executive Reports Setup (Optional - 5 minutes)

Once you've analyzed some flows, create Salesforce reports for leadership visibility.

### Quick Report Creation

1. **Navigate to Reports**:
   - Click **Reports** tab
   - Click **"New Report"**
   - Search for **"Flow Analysis Reports"**
   - Click **Continue**

2. **Build Your First Report** (Flow Analysis Summary):
   - **Format**: Summary Report
   - **Group By**: Overall Status
   - **Filters**: Status equals Completed
   - **Columns**: Flow Label, Overall Score, Status, Last Modified Date
   - **Chart**: Horizontal Bar (shows PASS/PARTIAL/FAIL distribution)
   - **Save**: Name it "Flow Analysis Summary"

3. **View Your Report**:
   - See breakdown by PASS (80-100%), PARTIAL (50-79%), FAIL (0-49%)
   - Bar chart shows visual distribution
   - Export to Excel if needed

### Additional Reports You Can Create

**Flows Needing Attention** (Priority List):
```
Format: Tabular
Filters: Status = Completed AND Overall Score < 80
Sort: Overall Score (Ascending - worst first)
Purpose: Focus on flows that need immediate work
```

**Flow Score Trends** (Track Improvements):
```
Format: Summary with Line Chart
Group By: Created Date (by Week)
Chart: Average score over time
Purpose: Measure improvement initiatives
```

### Building an Executive Dashboard

1. Go to **Dashboards** tab → **New Dashboard**
2. Add components:
   - Flow Analysis Summary (Bar Chart)
   - Flow Score Trends (Line Chart)
   - Flows Needing Attention (Table)
3. Set refresh schedule (daily/weekly)
4. Share with executives

### Benefits for Leadership

| Capability | Benefit |
|------------|---------|
| **Real-Time Data** | Always see current state |
| **Trend Analysis** | Track improvements over time |
| **KPI Tracking** | Use average score as team metric |
| **Automated Delivery** | Schedule weekly email reports |
| **Export Flexibility** | Excel/PDF for presentations |
| **Mobile Access** | View on Salesforce mobile app |

📘 **Full Documentation**: See **REPORTS_SETUP_GUIDE.md** for:
- Step-by-step instructions for all reports
- Sample SOQL queries
- Dashboard layout recommendations
- Export instructions
- 7 additional report ideas
- Visualization tips and best practices

---

## 🎨 What You Should See

### Dashboard Layout:
```
┌─────────────────────────────────────────────────────────┐
│ 🤖 Flow AI Audit Dashboard                              │
├─────────────────────────────────────────────────────────┤
│ [Select Flow ▼] [Run Analysis] [Select Multiple Flows] │
├─────────────────────────────────────────────────────────┤
│ Flow Name         │ Status    │ Score │ Date  │ Actions│
│ MyTestFlow        │ Completed │ 75%   │ Now   │ View ▼ │
│ CheckoutFlow      │ Pending   │ -     │ -     │ -      │
└─────────────────────────────────────────────────────────┘
```

### Analysis Modal (View button):
```
┌─────────────────────────────────────────────────────────┐
│                        75%                               │
│                      PARTIAL                             │
├─────────────────────────────────────────────────────────┤
│ 📋 1. Documentation, Naming, and Clarity                │
│ Status: COMPLIANT ✅                                     │
│ Analysis: The flow has clear naming...                  │
│ Recommendation: Continue current practices              │
├─────────────────────────────────────────────────────────┤
│ 🧩 2. Logic Modularity & Reuse                          │
│ Status: PARTIAL ⚠️                                      │
│ ... [10 more categories]                                │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 Key Features

| Feature | What It Does | Why It's Awesome |
|---------|-------------|------------------|
| **Batch Processing** | Analyzes 1000+ flows | 30x faster than V1 |
| **Dashboard** | Visual status of all flows | No more manual tracking |
| **One-Click Re-run** | Analyze single flow | Saves API calls |
| **Real-time Progress** | See batch completion % | No more waiting blindly |
| **Persistent Storage** | Historical analysis | Track improvements |
| **Smart Filtering** | Pass/Fail/Partial filter | Focus on what matters |

---

## 📊 Before & After

### Before (V1) ❌
- ⏱️ 10-30 seconds per flow
- 🔄 Manual one-at-a-time
- 💾 No saved results
- 👀 No progress visibility
- 🔁 Can't re-run easily

### After (V2) ✅
- ⚡ <1 second per flow
- 🚀 Batch 1000+ flows
- 💾 Persistent storage
- 📊 Real-time progress
- 🔁 One-click re-analysis

---

## 🎨 Dashboard Preview

```
┌─────────────────────────────────────────────────────────────┐
│ Flow AI Audit Dashboard                  [Run All] [Refresh]│
├─────────────────────────────────────────────────────────────┤
│  ╔══════╗  ╔══════╗  ╔══════╗  ╔══════╗  ╔══════╗         │
│  ║  45  ║  ║  12  ║  ║   8  ║  ║   5  ║  ║  70  ║         │
│  ║ Pass ║  ║Partl ║  ║ Fail ║  ║Pendg ║  ║Total ║         │
│  ╚══════╝  ╚══════╝  ╚══════╝  ╚══════╝  ╚══════╝         │
├─────────────────────────────────────────────────────────────┤
│ 🔍 Search: [_____________]  Status: [All ▼]                │
├─────────────────────────────────────────────────────────────┤
│ Flow Name      │ Status │ Score │ Last Analyzed │ Actions  │
│ CheckoutFlow   │ Pass   │ 95%   │ 2h ago        │ [▼]      │
│ InvoiceFlow    │ Fail   │ 45%   │ 2h ago        │ [▼]      │
│ OrderFlow      │ Partial│ 68%   │ 2h ago        │ [▼]      │
└─────────────────────────────────────────────────────────────┘
```

---

## 🆘 Troubleshooting

### Issue 1: "Unauthorized endpoint"

**Symptom**: Error when running analysis

**Solution**:
1. Setup → Security → Remote Site Settings
2. Click **"New Remote Site"**
3. Configure:
   ```
   Name: Salesforce_Instance
   URL: https://YOUR_DOMAIN.my.salesforce.com
   Active: ✅ Checked
   ```
4. Click **Save**

### Issue 2: "No flows showing in dropdown"

**Symptom**: Dropdown is empty

**Solution**:
1. Verify you have active flows in your org:
   - Setup → Flows
   - Check you have at least one Active flow

2. Check Named Credential authentication:
   - Setup → Named Credentials
   - Find "Salesforce_Tooling_API"
   - Status should show "Authenticated" ✅
   - If not, click Edit → Re-authenticate

3. Check browser console (F12):
   - Look for error messages
   - Share with support if needed

### Issue 3: "Analysis stuck in Processing"

**Symptom**: Status never changes from "Processing"

**Solution**:
1. Check Einstein service limits:
   - Setup → Einstein → Usage
   - Verify you haven't hit limits

2. Check Debug Logs:
   - Setup → Debug Logs
   - Monitor for new user → Save
   - Re-run analysis
   - Check logs for errors

3. Verify prompt template:
   - Setup → Einstein → Prompt Templates
   - Status should be "Active"

### Issue 4: "JSON not parsing / Raw JSON displayed"

**Symptom**: See raw JSON instead of formatted cards

**Solution**: This should be fixed in the latest version. If still occurring:
1. Clear browser cache
2. Hard refresh (Ctrl+Shift+R or Cmd+Shift+R)
3. Check console for JavaScript errors

### Issue 5: "PDF Export not working"

**Symptom**: PDF doesn't download

**Solution**:
1. Check pop-up blocker settings
2. Allow pop-ups for your Salesforce domain
3. Try different browser (Chrome recommended)

### Issue 6: "Insufficient Privileges"

**Symptom**: Permission error when accessing dashboard

**Solution**:
1. Assign permission set:
   ```bash
   sf org assign permset --name Flow_AI_Audit_Dashboard_Access
   ```

2. Or manually:
   - Setup → Permission Sets
   - Find "Flow AI Audit Dashboard Access"
   - Click → Manage Assignments → Add your user

### Issue 7: "INVALID_SESSION_ID"

**Symptom**: Session expired error

**Solution**:
1. Re-authenticate Named Credential:
   - Setup → Named Credentials
   - Edit "Salesforce_Tooling_API"
   - Check "Start Authentication Flow on Save"
   - Save → Authenticate

---

## 📊 Understanding Your Results

### Score Ranges:
- **80-100% (PASS)** 🟢: Excellent! Minor improvements only
- **50-79% (PARTIAL)** 🟡: Good, but needs attention
- **0-49% (FAIL)** 🔴: Requires significant improvements

### Status Types:
- **COMPLIANT** ✅: Meets best practices
- **PARTIAL** ⚠️: Some improvements needed
- **ISSUE** ❌: Requires immediate attention

### 12 Categories Explained:

1. **📋 Documentation & Naming**: Are elements well-documented?
2. **🧩 Modularity**: Are subflows used appropriately?
3. **🌪️ Bulkification**: Will it handle 200 records?
4. **✔️ Defensive Design**: Are null checks in place?
5. **🔲 Data-Driven Design**: Are values hardcoded?
6. **🚨 Error Handling**: Are fault paths configured?
7. **🔒 Security**: Is flow context appropriate?
8. **🏗️ Tool Strategy**: Is Flow the right tool?
9. **⏳ Governor Limits**: Will it scale?
10. **⚡ Processing Model**: Sync vs async appropriate?
11. **⚖️ Flow vs Apex**: Right tool for the job?
12. **📝 Summary**: Overall recommendations

---

## 🎓 Best Practices for Using the Tool

### For Administrators:

1. **Start Small**:
   - Analyze 5-10 flows first
   - Understand the results
   - Then batch analyze all

2. **Prioritize Fixes**:
   - Focus on FAIL status first
   - Then address PARTIAL
   - PASS flows need monitoring only

3. **Regular Audits**:
   - Schedule quarterly reviews
   - Track score improvements
   - Document changes

4. **Share Results**:
   - Export PDFs for flow creators
   - Discuss recommendations
   - Track remediation

### For Flow Developers:

1. **Pre-Deployment Check**:
   - Analyze before deploying to production
   - Aim for 80%+ score
   - Address all ISSUE categories

2. **Learn from Feedback**:
   - Read explanations carefully
   - Understand WHY, not just WHAT
   - Apply learnings to new flows

3. **Iterative Improvement**:
   - Don't try to fix everything at once
   - Address high-priority items first
   - Re-analyze after changes

4. **Documentation**:
   - Use recommendations to improve docs
   - Add descriptions based on feedback
   - Update as flow evolves

### For Architects:

1. **Set Standards**:
   - Establish minimum score (e.g., 70%)
   - Define acceptable categories
   - Enforce before production

2. **Create Templates**:
   - Build compliant flow templates
   - Share reusable subflows
   - Document best practices

3. **Monitor Trends**:
   - Track org-wide average score
   - Identify common issues
   - Provide targeted training

---

## 📁 Project Structure

```
PersonalOrg/
├── force-app/main/default/
│   ├── objects/Flow_Analysis__c/      ← Data storage
│   ├── classes/                        ← Business logic
│   ├── lwc/flowAnalysisDashboard/     ← Dashboard UI
│   ├── genAiPromptTemplates/          ← AI template
│   └── flexipages/                    ← Lightning page
│
├── deploy.sh                          ← One-command deploy
├── validate.sh                        ← Pre-deploy check
│
├── FLOW_AI_AUDIT_README.md           ← Full user guide
├── EINSTEIN_GPT_INTEGRATION.md       ← AI setup guide
├── DEPLOYMENT_GUIDE.md               ← Deploy instructions
├── PROJECT_SUMMARY.md                ← Complete overview
└── QUICK_START.md                    ← This file!
```

---

## 🎯 Complete Beginner Checklist

Use this checklist to ensure you've completed everything:

### Pre-Installation ☐
- [ ] Verified Salesforce CLI installed (`sf version`)
- [ ] Confirmed System Administrator access
- [ ] Checked Einstein 1 license available
- [ ] Verified API access enabled
- [ ] Git installed (if using GitHub clone)

### Installation ☐
- [ ] Cloned/downloaded repository
- [ ] Authenticated with Salesforce org
- [ ] Deployed all metadata successfully
- [ ] Verified deployment (127 components)
- [ ] Checked no errors in deployment

### Tooling API Setup ☐
- [ ] Created Connected App
- [ ] Saved Consumer Key and Secret securely
- [ ] Created Auth Provider (ToolingAPILoopback)
- [ ] Created Named Credential (Salesforce_Tooling_API)
- [ ] Completed authentication flow
- [ ] Verified authentication status shows "Authenticated"
- [ ] Tested with Developer Console (Status: 200)
- [ ] Added Remote Site Setting (if needed)

### Einstein Configuration ☐
- [ ] Located prompt template in Prompt Builder
- [ ] Verified template content (12 categories)
- [ ] Set response format to JSON
- [ ] Activated prompt template
- [ ] Tested Einstein connection (optional)

### Dashboard Access ☐
- [ ] Found dashboard in App Launcher
- [ ] Dashboard loads without errors
- [ ] Flow dropdown shows available flows
- [ ] Can select a flow
- [ ] Permission set assigned (if needed)

### First Analysis ☐
- [ ] Selected a test flow
- [ ] Clicked "Run Analysis"
- [ ] Analysis completed (30-60 seconds)
- [ ] Results display in table
- [ ] Clicked "View" to see details
- [ ] Saw formatted cards with 12 categories
- [ ] Overall score displayed correctly
- [ ] Recommendations make sense

### Batch Analysis ☐
- [ ] Clicked "Select Multiple Flows"
- [ ] Multi-select modal opens
- [ ] Selected 3-5 test flows
- [ ] Batch analysis started
- [ ] Progress shown in table
- [ ] All analyses completed
- [ ] Can view each individual result

### PDF Export ☐
- [ ] Clicked "Export PDF" on a result
- [ ] PDF generated successfully
- [ ] PDF downloads automatically
- [ ] PDF contains all analysis details
- [ ] PDF is properly formatted

### Executive Reports (Optional) ☐
- [ ] Navigated to Reports tab
- [ ] Created new report using "Flow Analysis Reports" type
- [ ] Created "Flow Analysis Summary" report
- [ ] Added chart to report
- [ ] Saved report to public folder
- [ ] Report displays data correctly
- [ ] Exported report to Excel (tested)
- [ ] Created additional reports (optional)
- [ ] Built executive dashboard (optional)
- [ ] Shared with leadership (optional)

### Verification ☐
- [ ] All tests passing (check Debug Logs)
- [ ] No governor limit errors
- [ ] Dashboard responds quickly (<2 seconds)
- [ ] Multiple users can access (if applicable)
- [ ] Bookmarked dashboard for easy access

---

## 💡 Pro Tips for Beginners

### Tip 1: Start with Simple Flows
Don't analyze your most complex flow first. Start with:
- Screen flows with 3-5 elements
- Simple record-triggered flows
- Basic automation flows

### Tip 2: Read the Explanations
Each category has an "Explanation" section that tells you WHY it received that status. This is more valuable than just the score.

### Tip 3: Don't Aim for 100%
A score of 80-90% is excellent. Aiming for 100% on every flow may not be practical or necessary.

### Tip 4: Use the Summary Table
At the bottom of each analysis is a summary table. This gives you a quick action plan.

### Tip 5: Export and Share
Use the PDF export feature to share results with flow creators and stakeholders.

### Tip 6: Track Improvements
Re-analyze flows after making changes to track improvement over time.

### Tip 7: Learn Patterns
After analyzing 10-20 flows, you'll notice common issues. Address these patterns org-wide.

### Tip 8: Monitor Einstein Usage
Check Setup → Einstein → Usage regularly to ensure you're not hitting limits.

### Tip 9: Batch Wisely
Don't analyze all 500 flows at once on your first try. Start with 10-20 to understand the system.

### Tip 10: Join the Community
Check GitHub Discussions for tips, questions, and shared experiences from other users.

---

## 📚 Additional Resources

### Documentation Files in This Repository:
- **README.md** - Complete overview and features
- **docs/TOOLING_API_SETUP.md** - Detailed Tooling API guide
- **PROPER_JSON_STRUCTURE.md** - Einstein prompt template
- **JSON_PARSING_FIX.md** - Technical fix documentation
- **CONTRIBUTING.md** - How to contribute
- **CHANGELOG.md** - Version history

### External Resources:
- **Salesforce Flow Best Practices**: https://help.salesforce.com/s/articleView?id=sf.flow_prep_bestpractices.htm
- **Einstein Prompt Builder**: https://help.salesforce.com/s/articleView?id=sf.prompt_builder_overview.htm
- **Tooling API Guide**: https://developer.salesforce.com/docs/atlas.en-us.api_tooling.meta/api_tooling/
- **Named Credentials**: https://help.salesforce.com/s/articleView?id=sf.named_credentials_about.htm

### Community Support:
- **GitHub Issues**: https://github.com/pasumartyshiva/FlowAIAudit/issues
- **GitHub Discussions**: https://github.com/pasumartyshiva/FlowAIAudit/discussions
- **Salesforce Trailblazer Community**: Search for "Flow AI Audit"

---

## 🎬 What to Do After Setup

### Immediate Actions (First Hour):
1. ✅ Analyze 5-10 test flows
2. ✅ Review results and understand scoring
3. ✅ Export 1-2 PDFs to see format
4. ✅ Test batch analysis with 3-5 flows
5. ✅ Verify all features work correctly

### Short-term Actions (First Week):
1. ✅ Analyze all critical production flows
2. ✅ Share results with flow developers
3. ✅ Create remediation plan for FAIL flows
4. ✅ Document org-specific patterns
5. ✅ Set up regular audit schedule

### Long-term Actions (First Month):
1. ✅ Re-analyze improved flows
2. ✅ Track score improvements
3. ✅ Create flow templates based on learnings
4. ✅ Train team on best practices
5. ✅ Establish governance standards

---

## 🔧 Important Files to Understand

---

## 💡 Common CLI Commands

### For Beginners - Essential Commands

**Check Salesforce CLI Version**:
```bash
sf version
```

**List All Connected Orgs**:
```bash
sf org list
```

**Display Current Org Info**:
```bash
sf org display
```

**Open Org in Browser**:
```bash
sf org open
```

**Deploy Code to Org**:
```bash
sf project deploy start --source-dir force-app
```

**Check Deployment Status**:
```bash
sf project deploy report
```

**Run All Apex Tests**:
```bash
sf apex test run --test-level RunLocalTests --result-format human --wait 10
```

**Query Data (Example - Check Flow Analysis Records)**:
```bash
sf data query --query "SELECT Id, Flow_API_Name__c, Status__c, Overall_Score__c FROM Flow_Analysis__c ORDER BY CreatedDate DESC LIMIT 5"
```

**View Recent Debug Logs**:
```bash
sf apex log list
```

**Tail Debug Logs (Real-time)**:
```bash
sf apex log tail
```

### For Advanced Users

**Create Scratch Org**:
```bash
sf org create scratch --definition-file config/project-scratch-def.json --alias flow-audit-scratch --set-default
```

**Push Source to Scratch Org**:
```bash
sf project deploy start
```

**Generate Password for Org**:
```bash
sf org generate password
```

**Assign Permission Set**:
```bash
sf org assign permset --name Flow_AI_Audit_Dashboard_Access
```

**Import Sample Data (if you create test data file)**:
```bash
sf data import tree --plan data/sample-data-plan.json
```

**Export Org Data**:
```bash
sf data export tree --query "SELECT Id, Flow_API_Name__c, Status__c FROM Flow_Analysis__c" --output-dir data --plan
```

**Delete All Analysis Records (Cleanup)**:
```bash
sf data delete bulk --sobject Flow_Analysis__c --file data/ids-to-delete.csv
```

---

## 🎓 How It Works

```
1. User clicks "Run All Flows"
            ↓
2. Batch Apex starts (50-200 flows per batch)
            ↓
3. Tooling API queries flow metadata
            ↓
4. Einstein GPT analyzes each flow
            ↓
5. Results saved to Flow_Analysis__c
            ↓
6. Dashboard auto-refreshes every 5s
            ↓
7. User sees results in real-time!
```

---

## 📈 Scalability

| Org Size | Flows | Processing Time | Cost/Month |
|----------|-------|-----------------|------------|
| Small    | 100   | 5-10 min        | $5-10      |
| Medium   | 500   | 15-30 min       | $25-50     |
| Large    | 1000+ | 30-60 min       | $75-150    |

---

## ✅ Deployment Checklist

- [ ] Run `./validate.sh` - all checks pass
- [ ] Run `./deploy.sh <org-alias>`
- [ ] Add dashboard to app navigation
- [ ] Publish Flow_Evaluator_V2 template
- [ ] Implement AI integration
- [ ] Assign user permissions
- [ ] Test with 5-10 flows
- [ ] Monitor Einstein GPT usage
- [ ] Review results dashboard
- [ ] Document any org-specific setup

---

## 🆘 Need Help?

### Documentation Files
1. **Start here**: `QUICK_START.md` (this file)
2. **Full guide**: `FLOW_AI_AUDIT_README.md`
3. **AI setup**: `EINSTEIN_GPT_INTEGRATION.md`
4. **Deploy help**: `DEPLOYMENT_GUIDE.md`
5. **Technical details**: `PROJECT_SUMMARY.md`

### Common Issues

**Q: "Validation failed"**
A: Ensure you're in `/Users/spasumarty/Documents/PersonalOrg/`

**Q: "Deployment failed"**
A: Check org connection with `sfdx force:org:display -u <alias>`

**Q: "Dashboard shows no data"**
A: Click "Run All Flows" to start batch analysis

**Q: "AI analysis not working"**
A: Implement `callPromptTemplate()` method (see EINSTEIN_GPT_INTEGRATION.md)

---

## ❓ Frequently Asked Questions (FAQ)

### General Questions

**Q: Do I need Einstein 1 license for every user?**
A: Only users who will run analyses need Einstein licenses. Users who just view results don't need licenses.

**Q: How much does this cost to run?**
A: Costs depend on Einstein usage. Roughly $0.01-0.05 per flow analysis. A 100-flow org might cost $1-5 per audit.

**Q: Can I use this in production?**
A: Yes! The tool is read-only for flows (it doesn't modify them) and is safe for production use.

**Q: Will this work in sandbox?**
A: Absolutely! Sandbox is actually recommended for initial testing.

**Q: How long does analysis take?**
A: Single flow: 30-60 seconds. Batch of 100 flows: 5-10 minutes.

### Technical Questions

**Q: What API version is required?**
A: API version 64.0 or higher. The tool uses v65.0 by default.

**Q: Does this count against my API limits?**
A: Yes, but minimally. Each flow analysis uses 1-2 API calls.

**Q: Can I customize the evaluation criteria?**
A: Yes! Edit the Einstein Prompt Template to add/modify categories.

**Q: Does this work with Flow Builder (not Process Builder)?**
A: Yes, it analyzes Salesforce Flows only. Process Builder migration analysis is on the roadmap.

**Q: What about screen flows vs record-triggered flows?**
A: It analyzes all flow types: Screen, Record-Triggered, Scheduled, Platform Event, and Autolaunched.

### Setup Questions

**Q: I don't see the dashboard after deployment. Why?**
A: Add it to your app: Setup → App Manager → Edit App → Add "Flow AI Audit Dashboard" tab.

**Q: My Named Credential shows "Not Authenticated". What do I do?**
A: Click Edit → Check "Start Authentication Flow on Save" → Save → Complete OAuth flow.

**Q: Can I use a different AI model than Claude?**
A: The prompt template is optimized for Claude Sonnet models, but you can try other Einstein models.

**Q: Do I need to set up Tooling API in every org?**
A: Yes, each org needs its own Connected App, Auth Provider, and Named Credential.

### Usage Questions

**Q: Can I analyze the same flow multiple times?**
A: Yes! Each analysis creates a new record, allowing you to track improvements over time.

**Q: What happens if analysis fails?**
A: The record will show "Error" status. Check Debug Logs for details. Common causes: Einstein limits, invalid flow metadata.

**Q: Can multiple users run analyses simultaneously?**
A: Yes, the tool supports concurrent use. Each user's analyses are tracked separately.

**Q: How do I delete old analysis records?**
A: Go to Setup → Object Manager → Flow Analysis → Delete records, or use Data Loader.

**Q: Can I schedule automatic analysis?**
A: Not built-in yet, but you can create a scheduled Flow that calls the batch Apex class. Feature coming in v2.0.

### Results Questions

**Q: What's a "good" score?**
A: 80%+ is excellent, 50-79% is acceptable, below 50% needs work. Context matters though!

**Q: Why did my simple flow get a low score?**
A: The tool evaluates 12 categories. A simple flow might lack error handling or documentation, lowering its score.

**Q: Can I export all results at once?**
A: Currently, PDF export is per-flow. Bulk export feature is on the roadmap.

**Q: Are the recommendations always correct?**
A: Recommendations are AI-generated and generally accurate, but use your judgment. They're guidelines, not rules.

**Q: How often should I re-analyze flows?**
A: After significant changes, or quarterly as part of governance review.

### Troubleshooting Questions

**Q: I see "Insufficient Privileges" error**
A: Assign the permission set: `sf org assign permset --name Flow_AI_Audit_Dashboard_Access`

**Q: Einstein returns an error**
A: Check: (1) Prompt template is Active, (2) You haven't hit Einstein limits, (3) Input data is valid.

**Q: The dashboard is blank**
A: Check browser console (F12) for JavaScript errors. Clear cache and hard refresh.

**Q: PDF export opens a blank page**
A: Disable pop-up blocker for your Salesforce domain. Try a different browser.

**Q: Analysis stuck at "Processing" forever**
A: Check Debug Logs for errors. Common causes: Tooling API not authenticated, Einstein timeout, or invalid flow.

---

## 🎉 Success Metrics

After deployment, you should see:

✅ Dashboard loads in <2 seconds
✅ Flow dropdown populated with active flows
✅ Single analysis completes in 30-60 seconds
✅ Batch analysis processes flows consistently
✅ Results display with formatted cards
✅ PDF export works without errors
✅ No governor limit warnings in debug logs
✅ All 12 categories show in analysis
✅ Status badges display correct colors
✅ Recommendations are actionable and clear

---

## 🚀 Ready to Launch?

### Quick Setup Command (GitHub Clone):
```bash
git clone https://github.com/pasumartyshiva/FlowAIAudit.git
cd FlowAIAudit
sf org login web --alias my-org
sf project deploy start --source-dir force-app
```

### Then Complete:
1. ✅ Tooling API setup (10 minutes) - See "Tooling API Setup" section above
2. ✅ Einstein configuration (5 minutes) - Activate prompt template
3. ✅ First analysis (2 minutes) - Test with simple flow

**That's it!** Your Flow AI Audit Dashboard is ready! 🎊

---

## 📞 Need Help?

### Documentation:
- **This Guide**: Complete setup walkthrough
- **README.md**: Feature overview and architecture
- **docs/TOOLING_API_SETUP.md**: Detailed API setup
- **CONTRIBUTING.md**: How to contribute
- **CHANGELOG.md**: Version history

### Community:
- **GitHub Issues**: Report bugs or request features
- **GitHub Discussions**: Ask questions and share experiences
- **Salesforce Trailblazer Community**: Search for "Flow AI Audit"

### Support:
- **Email**: support@flowaiaudit.com
- **GitHub**: https://github.com/pasumartyshiva/FlowAIAudit

---

## 🎊 Congratulations!

You've successfully set up the Flow AI Audit Dashboard!

**Next Steps**:
1. 🎯 Analyze your first 10 flows
2. 📊 Review and understand results
3. 🔧 Address high-priority issues
4. 📈 Track improvements over time
5. 🤝 Share with your team

**Happy Flow Auditing!** 🚀

---

*Last Updated: January 26, 2026*
*Version: 1.0.0*
*Repository: https://github.com/pasumartyshiva/FlowAIAudit*
