# Prompt Template Debugging Guide

## Quick Start

The `PromptTemplateDebugger` class helps you debug Einstein Prompt Template issues from Developer Console's Anonymous Apex execution window.

---

## 🚀 Usage Examples

### Example 1: Test Flow Evaluator V3 (Simplest)

```apex
// Run this in Developer Console > Debug > Open Execute Anonymous Window
PromptTemplateDebugger.testFlowEvaluatorV3();
```

This uses a sample flow XML and tests the `Flow_Evaluator_V3` template.

---

### Example 2: Test with Your Own Flow XML

```apex
// Get your flow XML (replace 'MyFlowName' with actual flow name)
Flow flowMetadata = [SELECT Metadata FROM Flow WHERE ApiName = 'MyFlowName' LIMIT 1];
String flowXml = flowMetadata.Metadata;

// Test it
PromptTemplateDebugger.testTemplate('Flow_Evaluator_V3', flowXml);
```

---

### Example 3: Test with Knowledge Parameter

```apex
String flowXml = '<Flow xmlns="http://soap.sforce.com/2006/04/metadata">...</Flow>';
String knowledge = 'Salesforce Flow Best Practices: Always use fault connectors...';

PromptTemplateDebugger.testTemplate('Flow_Evaluator_V3', flowXml, knowledge);
```

---

### Example 4: Advanced - Detailed Logging

```apex
PromptTemplateDebugger debugger = new PromptTemplateDebugger();
debugger.enableVerboseLogging(true);

String flowXml = '<Flow>...</Flow>';
String knowledge = 'Best practices...';

debugger.testPromptTemplate('Flow_Evaluator_V3', flowXml, knowledge);
```

---

### Example 5: List Available Templates

```apex
PromptTemplateDebugger.listAvailableTemplates();
```

---

## 📊 What the Debugger Shows

### ✅ Success Output

```
========================================
PROMPT TEMPLATE DEBUG SESSION STARTED
========================================
Template Name: Flow_Evaluator_V3
Timestamp: 2026-01-23 10:30:45
...
--- ATTEMPTING API CALL ---
Template: Flow_Evaluator_V3
Calling: ConnectApi.EinsteinLlm.generateMessagesForPromptTemplate()
Start Time: 2026-01-23 10:30:45
✓ SUCCESS! Call completed in 3247ms

--- RESPONSE DETAILS ---
Response Object: ConnectApi.EinsteinPromptTemplateGenerationsRepresentation...
✓ Number of Generations: 1

Generation #1:
Text Length: 2341 characters
--- GENERATED TEXT ---
{
  "qualityScore": 8.5,
  "assessment": {
    "errorHandling": {
      "score": 9,
      "findings": "..."
    },
    ...
  }
}
--- END GENERATED TEXT ---

--- JSON VALIDATION ---
✓ Valid JSON structure
✓ Parsed as Map with 2 keys
Keys: qualityScore, assessment
========================================
```

### ❌ Failure Output - Template Not Published

```
✗ CONNECTAPI EXCEPTION OCCURRED
Duration: 245ms

Exception Details:
  Type: ConnectApiException
  Message: Prompt template 'Flow_Evaluator_V3' not found

--- ERROR ANALYSIS ---
⚠ LIKELY CAUSE: Prompt Template Not Found or Not Published

SOLUTION:
  1. Go to Setup > Prompt Builder
  2. Find your template (Flow_Evaluator_V3)
  3. Click "Publish" button
  4. Wait 2-3 minutes for propagation
  5. Re-run this test
```

### ❌ Failure Output - Einstein Not Enabled

```
✗ CONNECTAPI EXCEPTION OCCURRED

Exception Details:
  Message: Feature not enabled for this organization

--- ERROR ANALYSIS ---
⚠ LIKELY CAUSE: Einstein Features Not Enabled

SOLUTION:
  1. Go to Setup > Einstein Setup
  2. Enable "Einstein Generative AI"
  3. Ensure Einstein 1 Platform license is assigned
  4. Re-run this test
```

