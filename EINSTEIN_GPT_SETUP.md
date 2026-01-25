# Einstein GPT + HuggingFace Hybrid Setup

## Architecture

Your Flow Guru tool now uses a **hybrid approach**:

1. **PRIMARY: Einstein GPT** (Prompt Template) - Production-ready, no API key needed
2. **FALLBACK: HuggingFace** (Qwen 72B) - Free alternative for demos/prototypes

### How It Works

```
┌─────────────────────────────────────────────────┐
│   Flow Analysis Request                         │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
         ┌─────────────────────┐
         │  Try Einstein GPT   │
         │  (Prompt Template)  │
         └──────────┬──────────┘
                    │
         ┌──────────┴──────────┐
         │                     │
    SUCCESS ✓            FAIL (No license)
         │                     │
         │              ┌──────▼──────────┐
         │              │ Try HuggingFace │
         │              │   (Free API)    │
         │              └──────┬──────────┘
         │                     │
         │              ┌──────┴──────┐
         │              │             │
         │         SUCCESS ✓     FAIL ✗
         │              │             │
         ▼              ▼             ▼
    ┌────────────────────────────────────┐
    │      Return Analysis Result        │
    └────────────────────────────────────┘
```

## Setup Steps

### Option 1: Einstein GPT (Production - Recommended)

**Prerequisites:**
- Einstein 1 Platform license in your org
- OR Einstein Trust Layer access

**Steps:**

1. **Navigate to Prompt Builder**
   ```
   Setup → Search "Prompt Builder" → Open Prompt Builder
   ```

2. **Find Flow_Evaluator_V3 Template**
   - Look for "Flow_Evaluator_V3" in the list
   - Status should show as "Inactive" or "Draft"

3. **Publish the Template**
   - Click on "Flow_Evaluator_V3"
   - Click "Publish" button
   - Confirm publication

4. **Test the Integration**
   ```apex
   FlowAnalysisBatch.runBatch(1);
   ```

5. **Verify in Debug Logs**
   ```
   INFO|Attempting Einstein GPT call with template: Flow_Evaluator_V3
   INFO|Einstein GPT API call completed successfully
   ```

**Benefits:**
- ✅ No API keys to manage
- ✅ Fast response times (3-5 seconds)
- ✅ Production-ready and reliable
- ✅ Uses org's Einstein tokens (not external APIs)
- ✅ No timeout issues

**Limitations:**
- ❌ Requires Einstein 1 Platform license ($75/user/month)
- ❌ Consumes org-level Einstein tokens

---

### Option 2: HuggingFace Fallback (Demo/Prototype)

**Prerequisites:**
- Free HuggingFace account
- HuggingFace API token (read access)

**Steps:**

1. **Get HuggingFace API Token**
   - Visit: https://huggingface.co/settings/tokens
   - Click "Create new token"
   - Name: "Salesforce Flow Guru"
   - Type: "Read" or "Make calls to Inference Providers"
   - Click "Create"
   - Copy the token (starts with `hf_...`)

2. **Configure in Salesforce**
   ```
   Setup → Custom Metadata Types → LLM Configuration → Manage Records
   ```

3. **Edit HuggingFace Configuration**
   - Click "Edit" next to "HuggingFace Qwen 72B"
   - Paste token in "API Key" field
   - Check "Is Active" checkbox
   - Click "Save"

4. **Test the Integration**
   ```apex
   FlowAnalysisBatch.runBatch(1);
   ```

5. **Verify in Debug Logs**
   ```
   WARN|Einstein GPT unavailable: <error message>
   INFO|Attempting fallback to External BYO-LLM (HuggingFace)
   INFO|Using External BYO-LLM provider as fallback
   INFO|Calling Hugging Face Router API (OpenAI-compatible)
   ```

**Benefits:**
- ✅ Completely FREE (no cost)
- ✅ No Salesforce license requirements
- ✅ Works in any org (including Dev Edition)
- ✅ Great for demos and prototypes

**Limitations:**
- ❌ Slow response times (10-30 seconds)
- ❌ Frequent 504 Gateway Timeouts (free tier is unreliable)
- ❌ Not production-ready
- ❌ Limited to 1000 requests/month on free tier

---

## Testing the Hybrid Setup

### Scenario 1: Einstein GPT Available (Production)

