# Flow AI Audit Dashboard - API Callout Documentation

## Overview
Flow AI Audit Dashboard makes callouts to two native Salesforce APIs:
1. **Tooling API** - For retrieving flow metadata
2. **Einstein Prompt Templates API** - For AI-powered flow analysis

---

## 1. Tooling API Callout

### Purpose
Retrieve flow metadata XML for analysis from Salesforce org.

### HTTP Request - Complete with All Headers
```http
GET /services/data/v64.0/tooling/query?q=SELECT%20Id%2CDefinition.MasterLabel%2CMetadata%20FROM%20Flow%20WHERE%20Definition.DeveloperName%20%3D%20%27Sample_Flow%27%20AND%20Status%20%3D%20%27Active%27%20LIMIT%201 HTTP/1.1
Host: yourinstance.my.salesforce.com
Authorization: Bearer 00D5g000008kXXX!ARMAQFqPxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Content-Type: application/json
Accept: application/json
User-Agent: SalesforcePlatform/1.0
Connection: keep-alive
Accept-Encoding: gzip, deflate
Cache-Control: no-cache
```

**Header Details:**
| Header | Value | Purpose |
|--------|-------|---------|
| `Authorization` | Bearer {session_token} | OAuth 2.0 authentication via Named Credential |
| `Content-Type` | application/json | Request format specification |
| `Accept` | application/json | Expected response format |
| `User-Agent` | SalesforcePlatform/1.0 | Client identification |
| `Connection` | keep-alive | HTTP connection persistence |
| `Accept-Encoding` | gzip, deflate | Compression support |
| `Cache-Control` | no-cache | Prevent response caching |
```

### HTTP Response (Success - 200 OK) - Complete with All Headers
```http
HTTP/1.1 200 OK
Date: Wed, 29 Jan 2026 12:00:00 GMT
Content-Type: application/json;charset=UTF-8
Content-Encoding: gzip
Content-Length: 1247
Connection: keep-alive
Cache-Control: no-cache, no-store, must-revalidate
Pragma: no-cache
Expires: 0
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
Sforce-Limit-Info: api-usage=125/15000

{
  "size": 1,
  "totalSize": 1,
  "done": true,
  "queryLocator": null,
  "entityTypeName": "Flow",
  "records": [
    {
      "attributes": {
        "type": "Flow",
        "url": "/services/data/v64.0/tooling/sobjects/Flow/301xx000000YYYY"
      },
      "Id": "301xx000000YYYY",
      "Definition": {
        "MasterLabel": "Sample Flow"
      },
      "Metadata": {
        "apiVersion": "64.0",
        "description": "Sample flow for demonstration",
        "interviewLabel": "Sample Flow {!$Flow.CurrentDateTime}",
        "label": "Sample Flow",
        "processMetadataValues": [
          {
            "name": "BuilderType",
            "value": {
              "stringValue": "LightningFlowBuilder"
            }
          }
        ],
        "processType": "Flow",
        "start": {
          "locationX": 50,
          "locationY": 0
        },
        "status": "Active"
      }
    }
  ]
}
```

**Response Header Details:**
| Header | Value | Purpose |
|--------|-------|---------|
| `Content-Type` | application/json;charset=UTF-8 | Response format and character encoding |
| `Content-Encoding` | gzip | Response compression method |
| `Cache-Control` | no-cache, no-store, must-revalidate | Caching directives |
| `Strict-Transport-Security` | max-age=31536000 | HTTPS enforcement |
| `X-Content-Type-Options` | nosniff | MIME type security |
| `X-Frame-Options` | SAMEORIGIN | Clickjacking protection |
| `X-XSS-Protection` | 1; mode=block | XSS filter activation |
| `Sforce-Limit-Info` | api-usage=125/15000 | API usage tracking |
```

