// ============================================================
// QUICK EINSTEIN PROMPT TEMPLATE TEST - FIXED VERSION
// Copy and paste into: Developer Console > Debug > Execute Anonymous
// ============================================================

String templateName = 'Flow_Evaluator_V3';
String flowXml = '<Flow xmlns="http://soap.sforce.com/2006/04/metadata"><status>Active</status></Flow>';
String knowledge = 'Salesforce Flow Best Practices';

System.debug('========================================');
System.debug('Testing: ' + templateName);
System.debug('========================================');

try {
    // Build input
    ConnectApi.EinsteinPromptTemplateGenerationsInput input =
        new ConnectApi.EinsteinPromptTemplateGenerationsInput();
    input.isPreview = false;

    ConnectApi.WrappedValue flowValue = new ConnectApi.WrappedValue();
    flowValue.value = flowXml;

    ConnectApi.WrappedValue knowledgeValue = new ConnectApi.WrappedValue();
    knowledgeValue.value = knowledge;

    input.inputParams = new Map<String, ConnectApi.WrappedValue>();
    input.inputParams.put('Input:MetadataXMLVar', flowValue);
    input.inputParams.put('Input:KnowledgeText', knowledgeValue);

    input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
    input.additionalConfig.maxTokens = 4000;

    System.debug('Parameters: ' + input.inputParams.keySet());
    System.debug('Calling Einstein API...');

    Datetime start = System.now();

    // THE ACTUAL CALL
    ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response =
        ConnectApi.EinsteinLlm.generateMessagesForPromptTemplate(templateName, input);

    Long duration = System.now().getTime() - start.getTime();

    System.debug('========================================');
    System.debug('✓✓✓ SUCCESS! ✓✓✓');
    System.debug('========================================');
    System.debug('Duration: ' + duration + 'ms');

    if (response != null && response.generations != null && !response.generations.isEmpty()) {
        System.debug('\n--- RESPONSE ---');
        System.debug(response.generations[0].text);
        System.debug('--- END ---\n');

        // Validate JSON
        try {
            Object parsed = JSON.deserializeUntyped(response.generations[0].text);
            System.debug('✓ Valid JSON response');
        } catch (Exception jsonEx) {
            System.debug('⚠ Response is not JSON (may be expected)');
        }
    } else {
        System.debug('✗ Empty response');
    }

} catch (ConnectApi.ConnectApiException apiEx) {
    System.debug('========================================');
    System.debug('✗✗✗ FAILED ✗✗✗');
    System.debug('========================================');
    System.debug('Error: ' + apiEx.getMessage());
    System.debug('Type: ConnectApiException');
    System.debug('');

    String msg = apiEx.getMessage().toLowerCase();
    if (msg.contains('not found') || msg.contains('doesn\'t exist')) {
        System.debug('⚠ SOLUTION: Template not published');
        System.debug('   1. Setup > Prompt Builder');
        System.debug('   2. Find: Flow_Evaluator_V3');
        System.debug('   3. Click PUBLISH');
        System.debug('   4. Wait 2-3 minutes');
        System.debug('   5. Re-run this script');
    } else if (msg.contains('license') || msg.contains('feature')) {
        System.debug('⚠ SOLUTION: Einstein not enabled');
        System.debug('   1. Setup > Einstein Setup');
        System.debug('   2. Enable Einstein Generative AI');
        System.debug('   3. Verify license assigned');
    } else if (msg.contains('parameter') || msg.contains('input')) {
        System.debug('⚠ SOLUTION: Parameter mismatch');
        System.debug('   Template expects: Input:MetadataXMLVar, Input:KnowledgeText');
        System.debug('   Code is sending: ' + input.inputParams.keySet());
    }

} catch (Exception ex) {
    System.debug('========================================');
    System.debug('✗✗✗ EXCEPTION ✗✗✗');
    System.debug('========================================');
    System.debug('Error: ' + ex.getMessage());
    System.debug('Type: ' + ex.getTypeName());
    System.debug('Line: ' + ex.getLineNumber());
}

System.debug('========================================');
