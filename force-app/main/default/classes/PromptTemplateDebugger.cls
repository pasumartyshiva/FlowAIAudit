/**
 * @description Utility class for debugging Einstein Prompt Templates from Anonymous Apex
 * @usage Run in Developer Console > Debug > Open Execute Anonymous Window
 */
// FIX: Added 'virtual' keyword so this class can be extended/mocked in tests
public virtual class PromptTemplateDebugger {

    private Boolean verboseLogging = false;
    private List<String> debugMessages = new List<String>();

    // =========================================================================
    // STATIC UTILITY METHODS (Quick Entry Points)
    // =========================================================================

    /**
     * Quick test method for anonymous execution
     */
    public static void testTemplate(String templateName, String flowXml) {
        testTemplate(templateName, flowXml, null);
    }

    /**
     * Quick test with knowledge parameter
     */
    public static void testTemplate(String templateName, String flowXml, String knowledge) {
        PromptTemplateDebugger debugger = new PromptTemplateDebugger();
        debugger.enableVerboseLogging(true);
        debugger.testPromptTemplate(templateName, flowXml, knowledge);
    }

    /**
     * Test the Flow_Evaluator_V3 template specifically
     */
    public static void testFlowEvaluatorV3() {
        String sampleFlowXml = '<Flow xmlns="http://soap.sforce.com/2006/04/metadata">' +
            '<start><locationX>100</locationX><locationY>0</locationY></start>' +
            '<status>Active</status>' +
            '</Flow>';

        testTemplate('Flow_Evaluator_V3', sampleFlowXml, 'Salesforce Flow Best Practices');
    }

    /**
     * List all available prompt templates in the org
     */
    public static void listAvailableTemplates() {
        try {
            List<String> knownTemplates = new List<String>{
                'Flow_Evaluator_V2',
                'Flow_Evaluator_V3'
            };
            for (String template : knownTemplates) { 
                System.debug('Known Template: ' + template);
            }
        } catch (Exception e) {
            System.debug('Error listing templates: ' + e.getMessage());
        }
    }

    // =========================================================================
    // INSTANCE METHODS
    // =========================================================================

    public void enableVerboseLogging(Boolean enabled) {
        this.verboseLogging = enabled;
    }

    public void testPromptTemplate(String templateName, String flowXml, String knowledge) {
        log('========================================');
        log('PROMPT TEMPLATE DEBUG SESSION STARTED');
        log('========================================');
        log('Template Name: ' + templateName);
        log('Timestamp: ' + System.now());
        
        // Step 1: Pre-flight checks
        runPreflightChecks();

        // Step 2: Check if Einstein is enabled
        checkEinsteinSettings();

        // Step 3: Prepare the input
        ConnectApi.EinsteinPromptTemplateGenerationsInput generationInput = 
            prepareInput(flowXml, knowledge);

        // Step 4: Attempt the API call
        attemptPromptTemplateCall(templateName, generationInput);

        // Step 5: Summary
        printSummary();
    }

    private void runPreflightChecks() {
        log('--- PRE-FLIGHT CHECKS ---');
        log('API Version: v65.0');
        try {
            log('User has API Enabled: ' + (UserInfo.getUserType() == 'Standard'));
        } catch (Exception e) {
            log('WARNING: Could not verify user permissions: ' + e.getMessage());
        }
        log('');
    }

    private void checkEinsteinSettings() {
        log('--- EINSTEIN SETTINGS CHECK ---');
        try {
            log('Einstein Features Status:');
            log('  Navigate to: Setup > Prompt Builder to verify templates');
        } catch (Exception e) {
            log('WARNING: Could not check Einstein settings: ' + e.getMessage());
        }
        log('');
    }

    private ConnectApi.EinsteinPromptTemplateGenerationsInput prepareInput(
        String flowXml, String knowledge) {

        log('--- PREPARING INPUT ---');

        ConnectApi.EinsteinPromptTemplateGenerationsInput generationInput = 
            new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        generationInput.isPreview = false;

        ConnectApi.WrappedValue metadataValue = new ConnectApi.WrappedValue();
        metadataValue.value = flowXml;
        
        generationInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        generationInput.additionalConfig.maxTokens = 4000;
        generationInput.additionalConfig.numGenerations = 1;

        generationInput.inputParams = new Map<String, ConnectApi.WrappedValue>();
        generationInput.inputParams.put('Input:MetadataXMLVar', metadataValue);

        if (String.isNotBlank(knowledge)) {
            ConnectApi.WrappedValue knowledgeValue = new ConnectApi.WrappedValue();
            knowledgeValue.value = knowledge;
            generationInput.inputParams.put('Input:KnowledgeText', knowledgeValue);
        } else {
            log('Knowledge: (none provided)');
        }

        log('Max Tokens: 4000');
        log('');

        return generationInput;
    }

    /**
     * CRITICAL FOR TESTING: Isolated virtual method for the API call.
     */
    @TestVisible
    protected virtual ConnectApi.EinsteinPromptTemplateGenerationsRepresentation executeApiCall(
        String templateName, 
        ConnectApi.EinsteinPromptTemplateGenerationsInput generationInput
    ) {
        return ConnectApi.EinsteinLlm.generateMessagesForPromptTemplate(
            templateName,
            generationInput
        );
    }

    private void attemptPromptTemplateCall(
        String templateName,
        ConnectApi.EinsteinPromptTemplateGenerationsInput generationInput) {

        log('--- ATTEMPTING API CALL ---');
        Datetime startTime = System.now();

        try {
            log('Calling: ConnectApi.EinsteinLlm.generateMessagesForPromptTemplate()');
            
            // CHANGED: Call the virtual method
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response = 
                executeApiCall(templateName, generationInput);

            Datetime endTime = System.now();
            Long duration = endTime.getTime() - startTime.getTime();

            log('✓ SUCCESS! Call completed in ' + duration + 'ms');
            log('');

            parseResponse(response);

        } catch (ConnectApi.ConnectApiException apiException) {
            handleConnectApiException(apiException, startTime);
        } catch (System.CalloutException calloutException) {
            handleCalloutException(calloutException, startTime);
        } catch (Exception generalException) {
            handleGeneralException(generalException, startTime);
        }
    }

    private void parseResponse(ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response) {
        log('--- RESPONSE DETAILS ---');

        if (response == null || response.generations == null || response.generations.isEmpty()) {
            log('✗ ERROR: No generations in response');
            return;
        }

        log('✓ Number of Generations: ' + response.generations.size());

        for (Integer i = 0; i < response.generations.size(); i++) {
            ConnectApi.EinsteinLlmGenerationItemOutput generation = response.generations[i];
            
            if (generation.text != null) {
                log('--- GENERATED TEXT ---');
                log(generation.text);
                validateJsonResponse(generation.text);
            }
        }
        log('');
    }

    private void validateJsonResponse(String responseText) {
        log('\n--- JSON VALIDATION ---');
        try {
            JSON.deserializeUntyped(responseText);
            log('✓ Valid JSON structure');
        } catch (Exception jsonException) {
            log('✗ NOT valid JSON: ' + jsonException.getMessage());
        }
    }

    private void handleConnectApiException(ConnectApi.ConnectApiException apiException, Datetime startTime) {
        log('✗ CONNECTAPI EXCEPTION OCCURRED');
        log('Message: ' + apiException.getMessage());
        analyzeCommonErrors(apiException.getMessage());
    }

    private void handleCalloutException(System.CalloutException calloutException, Datetime startTime) {
        log('✗ CALLOUT EXCEPTION OCCURRED');
        log('Message: ' + calloutException.getMessage());
        log('TROUBLESHOOTING: Check Remote Site Settings and Network.');
    }

    private void handleGeneralException(Exception generalException, Datetime startTime) {
        log('✗ EXCEPTION OCCURRED');
        log('Message: ' + generalException.getMessage());
        analyzeCommonErrors(generalException.getMessage());
    }

    private void analyzeCommonErrors(String errorMessage) {
        log('--- ERROR ANALYSIS ---');
        if (errorMessage.containsIgnoreCase('not found')) {
            log('⚠ LIKELY CAUSE: Prompt Template Not Found');
        } else if (errorMessage.containsIgnoreCase('license')) {
            log('⚠ LIKELY CAUSE: Einstein Features Not Enabled');
        } else {
            log('⚠ UNKNOWN ERROR');
        }
        log('');
    }

    private void printSummary() {
        log('========================================');
        log('DEBUG SESSION COMPLETED');
        log('========================================');
    }

    private void log(String message) {
        if (verboseLogging) {
            debugMessages.add(message);
        }
    }

    public List<String> getDebugMessages() {
        return debugMessages;
    }
}