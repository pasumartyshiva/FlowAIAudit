# Flow AI Audit: Configuration & Setup Guide

**Version:** 1.0  
**Last Updated:** January 28, 2026  
**Estimated Setup Time:** 30-45 minutes  

---

## Quick Start (5 Minutes)

### Option 1: Automatic Installation

```bash
# Clone and deploy in one command
git clone https://github.com/pasumartyshiva/FlowAIAudit.git
cd FlowAIAudit
sf project:deploy:start --target-org YourOrgAlias
```

### Option 2: Manual Org Setup

1. Visit [Salesforce AppExchange](link-to-package) and install package
2. Authorize your org and follow prompts
3. Navigate to **Setup → Flow AI Audit Dashboard** (new custom app)
4. Run your first audit

---

## Detailed Installation Guide

### Prerequisites

- Salesforce CLI (v2.0+) installed
- Org with **API Enabled**
- System Administrator or equivalent permissions
- Git installed (for source control)
- ~15 MB storage for application

### Step 1: Authenticate with Salesforce Org

```bash
# Web-based authentication (recommended)
sf org:login:web --alias FlowAudit

# Verify authentication
sf org:list
```

**Expected Output:**
```
OrgAuth  Scratch      Org Name       Org ID        Instance URL                 Username
───────  ───────      ────────       ──────        ────────────                 ────────
FlowAudit              My Production  00Dxx0000...  https://xxx.salesforce.com   admin@company.com
```

### Step 2: Clone Repository

```bash
git clone https://github.com/pasumartyshiva/FlowAIAudit.git
cd FlowAIAudit

# Verify project structure
ls -la force-app/main/default/
```

### Step 3: Deploy to Target Org

```bash
# Standard deployment (full package)
sf project:deploy:start --target-org FlowAudit

# Check deployment status
sf project:deploy:report --org FlowAudit
```

**Expected Deployment Artifacts:**
- ✅ Apex Classes (Core Analysis Engine)
- ✅ Lightning Web Components (Dashboard UI)
- ✅ Custom Objects (Audit Results Storage)
- ✅ Permission Sets (Role-based Access)
- ✅ Custom Labels (Configuration)
- ✅ Reports & Dashboards (Visualization)

### Step 4: Verify Installation

```bash
# Test Apex classes
sf apex:run --file tests/FlowAuditTest.apex --target-org FlowAudit

# Check custom app creation
sf org:open --target-org FlowAudit
```

**In Salesforce UI:**
1. Navigate to **Setup → Apps → App Manager**
2. Verify "**Flow AI Audit**" app is listed
3. Assign to appropriate profiles/permission sets

---

## Configuration Steps

### Configuration Step 1: Set Role-Based Permissions

#### Assign Permission Set: "FlowAudit_Auditor"

**Target Users:**
- Salesforce Architects
- Lead Administrators
- Lead Developers
- System Engineers

**Steps:**
1. **Setup → Permission Sets → Flow Audit Auditor**
2. Click **Manage Assignments**
3. Add users who should run audits
4. Click **Assign**

**Permissions Included:**
- ✅ Read/Create Flow Audit Results
- ✅ View Audit Dashboards & Reports
- ✅ Configure Audit Settings
- ✅ Export Audit Reports

#### Assign Permission Set: "FlowAudit_Viewer"

**Target Users:**
- Developers (view only)
- Program Managers
- QA Teams

**Steps:**
1. **Setup → Permission Sets → Flow Audit Viewer**
2. Click **Manage Assignments**
3. Add view-only users
4. Click **Assign**

**Permissions Included:**
- ✅ Read Flow Audit Results
- ✅ View Audit Dashboards
- ❌ Create/Modify Audits

### Configuration Step 2: Customize Audit Policies

#### Create Custom Metadata: FlowAuditConfig__mdt

**Purpose:** Define org-specific audit rules and thresholds.

**Steps:**
1. **Setup → Custom Metadata Types → Flow Audit Config**
2. Click **Manage Records → New**
3. Configure values:

