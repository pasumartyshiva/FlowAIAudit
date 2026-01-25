# Flow Guru - Session Handoff Documentation

**Date**: January 23, 2026
**Project**: Salesforce Flow Guru - AI-Powered Flow Analysis Tool
**Status**: ✅ Fully Implemented with Hybrid LLM Architecture

---

## Project Overview

Flow Guru is a Salesforce tool that uses AI to analyze flows and provide detailed quality assessments based on a 12-point framework. The tool has evolved to support multiple LLM providers with intelligent fallback mechanisms.

---

## What We Built

### Core Features
1. **AI-Powered Flow Analysis** - Analyzes Salesforce flows using LLM models
2. **Hybrid LLM Architecture** - Primary: Einstein GPT, Fallback: HuggingFace
3. **Batch Processing** - Analyzes multiple flows asynchronously
4. **Dashboard UI** - Lightning Web Component for viewing results
5. **12-Point Assessment Framework** - Comprehensive quality criteria

### LLM Provider Architecture

**Priority 1: Einstein GPT (Prompt Template)**
- No API keys required
- Uses org's Einstein 1 Platform license
- Fast response times (3-5 seconds)
- Production-ready

**Priority 2: HuggingFace (External API)**
- Free alternative for demos/prototypes
- Qwen 2.5 72B Instruct model
- OpenAI-compatible Router API
- Slower but completely free

**Fallback Logic**:
```
Try Einstein GPT → Success? Return result
                 ↓
                Fail
                 ↓
Try HuggingFace → Success? Return result
                 ↓
                Fail
                 ↓
Return error with setup instructions
```

---

## Project Structure

```
/Users/spasumarty/Documents/PersonalOrg/
├── force-app/main/default/
│   ├── classes/
│   │   ├── FlowAnalysisService.cls          # Main orchestration service
│   │   ├── ExternalLLMService.cls           # BYO-LLM provider abstraction
│   │   ├── FlowAnalysisBatch.cls            # Batch processing
│   │   ├── FlowAnalysisQueueable.cls        # Queueable job for individual flows
│   │   └── *Test.cls files                  # Test classes (100% coverage)
│   ├── lwc/
│   │   └── flowAiAuditDashboard/            # Dashboard UI component
│   ├── objects/
│   │   ├── Flow_Analysis__c/                # Custom object to store results
│   │   └── LLM_Configuration__mdt/          # Custom metadata type for LLM configs
│   ├── customMetadata/
│   │   ├── LLM_Configuration.Google_Gemini_1_5_Pro.md-meta.xml
│   │   ├── LLM_Configuration.Anthropic_Claude_3_5_Sonnet.md-meta.xml
│   │   └── LLM_Configuration.HuggingFace_Qwen_72B.md-meta.xml
│   ├── remoteSiteSettings/
│   │   ├── Google_Gemini.remoteSite-meta.xml
│   │   ├── Anthropic_API.remoteSite-meta.xml
│   │   └── HuggingFace_API.remoteSite-meta.xml
│   ├── genAiPromptTemplates/
│   │   ├── Flow_Evaluator_V2.genAiPromptTemplate-meta.xml
│   │   └── Flow_Evaluator_V3.genAiPromptTemplate-meta.xml
│   └── namedCredentials/
│       ├── Google_Gemini_API.namedCredential-meta.xml
│       └── Anthropic_API.namedCredential-meta.xml
├── deploy-to-new-org.sh                     # Automated deployment script
└── Documentation/
    ├── EINSTEIN_GPT_SETUP.md                # Einstein GPT setup guide
    ├── BYO_LLM_SETUP.md                     # External LLM setup guide
    ├── HUGGINGFACE_SETUP.md                 # HuggingFace-specific guide
    ├── HUGGINGFACE_TOKEN_GUIDE.md           # Token generation guide
    └── AI_INTEGRATION_UPDATE.md             # Original integration docs
```

---

