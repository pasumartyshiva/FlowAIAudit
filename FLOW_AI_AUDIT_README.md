# Flow AI Audit System 2.0

A complete redesign of the Flow AI Audit system that provides **scalable, efficient, and persistent flow analysis** using Einstein GPT.

## 🎯 Key Improvements Over V1

| Feature | V1 (Old) | V2 (New) |
|---------|----------|----------|
| **Speed** | Slow (Metadata API async retrieval) | Fast (Direct Tooling API query) |
| **Scale** | Manual, one-at-a-time | Batch processing (1000+ flows) |
| **Storage** | No persistence | Custom objects with history |
| **Dashboard** | None | Full interactive dashboard |
| **Re-runs** | Required manual re-selection | One-click re-analysis |
| **Progress** | No visibility | Real-time batch progress |
| **API Efficiency** | High (separate calls per flow) | Optimized (bulk queries) |

## 🏗️ Architecture

```
User clicks "Run All Flows"
         ↓
FlowAnalysisBatch (Batch Apex)
  - Queries all active unmanaged flows
  - Fetches XML metadata in bulk
  - Processes 50 flows per batch
         ↓
FlowAnalysisService
  - Calls Flow_Evaluator_V2 prompt template
  - Parses JSON response
  - Updates Flow_Analysis__c record
         ↓
Dashboard Auto-Refreshes
  - Shows real-time progress
  - Updates summary cards
  - Displays results table
```

## 📦 Components Created

### Custom Objects
- **Flow_Analysis__c** - Stores analysis results
  - Flow_API_Name__c (External ID)
  - Status__c (Pass/Partial/Fail/Pending/Analyzing/Error)
  - Overall_Score__c
  - Analysis_Report__c (HTML)
  - Raw_Findings__c (JSON)
  - Last_Analyzed__c
  - Flow_Version__c

### Apex Classes
1. **FlowAnalysisService** - Core analysis logic
2. **FlowAnalysisBatch** - Batch processor for bulk analysis
3. **FlowAnalysisQueueable** - Individual flow re-analysis
4. **FlowAnalysisDashboardController** - LWC backend

### Lightning Web Component
- **flowAnalysisDashboard** - Interactive dashboard with:
  - Summary cards (Pass/Fail/Partial counts)
  - Real-time batch progress
  - Filterable data table
  - Search functionality
  - One-click re-analysis
  - Detail view modal

### AI Prompt Template
- **Flow_Evaluator_V2** - Enhanced template with structured JSON output

### Lightning Page
- **Flow_AI_Audit_Dashboard** - Ready-to-use app page

## 🚀 Installation Steps

### 1. Deploy Metadata
```bash
cd /Users/spasumarty/Documents/PersonalOrg

# Deploy custom objects
sfdx force:source:deploy -p force-app/main/default/objects/Flow_Analysis__c -u YourOrgAlias

# Deploy Apex classes
sfdx force:source:deploy -p force-app/main/default/classes -u YourOrgAlias

# Deploy LWC
sfdx force:source:deploy -p force-app/main/default/lwc/flowAnalysisDashboard -u YourOrgAlias

# Deploy prompt template
sfdx force:source:deploy -p force-app/main/default/genAiPromptTemplates -u YourOrgAlias

# Deploy Lightning page
sfdx force:source:deploy -p force-app/main/default/flexipages -u YourOrgAlias
```

### 2. Configure Einstein GPT
Ensure you have:
- Einstein 1 Platform license
- Prompt Builder enabled
- Access to Claude 3.7 Sonnet model

### 3. Add Dashboard to App
1. Go to **Setup → App Manager**
2. Edit your target app
3. Add the **Flow AI Audit Dashboard** page as a new tab
4. Save and activate

### 4. Set Permissions
Grant users access to:
- Flow_Analysis__c object (Read, Create, Edit)
- Apex classes (FlowAnalysisDashboardController, etc.)
- Lightning page

## 💡 Usage

### Running Bulk Analysis

1. Navigate to the **Flow AI Audit Dashboard**
2. Click **"Run All Flows"** button
3. Monitor progress in the yellow progress bar
4. Results appear automatically as they complete

### Re-analyzing Individual Flows

1. Find the flow in the data table
2. Click the dropdown menu (▼)
3. Select **"Re-analyze"**
4. Status updates to "Analyzing"
5. Result refreshes when complete

### Filtering Results

- **Status Filter**: Show only Pass, Fail, Partial, etc.
- **Search**: Find flows by name or API name
- **View Details**: Click dropdown → "View Details" for full report

### Understanding Results

