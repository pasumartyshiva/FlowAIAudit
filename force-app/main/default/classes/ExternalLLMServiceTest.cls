/**
 * @description Test class for ExternalLLMService with comprehensive coverage
 */
@isTest
private class ExternalLLMServiceTest {

    /**
     * @description Mock HTTP callout for testing
     */
    private class MockHttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        public MockHttpResponse(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    /**
     * @description Creates a mock LLM configuration for testing
     */
    private static LLM_Configuration__mdt createMockConfig(String provider) {
        LLM_Configuration__mdt config = new LLM_Configuration__mdt();
        config.Provider_Name__c = provider;
        config.API_Endpoint__c = 'https://api.example.com/v1/test';
        config.Model_Name__c = 'test-model';
        config.API_Key__c = 'test-api-key-12345';
        config.Max_Tokens__c = 8000;
        config.Temperature__c = 0.1;
        config.System_Prompt__c = 'You are a helpful assistant.';
        return config;
    }

    @isTest
    static void testIsConfigured_NoActiveConfig() {
        Test.startTest();
        Boolean result = ExternalLLMService.isConfigured();
        Test.stopTest();
        System.assertEquals(false, result, 'Should return false when no active configuration exists');
    }

    @isTest
    static void testBuildPrompt() {
        String flowXml = '<Flow><description>Test Flow</description></Flow>';
        String framework = '1. Check error handling\n2. Check bulkification';
        
        Test.startTest();
        String result = ExternalLLMService.buildPrompt(flowXml, framework);
        Test.stopTest();
        
        System.assert(result.contains('Salesforce Flow expert'), 'Prompt should contain expert context');
        System.assert(result.contains('ASSESSMENT FRAMEWORK'), 'Prompt should contain framework section');
        System.assert(result.contains('FLOW METADATA XML'), 'Prompt should contain metadata section');
        System.assert(result.contains(flowXml), 'Prompt should contain the flow XML');
        System.assert(result.contains(framework), 'Prompt should contain the framework');
    }

    @isTest
    static void testCallGoogleGemini_Success() {
        String mockResponse = '{"candidates":[{"content":{"parts":[{"text":"{\\"status\\":\\"Pass\\",\\"score\\":85}"}]}}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        LLM_Configuration__mdt config = createMockConfig('Google');
        
        Test.startTest();
        String result = ExternalLLMService.callGoogleGemini('Test prompt', config);
        Test.stopTest();
        
        System.assert(result.contains('Pass'), 'Should return parsed response text');
    }

    @isTest
    static void testCallGoogleGemini_APIError() {
        String mockResponse = '{"error":"Unauthorized"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(401, mockResponse));
        
        LLM_Configuration__mdt config = createMockConfig('Google');
        
        Test.startTest();
        try {
            ExternalLLMService.callGoogleGemini('Test prompt', config);
            System.assert(false, 'Should have thrown exception');
        } catch (ExternalLLMService.ExternalLLMException e) {
            System.assert(e.getMessage().contains('Google Gemini API error'), 'Should contain API error message');
        }
        Test.stopTest();
    }

    @isTest
    static void testCallGoogleGemini_EmptyCandidates() {
        String mockResponse = '{"candidates":[]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        LLM_Configuration__mdt config = createMockConfig('Google');
        
        Test.startTest();
        try {
            ExternalLLMService.callGoogleGemini('Test prompt', config);
            System.assert(false, 'Should have thrown exception');
        } catch (ExternalLLMService.ExternalLLMException e) {
            System.assert(e.getMessage().contains('No candidates'), 'Should indicate no candidates');
        }
        Test.stopTest();
    }

    @isTest
    static void testCallGoogleGemini_MissingApiKey() {
        LLM_Configuration__mdt config = createMockConfig('Google');
        config.API_Key__c = null;
        
        Test.startTest();
        try {
            ExternalLLMService.callGoogleGemini('Test prompt', config);
            System.assert(false, 'Should have thrown exception');
        } catch (ExternalLLMService.ExternalLLMException e) {
            System.assert(e.getMessage().contains('API Key is not configured'), 'Should indicate missing API key');
        }
        Test.stopTest();
    }

    @isTest
    static void testCallAnthropicClaude_Success() {
        String mockResponse = '{"content":[{"text":"{\\"status\\":\\"Pass\\",\\"score\\":90}"}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        LLM_Configuration__mdt config = createMockConfig('Anthropic');
        
        Test.startTest();
        String result = ExternalLLMService.callAnthropicClaude('Test prompt', config);
        Test.stopTest();
        
        System.assert(result.contains('Pass'), 'Should return parsed response text');
    }

    @isTest
    static void testCallAnthropicClaude_WithSystemPrompt() {
        String mockResponse = '{"content":[{"text":"{\\"status\\":\\"Pass\\"}"}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        LLM_Configuration__mdt config = createMockConfig('Anthropic');
        config.System_Prompt__c = 'You are an expert Salesforce architect.';
        
        Test.startTest();
        String result = ExternalLLMService.callAnthropicClaude('Test prompt', config);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return response');
    }

    @isTest
    static void testCallAnthropicClaude_APIError() {
        String mockResponse = '{"error":"Rate limit exceeded"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(429, mockResponse));
        
        LLM_Configuration__mdt config = createMockConfig('Anthropic');
        
        Test.startTest();
        try {
            ExternalLLMService.callAnthropicClaude('Test prompt', config);
            System.assert(false, 'Should have thrown exception');
        } catch (ExternalLLMService.ExternalLLMException e) {
            System.assert(e.getMessage().contains('Anthropic Claude API error'), 'Should contain API error');
        }
        Test.stopTest();
    }

    @isTest
    static void testCallAnthropicClaude_EmptyContent() {
        String mockResponse = '{"content":[]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        LLM_Configuration__mdt config = createMockConfig('Anthropic');
        
        Test.startTest();
        try {
            ExternalLLMService.callAnthropicClaude('Test prompt', config);
            System.assert(false, 'Should have thrown exception');
        } catch (ExternalLLMService.ExternalLLMException e) {
            System.assert(e.getMessage().contains('No content'), 'Should indicate no content');
        }
        Test.stopTest();
    }

    @isTest
    static void testCallAnthropicClaude_MissingApiKey() {
        LLM_Configuration__mdt config = createMockConfig('Anthropic');
        config.API_Key__c = '';
        
        Test.startTest();
        try {
            ExternalLLMService.callAnthropicClaude('Test prompt', config);
            System.assert(false, 'Should have thrown exception');
        } catch (ExternalLLMService.ExternalLLMException e) {
            System.assert(e.getMessage().contains('API Key is not configured'), 'Should indicate missing key');
        }
        Test.stopTest();
    }

    @isTest
    static void testCallOpenAI_NotImplemented() {
        LLM_Configuration__mdt config = createMockConfig('OpenAI');
        
        Test.startTest();
        try {
            ExternalLLMService.callOpenAI('Test prompt', config);
            System.assert(false, 'Should have thrown exception');
        } catch (ExternalLLMService.ExternalLLMException e) {
            System.assert(e.getMessage().contains('not yet implemented'), 'Should indicate not implemented');
        }
        Test.stopTest();
    }

    @isTest
    static void testCallHuggingFace_Success() {
        String mockResponse = '{"output":[{"content":[{"text":"{\\"status\\":\\"Pass\\",\\"score\\":75}"}]}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        LLM_Configuration__mdt config = createMockConfig('HuggingFace');
        
        Test.startTest();
        String result = ExternalLLMService.callHuggingFace('Test prompt', config);
        Test.stopTest();
        
        System.assert(result.contains('Pass'), 'Should return parsed response');
    }

    @isTest
    static void testCallHuggingFace_WithMarkdownCodeBlock() {
        String mockResponse = '{"output":[{"content":[{"text":"```json\\n{\\"status\\":\\"Pass\\"}\\n```"}]}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        LLM_Configuration__mdt config = createMockConfig('HuggingFace');
        
        Test.startTest();
        String result = ExternalLLMService.callHuggingFace('Test prompt', config);
        Test.stopTest();
        
        System.assert(!result.contains('```'), 'Should strip markdown code blocks');
    }

    @isTest
    static void testCallHuggingFace_APIError() {
        String mockResponse = '{"error":"Model not found"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(404, mockResponse));
        
        LLM_Configuration__mdt config = createMockConfig('HuggingFace');
        
        Test.startTest();
        try {
            ExternalLLMService.callHuggingFace('Test prompt', config);
            System.assert(false, 'Should have thrown exception');
        } catch (ExternalLLMService.ExternalLLMException e) {
            System.assert(e.getMessage().contains('Hugging Face API error'), 'Should contain API error');
        }
        Test.stopTest();
    }

    @isTest
    static void testCallHuggingFace_EmptyOutput() {
        String mockResponse = '{"output":[]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        LLM_Configuration__mdt config = createMockConfig('HuggingFace');
        
        Test.startTest();
        try {
            ExternalLLMService.callHuggingFace('Test prompt', config);
            System.assert(false, 'Should have thrown exception');
        } catch (ExternalLLMService.ExternalLLMException e) {
            System.assert(e.getMessage().contains('Empty output'), 'Should indicate empty output');
        }
        Test.stopTest();
    }

    @isTest
    static void testCallHuggingFace_EmptyContent() {
        String mockResponse = '{"output":[{"content":[]}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        LLM_Configuration__mdt config = createMockConfig('HuggingFace');
        
        Test.startTest();
        try {
            ExternalLLMService.callHuggingFace('Test prompt', config);
            System.assert(false, 'Should have thrown exception');
        } catch (ExternalLLMService.ExternalLLMException e) {
            System.assert(e.getMessage().contains('Empty content'), 'Should indicate empty content');
        }
        Test.stopTest();
    }

    @isTest
    static void testCallHuggingFace_EmptyText() {
        String mockResponse = '{"output":[{"content":[{"text":""}]}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        LLM_Configuration__mdt config = createMockConfig('HuggingFace');
        
        Test.startTest();
        try {
            ExternalLLMService.callHuggingFace('Test prompt', config);
            System.assert(false, 'Should have thrown exception');
        } catch (ExternalLLMService.ExternalLLMException e) {
            System.assert(e.getMessage().contains('Empty text'), 'Should indicate empty text');
        }
        Test.stopTest();
    }

    @isTest
    static void testCallHuggingFace_MissingApiKey() {
        LLM_Configuration__mdt config = createMockConfig('HuggingFace');
        config.API_Key__c = null;
        
        Test.startTest();
        try {
            ExternalLLMService.callHuggingFace('Test prompt', config);
            System.assert(false, 'Should have thrown exception');
        } catch (ExternalLLMService.ExternalLLMException e) {
            System.assert(e.getMessage().contains('API Key is not configured'), 'Should indicate missing key');
        }
        Test.stopTest();
    }

    @isTest
    static void testCallHuggingFace_WithSystemPrompt() {
        String mockResponse = '{"output":[{"content":[{"text":"{\\"status\\":\\"Pass\\"}"}]}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        LLM_Configuration__mdt config = createMockConfig('HuggingFace');
        config.System_Prompt__c = 'Be concise.';
        
        Test.startTest();
        String result = ExternalLLMService.callHuggingFace('Test prompt', config);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return response with system prompt');
    }

    @isTest
    static void testCallGoogleGemini_WithDefaultTokens() {
        String mockResponse = '{"candidates":[{"content":{"parts":[{"text":"Test"}]}}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        LLM_Configuration__mdt config = createMockConfig('Google');
        config.Max_Tokens__c = null;
        config.Temperature__c = null;
        
        Test.startTest();
        String result = ExternalLLMService.callGoogleGemini('Test prompt', config);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should use defaults when null');
    }

    @isTest
    static void testCallAnthropicClaude_WithDefaultTokens() {
        String mockResponse = '{"content":[{"text":"Test"}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        LLM_Configuration__mdt config = createMockConfig('Anthropic');
        config.Max_Tokens__c = null;
        config.Temperature__c = null;
        config.System_Prompt__c = null;
        
        Test.startTest();
        String result = ExternalLLMService.callAnthropicClaude('Test prompt', config);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should use defaults when null');
    }

    @isTest
    static void testGenerateCompletion_NoConfig() {
        Test.startTest();
        try {
            ExternalLLMService.generateCompletion('<Flow/>', 'Framework');
            System.assert(false, 'Should have thrown exception');
        } catch (ExternalLLMService.ExternalLLMException e) {
            System.assert(e.getMessage().contains('No active LLM configuration'), 'Should indicate no config');
        }
        Test.stopTest();
    }

    @isTest
    static void testCallHuggingFace_NullResponse() {
        String mockResponse = 'null';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        LLM_Configuration__mdt config = createMockConfig('HuggingFace');
        
        Test.startTest();
        try {
            ExternalLLMService.callHuggingFace('Test prompt', config);
            System.assert(false, 'Should have thrown exception');
        } catch (ExternalLLMService.ExternalLLMException e) {
            System.assert(e.getMessage().contains('No response'), 'Should indicate no response');
        }
        Test.stopTest();
    }

    @isTest
    static void testCallHuggingFace_StripPlainCodeBlock() {
        String mockResponse = '{"output":[{"content":[{"text":"```\\n{\\"status\\":\\"Pass\\"}\\n```"}]}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponse));
        
        LLM_Configuration__mdt config = createMockConfig('HuggingFace');
        
        Test.startTest();
        String result = ExternalLLMService.callHuggingFace('Test prompt', config);
        Test.stopTest();
        
        System.assert(!result.startsWith('```'), 'Should strip plain code blocks');
    }
}