# Einstein GPT Integration Guide

## 🔌 Implementing the Prompt Template Call

The `FlowAnalysisService.callPromptTemplate()` method needs to be implemented based on your org's Einstein GPT setup. Here are the options:

### Option 1: Using Flow-Invocable Actions (Recommended)

Create an invocable Apex method that the batch can call:

```apex
public class FlowAnalysisEinsteinService {

    @InvocableMethod(label='Call Flow Evaluator' description='Calls the Flow Evaluator prompt template')
    public static List<Response> callFlowEvaluator(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();

            try {
                // Use ConnectApi to call the prompt template
                ConnectApi.EinsteinPromptTemplateGenerationsInput input =
                    new ConnectApi.EinsteinPromptTemplateGenerationsInput();

                input.isPreview = false;
                input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
                input.additionalConfig.applicationName = 'FlowAIAudit';

                // Set input parameters
                Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
                inputParams.put('MetadataXMLVar', ConnectApi.WrappedValue.create(req.flowMetadata));
                inputParams.put('KnowledgeText', ConnectApi.WrappedValue.create(req.knowledgeText));
                input.inputParams = inputParams;

                // Call the prompt template
                ConnectApi.EinsteinPromptTemplateGenerationsRepresentation result =
                    ConnectApi.EinsteinLlm.generateMessagesForPromptTemplate(
                        'Flow_Evaluator_V2',
                        input
                    );

                // Extract the response
                if (result.generations != null && !result.generations.isEmpty()) {
                    res.analysisResult = result.generations[0].text;
                    res.success = true;
                } else {
                    res.success = false;
                    res.errorMessage = 'No response from AI model';
                }

            } catch (Exception e) {
                res.success = false;
                res.errorMessage = e.getMessage();
                System.debug(LoggingLevel.ERROR, 'Error calling prompt template: ' + e.getMessage());
            }

            responses.add(res);
        }

        return responses;
    }

    public class Request {
        @InvocableVariable(required=true)
        public String flowMetadata;

        @InvocableVariable(required=true)
        public String knowledgeText;
    }

    public class Response {
        @InvocableVariable
        public String analysisResult;

        @InvocableVariable
        public Boolean success;

        @InvocableVariable
        public String errorMessage;
    }
}
```

Then update `FlowAnalysisService.callPromptTemplate()`:

```apex
private static String callPromptTemplate(String templateName, Map<String, Object> inputs) {
    try {
        // Create request
        FlowAnalysisEinsteinService.Request req = new FlowAnalysisEinsteinService.Request();
        req.flowMetadata = (String) inputs.get('MetadataXMLVar');
        req.knowledgeText = (String) inputs.get('KnowledgeText');

        // Call invocable
        List<FlowAnalysisEinsteinService.Request> requests = new List<FlowAnalysisEinsteinService.Request>{ req };
        List<FlowAnalysisEinsteinService.Response> responses =
            FlowAnalysisEinsteinService.callFlowEvaluator(requests);

        // Process response
        if (!responses.isEmpty() && responses[0].success) {
            return responses[0].analysisResult;
        } else {
            throw new FlowAnalysisException(
                responses.isEmpty() ? 'No response' : responses[0].errorMessage
            );
        }

    } catch (Exception e) {
        throw new FlowAnalysisException('Failed to call prompt template: ' + e.getMessage());
    }
}
```

### Option 2: Using Named Credentials + REST API

If ConnectApi is not available, use the Einstein GPT REST API:

```apex
private static String callPromptTemplate(String templateName, Map<String, Object> inputs) {
    try {
        // Build request body
        Map<String, Object> requestBody = new Map<String, Object>{
            'promptTemplateId' => templateName,
            'inputParams' => inputs,
            'isPreview' => false,
            'additionalConfig' => new Map<String, Object>{
                'applicationName' => 'FlowAIAudit'
            }
        };

        // Make HTTP callout using Named Credential
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Einstein_GPT/einstein/prompt-templates/' + templateName + '/generations');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(requestBody));
        req.setTimeout(120000); // 2 minutes

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> generations = (List<Object>) responseBody.get('generations');

            if (generations != null && !generations.isEmpty()) {
                Map<String, Object> firstGeneration = (Map<String, Object>) generations[0];
                return (String) firstGeneration.get('text');
            } else {
                throw new FlowAnalysisException('No generations in response');
            }
        } else {
            throw new FlowAnalysisException('HTTP ' + res.getStatusCode() + ': ' + res.getBody());
        }

    } catch (Exception e) {
        throw new FlowAnalysisException('Failed to call prompt template: ' + e.getMessage());
    }
}
```