| Status | Meaning | Score Range |
|--------|---------|-------------|
| **Pass** | Meets all best practices | 80-100 |
| **Partial** | Some issues, mostly good | 50-79 |
| **Fail** | Critical issues found | 0-49 |
| **Pending** | Not yet analyzed | N/A |
| **Analyzing** | Currently processing | N/A |
| **Error** | Analysis failed | N/A |

## 🔧 Configuration

### Batch Size
Adjust batch size in the controller:
```apex
// Default: 50 flows per batch
FlowAnalysisBatch.runBatch(50);

// For larger orgs: 100 flows per batch
FlowAnalysisBatch.runBatch(100);

// For smaller orgs: 25 flows per batch
FlowAnalysisBatch.runBatch(25);
```

### Polling Interval
Adjust refresh rate in flowAnalysisDashboard.js:
```javascript
// Default: 5 seconds
this.progressInterval = setInterval(() => {
    this.checkBatchProgress();
}, 5000);

// Change to 10 seconds
}, 10000);
```

### Prompt Template Customization
Edit **Flow_Evaluator_V2** to add custom evaluation criteria:
```xml
<content>...your custom criteria here...</content>
```

## 📊 Dashboard Features

### Summary Cards
- **Pass**: Flows meeting all standards
- **Partial**: Flows with minor issues
- **Fail**: Flows needing immediate attention
- **Pending**: Flows awaiting analysis
- **Analyzing**: Flows currently processing
- **Total**: All flows in the org

### Data Table Columns
- Flow Name
- API Name
- Status (color-coded)
- Score (0-100)
- Last Analyzed timestamp
- Actions (View Details, Re-analyze)

### Batch Progress
- Live updates every 5 seconds
- Shows "Processing: X of Y"
- Auto-hides when complete

## 🔍 Troubleshooting

### "A flow analysis batch is already running"
Wait for the current batch to complete. Check progress in the dashboard.

### "No metadata found for flow"
The flow may be:
- Inactive
- From a managed package
- Corrupted

### Analysis shows "Error"
Check debug logs for:
- API limits hit
- Prompt template issues
- Invalid XML metadata

### Dashboard not loading
Verify:
- User has access to Flow_Analysis__c
- Apex classes are deployed
- LWC is deployed and assigned to page

## 🎓 Best Practices

1. **Run analysis during off-peak hours** for large orgs (1000+ flows)
2. **Re-analyze flows after major changes** using individual re-run
3. **Review "Fail" status flows immediately** - critical issues
4. **Use filters** to focus on specific status types
5. **Check batch progress** before running another bulk analysis

## 🔐 Security Considerations

- Uses `with sharing` in all Apex classes
- Respects user permissions on Flow_Analysis__c
- Only analyzes **unmanaged** flows (not managed packages)
- Only analyzes **active** flow versions

## 📈 Scalability

| Org Size | Flows | Batch Size | Estimated Time |
|----------|-------|------------|----------------|
| Small | 1-100 | 50 | 5-10 min |
| Medium | 100-500 | 100 | 15-30 min |
| Large | 500-1000 | 100 | 30-60 min |
| Enterprise | 1000+ | 200 | 1-2 hours |

**Note**: Time depends on:
- Einstein GPT API response time
- Flow complexity
- Org governor limits

## 🆕 Future Enhancements

Potential additions:
- Scheduled analysis (weekly/monthly)
- Email notifications on completion
- Flow comparison (version-to-version)
- Export to CSV/PDF
- Integration with DevOps pipelines
- Historical trend analysis

## 🤝 Support

For issues or questions:
1. Check debug logs
2. Review Einstein GPT usage limits
3. Verify prompt template is published
4. Ensure all metadata is deployed

## 📝 Notes

- **Important**: The `FlowAnalysisService.callPromptTemplate()` method is a placeholder. You'll need to implement the actual Einstein GPT API call based on your org's setup. See inline comments in the code.

- **Tooling API Access**: Batch and Queueable classes query the Flow object via Tooling API. Ensure the running user has appropriate permissions.

- **Governor Limits**: The system respects Salesforce governor limits:
  - Max 5 queueable jobs chained
  - Max 50 concurrent batch jobs
  - API call limits per transaction

## 🎉 What You Get

With this new system:
✅ **No more waiting** for Metadata API async retrieval
✅ **Scalable** to 1000+ flows
✅ **Persistent** results you can review anytime
✅ **Dashboard** with filtering and search
✅ **One-click** re-analysis for individual flows
✅ **Real-time** progress tracking
✅ **Efficient** API usage through bulk queries

---

**Created by**: Sai Pasumarty
**Version**: 2.0
**Last Updated**: 2026-01-22
