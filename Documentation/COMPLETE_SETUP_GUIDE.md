# Complete Setup Guide - Full Flow Analysis with Einstein

**Status:** Code deployed, Named Credential setup required
**Goal:** Enable full flow metadata analysis with Einstein Prompt Templates

---

## 🎯 What This Achieves

With this setup, clicking "Re-analyze" on a flow in the dashboard will:
1. ✅ Fetch **complete flow metadata** from Tooling API (all elements, decisions, loops, etc.)
2. ✅ Call Einstein synchronously in **user session context**
3. ✅ Get **detailed AI-powered analysis** with specific recommendations
4. ✅ Save results to Flow_Analysis__c record

---

## 📋 Step-by-Step Setup

### Step 1: Create Named Credential (5 minutes)

#### Option A: Simple Session-Based (Recommended for Testing)

1. **Navigate to:** Setup → Named Credentials
2. **Click:** "New" → "New Legacy"
3. **Fill in the form:**
   ```
   Label: Salesforce_Tooling_API
   Name: Salesforce_Tooling_API
   URL: callout:Salesforce_Instance
   Identity Type: Anonymous
   Authentication Protocol: No Authentication
   Certificate: (leave blank)
   Generate Authorization Header: ❌ UNCHECKED
   Allow Merge Fields in HTTP Header: ✅ CHECKED
   Allow Merge Fields in HTTP Body: ❌ UNCHECKED
   ```
4. **Click:** "Save"

#### Option B: External Credential-Based (More Secure)

If Option A doesn't work, follow the detailed instructions in:
`Documentation/NAMED_CREDENTIAL_SETUP.md`

---

### Step 2: Verify Remote Site Setting Exists

The Remote Site Setting should already exist from previous deployment, but verify:

1. **Navigate to:** Setup → Remote Site Settings
2. **Look for:** "Salesforce_Instance"
3. **If it exists:**
   - **Click:** Edit
   - **Verify URL matches your org:** `https://yourinstance.my.salesforce.com`
   - **Active:** ✅ Checked
   - **Click:** Save

4. **If it doesn't exist:**
   - **Click:** New Remote Site
   - **Remote Site Name:** `Salesforce_Instance`
   - **Remote Site URL:** `https://yourinstance.my.salesforce.com`
     - Replace `yourinstance` with your actual org domain
     - You can get this from: `URL.getOrgDomainUrl().toExternalForm()`
   - **Active:** ✅ Checked
   - **Click:** Save

---

### Step 3: Test the Setup

Run this test script in Developer Console → Execute Anonymous:

```apex
// Test Named Credential and Full Metadata Retrieval

List<FlowDefinitionView> flows = [
    SELECT ApiName, Label
    FROM FlowDefinitionView
    WHERE IsActive = true
    LIMIT 1
];

if (flows.isEmpty()) {
    System.debug('❌ No active flows found');
} else {
    String flowApiName = flows[0].ApiName;

    System.debug('========================================');
    System.debug('Testing Full Flow Analysis');
    System.debug('Flow: ' + flows[0].Label);
    System.debug('========================================\n');

    try {
        Datetime start = System.now();

        // This will fetch FULL metadata via Named Credential
        String result = FlowAnalysisDashboardController.reanalyzeFlow(flowApiName);

        Long duration = System.now().getTime() - start.getTime();

        System.debug('✓✓✓ SUCCESS! ✓✓✓');
        System.debug('Duration: ' + (duration/1000.0) + ' seconds');
        System.debug('Result: ' + result + '\n');

        // Check the analysis record
        List<Flow_Analysis__c> analyses = [
            SELECT Status__c, Overall_Score__c,
                   Analysis_Report__c, Raw_Findings__c
            FROM Flow_Analysis__c
            WHERE Flow_API_Name__c = :flowApiName
            ORDER BY Last_Analyzed__c DESC
            LIMIT 1
        ];

        if (!analyses.isEmpty()) {
            Flow_Analysis__c analysis = analyses[0];
            System.debug('✓ Analysis Record:');
            System.debug('  Status: ' + analysis.Status__c);
            System.debug('  Score: ' + analysis.Overall_Score__c);
            System.debug('  Report Length: ' + analysis.Analysis_Report__c?.length());
            System.debug('  Findings Length: ' + analysis.Raw_Findings__c?.length());

            // Show first 1000 chars of raw findings
            if (analysis.Raw_Findings__c != null) {
                System.debug('\n--- Einstein Response Preview ---');
                System.debug(analysis.Raw_Findings__c.substring(0,
                    Math.min(1000, analysis.Raw_Findings__c.length())));
                System.debug('...');
            }
        }

        System.debug('\n========================================');
        System.debug('✓✓✓ FULL SETUP VERIFIED ✓✓✓');
        System.debug('========================================');

    } catch (Exception e) {
        System.debug('\n========================================');
        System.debug('✗✗✗ SETUP INCOMPLETE ✗✗✗');
        System.debug('========================================');
        System.debug('Error: ' + e.getMessage());
        System.debug('Type: ' + e.getTypeName());

        String msg = e.getMessage().toLowerCase();
        if (msg.contains('unauthorized endpoint')) {
            System.debug('\n⚠ ACTION REQUIRED:');
            System.debug('1. Create Named Credential: Salesforce_Tooling_API');
            System.debug('2. See NAMED_CREDENTIAL_SETUP.md for instructions');
        } else if (msg.contains('401')) {
            System.debug('\n⚠ ACTION REQUIRED:');
            System.debug('1. Verify Named Credential authentication');
            System.debug('2. Check Remote Site Setting is active');
        } else {
            System.debug('\nStack Trace:');
            System.debug(e.getStackTraceString());
        }
    }
}
```

