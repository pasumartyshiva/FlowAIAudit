# Flow AI Audit Dashboard - API Callout Documentation

## Overview
Flow AI Audit Dashboard makes callouts to two native Salesforce APIs:
1. **Tooling API** - For retrieving flow metadata
2. **Einstein Prompt Templates API** - For AI-powered flow analysis

---

## 1. Tooling API Callout

### Purpose
Retrieve flow metadata XML for analysis from Salesforce org.

### HTTP Request
```http
GET /services/data/v64.0/tooling/query/?q=SELECT+Id,ActiveVersion.VersionNumber,ActiveVersion.Definition,FullName,Label+FROM+FlowDefinition+WHERE+ActiveVersionId+!=+null HTTP/1.1
Host: [instance].my.salesforce.com

Headers:
Authorization: Bearer {OAUTH_TOKEN_FROM_NAMED_CREDENTIAL}
Content-Type: application/json
Accept: application/json
```

### HTTP Response (Success - 200 OK)
```json
{
  "size": 1,
  "totalSize": 1,
  "done": true,
  "queryLocator": null,
  "entityTypeName": "FlowDefinition",
  "records": [
    {
      "attributes": {
        "type": "FlowDefinition",
        "url": "/services/data/v64.0/tooling/sobjects/FlowDefinition/300xx000000XXXX"
      },
      "Id": "300xx000000XXXX",
      "FullName": "Billing_Request",
      "Label": "Billing Request",
      "ActiveVersion": {
        "attributes": {
          "type": "Flow",
          "url": "/services/data/v64.0/tooling/sobjects/Flow/301xx000000YYYY"
        },
        "VersionNumber": 1,
        "Definition": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Flow xmlns=\"http://soap.sforce.com/2006/04/metadata\">\n    <apiVersion>64.0</apiVersion>\n    <description>Handles billing request workflow</description>\n    <interviewLabel>Billing Request {!$Flow.CurrentDateTime}</interviewLabel>\n    <label>Billing Request</label>\n    <processMetadataValues>\n        <name>BuilderType</name>\n        <value><stringValue>LightningFlowBuilder</stringValue></value>\n    </processMetadataValues>\n    <processType>Flow</processType>\n    <start>\n        <locationX>50</locationX>\n        <locationY>0</locationY>\n    </start>\n    <status>Active</status>\n</Flow>"
      }
    }
  ]
}
```

### Error Response (401 Unauthorized)
```json
{
  "message": "Session expired or invalid",
  "errorCode": "INVALID_SESSION_ID"
}
```

### Error Response (400 Bad Request)
```json
{
  "message": "INVALID_TYPE: sObject type 'FlowDefinition' is not supported",
  "errorCode": "INVALID_TYPE"
}
```

### Authentication
- **Method**: OAuth 2.0 via Named Credential
- **Named Credential**: `Salesforce_Tooling_API`
- **Token Management**: Automatic via Salesforce platform
- **Token Storage**: Encrypted by platform (AES-256)
- **No credentials in code**: All authentication handled by Named Credential framework

### Implementation Reference
- **Apex Class**: `ToolingAPIService.cls`
- **Method**: `getFlowMetadata(String flowApiName)`
- **Line**: ~45-120

### Sample Apex Code
```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:Salesforce_Tooling_API/services/data/v64.0/tooling/query/?q=' +
    EncodingUtil.urlEncode(soqlQuery, 'UTF-8'));
req.setMethod('GET');
req.setHeader('Content-Type', 'application/json');
req.setHeader('Accept', 'application/json');

Http http = new Http();
HttpResponse res = http.send(req);

if (res.getStatusCode() == 200) {
    // Parse JSON response
    Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    // Process flow metadata...
}
```

---

## 2. Einstein Prompt Templates API Callout

### Purpose
Submit flow metadata to Einstein AI (Claude Sonnet 3.7/4.5) for comprehensive best practice analysis.

### Conceptual HTTP Request
```http
POST /services/data/v64.0/einstein/prompt-templates/{TEMPLATE_API_NAME}/generations HTTP/1.1
Host: [instance].my.salesforce.com

Headers:
Authorization: Bearer {SESSION_TOKEN}
Content-Type: application/json
Accept: application/json

Body:
{
  "isPreview": false,
  "inputParams": {
    "flowMetadata": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Flow xmlns=\"http://soap.sforce.com/2006/04/metadata\">...</Flow>",
    "flowType": "Record-Triggered Flow",
    "flowLabel": "Billing Request"
  }
}
```