---

## 🔍 Common Error Scenarios

### Error 1: Template Not Found

**Error Message:**
```
Prompt template 'Flow_Evaluator_V3' not found
```

**Solution:**
1. Navigate to Setup > Prompt Builder
2. Find "Flow_Evaluator_V3" template
3. Click **Publish** button (top right)
4. Wait 2-3 minutes for changes to propagate
5. Re-run the debugger

**Verify Template Exists:**
```apex
// This won't directly verify, but you can check in Setup
// Setup > Prompt Builder > [Search for Flow_Evaluator_V3]
```

---

### Error 2: Feature Not Enabled

**Error Message:**
```
Feature not enabled for this organization
```

**Solution:**
1. Setup > Einstein Setup
2. Click **Turn on Einstein**
3. Enable "Einstein Generative AI"
4. Verify Einstein 1 Platform license is assigned to your user
5. May need to wait 15-30 minutes for activation

---

### Error 3: Insufficient Permissions

**Error Message:**
```
User does not have permission to access Einstein features
```

**Solution:**
1. Setup > Users > [Your User]
2. Verify Permission Set includes:
   - "Einstein Generative AI User"
   - "API Enabled"
3. Or update Profile to include these permissions

---

### Error 4: Null Response / Empty Generations

**What You See:**
```
Response Object: [valid object]
✗ ERROR: No generations in response
Response.generations is EMPTY
```

**Possible Causes:**
1. Input parameters don't match template requirements
2. Template configuration issue
3. Token limit exceeded

**Solution:**
1. Check prompt template parameter names match exactly:
   - `Input:flow_metadata`
   - `Input:knowledge`
2. Verify template is properly configured in Prompt Builder
3. Reduce input size if very large

---

## 🛠️ Troubleshooting Steps

### Step 1: Verify Template is Published

```apex
// Run the list command
PromptTemplateDebugger.listAvailableTemplates();

// Then manually check in Setup
// Setup > Prompt Builder > Templates
```

### Step 2: Test with Minimal Input

```apex
// Use the simplest possible test
PromptTemplateDebugger.testFlowEvaluatorV3();
```

If this works, your template is configured correctly. If your real flow fails, the issue is with the flow XML size or content.

### Step 3: Check Input Parameter Names

Verify your template expects these parameter names:
- `Input:flow_metadata` (for flow XML)
- `Input:knowledge` (optional)

Go to Setup > Prompt Builder > Flow_Evaluator_V3 > Edit to verify parameter names.

### Step 4: Reduce Input Size

If you get timeouts or null responses:

```apex
// Truncate very long flow XML for testing
String flowXml = fullFlowXml.substring(0, Math.min(10000, fullFlowXml.length()));
PromptTemplateDebugger.testTemplate('Flow_Evaluator_V3', flowXml);
```

---

## 📝 Integration with FlowAnalysisService

Once your template is working via the debugger, you can use it in production:

```apex
// From FlowAnalysisService.cls (lines 228-234)
ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response =
    ConnectApi.EinsteinLlm.generateMessagesForPromptTemplate(
        'Flow_Evaluator_V3',
        generationInput
    );

if (response != null && response.generations != null && !response.generations.isEmpty()) {
    return response.generations[0].text;
}
```

---

## 🎯 Common Use Cases

### Use Case 1: First-Time Setup Verification

After deploying to a new org:

```apex
// Quick validation that everything is configured
PromptTemplateDebugger.testFlowEvaluatorV3();
```

Expected: ✓ SUCCESS in 3-5 seconds

---

### Use Case 2: Debugging Production Failures

If `FlowAnalysisService` is failing:

```apex
// Get the actual flow that's failing
Flow problematicFlow = [SELECT Metadata FROM Flow WHERE ApiName = 'ProblemFlow' LIMIT 1];

// Test it directly
PromptTemplateDebugger.testTemplate('Flow_Evaluator_V3', problematicFlow.Metadata);
```

