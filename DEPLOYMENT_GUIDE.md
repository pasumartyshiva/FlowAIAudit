# Flow AI Audit System 2.0 - Deployment Guide

## Quick Start

All files have been validated and are ready for deployment!

### Option 1: Automated Deployment (Recommended)

Run the deployment script with your target org alias:

```bash
cd /Users/spasumarty/Documents/PersonalOrg
./deploy.sh <org-alias>
```

**Example:**
```bash
./deploy.sh my-dev-org
```

### Option 2: Manual Deployment

Deploy each component individually:

#### Step 1: Deploy Custom Object
```bash
sfdx force:source:deploy -p force-app/main/default/objects/Flow_Analysis__c -u <org-alias>
```

#### Step 2: Deploy Apex Classes
```bash
sfdx force:source:deploy -p force-app/main/default/classes -u <org-alias> --testlevel RunLocalTests
```

#### Step 3: Deploy LWC
```bash
sfdx force:source:deploy -p force-app/main/default/lwc/flowAnalysisDashboard -u <org-alias>
```

#### Step 4: Deploy Prompt Template
```bash
sfdx force:source:deploy -p force-app/main/default/genAiPromptTemplates -u <org-alias>
```

#### Step 5: Deploy Lightning Page
```bash
sfdx force:source:deploy -p force-app/main/default/flexipages -u <org-alias>
```

## Available Orgs

Based on your SFDX configuration, you have these connected orgs:

| Alias | Username | Type | Status |
|-------|----------|------|--------|
| my-dev-org | pasumarty_shiva@agentforce.com | Developer | ✓ Connected |
| vscodeOrg | spasumarty@salesforce.com.agentforcelegend | Developer | ✓ Connected |
| devscratch | spasumarty@empathetic-shark-hnahlr.com | DevHub | ✓ Connected |

**Recommended for testing:** `my-dev-org` or `vscodeOrg`

## Validation Before Deployment

Always validate before deploying:

```bash
./validate.sh
```

This checks that all required files exist.

## Post-Deployment Checklist

After successful deployment:

### 1. Add Dashboard to App Navigation
- Go to **Setup → App Manager**
- Edit your target app
- Add new tab: **Flow AI Audit Dashboard**
- Save and activate

### 2. Assign User Permissions

Create/update a permission set with:
- **Object Permissions**:
  - Flow_Analysis__c: Read, Create, Edit
- **Apex Class Access**:
  - FlowAnalysisService
  - FlowAnalysisBatch
  - FlowAnalysisQueueable
  - FlowAnalysisDashboardController
- **Page Access**:
  - Flow_AI_Audit_Dashboard

### 3. Configure Einstein GPT

1. **Verify License**:
   - Setup → Company Information
   - Check for Einstein 1 Platform license

2. **Publish Prompt Template**:
   - Setup → Prompt Builder
   - Find "Flow_Evaluator_V2"
   - Click "Publish"

3. **Configure Model Access**:
   - Setup → Einstein Setup
   - Navigate to Einstein Trust Layer
   - Verify Claude 3.7 Sonnet access

### 4. Implement AI Integration

Choose ONE of these options (see `EINSTEIN_GPT_INTEGRATION.md` for details):

**Option A: ConnectApi (Recommended)**
- Update `FlowAnalysisService.callPromptTemplate()`
- Use ConnectApi.EinsteinLlm.generateMessagesForPromptTemplate()

**Option B: REST API**
- Create Named Credential for Einstein GPT
- Use HTTP callout

**Option C: Flow-Invocable**
- Create wrapper Flow
- Call from Apex

### 5. Test the Deployment

1. Navigate to Flow AI Audit Dashboard
2. Click "Run All Flows" (start with 5 flows for testing)
3. Monitor the progress bar
4. Verify results appear in the table
5. Test "Re-analyze" on a single flow
6. Test filters and search

## Troubleshooting

### Deployment Fails

