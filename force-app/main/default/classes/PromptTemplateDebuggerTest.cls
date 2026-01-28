@IsTest
private class PromptTemplateDebuggerTest {

    // =========================================================================
    // MOCK CLASSES
    // =========================================================================

    /**
     * Mock 1: Simulates a successful JSON response
     */
    public class MockSuccessWithJson extends PromptTemplateDebugger {
        protected override ConnectApi.EinsteinPromptTemplateGenerationsRepresentation executeApiCall(
            String templateName, 
            ConnectApi.EinsteinPromptTemplateGenerationsInput input
        ) {
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation mockResponse = 
                new ConnectApi.EinsteinPromptTemplateGenerationsRepresentation();
            
            ConnectApi.EinsteinLlmGenerationItemOutput generation = 
                new ConnectApi.EinsteinLlmGenerationItemOutput();
            
            generation.text = '{"summary": "Flow looks good", "status": "Active", "score": 95}';
            
            mockResponse.generations = new List<ConnectApi.EinsteinLlmGenerationItemOutput>{ generation };
            return mockResponse;
        }
    }

    /**
     * Mock 2: Simulates a successful Plain Text response (Non-JSON)
     */
    public class MockSuccessWithText extends PromptTemplateDebugger {
        protected override ConnectApi.EinsteinPromptTemplateGenerationsRepresentation executeApiCall(
            String templateName, 
            ConnectApi.EinsteinPromptTemplateGenerationsInput input
        ) {
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation mockResponse = 
                new ConnectApi.EinsteinPromptTemplateGenerationsRepresentation();
            
            ConnectApi.EinsteinLlmGenerationItemOutput generation = 
                new ConnectApi.EinsteinLlmGenerationItemOutput();
            
            generation.text = 'This is just a plain text response.';
            
            mockResponse.generations = new List<ConnectApi.EinsteinLlmGenerationItemOutput>{ generation };
            return mockResponse;
        }
    }

    /**
     * Mock 3: Simulates ConnectApi Failure
     * FIX: Uses JSON.deserialize because ConnectApiException has no public constructor
     */
    public class MockConnectError extends PromptTemplateDebugger {
        protected override ConnectApi.EinsteinPromptTemplateGenerationsRepresentation executeApiCall(
            String t, ConnectApi.EinsteinPromptTemplateGenerationsInput i
        ) {
            String jsonException = '{"message": "Prompt Template not found or not published"}';
            ConnectApi.ConnectApiException ex = (ConnectApi.ConnectApiException)JSON.deserialize(
                jsonException, 
                ConnectApi.ConnectApiException.class
            );
            throw ex;
        }
    }

    /**
     * Mock 4: Simulates Callout Failure
     */
    public class MockCalloutError extends PromptTemplateDebugger {
        protected override ConnectApi.EinsteinPromptTemplateGenerationsRepresentation executeApiCall(
            String t, ConnectApi.EinsteinPromptTemplateGenerationsInput i
        ) {
            // CalloutException has a visible constructor, so this is fine
            throw new System.CalloutException('Read timed out');
        }
    }

    /**
     * Mock 5: Simulates General Failure
     */
    public class MockGeneralError extends PromptTemplateDebugger {
        protected override ConnectApi.EinsteinPromptTemplateGenerationsRepresentation executeApiCall(
            String t, ConnectApi.EinsteinPromptTemplateGenerationsInput i
        ) {
            // MathException has a visible constructor
            throw new System.MathException('Unexpected math error');
        }
    }

    // =========================================================================
    // TEST METHODS
    // =========================================================================

    @IsTest
    static void testSuccessPathWithJson() {
        Test.startTest();
        PromptTemplateDebugger debugger = new MockSuccessWithJson();
        debugger.enableVerboseLogging(true);
        debugger.testPromptTemplate('Test_Template', '<Flow></Flow>', 'Some Knowledge');
        Test.stopTest();

        List<String> logs = debugger.getDebugMessages();
        Boolean foundSuccess = false;
        Boolean foundJson = false;

        for (String log : logs) {
            if (log.contains('SUCCESS!')) foundSuccess = true;
            if (log.contains('Valid JSON structure')) foundJson = true;
        }

        System.assert(foundSuccess, 'Should log success on valid API return');
        System.assert(foundJson, 'Should validate JSON correctly');
    }

    @IsTest
    static void testSuccessPathWithPlainText() {
        Test.startTest();
        PromptTemplateDebugger debugger = new MockSuccessWithText();
        debugger.enableVerboseLogging(true);
        debugger.testPromptTemplate('Test_Template', '<Flow></Flow>', null);
        Test.stopTest();

        List<String> logs = debugger.getDebugMessages();
        Boolean foundInvalidJson = false;

        for (String log : logs) {
            if (log.contains('NOT valid JSON')) foundInvalidJson = true;
        }

        System.assert(foundInvalidJson, 'Should gracefully handle non-JSON text');
    }

    
    @IsTest
    static void testCalloutException() {
        Test.startTest();
        PromptTemplateDebugger debugger = new MockCalloutError();
        debugger.enableVerboseLogging(true);
        debugger.testPromptTemplate('Test_Template', '<Flow></Flow>', null);
        Test.stopTest();

        List<String> logs = debugger.getDebugMessages();
        Boolean foundError = false;

        for (String log : logs) {
            if (log.contains('CALLOUT EXCEPTION')) foundError = true;
        }

        System.assert(foundError, 'Should catch CalloutException');
    }

    @IsTest
    static void testGeneralException() {
        Test.startTest();
        PromptTemplateDebugger debugger = new MockGeneralError();
        debugger.enableVerboseLogging(true);
        debugger.testPromptTemplate('Test_Template', '<Flow></Flow>', null);
        Test.stopTest();

        List<String> logs = debugger.getDebugMessages();
        Boolean foundError = false;

        for (String log : logs) {
            if (log.contains('EXCEPTION OCCURRED')) foundError = true;
        }

        System.assert(foundError, 'Should catch General Exception');
    }

    @IsTest
    static void testStaticEntryPoints() {
        Test.startTest();
        try { PromptTemplateDebugger.testTemplate('Flow_Evaluator_V3', '<xml>'); } catch(Exception e) {}
        try { PromptTemplateDebugger.testTemplate('Flow_Evaluator_V3', '<xml>', 'knowledge'); } catch(Exception e) {}
        try { PromptTemplateDebugger.testFlowEvaluatorV3(); } catch(Exception e) {}
        PromptTemplateDebugger.listAvailableTemplates();
        Test.stopTest();
    }
}