### Actual Implementation (ConnectApi - Platform Managed)
```apex
// Create input for Einstein Prompt Template
ConnectApi.EinsteinPromptTemplateGenerationsInput input =
    new ConnectApi.EinsteinPromptTemplateGenerationsInput();

// Build input parameters map
Map<String, ConnectApi.WrappedValue> inputParams =
    new Map<String, ConnectApi.WrappedValue>();

// Add flow metadata
ConnectApi.WrappedValue flowMetadataParam = new ConnectApi.WrappedValue();
flowMetadataParam.value = flowMetadataXml;
inputParams.put('flowMetadata', flowMetadataParam);

// Add flow type for context-aware analysis
ConnectApi.WrappedValue flowTypeParam = new ConnectApi.WrappedValue();
flowTypeParam.value = 'Record-Triggered Flow';
inputParams.put('flowType', flowTypeParam);

input.inputParams = inputParams;
input.isPreview = false;

// Call Einstein API
ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response =
    ConnectApi.EinsteinLlm.generateMessagesForPromptTemplate(
        'Flow_Best_Practices_Analysis',
        input
    );

// Extract AI response
String aiAnalysis = response.generations[0].text;
```

### HTTP Response (Success - 200 OK)
```json
{
  "generations": [
    {
      "id": "gen_abc123xyz",
      "prompt": "You are a Salesforce Flow expert...",
      "text": "{\n  \"overallScore\": 67,\n  \"overallStatus\": \"NEEDS WORK\",\n  \"categories\": [\n    {\n      \"number\": 1,\n      \"name\": \"Documentation, Naming, and Clarity\",\n      \"icon\": \"\\ud83d\\udccb\",\n      \"status\": \"NEEDS WORK\",\n      \"analysis\": \"The flow has basic naming but lacks comprehensive documentation.\",\n      \"details\": [\n        {\n          \"heading\": \"Flow Naming\",\n          \"content\": \"Flow name 'Billing Request' is clear and descriptive.\"\n        },\n        {\n          \"heading\": \"Missing Documentation\",\n          \"content\": \"Flow lacks description and variable documentation.\"\n        }\n      ],\n      \"explanation\": \"While flow name is clear, missing comprehensive documentation impacts maintainability.\",\n      \"recommendation\": \"Add detailed flow description and document all variables with their purpose.\"\n    }\n  ],\n  \"findings\": [\n    {\n      \"area\": \"Documentation\",\n      \"severity\": \"NEEDS WORK\",\n      \"explanation\": \"Missing flow description and variable documentation.\",\n      \"recommendation\": \"Add comprehensive documentation for maintainability.\"\n    }\n  ]\n}",
      "parameters": {
        "temperature": 0.7,
        "maxTokens": 4000
      },
      "tokensUsed": 3250
    }
  ]
}
```

### Error Response (403 Forbidden - No Einstein License)
```json
{
  "message": "Einstein features are not enabled for this organization",
  "errorCode": "EINSTEIN_NOT_ENABLED"
}
```

### Error Response (400 Bad Request - Invalid Input)
```json
{
  "message": "Required input parameter 'flowMetadata' is missing",
  "errorCode": "MISSING_REQUIRED_PARAM"
}
```

### Authentication
- **Method**: Platform session token (automatic)
- **Authorization**: Einstein 1 license validates access
- **No custom token handling**: Managed entirely by ConnectApi framework
- **Token Storage**: N/A - uses current user session

### Implementation Reference
- **Apex Class**: `FlowAnalysisService.cls`
- **Method**: `analyzeFlowWithPromptTemplate(String flowApiName, String flowMetadata)`
- **Line**: ~180-350

---

## 3. Security Implementation

### Token Security
| Aspect | Implementation |
|--------|----------------|
| **Tooling API Tokens** | Stored in Named Credential (encrypted at rest) |
| **Einstein API Tokens** | Platform session token (automatic) |
| **Token Encryption** | AES-256 (Salesforce platform managed) |
| **Token Rotation** | Automatic via Named Credential refresh |
| **Token Exposure** | Never exposed to code, logs, or UI |
| **Credential Storage** | No hardcoded credentials anywhere |