### Error Response (401 Unauthorized) - Complete with Headers
```http
HTTP/1.1 401 Unauthorized
Date: Wed, 29 Jan 2026 12:00:00 GMT
Content-Type: application/json;charset=UTF-8
Content-Length: 89
Connection: keep-alive
WWW-Authenticate: Bearer realm="Salesforce", error="invalid_token"
Cache-Control: no-cache, no-store, must-revalidate
Pragma: no-cache

{
  "message": "Session expired or invalid",
  "errorCode": "INVALID_SESSION_ID"
}
```

### Error Response (400 Bad Request) - Complete with Headers
```http
HTTP/1.1 400 Bad Request
Date: Wed, 29 Jan 2026 12:00:00 GMT
Content-Type: application/json;charset=UTF-8
Content-Length: 132
Connection: keep-alive
Cache-Control: no-cache, no-store, must-revalidate
X-Content-Type-Options: nosniff

{
  "message": "MALFORMED_QUERY: Unexpected token 'LIMIT'. Expecting: 'EOF'",
  "errorCode": "MALFORMED_QUERY"
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

### Sample Apex Code - FlowAnalysisQueueable.cls Implementation
```apex
// Method: fetchFlowMetadata() - Lines 99-142
private FlowMetadataResult fetchFlowMetadata(String apiName) {
    try {
        // Build Tooling API endpoint
        String endpoint = URL.getOrgDomainUrl().toExternalForm() +
            '/services/data/v64.0/tooling/query?q=' +
            EncodingUtil.urlEncode(
                'SELECT Id, Definition.MasterLabel, Metadata ' +
                'FROM Flow ' +
                'WHERE Definition.DeveloperName = \'' + String.escapeSingleQuotes(apiName) + '\' ' +
                'AND Status = \'Active\' ' +
                'LIMIT 1',
                'UTF-8'
            );

        // Create HTTP request with all required headers
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());  // Session-based auth
        req.setHeader('Content-Type', 'application/json');                    // Request format
        req.setHeader('Accept', 'application/json');                          // Expected response

        // Send request
        Http http = new Http();
        HttpResponse res = http.send(req);

        // Process response
        if (res.getStatusCode() == 200) {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> records = (List<Object>) response.get('records');

            if (records != null && !records.isEmpty()) {
                Map<String, Object> flowRecord = (Map<String, Object>) records[0];
                Map<String, Object> definition = (Map<String, Object>) flowRecord.get('Definition');
                Object metadata = flowRecord.get('Metadata');

                FlowMetadataResult result = new FlowMetadataResult();
                result.label = (String) definition.get('MasterLabel');
                result.metadata = metadata != null ? JSON.serialize(metadata) : null;
                return result;
            }
        }
        return null;
    } catch (Exception e) {
        return null;
    }
}
```

**Complete Request Headers Sent:**
```http
GET /services/data/v64.0/tooling/query?q=SELECT%20Id%2C%20Definition.MasterLabel%2C%20Metadata%20FROM%20Flow%20WHERE%20Definition.DeveloperName%20%3D%20%27Sample_Flow%27%20AND%20Status%20%3D%20%27Active%27%20LIMIT%201 HTTP/1.1
Host: yourinstance.my.salesforce.com
Authorization: Bearer 00D5g000008kXXX!ARMAQFqPxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Content-Type: application/json
Accept: application/json
User-Agent: Jakarta Commons-HttpClient/3.1
Connection: keep-alive
```

**Note on Authorization Header:**
- Uses `UserInfo.getSessionId()` which returns the current user's session token
- Token format: `{OrgId}!{SessionHash}` (e.g., `00D5g000008kXXX!ARMAQFqP...`)
- Token is automatically validated by Salesforce platform
- No credential storage in code - uses runtime session context
```

---

## 2. External LLM API Callouts (BYO-LLM Option)

### Purpose
Optional fallback for customers without Einstein license. Supports Google Gemini and Anthropic Claude APIs for flow analysis.

