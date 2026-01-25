# BYO-LLM Setup Guide for Salesforce Flow Guru

## Overview

The Salesforce Flow Guru now supports **Bring Your Own LLM (BYO-LLM)**, allowing you to use external AI providers like Google Gemini or Anthropic Claude for flow analysis. This eliminates the need for Einstein 1 Platform licenses and org-level token consumption.

### Benefits
- ✅ **No Einstein License Required** - Works in any Salesforce org including Dev Edition
- ✅ **No Org Token Consumption** - Uses your own API keys
- ✅ **Developer Friendly** - Run analysis anytime without org limits
- ✅ **Cost Effective** - Pay only for what you use (~$0.35-$0.50 per 100 flows)
- ✅ **High Quality** - Same or better analysis quality as Einstein GPT
- ✅ **Free Tier Available** - Google Gemini offers 1500 free requests/day

## Supported LLM Providers

| Provider | Model | Cost per 100 Flows* | Free Tier | Quality |
|----------|-------|---------------------|-----------|---------|
| **Google Gemini** (Default) | gemini-1.5-pro | ~$0.35 | 1500 req/day | Excellent |
| **Anthropic Claude** | claude-3-5-sonnet-20241022 | ~$0.50 | None | Superior |

*Estimated cost based on 50KB average flow size + 12KB assessment framework

## Quick Start

### Option 1: Google Gemini (Recommended)

#### Step 1: Get API Key
1. Visit https://aistudio.google.com/apikey
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the API key (starts with `AIza...`)

#### Step 2: Deploy Components
```bash
sf project deploy start -d force-app/main/default -o your-org-alias
```

#### Step 3: Configure Named Credential
1. Navigate to **Setup → Named Credentials**
2. Find **Google_Gemini_API**
3. Click **Edit**
4. Under **Custom Headers**:
   - Header Name: `x-goog-api-key`
   - Header Value: Paste your API key
5. Click **Save**

#### Step 4: Activate Configuration
1. Navigate to **Setup → Custom Metadata Types**
2. Click **Manage Records** next to **LLM Configuration**
3. Click **Edit** on **Google Gemini 1.5 Pro**
4. Check **Is Active**
5. Click **Save**

#### Step 5: Test
Run in Anonymous Apex:
```apex
// Test single flow analysis
FlowAnalysisBatch.runBatch(1);

// Check results
List<Flow_Analysis__c> results = [SELECT Id, Flow_API_Name__c, Status__c, Overall_Score__c
                                   FROM Flow_Analysis__c
                                   ORDER BY CreatedDate DESC LIMIT 1];
System.debug('Analysis Result: ' + results);
```

---

### Option 2: Anthropic Claude

#### Step 1: Get API Key
1. Visit https://console.anthropic.com/settings/keys
2. Sign in or create an account
3. Click "Create Key"
4. Copy the API key (starts with `sk-ant-...`)

#### Step 2: Deploy Components
```bash
sf project deploy start -d force-app/main/default -o your-org-alias
```

#### Step 3: Configure Named Credential
1. Navigate to **Setup → Named Credentials**
2. Find **Anthropic_API**
3. Click **Edit**
4. Under **Custom Headers**:
   - Header Name: `x-api-key`
   - Header Value: Paste your API key
5. Click **Save**

#### Step 4: Activate Configuration
1. Navigate to **Setup → Custom Metadata Types**
2. Click **Manage Records** next to **LLM Configuration**
3. Click **Edit** on **Anthropic Claude 3.5 Sonnet**
4. Check **Is Active**
5. Uncheck **Is Active** on **Google Gemini 1.5 Pro** (only one can be active)
6. Click **Save**

#### Step 5: Test
Run in Anonymous Apex:
```apex
// Test single flow analysis
FlowAnalysisBatch.runBatch(1);

// Check results
List<Flow_Analysis__c> results = [SELECT Id, Flow_API_Name__c, Status__c, Overall_Score__c
                                   FROM Flow_Analysis__c
                                   ORDER BY CreatedDate DESC LIMIT 1];
System.debug('Analysis Result: ' + results);
```

---

## Detailed Configuration

### Custom Metadata Fields

Each LLM Configuration record has the following fields:

| Field | Description | Example |
|-------|-------------|---------|
| **Provider Name** | LLM provider identifier | `Google` or `Anthropic` |
| **API Endpoint** | Provider API URL | `https://generativelanguage.googleapis.com/...` |
| **Model Name** | Specific model to use | `gemini-1.5-pro` |
| **API Key Name** | Named Credential API name | `Google_Gemini_API` |
| **Is Active** | Enable this configuration | ✓ (only one active at a time) |
| **Max Tokens** | Max response length | `8000` |
| **Temperature** | Creativity level (0-1) | `0.1` (lower = more consistent) |
| **System Prompt** | Optional system instructions | (Leave blank for default) |

### Switching Providers

To switch from Google to Anthropic or vice versa:

1. Navigate to **Setup → Custom Metadata Types → LLM Configuration → Manage Records**
2. **Edit** the current active provider → **Uncheck** "Is Active" → **Save**
3. **Edit** the desired provider → **Check** "Is Active" → **Save**
4. Re-run analysis - the new provider will be used automatically

### Advanced Configuration

#### Adjusting Temperature
- **0.0-0.3**: More deterministic, consistent analysis (recommended)
- **0.4-0.7**: Balanced creativity and consistency
- **0.8-1.0**: More creative but less predictable responses