### Data Transmission Security
- **Protocol**: HTTPS/TLS 1.2+ (enforced by platform)
- **Encryption in Transit**: 256-bit SSL encryption
- **Certificate Validation**: Automatic platform validation
- **MITM Protection**: Certificate pinning via platform

### Error Handling Security
```apex
// Sensitive data never logged
try {
    HttpResponse res = http.send(req);
    // Process response
} catch (Exception e) {
    // Generic error message - no token exposure
    System.debug(LoggingLevel.ERROR, 'API callout failed: ' + e.getTypeName());
    // Never log: tokens, credentials, full stack trace with data
}
```

---

## 4. Governor Limits Compliance

### Callout Limits
| Limit | Threshold | App Usage | Compliance |
|-------|-----------|-----------|------------|
| **Callouts per transaction** | 100 | 1-2 | ✅ Well below limit |
| **Callout timeout** | 120 seconds | 30-60 seconds | ✅ Well below limit |
| **Heap size** | 6 MB (synchronous) | ~2 MB | ✅ Optimized parsing |
| **CPU time** | 10 seconds | 2-3 seconds | ✅ Efficient processing |

### Best Practices
1. **Asynchronous Processing**: Long-running analyses use `@future` or Queueable
2. **Response Caching**: Analysis results stored in `Flow_Analysis__c` object
3. **Error Retry**: Exponential backoff for transient failures
4. **Bulk Prevention**: Max 5 flows analyzed per batch operation

---

## 5. API Rate Limiting

### Tooling API Limits
- **Rate Limit**: 15 requests per rolling 20-second window (per org)
- **App Behavior**: Sequential processing with delays between requests
- **Retry Logic**: 3 attempts with exponential backoff (2s, 4s, 8s)

### Einstein API Limits
- **Credit-Based**: Consumes Einstein credits (not rate-limited)
- **Typical Cost**: 100-500 credits per flow analysis
- **Credit Check**: Users notified when credits are low
- **Governance**: Admin can set monthly analysis quotas

---

## 6. Data Privacy & Compliance

### Data Handling
- **Flow Metadata**: Transmitted to Einstein API for analysis
- **Analysis Results**: Stored in customer's Salesforce org only
- **Data Residency**: All data stays within customer's Salesforce instance
- **No External Storage**: Zero data transmitted to third-party systems
- **Einstein Data**: Processed per Salesforce Trust agreements

### PII Considerations
- **Flow metadata may contain**: Field names, labels, formulas
- **Does NOT contain**: Actual record data, user PII, production data
- **Analysis scope**: Code structure only, not runtime data

---

## 7. Monitoring & Debugging

### Platform Event Monitoring
- API callouts logged in **Setup → Event Monitoring → API Event Type**
- Monitor via: `SELECT ApiType, ApiVersion, UserAgent, StatusCode FROM ApiEvent`

### Custom Debug Logging
```apex
// Debug logs (sanitized)
System.debug('Tooling API Response Status: ' + res.getStatusCode());
System.debug('Einstein Analysis Score: ' + analysisResult.get('overallScore'));
// Never logged: OAuth tokens, credentials, full API responses
```

### Error Tracking
- **Apex Exceptions**: Logged to `Flow_Analysis__c.Error_Message__c`
- **HTTP Errors**: Status codes captured for troubleshooting
- **User Notifications**: Toast messages for user-facing errors

---

## Document Metadata

- **Version**: 1.0
- **Last Updated**: January 28, 2026
- **Maintained By**: Flow AI Audit Team
- **Repository**: https://github.com/pasumartyshiva/FlowAIAudit
- **Contact**: GitHub Issues for technical questions

---

## Appendix: Sample cURL Commands (for reference)

### Tooling API Query (requires session token)
```bash
curl -X GET \
  "https://yourinstance.my.salesforce.com/services/data/v64.0/tooling/query/?q=SELECT+Id,FullName,Label+FROM+FlowDefinition+LIMIT+1" \
  -H "Authorization: Bearer YOUR_SESSION_TOKEN" \
  -H "Content-Type: application/json"
```

### Note on Einstein API
Einstein Prompt Templates API cannot be called directly via cURL as it requires ConnectApi framework integration and Einstein license validation.

---

*End of API Callout Documentation*