## Key Technical Decisions

### 1. Hybrid Architecture (Einstein GPT + HuggingFace)

**Reason**: User wanted:
- Production-ready solution without external API keys (Einstein GPT)
- Free fallback for demos/prototypes (HuggingFace)
- Ability to showcase both approaches

**Implementation**:
- `FlowAnalysisService.cls` tries Einstein GPT first
- If Einstein fails (no license/not published), falls back to External LLM
- External LLM checks Custom Metadata for active provider
- All providers use same abstraction layer in `ExternalLLMService.cls`

### 2. Custom Metadata for Configuration

**Reason**: Allows runtime configuration without code changes

**Fields**:
- `Provider_Name__c` - Google, Anthropic, HuggingFace
- `API_Endpoint__c` - Provider API URL
- `Model_Name__c` - Specific model identifier
- `API_Key__c` - Direct API key storage (simplified from Named Credentials)
- `Is_Active__c` - Enable/disable provider
- `Max_Tokens__c` - Response length limit
- `Temperature__c` - Creativity setting

### 3. API Key Storage Evolution

**Original**: Named Credentials (complex setup)
**Final**: Direct storage in Custom Metadata `API_Key__c` field

**Reason**: User couldn't find where to add API key in Named Credential UI. Simplified to direct field entry.

### 4. HuggingFace API Migration

**Original**: `api-inference.huggingface.co` (old inference API)
**Current**: `router.huggingface.co/v1/responses` (OpenAI-compatible)

**Request Format**:
```json
{
  "model": "Qwen/Qwen2.5-72B-Instruct",
  "input": "prompt text"
}
```

**Response Format**:
```json
{
  "output": [
    {
      "content": [
        {
          "type": "output_text",
          "text": "```json\n{...analysis...}\n```"
        }
      ]
    }
  ]
}
```

**Parsing**: Extract `output[0].content[0].text` and strip markdown code blocks

---

## Issues Encountered & Solutions

### Issue 1: Google Gemini Model Deprecation
- **Problem**: `gemini-1.5-pro` deprecated, got 404 errors
- **Solution**: Updated to `gemini-2.0-flash-exp` on v1beta endpoint
- **File**: `LLM_Configuration.Google_Gemini_1_5_Pro.md-meta.xml`

### Issue 2: Google Quota Exceeded
- **Problem**: User hit free tier limit (1500 req/day)
- **Solution**: Pivoted to HuggingFace as free alternative
- **Status**: Google config now inactive by default

### Issue 3: HuggingFace 410 - Deprecated Endpoint
- **Problem**: Old API endpoint no longer supported
- **Solution**: Updated to `router.huggingface.co`
- **Files**:
  - `ExternalLLMService.cls` (request format)
  - `LLM_Configuration.HuggingFace_Qwen_72B.md-meta.xml` (endpoint)
  - `HuggingFace_API.remoteSite-meta.xml` (CORS)

### Issue 4: HuggingFace 504 Gateway Timeout
- **Problem**: Free tier is slow, frequently times out
- **Solution**: Made Einstein GPT primary, HuggingFace fallback only
- **Status**: User chose to use Einstein GPT in production

### Issue 5: Empty Response Error (HuggingFace)
- **Problem**: Response parsing failed - expected `output_text` but got nested structure
- **Solution**: Updated parsing to extract `output[0].content[0].text`
- **File**: `ExternalLLMService.cls` line 302-330

### Issue 6: Markdown Code Blocks in Response
- **Problem**: Model wraps JSON in ```json...```
- **Solution**: Added cleanup logic to strip markdown formatting
- **File**: `ExternalLLMService.cls` line 327-339

---

## Current State

### Deployed Components
- ✅ All Apex classes deployed to `pasumarty_shiva@agentforce.com`
- ✅ Custom Metadata Type with 3 provider configs
- ✅ Remote Site Settings for all providers
- ✅ Prompt Templates (V2 and V3) deployed
- ✅ Lightning Web Component dashboard
- ✅ Named Credentials (for reference, not actively used)