```apex
// Run batch job
FlowAnalysisBatch.runBatch(1);

// Expected debug logs:
// INFO|Attempting Einstein GPT call with template: Flow_Evaluator_V3
// INFO|Einstein GPT API call completed successfully
// ✅ Fast, reliable results
```

### Scenario 2: Einstein GPT Unavailable, HuggingFace Active (Demo)

```apex
// Run batch job (no Einstein license)
FlowAnalysisBatch.runBatch(1);

// Expected debug logs:
// WARN|Einstein GPT unavailable: Prompt template not published
// INFO|Attempting fallback to External BYO-LLM (HuggingFace)
// INFO|Using External BYO-LLM provider as fallback
// INFO|Hugging Face Router API response status: 200
// ⚠️ Slower, may timeout occasionally
```

### Scenario 3: Both Unavailable (Configuration Needed)

```apex
// Run batch job (no license, no API key)
FlowAnalysisBatch.runBatch(1);

// Expected result:
// Flow Analysis Report shows:
// "⚠️ LLM CONFIGURATION REQUIRED"
// With setup instructions for both options
```

---

## Cost Comparison

| Option | Setup Time | Monthly Cost | Response Time | Reliability | Best For |
|--------|-----------|--------------|---------------|-------------|----------|
| **Einstein GPT** | 5 min | $75/user* | 3-5 sec | ⭐⭐⭐⭐⭐ | Production |
| **HuggingFace** | 10 min | $0 | 10-30 sec | ⭐⭐ | Demos/Prototypes |

*Requires Einstein 1 Platform license

---

## Troubleshooting

### Einstein GPT Issues

**Error: "Prompt template not found"**
- Solution: Publish the template in Prompt Builder
- Path: Setup → Prompt Builder → Flow_Evaluator_V3 → Publish

**Error: "Einstein GPT is not enabled"**
- Solution: Enable Einstein Trust Layer or get Einstein 1 Platform license
- Path: Setup → Einstein Setup → Enable Einstein

**Error: "Insufficient privileges"**
- Solution: Ensure running user has Einstein user permissions
- Path: Setup → Users → Edit → Assign Einstein Permission Set

### HuggingFace Issues

**Error: "504 Gateway Timeout"**
- Cause: Free tier is slow, HuggingFace servers overloaded
- Solution: Retry after a few minutes, or upgrade to paid tier
- Workaround: Use Einstein GPT as primary instead

**Error: "401 Unauthorized"**
- Cause: Invalid or expired API token
- Solution: Generate new token at https://huggingface.co/settings/tokens
- Update: Custom Metadata → HuggingFace Qwen 72B → API Key field

**Error: "Empty response from Hugging Face API"**
- Cause: API returned data in unexpected format
- Solution: Check debug logs for full response body
- Contact: support if issue persists

---

## Recommended Setup for Different Use Cases

### 1. Production Org
```
✅ PRIMARY: Einstein GPT (publish template)
❌ FALLBACK: HuggingFace (disabled)
```

### 2. Demo/Prototype Org
```
❌ PRIMARY: Einstein GPT (not available)
✅ FALLBACK: HuggingFace (active with API key)
```

### 3. Development Org (Testing Both)
```
✅ PRIMARY: Einstein GPT (publish template)
✅ FALLBACK: HuggingFace (active with API key)
```

---

## Quick Start Commands

### Deploy (Already Done)
```bash
sf project deploy start -d force-app/main/default/classes/FlowAnalysisService.cls \
  force-app/main/default/genAiPromptTemplates -o my-dev-org
```

### Test Single Flow
```apex
FlowAnalysisBatch.runBatch(1);
```

### Test All Flows
```apex
FlowAnalysisBatch.runBatch(200);
```

### Check Configuration
```apex
// Anonymous Apex
System.debug('External LLM Configured: ' + ExternalLLMService.isConfigured());
```

---

## Support

- **Einstein GPT Issues**: Check Salesforce Einstein documentation
- **HuggingFace Issues**: Visit https://huggingface.co/docs
- **Integration Issues**: Check debug logs for detailed error messages

---

**Status**: ✅ Hybrid system deployed and ready for setup
**Next Step**: Choose Option 1 (Einstein GPT) or Option 2 (HuggingFace) based on your org type