---

## ✅ Expected Results

### Success Output:

```
========================================
Testing Full Flow Analysis
Flow: My Flow Name
========================================

✓✓✓ SUCCESS! ✓✓✓
Duration: 14.3 seconds
Result: Flow analyzed successfully

✓ Analysis Record:
  Status: Pass
  Score: 85
  Report Length: 8432
  Findings Length: 5291

--- Einstein Response Preview ---
{
  "status": "Pass",
  "score": 85,
  "summary": "This flow demonstrates good practices with proper bulkification...",
  "findings": [
    {
      "category": "Bulkification & Loop Efficiency",
      "severity": "Low",
      "issue": "DML operations are properly batched outside loops",
      "recommendation": "Continue this pattern for all future flows"
    },
    ...
  ],
  "strengths": [
    "Excellent error handling with fault paths",
    "Well-documented with clear element names",
    "Proper use of collections for bulk processing"
  ],
  "risks": [
    "Consider adding governor limit checks for very large batches"
  ]
}
...

========================================
✓✓✓ FULL SETUP VERIFIED ✓✓✓
========================================
```

---

## 🚨 Troubleshooting

### Error: "Unauthorized endpoint"

**Problem:** Named Credential not set up or Remote Site Setting missing

**Solution:**
1. Complete Step 1 (Create Named Credential)
2. Verify Step 2 (Remote Site Setting exists and is active)
3. Re-run test script

### Error: "401 Unauthorized"

**Problem:** Authentication not working correctly

**Solution:**
1. **Go to:** Setup → Named Credentials
2. **Find:** Salesforce_Tooling_API
3. **Click:** Edit
4. **Try these settings:**
   - Generate Authorization Header: ❌ UNCHECKED (try both checked/unchecked)
   - Allow Merge Fields in HTTP Header: ✅ CHECKED
5. **Alternative:** Try Option B in NAMED_CREDENTIAL_SETUP.md

### Error: "Named Credential 'Salesforce_Tooling_API' does not exist"

**Problem:** Named Credential name doesn't match exactly

**Solution:**
1. Verify the API Name is exactly: `Salesforce_Tooling_API`
2. Check spelling, underscores, and capitalization
3. If you named it differently, update the code in FlowAnalysisDashboardController.cls line 224

### Test Works but Dashboard Doesn't

**Problem:** Named Credential works in Execute Anonymous but fails from LWC

**Solution:**
1. **Check user permissions:** User needs "API Enabled" permission
2. **Check session timeout:** LWC session may have expired
3. **Try refreshing the page** and clicking Re-analyze again

---

## 📊 What You Get with Full Metadata

With the Named Credential setup, Einstein receives the complete flow structure:

### Before (Simplified XML):
```xml
<Flow>
    <apiName>My_Flow</apiName>
    <label>My Flow</label>
    <status>Active</status>
</Flow>
```
**Result:** Generic feedback only

### After (Full Metadata):
```xml
<Flow>
    <apiName>My_Flow</apiName>
    <label>My Flow</label>
    <decisions>...</decisions>
    <loops>...</loops>
    <recordLookups>...</recordLookups>
    <recordCreates>...</recordCreates>
    <recordUpdates>...</recordUpdates>
    <assignments>...</assignments>
    ...hundreds more lines of metadata...
</Flow>
```
**Result:** Specific, actionable analysis of:
- Loop efficiency
- DML bulkification
- Null checks
- Error handling
- Security context
- Governor limit risks

---

## 🎉 Next Steps After Setup

1. **Test from the UI:**
   - Open Flow Analysis Dashboard
   - Click "Re-analyze" on any flow
   - Wait 10-15 seconds
   - Verify detailed analysis appears

2. **Review the Analysis:**
   - Check Status (Pass/Partial/Fail)
   - Review Overall Score
   - Read detailed findings
   - Implement recommendations

3. **Monitor Usage:**
   - Check Einstein API usage in Setup
   - Monitor debug logs for errors
   - Track analysis record creation

---

## 💡 Pro Tips

- **First Time:** Test with a simple flow (3-5 elements) to verify setup
- **Large Flows:** Complex flows may take 20-30 seconds to analyze
- **Batch vs Single:** Use "Re-analyze" for individual flows, batch for bulk
- **Error Logs:** Check Setup → Debug Logs for detailed error messages

---

**Setup is complete once the test script shows "FULL SETUP VERIFIED"!**

After that, you'll have Einstein analyzing complete flow metadata with detailed, actionable recommendations.