#### Adjusting Max Tokens
- **4000**: Shorter responses, faster, cheaper
- **8000**: Default, recommended for detailed analysis
- **16000**: Extended responses for very complex flows (higher cost)

---

## Troubleshooting

### Error: "No active LLM configuration found"
**Solution**: Activate a provider in Custom Metadata Types → LLM Configuration

### Error: "API key is invalid"
**Solution**:
1. Verify API key is correct in Named Credential
2. Check API key hasn't expired
3. For Google: Ensure API key is enabled for Generative Language API
4. For Anthropic: Verify account has credits

### Error: "Timeout" or "Connection refused"
**Solution**:
1. Check Remote Site Settings includes the API endpoint
2. Verify org has outbound network access
3. Check API endpoint URL is correct in Custom Metadata

### Error: "Rate limit exceeded"
**Solution**:
1. **Google Free Tier**: You've exceeded 1500 requests/day - wait until reset or upgrade
2. **Anthropic**: Check your usage limits in console
3. Reduce batch size in `FlowAnalysisBatch.runBatch(5)` instead of `(20)`

### Analysis Quality Issues
**Solution**:
1. Ensure Temperature is set to 0.1 for consistent results
2. Increase Max Tokens to 8000 for detailed analysis
3. For complex flows, consider using Anthropic Claude (higher quality)

---

## Cost Management

### Google Gemini Pricing
- **Free Tier**: 1500 requests/day
- **Paid**: $0.00025 per 1K input tokens, $0.00075 per 1K output tokens
- **Estimated**: ~$0.35 per 100 flows analyzed

### Anthropic Claude Pricing
- **No Free Tier**
- **Paid**: $3.00 per 1M input tokens, $15.00 per 1M output tokens
- **Estimated**: ~$0.50 per 100 flows analyzed

### Tips to Reduce Costs
1. Use Google Gemini free tier for regular analysis
2. Batch analyses instead of analyzing flows individually
3. Reserve Anthropic Claude for complex or critical flows
4. Set Max Tokens to 6000 for simpler flows

---

## Security Considerations

### API Key Storage
- ✅ API keys stored in Named Credentials (encrypted at rest)
- ✅ Never logged or exposed in debug logs
- ✅ Accessible only to authorized admins

### Data Privacy
- ⚠️ Flow metadata is sent to external LLM providers
- ⚠️ Consider data sensitivity before using external services
- ⚠️ Review provider's data retention policies:
  - Google: Data not used for training (as of 2024)
  - Anthropic: Data not used for training (as of 2024)

### Compliance
- Ensure use of external AI services complies with your org's policies
- For highly sensitive orgs, use Einstein GPT (keeps data in Salesforce)

---

## Fallback to Einstein GPT

The system automatically prioritizes providers in this order:
1. **External BYO-LLM** (if configured and active)
2. **Einstein GPT** (if prompt template published and licensed)
3. **Fallback Error Message** (with setup instructions)

To use Einstein GPT instead of BYO-LLM:
1. Deactivate all LLM Configuration records
2. Ensure Einstein GPT prompt template is published
3. Analysis will automatically use Einstein GPT

---

## API Rate Limits

### Google Gemini
- Free: 1500 requests/day, 15 requests/minute
- Paid: 2000 requests/minute (configurable)

### Anthropic Claude
- Tier 1: 50 requests/minute
- Tier 2: 1000 requests/minute
- Tier 3: 2000 requests/minute

### Batch Processing
The system uses `FlowAnalysisBatch` with default batch size of 10:
- Each batch processes flows sequentially
- 1 API call per flow
- Adjust batch size based on rate limits

---

## Support

### Documentation
- **Setup Guide**: This file (`BYO_LLM_SETUP.md`)
- **Einstein GPT Setup**: `AI_INTEGRATION_UPDATE.md`
- **Architecture**: See implementation plan in `.claude/plans/`

### Getting Help
1. Check Debug Logs for detailed error messages
2. Verify configuration step-by-step
3. Test with a single flow first before batch processing
4. Review provider API documentation for specific errors

### Provider Documentation
- **Google Gemini**: https://ai.google.dev/docs
- **Anthropic Claude**: https://docs.anthropic.com/
- **Salesforce Named Credentials**: https://help.salesforce.com/s/articleView?id=sf.named_credentials_about.htm

---

## Frequently Asked Questions

**Q: Can I use both Google and Anthropic?**
A: Yes, but only one can be active at a time. Switch providers via Custom Metadata.

**Q: Does this work in scratch orgs?**
A: Yes! BYO-LLM works in all Salesforce orgs including scratch orgs and Dev Edition.

**Q: Will this consume Salesforce API limits?**
A: Yes, but minimally. The Tooling API calls to fetch flow metadata count against API limits, not the LLM calls.

**Q: Can I use this in production?**
A: Yes, but ensure compliance with your org's policies on external service usage.

**Q: How do I know which provider is being used?**
A: Check debug logs - the system logs which provider is active at runtime.

**Q: Can I customize the analysis prompt?**
A: Yes, modify `FlowAnalysisService.buildPrompt()` or add a System Prompt in Custom Metadata.

---

## What's Next?

1. ✅ Deploy the components
2. ✅ Configure your preferred provider
3. ✅ Run a test analysis
4. 🚀 Analyze all your flows: `FlowAnalysisBatch.runBatch(10);`
5. 📊 Review results in the Flow Analysis tab

**Enjoy license-free, cost-effective flow analysis! 🎉**
