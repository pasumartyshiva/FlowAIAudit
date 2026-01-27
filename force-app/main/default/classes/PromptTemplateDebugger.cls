/**
 * @description Utility class for debugging Einstein Prompt Templates from Anonymous Apex
 * @usage Run in Developer Console > Debug > Open Execute Anonymous Window
 *
 * Example 1: Basic test
 * PromptTemplateDebugger.testTemplate('Flow_Evaluator_V3', 'Test flow XML here');
 *
 * Example 2: With detailed logging
 * PromptTemplateDebugger debugger = new PromptTemplateDebugger();
 * debugger.enableVerboseLogging(true);
 * debugger.testPromptTemplate('Flow_Evaluator_V3', 'Flow XML content', 'Knowledge context');
 *
 * Example 3: List all available templates
 * PromptTemplateDebugger.listAvailableTemplates();
 */
public class PromptTemplateDebugger {

    private Boolean verboseLogging = false;
    private List<String> debugMessages = new List<String>();

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
            // Query for prompt templates via Tooling API would require async,
            // so we'll check the known templates
            List<String> knownTemplates = new List<String>{
                'Flow_Evaluator_V2',
                'Flow_Evaluator_V3'
            };

            for (String template : knownTemplates) {
            }


        } catch (Exception e) {
        }
    }

    /**
     * Enable or disable verbose logging
     */
    public void enableVerboseLogging(Boolean enabled) {
        this.verboseLogging = enabled;
    }

    /**
     * Main test method - tests a prompt template with detailed error handling
     */
    public void testPromptTemplate(String templateName, String flowXml, String knowledge) {
        log('========================================');
        log('PROMPT TEMPLATE DEBUG SESSION STARTED');
        log('========================================');
        log('Template Name: ' + templateName);
        log('Timestamp: ' + System.now());
        log('User: ' + UserInfo.getUserName());
        log('Org ID: ' + UserInfo.getOrganizationId());
        log('========================================\n');

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

    /**
     * Run pre-flight checks
     */
    private void runPreflightChecks() {
        log('--- PRE-FLIGHT CHECKS ---');

        // Check API version
        log('API Version: v65.0');

        // Check user permissions
        try {
            log('User has API Enabled: ' + (UserInfo.getUserType() == 'Standard'));
        } catch (Exception e) {
            log('WARNING: Could not verify user permissions: ' + e.getMessage());
        }

        log('');
    }

    /**
     * Check Einstein settings (best effort)
     */
    private void checkEinsteinSettings() {
        log('--- EINSTEIN SETTINGS CHECK ---');

        try {
            // Note: Some settings require additional permissions to query
            log('Einstein Features Status:');
            log('  This requires manual verification in Setup > Einstein Setup');
            log('  Navigate to: Setup > Prompt Builder to verify templates');
        } catch (Exception e) {
            log('WARNING: Could not check Einstein settings: ' + e.getMessage());
        }

        log('');
    }

    /**
     * Prepare the generation input
     */
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
            log('Flow Metadata Length: ' + flowXml.length() + ' characters');
            log('Knowledge Length: ' + knowledge.length() + ' characters');
        } else {
            log('Flow Metadata Length: ' + flowXml.length() + ' characters');
            log('Knowledge: (none provided)');
        }

        log('Max Tokens: 4000');
        log('Num Generations: 1');
        log('');

        return generationInput;
    }

    /**
     * Attempt the actual API call with comprehensive error handling
     */
    private void attemptPromptTemplateCall(
        String templateName,
        ConnectApi.EinsteinPromptTemplateGenerationsInput generationInput) {

        log('--- ATTEMPTING API CALL ---');
        log('Template: ' + templateName);

        Datetime startTime = System.now();

        try {
            log('Calling: ConnectApi.EinsteinLlm.generateMessagesForPromptTemplate()');
            log('Start Time: ' + startTime);

            // THE ACTUAL API CALL
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response =
                ConnectApi.EinsteinLlm.generateMessagesForPromptTemplate(
                    templateName,
                    generationInput
                );

            Datetime endTime = System.now();
            Long duration = endTime.getTime() - startTime.getTime();

            log('✓ SUCCESS! Call completed in ' + duration + 'ms');
            log('');

            // Parse the response
            parseResponse(response);

        } catch (ConnectApi.ConnectApiException apiException) {
            handleConnectApiException(apiException, startTime);
        } catch (System.CalloutException calloutException) {
            handleCalloutException(calloutException, startTime);
        } catch (Exception generalException) {
            handleGeneralException(generalException, startTime);
        }
    }

    /**
     * Parse and display the response
     */
    private void parseResponse(ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response) {
        log('--- RESPONSE DETAILS ---');

        if (response == null) {
            log('✗ ERROR: Response is NULL');
            return;
        }

        log('Response Object: ' + response);

        if (response.generations == null || response.generations.isEmpty()) {
            log('✗ ERROR: No generations in response');
            log('Response.generations is ' +
                (response.generations == null ? 'NULL' : 'EMPTY'));
            return;
        }

        log('✓ Number of Generations: ' + response.generations.size());

        for (Integer i = 0; i < response.generations.size(); i++) {
            ConnectApi.EinsteinLlmGenerationItemOutput generation = response.generations[i];
            log('\nGeneration #' + (i + 1) + ':');
            log('Text Length: ' +
                (generation.text != null ? generation.text.length() + ' characters' : 'NULL'));

            if (generation.text != null) {
                log('--- GENERATED TEXT ---');
                log(generation.text);
                log('--- END GENERATED TEXT ---');

                // Try to validate if it's JSON
                validateJsonResponse(generation.text);
            }
        }

        log('');
    }

    /**
     * Validate if response is valid JSON
     */
    private void validateJsonResponse(String responseText) {
        log('\n--- JSON VALIDATION ---');

        try {
            Object parsed = JSON.deserializeUntyped(responseText);
            log('✓ Valid JSON structure');

            if (parsed instanceof Map<String, Object>) {
                Map<String, Object> responseMap = (Map<String, Object>) parsed;
                log('✓ Parsed as Map with ' + responseMap.keySet().size() + ' keys');
                log('Keys: ' + String.join(new List<String>(responseMap.keySet()), ', '));
            }
        } catch (Exception jsonException) {
            log('✗ NOT valid JSON: ' + jsonException.getMessage());
            log('This may be expected if the prompt returns plain text');
        }
    }

    /**
     * Handle ConnectApi specific exceptions
     */
    private void handleConnectApiException(
        ConnectApi.ConnectApiException apiException, Datetime startTime) {

        log('✗ CONNECTAPI EXCEPTION OCCURRED');
        log('Duration: ' + (System.now().getTime() - startTime.getTime()) + 'ms');
        log('');
        log('Exception Details:');
        log('  Type: ConnectApiException');
        log('  Message: ' + apiException.getMessage());
        log('  Stack Trace: ' + apiException.getStackTraceString());
        log('');

        // Common error scenarios
        analyzeCommonErrors(apiException.getMessage());
    }

    /**
     * Handle Callout exceptions
     */
    private void handleCalloutException(
        System.CalloutException calloutException, Datetime startTime) {

        log('✗ CALLOUT EXCEPTION OCCURRED');
        log('Duration: ' + (System.now().getTime() - startTime.getTime()) + 'ms');
        log('');
        log('Exception Details:');
        log('  Type: CalloutException');
        log('  Message: ' + calloutException.getMessage());
        log('  Stack Trace: ' + calloutException.getStackTraceString());
        log('');

        log('TROUBLESHOOTING:');
        log('  1. Check Remote Site Settings are configured');
        log('  2. Verify network connectivity');
        log('  3. Check Einstein service status');
    }

    /**
     * Handle general exceptions
     */
    private void handleGeneralException(Exception generalException, Datetime startTime) {
        log('✗ EXCEPTION OCCURRED');
        log('Duration: ' + (System.now().getTime() - startTime.getTime()) + 'ms');
        log('');
        log('Exception Details:');
        log('  Type: ' + generalException.getTypeName());
        log('  Message: ' + generalException.getMessage());
        log('  Line Number: ' + generalException.getLineNumber());
        log('  Stack Trace: ' + generalException.getStackTraceString());
        log('');

        analyzeCommonErrors(generalException.getMessage());
    }

    /**
     * Analyze common error messages and provide guidance
     */
    private void analyzeCommonErrors(String errorMessage) {
        log('--- ERROR ANALYSIS ---');

        if (errorMessage.containsIgnoreCase('not found') ||
            errorMessage.containsIgnoreCase('doesn\'t exist')) {
            log('⚠ LIKELY CAUSE: Prompt Template Not Found or Not Published');
            log('');
            log('SOLUTION:');
            log('  1. Go to Setup > Prompt Builder');
            log('  2. Find your template (Flow_Evaluator_V3)');
            log('  3. Click "Publish" button');
            log('  4. Wait 2-3 minutes for propagation');
            log('  5. Re-run this test');

        } else if (errorMessage.containsIgnoreCase('license') ||
                   errorMessage.containsIgnoreCase('feature not enabled')) {
            log('⚠ LIKELY CAUSE: Einstein Features Not Enabled');
            log('');
            log('SOLUTION:');
            log('  1. Go to Setup > Einstein Setup');
            log('  2. Enable "Einstein Generative AI"');
            log('  3. Ensure Einstein 1 Platform license is assigned');
            log('  4. Re-run this test');

        } else if (errorMessage.containsIgnoreCase('permission') ||
                   errorMessage.containsIgnoreCase('access')) {
            log('⚠ LIKELY CAUSE: Insufficient Permissions');
            log('');
            log('SOLUTION:');
            log('  1. Verify user has "Einstein Generative AI" permission');
            log('  2. Check Profile/Permission Set assignments');
            log('  3. User may need "API Enabled" permission');

        } else if (errorMessage.containsIgnoreCase('timeout')) {
            log('⚠ LIKELY CAUSE: Request Timeout');
            log('');
            log('SOLUTION:');
            log('  1. Reduce input size (flow XML length)');
            log('  2. Check Einstein service status');
            log('  3. Try again - may be transient');

        } else {
            log('⚠ UNKNOWN ERROR');
            log('');
            log('GENERAL TROUBLESHOOTING:');
            log('  1. Check Setup > Prompt Builder > Templates');
            log('  2. Verify Einstein Setup is complete');
            log('  3. Review Setup > Einstein Setup Assistant');
            log('  4. Check Salesforce Trust (trust.salesforce.com)');
        }

        log('');
    }

    /**
     * Print summary
     */
    private void printSummary() {
        log('========================================');
        log('DEBUG SESSION COMPLETED');
        log('========================================');
        log('Review the logs above for detailed information');
        log('');
        log('QUICK CHECKS:');
        log('  ✓ Success? Look for "SUCCESS! Call completed"');
        log('  ✗ Failed? Look for "ERROR ANALYSIS" section');
        log('');
        log('Next Steps:');
        log('  - Fix any errors identified above');
        log('  - Re-run: PromptTemplateDebugger.testFlowEvaluatorV3()');
        log('========================================');
    }

    /**
     * Logging utility
     */
    private void log(String message) {
        if (verboseLogging) {
            debugMessages.add(message);
        }
    }

    /**
     * Get all debug messages (useful for test classes)
     */
    public List<String> getDebugMessages() {
        return debugMessages;
    }
}