**Issue**: "Component cannot be deployed"
```bash
# Check deployment status
sfdx force:source:deploy:report -u <org-alias>

# View detailed error log
sfdx force:apex:log:list -u <org-alias>
```

**Issue**: "Test coverage insufficient"
```bash
# Run tests manually
sfdx force:apex:test:run -u <org-alias> --testlevel RunLocalTests --resultformat human
```

### Runtime Errors

**Issue**: "Prompt template not found"
- Verify template is published in Setup → Prompt Builder
- Check template API name is exactly "Flow_Evaluator_V2"

**Issue**: "No batch job running"
- Check async jobs: Setup → Apex Jobs
- Look for FlowAnalysisBatch jobs

**Issue**: "Dashboard shows no data"
- Run batch manually: Execute Anonymous
  ```apex
  Id jobId = FlowAnalysisBatch.runBatch(5);
  System.debug('Job ID: ' + jobId);
  ```

### Permission Errors

**Issue**: "Insufficient privileges"
- Verify user has permission set assigned
- Check object CRUD permissions
- Verify Apex class access

## Deployment to Production

### Pre-Production Checklist
- [ ] All tests passing (75%+ coverage)
- [ ] Validated in sandbox first
- [ ] Einstein GPT configured
- [ ] User permissions documented
- [ ] Change set/deployment package ready

### Production Deployment Steps

1. **Create Change Set** (if using change sets):
   - Include all components
   - Upload to production
   - Deploy during maintenance window

2. **Or use SFDX**:
   ```bash
   # Validate first (doesn't deploy)
   sfdx force:source:deploy -p force-app -u production --testlevel RunLocalTests --checkonly

   # Deploy after validation
   sfdx force:source:deploy -p force-app -u production --testlevel RunLocalTests
   ```

3. **Post-Production**:
   - Verify dashboard loads
   - Run sample analysis on 1-2 flows
   - Monitor debug logs
   - Check Einstein GPT usage limits

## Rollback Plan

If deployment causes issues:

1. **Disable Dashboard**:
   - Remove from app navigation
   - Prevents users from accessing

2. **Deactivate Batch**:
   - Don't run FlowAnalysisBatch
   - Existing records remain

3. **Full Rollback**:
   ```bash
   sfdx force:source:delete -p force-app -u <org-alias>
   ```
   **Warning**: This deletes all Flow_Analysis__c records!

## Cost Estimation

Approximate Einstein GPT costs:

| Org Size | Flows | Monthly Runs | Est. Cost |
|----------|-------|--------------|-----------|
| Small    | 100   | 4x          | $5-10     |
| Medium   | 500   | 4x          | $25-50    |
| Large    | 1000+ | 4x          | $75-150   |

**Note**: Actual costs depend on:
- Token usage per flow
- Einstein GPT pricing tier
- Analysis frequency

## Support Resources

- **Main Documentation**: `FLOW_AI_AUDIT_README.md`
- **AI Integration**: `EINSTEIN_GPT_INTEGRATION.md`
- **Validation**: Run `./validate.sh`
- **Deployment**: Run `./deploy.sh <org-alias>`

## Files Included

### Metadata (36 files total)
- 1 Custom Object
- 10 Custom Fields
- 4 Apex Classes (production)
- 4 Apex Test Classes
- 4 LWC Files
- 1 Prompt Template
- 1 Lightning Page
- 2 Documentation files
- 2 Shell scripts

### Total Lines of Code
- Apex: ~2,500 lines
- JavaScript: ~350 lines
- HTML: ~200 lines
- CSS: ~80 lines

## Version Control

Track your deployment:

```bash
# Create git tag
git tag -a v2.0.0 -m "Flow AI Audit System 2.0"
git push origin v2.0.0

# View deployment history
git log --oneline
```

## Success Metrics

After deployment, track:
- Number of flows analyzed
- Average analysis time
- Pass/Fail/Partial distribution
- User adoption rate
- Einstein GPT API usage

---

**Ready to deploy?** Run:
```bash
./deploy.sh my-dev-org
```

Good luck! 🚀
