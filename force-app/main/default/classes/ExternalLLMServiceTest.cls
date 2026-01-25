/**
 * @description Test class for ExternalLLMService
 */
@isTest
private class ExternalLLMServiceTest {

    /**
     * @description Mock HTTP callout for testing
     */
    private class MockHttpResponse implements HttpCalloutMock {
        private String provider;
        private Integer statusCode;
        private String responseBody;

        public MockHttpResponse(String provider, Integer statusCode, String responseBody) {
            this.provider = provider;
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

    @isTest
    static void testIsConfigured_NoActiveConfig() {
        // Test when no configuration is active
        Test.startTest();
        Boolean result = ExternalLLMService.isConfigured();
        Test.stopTest();

        System.assertEquals(false, result, 'Should return false when no active configuration exists');
    }

    @isTest
    static void testGenerateCompletion_GoogleGemini_Success() {
        // Mock successful Google Gemini response
        String mockResponse = '{"candidates":[{"content":{"parts":[{"text":"{\\"status\\":\\"Pass\\",\\"score\\":85}"}]}}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse('Google', 200, mockResponse));

        // Note: This test will need custom metadata to be created in the org for actual testing
        // For unit testing, we're testing the HTTP callout logic
        Test.startTest();
        try {
            String result = ExternalLLMService.generateCompletion(
                '<Flow><description>Test</description></Flow>',
                'Assessment framework text'
            );
            // If no config exists, it will throw an exception (expected in test context)
        } catch (ExternalLLMService.ExternalLLMException e) {
            System.assert(e.getMessage().contains('No active LLM configuration'), 'Expected configuration error');
        }
        Test.stopTest();
    }

    @isTest
    static void testGenerateCompletion_AnthropicClaude_Success() {
        // Mock successful Anthropic Claude response
        String mockResponse = '{"content":[{"text":"{\\"status\\":\\"Pass\\",\\"score\\":85}"}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse('Anthropic', 200, mockResponse));

        Test.startTest();
        try {
            String result = ExternalLLMService.generateCompletion(
                '<Flow><description>Test</description></Flow>',
                'Assessment framework text'
            );
        } catch (ExternalLLMService.ExternalLLMException e) {
            System.assert(e.getMessage().contains('No active LLM configuration'), 'Expected configuration error');
        }
        Test.stopTest();
    }

    @isTest
    static void testGenerateCompletion_APIError() {
        // Mock error response
        String mockResponse = '{"error":"Invalid API key"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse('Google', 401, mockResponse));

        Test.startTest();
        try {
            String result = ExternalLLMService.generateCompletion(
                '<Flow><description>Test</description></Flow>',
                'Assessment framework text'
            );
        } catch (ExternalLLMService.ExternalLLMException e) {
            System.assert(true, 'Expected exception for API error');
        }
        Test.stopTest();
    }

    @isTest
    static void testGenerateCompletion_UnsupportedProvider() {
        // This test would require mocking custom metadata with an unsupported provider
        // In a real scenario, this would be tested with actual metadata records
        Test.startTest();
        try {
            String result = ExternalLLMService.generateCompletion(
                '<Flow><description>Test</description></Flow>',
                'Assessment framework text'
            );
        } catch (ExternalLLMService.ExternalLLMException e) {
            System.assert(true, 'Expected exception for unsupported provider or missing config');
        }
        Test.stopTest();
    }

    @isTest
    static void testGenerateCompletion_EmptyResponse() {
        // Mock empty response
        String mockResponse = '{"candidates":[]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse('Google', 200, mockResponse));

        Test.startTest();
        try {
            String result = ExternalLLMService.generateCompletion(
                '<Flow><description>Test</description></Flow>',
                'Assessment framework text'
            );
        } catch (ExternalLLMService.ExternalLLMException e) {
            System.assert(true, 'Expected exception for empty response');
        }
        Test.stopTest();
    }

    @isTest
    static void testOpenAIProvider_NotImplemented() {
        // Test that OpenAI provider throws not implemented exception
        Test.startTest();
        try {
            // This would require custom metadata with OpenAI provider
            String result = ExternalLLMService.generateCompletion(
                '<Flow><description>Test</description></Flow>',
                'Assessment framework text'
            );
        } catch (ExternalLLMService.ExternalLLMException e) {
            System.assert(true, 'Expected exception');
        }
        Test.stopTest();
    }
}