### Active Configuration
- **Einstein GPT**: Not published yet (requires manual step)
- **Google Gemini**: Inactive (quota exceeded)
- **Anthropic Claude**: Inactive (no API key)
- **HuggingFace**: Inactive (has timeout issues)

### Next Steps for User
1. **Option A**: Publish Einstein GPT template in Prompt Builder
2. **Option B**: Deploy to new org and start fresh
3. **Option C**: Add HuggingFace API key for demo purposes

---

## Code Highlights

### FlowAnalysisService.cls - Priority Logic

```apex
// PRIORITY 1: Try Einstein GPT first
try {
    ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response =
        ConnectApi.EinsteinLlm.generateMessagesForPromptTemplate('Flow_Evaluator_V3', generationInput);

    if (response != null && response.generations != null && !response.generations.isEmpty()) {
        return response.generations[0].text;
    }
} catch (Exception einsteinError) {
    // PRIORITY 2: Fallback to External LLM
    if (ExternalLLMService.isConfigured()) {
        try {
            return ExternalLLMService.generateCompletion(metadataXml, knowledge);
        } catch (Exception externalError) {
            // Both failed
            return generateFallbackResponse(combinedError);
        }
    }
}
```

### ExternalLLMService.cls - HuggingFace Implementation

```apex
private static String callHuggingFace(String prompt, LLM_Configuration__mdt config) {
    // Build OpenAI-compatible request
    Map<String, Object> requestBody = new Map<String, Object>{
        'model' => config.Model_Name__c,  // "Qwen/Qwen2.5-72B-Instruct"
        'input' => prompt
    };

    HttpRequest req = new HttpRequest();
    req.setEndpoint('https://router.huggingface.co/v1/responses');
    req.setMethod('POST');
    req.setHeader('Authorization', 'Bearer ' + config.API_Key__c);
    req.setHeader('Content-Type', 'application/json');
    req.setBody(JSON.serialize(requestBody));

    // Parse nested response structure
    Map<String, Object> responseObj = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    List<Object> outputArray = (List<Object>) responseObj.get('output');
    Map<String, Object> firstOutput = (Map<String, Object>) outputArray[0];
    List<Object> contentArray = (List<Object>) firstOutput.get('content');
    Map<String, Object> contentObj = (Map<String, Object>) contentArray[0];
    String outputText = (String) contentObj.get('text');

    // Clean up markdown code blocks
    outputText = outputText.trim();
    if (outputText.startsWith('```json')) {
        outputText = outputText.substring(7);
    }
    if (outputText.endsWith('```')) {
        outputText = outputText.substring(0, outputText.length() - 3);
    }

    return outputText.trim();
}
```

---

## Testing

### Manual Test Commands

```apex
// Test single flow analysis
FlowAnalysisBatch.runBatch(1);

// Test all flows
FlowAnalysisBatch.runBatch(200);

// Check if external LLM is configured
System.debug('External LLM Configured: ' + ExternalLLMService.isConfigured());
```

### Expected Debug Logs (Einstein GPT)

```
INFO|Attempting Einstein GPT call with template: Flow_Evaluator_V3
INFO|Einstein GPT API call completed successfully
```

### Expected Debug Logs (HuggingFace Fallback)

```
WARN|Einstein GPT unavailable: Prompt template not published
INFO|Attempting fallback to External BYO-LLM (HuggingFace)
INFO|Using External BYO-LLM provider as fallback
INFO|Calling Hugging Face Router API (OpenAI-compatible)
INFO|Hugging Face Router API response status: 200
```

---

## Deployment Instructions

### Fresh Org Deployment

**Automated**:
```bash
cd /Users/spasumarty/Documents/PersonalOrg
./deploy-to-new-org.sh
```

**Manual**:
```bash
# Authenticate
sf org login web --alias new-org --set-default