```
Label: Default Org Policies
Developer Name: Default_Org_Policies

// Performance Thresholds
MaxNestingDepth: 3                          (Default: 2)
MaxLoopsPerFlow: 2                          (Default: 1)
MaxSOQLPerFlow: 100                         (Default: 100)
MaxDMLPerFlow: 150                          (Default: 150)

// Security Severity
EnableFLSValidation: TRUE                   (Default: TRUE)
EnableHardcodedSecretCheck: TRUE            (Default: TRUE)
EnableSOQLInjectionDetection: TRUE          (Default: TRUE)

// Best Practice Enforcement
EnforceMandatoryErrorHandling: TRUE         (Default: TRUE)
EnforceNamingConventions: TRUE              (Default: TRUE)
MinimumFlowDescription: 50                  (Minimum characters, Default: 20)

// Severity Thresholds
CriticalIssueThreshold: 3                   (Default: 2)
HighIssueThreshold: 5                       (Default: 5)
MediumIssueThreshold: 10                    (Default: 10)

// Exclusion Patterns
ExcludedFlowPatterns: ^TEST,^ARCHIVE,^DEPRECATED   (Regex patterns)
ExcludedFlowOwners: testadmin@company.com  (Comma-separated)
```

4. Click **Save**

**Effect:** All future audits will use these custom thresholds.

### Configuration Step 3: Define Excluded Flows

#### Create Exclusion Rules

**Purpose:** Skip flows from audit (test flows, deprecated, legacy).

**Steps:**
1. **Setup → Custom Metadata Types → Flow Audit Exclusion**
2. Click **Manage Records → New**
3. Add patterns:

```
Label: Test Flows
Developer Name: Test_Flow_Exclusions
FlowNamePattern: ^TEST_.*          (Regex to match flow names)
Reason: Test automation - exclude from audit
Active: TRUE

---

Label: Deprecated Flows
Developer Name: Deprecated_Flows
FlowNamePattern: ^DEPRECATED_.*
Reason: Legacy flows - scheduled for deactivation
Active: TRUE

---

Label: Archived Flows
Developer Name: Archived_Flows
FlowNamePattern: ^ARCHIVE_.*
Reason: Superseded by new flows
Active: TRUE
```

4. Click **Save**

**Effect:** Excluded flows will be skipped during bulk audits.

### Configuration Step 4: Set Severity Levels

#### Configure Issue Severity Mappings

**Purpose:** Define which issues warrant immediate attention vs. best-practice suggestions.

**Steps:**
1. **Setup → Custom Metadata Types → Flow Audit Severity**
2. Click **Manage Records** and review defaults:

```
Issue Type              Severity    Auto-Block    Action
─────────────────────   ────────    ──────────    ──────────────────────
Hardcoded Credentials   CRITICAL    TRUE          Block deployment
SQL Injection Risk      CRITICAL    TRUE          Block deployment
Missing FLS Check       HIGH        FALSE         Warn + recommend review
Missing Error Path      MEDIUM      FALSE         Notification
Poor Naming Convention  LOW         FALSE         FYI
Unused Variables        LOW         FALSE         FYI
```

3. Customize as needed (click **Edit**)
4. Click **Save**

### Configuration Step 5: Integrate with CI/CD (GitHub Actions)

#### Create GitHub Workflow File

**Purpose:** Run Flow AI Audit on every flow deployment.

**Location:** `.github/workflows/flow-audit.yml`

```yaml
name: Flow AI Audit on PR

on:
  pull_request:
    paths:
      - 'force-app/main/default/flows/**'
  push:
    branches:
      - main
    paths:
      - 'force-app/main/default/flows/**'

jobs:
  flow-audit:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Install Salesforce CLI
      run: npm install @salesforce/cli --global
    
    - name: Authenticate with Salesforce
      env:
        SFDX_AUTH_URL: ${{ secrets.SFDX_AUTH_URL }}
      run: sf auth:accesstoken:store --instance-url https://xxx.salesforce.com --auth-url $SFDX_AUTH_URL --alias ci-org
    
    - name: Run Flow AI Audit
      run: |
        sf apex:run --file scripts/runFlowAudit.apex --target-org ci-org > audit-results.txt
        cat audit-results.txt
    
    - name: Check for Critical Issues
      run: |
        if grep -q "CRITICAL" audit-results.txt; then
          echo "❌ Flow audit detected critical issues. Please fix before merging."
          exit 1
        else
          echo "✅ All flows passed quality gates"
          exit 0
        fi
    
    - name: Comment on PR
      if: failure()
      uses: actions/github-script@v6
      with:
        script: |
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: '❌ Flow AI Audit failed. See workflow logs for details.'
          })
```