The debugger will show you exactly what's wrong.

---

### Use Case 3: Testing Template Changes

After modifying a prompt template:

```apex
// Test immediately after publishing
PromptTemplateDebugger.testFlowEvaluatorV3();

// Wait 3 minutes if it fails (propagation delay)
// Then re-run
```

---

### Use Case 4: Comparing V2 vs V3 Templates

```apex
String flowXml = '<Flow>...</Flow>';

// Test V2
PromptTemplateDebugger.testTemplate('Flow_Evaluator_V2', flowXml);

// Test V3
PromptTemplateDebugger.testTemplate('Flow_Evaluator_V3', flowXml);

// Compare the outputs in the debug logs
```

---

## ⚡ Performance Notes

### Typical Response Times

- **Einstein GPT (Prompt Template)**: 3-5 seconds
- **Template Not Found Error**: < 1 second
- **Permission Error**: < 1 second

If you see > 10 seconds, check:
1. Flow XML size (should be < 100KB)
2. Network connectivity
3. Einstein service status at trust.salesforce.com

---

## 🔐 Security Considerations

### API Key Safety

This debugger does **NOT** require API keys! It uses:
- Einstein 1 Platform license (built-in)
- ConnectApi (native Salesforce API)
- No external callouts

### Permissions Required

The user running the debugger needs:
- API Enabled
- Einstein Generative AI User (permission set)
- Read access to Flow metadata (if querying flows)

---

## 📋 Deployment

Deploy the debugger to your org:

```bash
# From project root
sf project deploy start \
  --source-dir force-app/main/default/classes/PromptTemplateDebugger.cls \
  --target-org your-org-alias
```

Or use the automated script:

```bash
./deploy-to-new-org.sh
```

The debugger will be included with all other classes.

---

## 🧪 Testing

Run the test class to verify deployment:

```bash
sf apex run test --class-names PromptTemplateDebuggerTest --result-format human
```

Expected: 100% code coverage

---

## 💡 Tips & Tricks

### Tip 1: Copy-Paste Ready

The debugger formats errors to be copy-paste friendly. When asking for help, copy the entire debug output.

### Tip 2: Run in Synchronous Context

Always run from **Execute Anonymous Window**, not from asynchronous contexts (batch, queueable). This ensures you see real-time debug logs.

### Tip 3: Check Debug Log Levels

Set debug logs to FINEST for maximum detail:
1. Setup > Debug Logs
2. New > User Debug Log
3. Apex Code = FINEST
4. Callout = FINEST

### Tip 4: Compare with External LLM

If Einstein fails, test the fallback:

```apex
// First, ensure HuggingFace is configured
System.debug('External LLM Configured: ' + ExternalLLMService.isConfigured());

// Then test manually
String flowXml = '<Flow>...</Flow>';
String knowledge = 'Best practices...';
String result = ExternalLLMService.generateCompletion(flowXml, knowledge);
System.debug('External LLM Result: ' + result);
```

---

## 📞 Getting Help

If the debugger shows an error you can't resolve:

1. **Copy the full debug output** (from "SESSION STARTED" to "SESSION COMPLETED")
2. **Check the ERROR ANALYSIS section** for automated suggestions
3. **Verify Setup**:
   - Setup > Prompt Builder (template published?)
   - Setup > Einstein Setup (features enabled?)
4. **Check Salesforce Status**: trust.salesforce.com

---

## 🔗 Related Files

- Main Service: `FlowAnalysisService.cls` (lines 228-234)
- External Fallback: `ExternalLLMService.cls`
- Prompt Templates: `force-app/main/default/genAiPromptTemplates/`
- Setup Guide: `Documentation/EINSTEIN_GPT_SETUP.md`

---

**End of Debugging Guide**

✨ Happy debugging! The `PromptTemplateDebugger` will help you identify and fix Einstein Prompt Template issues quickly.