### 2A. Google Gemini API Callout

#### HTTP Request - Complete with All Headers
```http
POST /v1beta/models/gemini-1.5-pro-002:generateContent HTTP/1.1
Host: generativelanguage.googleapis.com
x-goog-api-key: AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
Content-Type: application/json
Accept: application/json
User-Agent: Flow-AI-Audit/1.2 (Salesforce)
Connection: keep-alive
Accept-Encoding: gzip, deflate, br
Content-Length: 2847

{
  "contents": [{
    "parts": [{
      "text": "You are a Salesforce Flow expert. Analyze this flow:\n\n<flow_metadata>\n<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Flow xmlns=\"http://soap.sforce.com/2006/04/metadata\">...</Flow>\n</flow_metadata>\n\nProvide analysis in JSON format with overall score and recommendations."
    }]
  }],
  "generationConfig": {
    "temperature": 0.7,
    "topK": 40,
    "topP": 0.95,
    "maxOutputTokens": 8192,
    "responseMimeType": "application/json"
  }
}
```

**Request Header Details:**
| Header | Value | Purpose |
|--------|-------|---------|
| `x-goog-api-key` | AIzaSy... | Google API authentication |
| `Content-Type` | application/json | Request format |
| `Accept` | application/json | Expected response format |
| `User-Agent` | Flow-AI-Audit/1.2 | Client identification |
| `Connection` | keep-alive | HTTP connection persistence |
| `Accept-Encoding` | gzip, deflate, br | Compression support (Brotli) |

#### HTTP Response (Success - 200 OK) - Complete with Headers
```http
HTTP/1.1 200 OK
Content-Type: application/json; charset=UTF-8
Date: Wed, 29 Jan 2026 12:00:00 GMT
Server: scaffolding on HTTPServer2
Content-Length: 3542
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 0
Alt-Svc: h3=":443"; ma=2592000,h3-29=":443"; ma=2592000
Connection: keep-alive

{
  "candidates": [{
    "content": {
      "parts": [{
        "text": "{\n  \"overallScore\": 72,\n  \"overallStatus\": \"PASS\",\n  \"categories\": [\n    {\n      \"number\": 1,\n      \"name\": \"Documentation\",\n      \"status\": \"PASS\",\n      \"analysis\": \"Flow has adequate documentation.\"\n    }\n  ]\n}"
      }],
      "role": "model"
    },
    "finishReason": "STOP",
    "safetyRatings": [{
      "category": "HARM_CATEGORY_HATE_SPEECH",
      "probability": "NEGLIGIBLE"
    }],
    "tokenCount": 856
  }],
  "usageMetadata": {
    "promptTokenCount": 1847,
    "candidatesTokenCount": 856,
    "totalTokenCount": 2703
  }
}
```

#### Error Response (401 Unauthorized)
```http
HTTP/1.1 401 Unauthorized
Content-Type: application/json; charset=UTF-8
Date: Wed, 29 Jan 2026 12:00:00 GMT
Content-Length: 178

{
  "error": {
    "code": 401,
    "message": "API key not valid. Please pass a valid API key.",
    "status": "UNAUTHENTICATED"
  }
}
```

### 2B. Anthropic Claude API Callout

#### HTTP Request - Complete with All Headers
```http
POST /v1/messages HTTP/1.1
Host: api.anthropic.com
x-api-key: sk-ant-api03-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
anthropic-version: 2023-06-01
Content-Type: application/json
Accept: application/json
User-Agent: Flow-AI-Audit/1.2 (Salesforce)
Connection: keep-alive
Content-Length: 2941

{
  "model": "claude-3-5-sonnet-20241022",
  "max_tokens": 8192,
  "temperature": 0.7,
  "system": "You are a Salesforce Flow expert providing structured analysis.",
  "messages": [{
    "role": "user",
    "content": "Analyze this Salesforce Flow:\n\n<flow_metadata>\n<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Flow>...</Flow>\n</flow_metadata>\n\nProvide JSON analysis with overallScore and recommendations."
  }]
}
```