**Setup Steps:**
1. Copy file to `.github/workflows/flow-audit.yml` in your repo
2. Generate SFDX auth URL (see next step)
3. Add to GitHub Secrets as `SFDX_AUTH_URL`
4. Commit and push

**Generate SFDX Auth URL:**

```bash
# Create a read-only service account in your org
# Then authenticate:
sf org:login:web --alias ci-org

# Display auth URL
sf org:display --target-org ci-org --json | jq -r '.result.sfdxAuthUrl'

# Copy output and add to GitHub Secrets
```

### Configuration Step 6: Set Up Reporting

#### Create Audit Dashboard

**Purpose:** Visualize org health trends and priority issues.

**Steps:**
1. **Setup → Dashboards → New Dashboard**
2. Name: "**Flow AI Audit - Executive Overview**"
3. Add following components:

**Component 1: Overall Health Score**
```
Metric: Average health score across all flows
Target: 85+
Type: Gauge
Color Coding: Red (<70), Yellow (70-85), Green (85+)
```

**Component 2: Critical Issues by Type**
```
Chart Type: Bar Chart
X-Axis: Issue Category (Performance, Security, Maintainability)
Y-Axis: Count of Critical Issues
Sort: Descending
```

**Component 3: Flow Quality Trend**
```
Chart Type: Line Chart
X-Axis: Audit Date (weekly)
Y-Axis: Average Health Score
Segment: By Flow Type
```

**Component 4: Top 10 Flows Needing Attention**
```
Chart Type: Table
Columns: Flow Name, Health Score, Critical Issues, Last Audit
Sort: Health Score (ascending)
Filter: Health Score < 70
```

4. Save and share with team

---

## Usage Guide

### Running Your First Audit

#### Method 1: Web UI (Recommended for Non-Developers)

1. **Open Flow AI Audit App**
   - In Salesforce, click app switcher
   - Select "**Flow AI Audit**"

2. **Click "Run New Audit"**
   - Select audit scope:
     - ☐ Single Flow
     - ☑ All Active Flows
     - ☐ Specific Team/Folder

3. **Click "Start Audit"**
   - System processes flows in background
   - Status updates in real-time

4. **Review Results**
   - Click flow name to see detailed analysis
   - Review recommendations
   - Click "Export" to save as PDF/CSV

#### Method 2: Salesforce CLI (Recommended for Architects)

```bash
# Audit single flow
sf apex:run --file scripts/auditSingleFlow.apex --target-org FlowAudit

# Audit all active flows
sf apex:run --file scripts/auditAllFlows.apex --target-org FlowAudit

# Generate HTML report
sf apex:run --file scripts/generateReport.apex --target-org FlowAudit > audit-report.html

# Export to CSV (for Excel analysis)
sf apex:run --file scripts/exportCSV.apex --target-org FlowAudit > audit-results.csv
```

#### Method 3: Scheduled Audit (Weekly Governance)

1. **Setup → Automation → Scheduled Actions**
2. Create new scheduled action:

```
Name: Weekly Flow Audit
Schedule: Every Monday at 2:00 AM
Action: Apex Class - FlowAuditScheduler
Parameters: auditAllFlows=TRUE, generateReport=TRUE, emailResults=TRUE
EmailRecipient: architecture-team@company.com
```

3. Click **Activate**

---

## Advanced Configuration

### Custom Severity Rules

**Scenario:** Your org requires stricter performance standards.

**Steps:**
1. **Setup → Custom Metadata → Flow Audit Config**
2. Modify thresholds:
   - `MaxNestingDepth: 2` (more strict than default 3)
   - `MaxLoopsPerFlow: 1` (tighter control)
3. Save and run audit (new rules apply immediately)

