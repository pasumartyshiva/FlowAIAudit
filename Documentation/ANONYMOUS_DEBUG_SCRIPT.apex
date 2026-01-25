// ============================================================
// EINSTEIN PROMPT TEMPLATE DEBUGGER
// Copy and paste this entire script into:
// Developer Console > Debug > Open Execute Anonymous Window
// ============================================================

// CONFIGURATION - EDIT THESE VALUES
String templateName = 'Flow_Evaluator_V3';
String flowXml = '<Flow xmlns="http://soap.sforce.com/2006/04/metadata">' +
    '<start><locationX>100</locationX><locationY>0</locationY></start>' +
    '<status>Active</status>' +
    '</Flow>';
String knowledge = 'Salesforce Flow Best Practices';

// ============================================================
// SCRIPT START - DO NOT EDIT BELOW THIS LINE
// ============================================================

System.debug('========================================');
System.debug('PROMPT TEMPLATE DEBUG TEST');
System.debug('========================================');
System.debug('Template: ' + templateName);
System.debug('Flow XML Length: ' + flowXml.length() + ' chars');
System.debug('Knowledge: ' + (String.isBlank(knowledge) ? 'None' : knowledge.length() + ' chars'));
System.debug('User: ' + UserInfo.getUserName());
System.debug('Org ID: ' + UserInfo.getOrganizationId());
System.debug('========================================\n');

try {
    System.debug('--- STEP 1: Preparing Input ---');

    // Build the input
    ConnectApi.EinsteinPromptTemplateGenerationsInput input =
        new ConnectApi.EinsteinPromptTemplateGenerationsInput();
    input.isPreview = false;

    // Set flow metadata parameter
    ConnectApi.WrappedValue flowValue = new ConnectApi.WrappedValue();
    flowValue.value = flowXml;

    input.inputParams = new Map<String, ConnectApi.WrappedValue>();
    input.inputParams.put('Input:MetadataXMLVar', flowValue);

    // Add knowledge if provided
    if (String.isNotBlank(knowledge)) {
        ConnectApi.WrappedValue knowledgeValue = new ConnectApi.WrappedValue();
        knowledgeValue.value = knowledge;
        input.inputParams.put('Input:KnowledgeText', knowledgeValue);
    }

    // Configure generation settings
    input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
    input.additionalConfig.maxTokens = 4000;
    input.additionalConfig.numGenerations = 1;

    System.debug('✓ Input prepared successfully');
    System.debug('  - Parameters: ' + input.inputParams.keySet());
    System.debug('  - Max Tokens: 4000');
    System.debug('  - Num Generations: 1\n');

    System.debug('--- STEP 2: Calling Einstein API ---');
    Datetime startTime = System.now();

    // THE ACTUAL API CALL
    ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response =
        ConnectApi.EinsteinLlm.generateMessagesForPromptTemplate(templateName, input);

    Datetime endTime = System.now();
    Long duration = endTime.getTime() - startTime.getTime();

    System.debug('✓ API CALL SUCCESSFUL!');
    System.debug('  Duration: ' + duration + 'ms\n');

    System.debug('--- STEP 3: Parsing Response ---');

    if (response == null) {
        System.debug('✗ ERROR: Response is NULL');
    } else if (response.generations == null || response.generations.isEmpty()) {
        System.debug('✗ ERROR: No generations in response');
        System.debug('  Response object exists but generations is ' +
            (response.generations == null ? 'NULL' : 'EMPTY'));
    } else {
        System.debug('✓ Response contains ' + response.generations.size() + ' generation(s)\n');

        for (Integer i = 0; i < response.generations.size(); i++) {
            ConnectApi.EinsteinLlmGenerationItemOutput gen = response.generations[i];

            System.debug('=== GENERATION #' + (i + 1) + ' ===');

            if (gen.text == null) {
                System.debug('✗ Text is NULL');
            } else {
                System.debug('✓ Text Length: ' + gen.text.length() + ' characters\n');
                System.debug('--- GENERATED TEXT START ---');
                System.debug(gen.text);
                System.debug('--- GENERATED TEXT END ---\n');

                // Validate JSON
                try {
                    Object parsed = JSON.deserializeUntyped(gen.text);
                    System.debug('✓ Valid JSON structure');

                    if (parsed instanceof Map<String, Object>) {
                        Map<String, Object> jsonMap = (Map<String, Object>) parsed;
                        System.debug('✓ JSON Keys: ' + String.join(new List<String>(jsonMap.keySet()), ', '));
                    }
                } catch (Exception jsonEx) {
                    System.debug('⚠ Not valid JSON (may be expected): ' + jsonEx.getMessage());
                }
            }
        }
    }

    System.debug('\n========================================');
    System.debug('✓✓✓ TEST COMPLETED SUCCESSFULLY ✓✓✓');
    System.debug('========================================');

} catch (ConnectApi.ConnectApiException apiEx) {
    System.debug('\n========================================');
    System.debug('✗✗✗ CONNECTAPI EXCEPTION ✗✗✗');
    System.debug('========================================');
    System.debug('Error Type: ConnectApiException');
    System.debug('Message: ' + apiEx.getMessage());
    System.debug('Stack Trace:\n' + apiEx.getStackTraceString());
    System.debug('========================================\n');

    String errorMsg = apiEx.getMessage().toLowerCase();

    if (errorMsg.contains('not found') || errorMsg.contains('doesn\'t exist')) {
        System.debug('⚠ LIKELY CAUSE: Prompt Template Not Published\n');
        System.debug('SOLUTION:');
        System.debug('  1. Go to Setup > Prompt Builder');
        System.debug('  2. Find template: ' + templateName);
        System.debug('  3. Click "Publish" button');
        System.debug('  4. Wait 2-3 minutes');
        System.debug('  5. Re-run this script');

    } else if (errorMsg.contains('license') || errorMsg.contains('feature not enabled')) {
        System.debug('⚠ LIKELY CAUSE: Einstein Not Enabled\n');
        System.debug('SOLUTION:');
        System.debug('  1. Go to Setup > Einstein Setup');
        System.debug('  2. Enable "Einstein Generative AI"');
        System.debug('  3. Verify Einstein 1 Platform license assigned');
        System.debug('  4. Re-run this script');

    } else if (errorMsg.contains('permission') || errorMsg.contains('access')) {
        System.debug('⚠ LIKELY CAUSE: Insufficient Permissions\n');
        System.debug('SOLUTION:');
        System.debug('  1. Verify "Einstein Generative AI" permission');
        System.debug('  2. Check Profile/Permission Set assignments');
        System.debug('  3. User needs "API Enabled" permission');

    } else {
        System.debug('⚠ UNKNOWN ERROR\n');
        System.debug('TROUBLESHOOTING:');
        System.debug('  1. Check Setup > Prompt Builder');
        System.debug('  2. Verify Einstein Setup is complete');
        System.debug('  3. Check trust.salesforce.com for service status');
    }

} catch (Exception ex) {
    System.debug('\n========================================');
    System.debug('✗✗✗ EXCEPTION OCCURRED ✗✗✗');
    System.debug('========================================');
    System.debug('Error Type: ' + ex.getTypeName());
    System.debug('Message: ' + ex.getMessage());
    System.debug('Line: ' + ex.getLineNumber());
    System.debug('Stack Trace:\n' + ex.getStackTraceString());
    System.debug('========================================');
}

System.debug('\n========================================');
System.debug('DEBUG SESSION ENDED');
System.debug('========================================');