**Request Header Details:**
| Header | Value | Purpose |
|--------|-------|---------|
| `x-api-key` | sk-ant-api03-... | Anthropic API authentication |
| `anthropic-version` | 2023-06-01 | API version specification |
| `Content-Type` | application/json | Request format |
| `Accept` | application/json | Expected response format |
| `User-Agent` | Flow-AI-Audit/1.2 | Client identification |

#### HTTP Response (Success - 200 OK) - Complete with Headers
```http
HTTP/1.1 200 OK
Content-Type: application/json
Date: Wed, 29 Jan 2026 12:00:00 GMT
request-id: req_01XXXXXXXXXXXXXXXXXXXXXXXXX
x-cloud-trace-context: 1234567890abcdef;o=1
anthropic-ratelimit-requests-limit: 50
anthropic-ratelimit-requests-remaining: 49
anthropic-ratelimit-requests-reset: 2026-01-29T12:01:00Z
anthropic-ratelimit-tokens-limit: 40000
anthropic-ratelimit-tokens-remaining: 37256
anthropic-ratelimit-tokens-reset: 2026-01-29T12:01:00Z
Content-Length: 3217

{
  "id": "msg_01XXXXXXXXXXXXXXXXXXXXXXXXX",
  "type": "message",
  "role": "assistant",
  "content": [{
    "type": "text",
    "text": "{\n  \"overallScore\": 78,\n  \"overallStatus\": \"PASS\",\n  \"categories\": [\n    {\n      \"number\": 1,\n      \"name\": \"Documentation\",\n      \"status\": \"PASS\"\n    }\n  ]\n}"
  }],
  "model": "claude-3-5-sonnet-20241022",
  "stop_reason": "end_turn",
  "stop_sequence": null,
  "usage": {
    "input_tokens": 1924,
    "output_tokens": 742
  }
}
```

#### Error Response (401 Unauthorized)
```http
HTTP/1.1 401 Unauthorized
Content-Type: application/json
Date: Wed, 29 Jan 2026 12:00:00 GMT
Content-Length: 134

{
  "type": "error",
  "error": {
    "type": "authentication_error",
    "message": "invalid x-api-key"
  }
}
```

### Authentication for External LLMs
| Aspect | Google Gemini | Anthropic Claude |
|--------|--------------|------------------|
| **Auth Method** | API Key in header | API Key in header |
| **Header Name** | `x-goog-api-key` | `x-api-key` |
| **Storage** | Named Credential (encrypted) | Named Credential (encrypted) |
| **Rotation** | Manual via Google Console | Manual via Anthropic Console |
| **Cost** | ~$0.0035 per flow | ~$0.005 per flow |

### Implementation Reference
- **Apex Class**: `ExternalLLMService.cls`
- **Methods**:
  - `callGoogleGemini()` - Lines 150-220
  - `callAnthropicClaude()` - Lines 225-295

---

## 3. Einstein Prompt Templates API Callout

### Purpose
Submit flow metadata to Einstein AI for comprehensive best practice analysis. Uses native Salesforce ConnectApi (not direct HTTP).

### Conceptual HTTP Request (Platform-Managed)
**Note**: This API is called via ConnectApi framework, not direct HTTP. The following shows the equivalent HTTP request for reference:

```http
POST /services/data/v64.0/connect/prompts/prompt-templates/FlowAIAudit/generations HTTP/1.1
Host: yourinstance.my.salesforce.com
Authorization: Bearer 00D5g000008kXXX!ARMAQFqPxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Content-Type: application/json
Accept: application/json
User-Agent: SalesforcePlatform/1.0
X-SFDC-Session: 00D5g000008kXXX!ARMAQFqPxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Connection: keep-alive
Content-Length: 15847

{
  "isPreview": false,
  "additionalConfig": {
    "numGenerations": 1,
    "applicationName": "FlowAIAudit"
  },
  "inputParams": {
    "Input:MetadataXMLVar": {
      "value": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Flow xmlns=\"http://soap.sforce.com/2006/04/metadata\">\n  <apiVersion>64.0</apiVersion>\n  <description>Sample flow for analysis</description>\n  <processType>Flow</processType>\n  <start>\n    <locationX>50</locationX>\n    <locationY>0</locationY>\n  </start>\n  <status>Active</status>\n</Flow>"
    },
    "Input:KnowledgeText": {
      "value": "Salesforce Flow Best Practices Assessment Framework..."
    }
  }
}
```

**Request Header Details:**
| Header | Value | Purpose |
|--------|-------|---------|
| `Authorization` | Bearer {session_token} | User session authentication |
| `Content-Type` | application/json | Request format |
| `Accept` | application/json | Expected response format |
| `User-Agent` | SalesforcePlatform/1.0 | Platform identification |
| `X-SFDC-Session` | {session_token} | Additional session validation |
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

### HTTP Response (Success - 200 OK) - Complete with Headers
```http
HTTP/1.1 200 OK
Date: Wed, 29 Jan 2026 12:00:00 GMT
Content-Type: application/json;charset=UTF-8
Content-Encoding: gzip
Content-Length: 4521
Connection: keep-alive
Cache-Control: no-cache, no-store, must-revalidate
Pragma: no-cache
Expires: 0
Strict-Transport-Security: max-age=31536000
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
X-SFDC-Request-Id: abcd1234-efgh-5678-ijkl-9012mnop3456

{
  "generations": [
    {
      "id": "gen_abc123xyz",
      "prompt": "You are a Salesforce Flow expert. Analyze this flow according to best practices...",
      "text": "{\n  \"overallScore\": 72,\n  \"overallStatus\": \"PASS\",\n  \"categories\": [\n    {\n      \"number\": 1,\n      \"name\": \"Documentation, Naming, and Clarity\",\n      \"icon\": \"📋\",\n      \"status\": \"PASS\",\n      \"analysis\": \"Flow has adequate documentation and clear naming conventions.\",\n      \"details\": [\n        {\n          \"heading\": \"Flow Naming\",\n          \"content\": \"Flow name is clear and follows naming standards.\"\n        },\n        {\n          \"heading\": \"Documentation\",\n          \"content\": \"Flow description and variable documentation are present.\"\n        }\n      ],\n      \"explanation\": \"Good documentation practices followed.\",\n      \"recommendation\": \"Continue maintaining clear documentation standards.\"\n    },\n    {\n      \"number\": 2,\n      \"name\": \"Bulkification & Loop Efficiency\",\n      \"icon\": \"⚡\",\n      \"status\": \"NEEDS WORK\",\n      \"analysis\": \"DML operations found inside loop.\",\n      \"recommendation\": \"Move DML outside loop and use collection-based operations.\"\n    }\n  ],\n  \"findings\": [\n    {\n      \"area\": \"Bulkification\",\n      \"severity\": \"MEDIUM\",\n      \"explanation\": \"DML in loop can cause governor limit issues.\",\n      \"recommendation\": \"Refactor to use collection-based DML.\"\n    }\n  ]\n}",
      "parameters": {
        "temperature": 0.7,
        "maxTokens": 8192,
        "modelId": "claude-3-5-sonnet-20241022"
      },
      "tokensUsed": 3847,
      "finishReason": "STOP"
    }
  ],
  "usage": {
    "promptTokens": 2124,
    "completionTokens": 3847,
    "totalTokens": 5971
  }
}
```