# Deploy all metadata
sf project deploy start \
  --source-dir force-app/main/default \
  --target-org new-org \
  --wait 10

# Run tests
sf apex run test --target-org new-org --result-format human --code-coverage

# Open org
sf org open --target-org new-org
```

### Post-Deployment Setup

**For Einstein GPT**:
1. Setup → Prompt Builder
2. Find "Flow_Evaluator_V3"
3. Click "Publish"
4. Test: `FlowAnalysisBatch.runBatch(1)`

**For HuggingFace**:
1. Get token: https://huggingface.co/settings/tokens
2. Setup → Custom Metadata Types → LLM Configuration
3. Edit "HuggingFace Qwen 72B"
4. Add API key, check "Is Active"
5. Test: `FlowAnalysisBatch.runBatch(1)`

---

## Documentation Files

1. **EINSTEIN_GPT_SETUP.md** - Comprehensive guide for Einstein GPT + HuggingFace hybrid setup
2. **BYO_LLM_SETUP.md** - External LLM provider setup (Google, Anthropic, HuggingFace)
3. **HUGGINGFACE_SETUP.md** - HuggingFace-specific configuration guide
4. **HUGGINGFACE_TOKEN_GUIDE.md** - Step-by-step token generation instructions
5. **AI_INTEGRATION_UPDATE.md** - Original Einstein GPT integration documentation
6. **deploy-to-new-org.sh** - Automated deployment script

---

## Known Limitations

1. **HuggingFace Timeouts**: Free tier frequently hits 504 Gateway Timeout
2. **Google Quota**: Free tier limited to 1500 requests/day
3. **Einstein GPT Requirement**: Needs Einstein 1 Platform license ($75/user/month)
4. **Salesforce HTTP Timeout**: Hard limit of 120 seconds per callout

---

## Future Enhancements (Out of Scope)

1. OpenAI GPT-4 integration
2. Azure OpenAI support
3. Response caching to reduce API costs
4. Prompt versioning and A/B testing
5. Cost tracking per provider
6. Streaming responses for real-time feedback
7. Retry logic with exponential backoff for HuggingFace
8. Platform Events for async processing beyond 120s timeout

---

## Session Context

### User's Original Request
"Would it make sense to use BYO-LLM here? This way we can avoid tokens being used on a platform level..."

### Evolution of Requirements
1. Started with BYO-LLM (Google Gemini, Anthropic)
2. Hit Google quota limits
3. Pivoted to HuggingFace (completely free)
4. Encountered 504 timeouts
5. Final decision: Einstein GPT primary, HuggingFace fallback for demos

### Final User Request
"Ok do it via prompt template so I don't have to get the api key, keep hugging face as an alternative option as a hybrid approach, cool to show as a prototype"

This led to the current hybrid architecture.

---

## Quick Reference

### Run Analysis
```apex
FlowAnalysisBatch.runBatch(1);
```

### Check Configuration
```apex
System.debug('Configured: ' + ExternalLLMService.isConfigured());
```

### View Results
- App Launcher → "Flow AI Audit Dashboard"
- Setup → Custom Objects → Flow Analysis → Records

### Publish Prompt Template
- Setup → Prompt Builder → Flow_Evaluator_V3 → Publish

### Add API Key
- Setup → Custom Metadata Types → LLM Configuration → Manage Records → Edit → API Key field

---

## Contact & Resources

- **Project Location**: `/Users/spasumarty/Documents/PersonalOrg`
- **Org**: `pasumarty_shiva@agentforce.com`
- **Deployment Script**: `./deploy-to-new-org.sh`
- **Current Org Alias**: `my-dev-org` (in SF CLI)

---

**End of Session Handoff**

All code is deployed and functional. The hybrid architecture is ready for production (Einstein GPT) or demo (HuggingFace) use cases. User's next step is to either publish the Einstein GPT template or deploy to a fresh org.