### Integration with External Tools

#### Slack Notifications

```apex
// Apex class to post audit results to Slack
public class FlowAuditSlackNotifier {
    public static void notifyTeam(FlowAuditResult result) {
        String webhookUrl = System.Label.SlackWebhookURL;
        
        String message = 'Flow AI Audit Results: ' + result.flowLabel + 
                        '\nHealth Score: ' + result.healthScore.score + '/100';
        
        // Call Slack webhook
        callSlackAPI(webhookUrl, message);
    }
}
```

#### Jira Integration

```apex
// Create Jira tickets for critical issues
public class FlowAuditJiraIntegration {
    public static void createJiraTickets(List<FlowAuditResult> results) {
        for (FlowAuditResult result : results) {
            for (SecurityRisk risk : result.securityRisks) {
                if (risk.severity == 'CRITICAL') {
                    createJiraTicket(result.flowLabel, risk);
                }
            }
        }
    }
}
```

---

## Troubleshooting

### Issue: "Insufficient Access" Error

**Cause:** User doesn't have required permission set.

**Fix:**
1. **Setup → Permission Sets → Flow Audit Auditor**
2. Click **Manage Assignments**
3. Add user
4. Click **Save**

### Issue: Audit Takes > 5 Minutes

**Cause:** Large number of flows (100+) or complex flows.

**Fix:**
1. Run in batches:
   ```bash
   sf flow:audit --type AUTOLAUNCHED --batch-size 20
   sf flow:audit --type RECORD_TRIGGERED --batch-size 20
   ```
2. Or use asynchronous processing:
   ```bash
   sf flow:audit --audit-all --use-async
   ```

### Issue: "Custom Metadata Not Found"

**Cause:** Installation incomplete.

**Fix:**
1. Run full deployment again:
   ```bash
   sf project:deploy:start --target-org FlowAudit --force
   ```
2. Verify custom metadata exists:
   ```bash
   sf mdapi:retrieve --retrievetargetdir ./retrieved --target-org FlowAudit
   ```

### Issue: Reports Show "No Data"

**Cause:** No audits have run yet.

**Fix:**
1. Run initial audit:
   ```bash
   sf flow:audit --audit-all --generate-report
   ```
2. Wait 5-10 minutes for data to populate
3. Refresh dashboard

---

## Best Practices

### Do's ✅
- ✅ Run audits **weekly** as part of governance
- ✅ Review **CRITICAL** issues immediately
- ✅ Implement recommendations **within sprint**
- ✅ Track trends over time (monthly health score)
- ✅ Share audit results with development teams
- ✅ Use audit insights in **code reviews**

### Don'ts ❌
- ❌ Ignore CRITICAL security issues
- ❌ Allow flows with no error handling to deploy
- ❌ Stack multiple recommendations into one flow (refactor incrementally)
- ❌ Disable audits for "legacy" flows (they need attention most!)
- ❌ Store sensitive data in flow debug logs

---

## Support & Next Steps

### Getting Help

1. **Check Documentation**
   - README.md - Overview
   - TECHNICAL_DESIGN_DOCUMENT.md - Architecture details
   - This guide - Setup & configuration

2. **GitHub Issues**
   - Report bugs: https://github.com/pasumartyshiva/FlowAIAudit/issues
   - Feature requests welcome

3. **Slack Community** (if available)
   - Real-time support
   - Tips & best practices

### Next Steps

1. ✅ **Complete Setup** (this guide)
2. ✅ **Run First Audit** (see Usage Guide)
3. ✅ **Review Results** (identify top priorities)
4. ✅ **Address CRITICAL Issues** (immediately)
5. ✅ **Plan Remediation** (within 30 days)
6. ✅ **Schedule Weekly Audits** (ongoing governance)
7. ✅ **Track Improvement** (monthly health score reviews)

---

**Setup Complete!** 🎉 You're ready to audit your flows.

**For Questions:** See [README.md](./README.md) or create a GitHub issue.

**For Architecture Details:** See [TECHNICAL_DESIGN_DOCUMENT.md](./TECHNICAL_DESIGN_DOCUMENT.md)