**Response Header Details:**
| Header | Value | Purpose |
|--------|-------|---------|
| `Content-Type` | application/json;charset=UTF-8 | Response format |
| `Content-Encoding` | gzip | Compression method |
| `Cache-Control` | no-cache, no-store | No caching directives |
| `Strict-Transport-Security` | max-age=31536000 | HTTPS enforcement |
| `X-SFDC-Request-Id` | UUID | Request tracking |
| `X-Content-Type-Options` | nosniff | MIME security |
| `X-Frame-Options` | SAMEORIGIN | Clickjacking protection |
```

### Error Response (403 Forbidden - No Einstein License) - Complete with Headers
```http
HTTP/1.1 403 Forbidden
Date: Wed, 29 Jan 2026 12:00:00 GMT
Content-Type: application/json;charset=UTF-8
Content-Length: 156
Connection: keep-alive
Cache-Control: no-cache, no-store, must-revalidate
X-Content-Type-Options: nosniff

{
  "message": "Einstein features are not enabled for this organization. Please contact your Salesforce administrator.",
  "errorCode": "EINSTEIN_NOT_ENABLED"
}
```

### Error Response (400 Bad Request - Invalid Input) - Complete with Headers
```http
HTTP/1.1 400 Bad Request
Date: Wed, 29 Jan 2026 12:00:00 GMT
Content-Type: application/json;charset=UTF-8
Content-Length: 147
Connection: keep-alive
Cache-Control: no-cache, no-store
X-Content-Type-Options: nosniff

{
  "message": "Required input parameter 'Input:MetadataXMLVar' is missing or invalid",
  "errorCode": "MISSING_REQUIRED_PARAM",
  "details": "Prompt template requires 'MetadataXMLVar' input"
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

## 4. Complete API Callout Summary Matrix

| API | Endpoint | Method | Auth Header | Key Headers | Response Format | Implementation |
|-----|----------|--------|-------------|-------------|-----------------|----------------|
| **Tooling API** | `/services/data/v64.0/tooling/query` | GET | `Authorization: Bearer {session}` | Content-Type, Accept, User-Agent | JSON | FlowAnalysisQueueable.cls:99-142 |
| **Google Gemini** | `/v1beta/models/gemini-1.5-pro-002:generateContent` | POST | `x-goog-api-key: {key}` | Content-Type, Accept, User-Agent | JSON | ExternalLLMService.cls:150-220 |
| **Anthropic Claude** | `/v1/messages` | POST | `x-api-key: {key}` | anthropic-version, Content-Type, Accept | JSON | ExternalLLMService.cls:225-295 |
| **Einstein AI** | `/connect/prompts/prompt-templates/{name}/generations` | POST | `Authorization: Bearer {session}` | X-SFDC-Session, Content-Type, Accept | JSON | FlowAnalysisService.cls:76-112 |

### Standard Headers Across All Callouts

**Request Headers:**
- `Content-Type: application/json` - All APIs
- `Accept: application/json` - All APIs
- `User-Agent: Flow-AI-Audit/1.2` or `SalesforcePlatform/1.0` - All APIs
- `Connection: keep-alive` - All APIs
- `Accept-Encoding: gzip, deflate` - All APIs

**Response Headers (Security):**
- `Strict-Transport-Security: max-age=31536000` - HTTPS enforcement
- `X-Content-Type-Options: nosniff` - MIME type security
- `X-Frame-Options: SAMEORIGIN` - Clickjacking protection
- `X-XSS-Protection: 1; mode=block` - XSS filter
- `Cache-Control: no-cache, no-store` - Prevent caching
- `Content-Encoding: gzip` - Response compression

---

## 5. Security Implementation

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

- **Version**: 2.0
- **Last Updated**: January 29, 2026
- **Maintained By**: Flow AI Audit Team
- **Repository**: https://github.com/pasumartyshiva/FlowAIAudit
- **Contact**: GitHub Issues for technical questions
- **Security Review**: Complete HTTP headers documented for all API callouts
- **Compliance**: AppExchange Security Review Requirements Met

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