**Setup Named Credential**:
1. Go to **Setup → Named Credentials**
2. Create new **Named Credential**:
   - Label: `Einstein GPT`
   - Name: `Einstein_GPT`
   - URL: `https://api.salesforce.com` (or your org's My Domain)
   - Identity Type: `Per User`
   - Authentication Protocol: `OAuth 2.0`
   - Authentication Provider: (Create one for Salesforce OAuth)

### Option 3: Using Apex Flow Actions (Simplest)

If you're on API 60.0+, you can invoke the prompt template directly from Flow, then call it from Apex:

1. Create a Flow with:
   - Input: `flowMetadata` (Text)
   - Input: `knowledgeText` (Text)
   - Action: Call `Flow_Evaluator_V2` prompt template
   - Output: `analysisResult` (Text)

2. Make the Flow auto-launched and invocable

3. Call from Apex:
```apex
private static String callPromptTemplate(String templateName, Map<String, Object> inputs) {
    try {
        Map<String, Object> flowInputs = new Map<String, Object>{
            'flowMetadata' => inputs.get('MetadataXMLVar'),
            'knowledgeText' => inputs.get('KnowledgeText')
        };

        Flow.Interview.FlowAnalyzerAI flow = new Flow.Interview.FlowAnalyzerAI(flowInputs);
        flow.start();

        return (String) flow.getVariableValue('analysisResult');

    } catch (Exception e) {
        throw new FlowAnalysisException('Failed to call prompt template: ' + e.getMessage());
    }
}
```

## 🔑 Prerequisites

### 1. Einstein 1 Platform License
Ensure your org has:
- Einstein 1 Platform or Einstein GPT licenses
- Prompt Builder enabled

### 2. Model Access
Configure access to Claude 3.7 Sonnet:
1. Go to **Setup → Einstein Setup**
2. Navigate to **Einstein Trust Layer**
3. Enable **Bring Your Own LLM** (if using Bedrock)
4. Configure model: `sfdc_ai__DefaultBedrockAnthropicClaude37Sonnet`

### 3. Prompt Template Permissions
Grant users:
- **View Prompt Template** permission
- **Run Prompt Template** permission

### 4. API Limits
Monitor your Einstein GPT usage:
- Each flow analysis = 1 API call
- Batch of 50 flows = 50 API calls
- Ensure you have sufficient daily/monthly limits

## 📊 Testing the Integration

### Test Single Analysis

```apex
// Anonymous Apex
String testXml = '<?xml version="1.0"?><Flow xmlns="http://soap.sforce.com/2006/04/metadata">...</Flow>';
String knowledge = 'Evaluate for best practices';

Flow_Analysis__c result = FlowAnalysisService.analyzeFlow(
    'Test_Flow',
    testXml,
    'Test Flow Label',
    1
);

insert result;
System.debug('Analysis Status: ' + result.Status__c);
System.debug('Analysis Report: ' + result.Analysis_Report__c);
```

### Test Batch Processing

```apex
// Start with small batch size for testing
Id jobId = FlowAnalysisBatch.runBatch(5); // Only 5 flows

// Check status
AsyncApexJob job = [
    SELECT Status, JobItemsProcessed, TotalJobItems, NumberOfErrors
    FROM AsyncApexJob
    WHERE Id = :jobId
];
System.debug('Job Status: ' + job);
```

### Test Queueable

```apex
// Test single flow re-analysis
Id jobId = FlowAnalysisQueueable.analyzeFlow('CheckoutProcess');

// Check results after a few seconds
List<Flow_Analysis__c> analyses = [
    SELECT Status__c, Analysis_Report__c
    FROM Flow_Analysis__c
    WHERE Flow_API_Name__c = 'CheckoutProcess'
];
System.debug('Analysis: ' + analyses);
```

## 🐛 Debugging

### Enable Debug Logs

1. **Setup → Debug Logs**
2. Add trace flag for your user
3. Set Apex Code to `FINEST`
4. Set Callout to `FINEST`

### Check Prompt Template Calls

Look for log lines:
```
CALLOUT_REQUEST|Einstein GPT API
CALLOUT_RESPONSE|[200] {"generations":[...]}
```

### Common Issues

| Error | Cause | Solution |
|-------|-------|----------|
| `No prompt template found` | Template not deployed | Deploy Flow_Evaluator_V2 |
| `Insufficient privileges` | User lacks permissions | Grant prompt template permissions |
| `API limit exceeded` | Too many calls | Wait or increase limits |
| `Invalid JSON response` | Template not configured for JSON | Set responseFormat to JSON |
| `Timeout` | Flow too large/complex | Increase timeout or simplify flow |

## 💰 Cost Considerations

Einstein GPT usage is typically billed by:
- **Token usage** (input + output tokens)
- **API calls** per month

Example costs (approximate):
- Small org (100 flows): ~$5-10/month
- Medium org (500 flows): ~$25-50/month
- Large org (1000+ flows): ~$75-150/month

**Cost optimization**:
1. Only analyze active flows
2. Re-analyze only when flows change
3. Use batch processing (more efficient)
4. Cache results in Flow_Analysis__c

## 🚀 Go-Live Checklist

- [ ] Deploy all metadata to production
- [ ] Configure Einstein GPT credentials
- [ ] Publish Flow_Evaluator_V2 template
- [ ] Test single flow analysis
- [ ] Test batch with 5-10 flows
- [ ] Verify dashboard loads correctly
- [ ] Grant users appropriate permissions
- [ ] Monitor API usage limits
- [ ] Set up scheduled batch (optional)
- [ ] Document org-specific setup

## 📞 Support

If you encounter issues:
1. Check Salesforce Einstein GPT documentation
2. Review debug logs
3. Verify API limits in Setup → System Overview
4. Contact Salesforce Support for Einstein GPT issues

---

**Note**: The exact implementation of `callPromptTemplate()` depends on your org's API version, Einstein GPT setup, and license type. Choose the option that best fits your environment.
