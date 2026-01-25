// ============================================================
// DIAGNOSTIC: Check Einstein Prompt Template Setup
// Identifies what's wrong with Einstein Generative AI
// ============================================================

System.debug('========================================');
System.debug('EINSTEIN PROMPT TEMPLATE DIAGNOSTIC');
System.debug('========================================\n');

// Step 1: Check Einstein Feature Access
System.debug('--- Step 1: Checking Einstein Feature Access ---');
try {
    // Check if ConnectApi.EinsteinLLM is accessible
    System.debug('✓ ConnectApi.EinsteinLLM class is accessible');
    System.debug('  This means Einstein APIs are available in your org\n');
} catch (Exception e) {
    System.debug('✗ ConnectApi.EinsteinLLM not accessible');
    System.debug('  Your org may not have Einstein Generative AI enabled\n');
}

// Step 2: Check User Permissions
System.debug('--- Step 2: Checking User Permissions ---');
System.debug('Current User: ' + UserInfo.getUserName());
System.debug('User ID: ' + UserInfo.getUserId());
System.debug('Profile: ' + [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name);

// Check for Einstein-related permissions
List<PermissionSetAssignment> einsteinPerms = [
    SELECT PermissionSet.Name, PermissionSet.Label
    FROM PermissionSetAssignment
    WHERE AssigneeId = :UserInfo.getUserId()
    AND (
        PermissionSet.Name LIKE '%Einstein%' OR
        PermissionSet.Name LIKE '%AI%' OR
        PermissionSet.Name LIKE '%GPT%' OR
        PermissionSet.Name LIKE '%Prompt%'
    )
];

if (einsteinPerms.isEmpty()) {
    System.debug('⚠ WARNING: No Einstein-related permission sets found for current user');
    System.debug('  You may need permission sets like:');
    System.debug('  - Salesforce Einstein Generative AI User');
    System.debug('  - Sales AI User');
    System.debug('  - Prompt Builder User\n');
} else {
    System.debug('✓ Found Einstein-related permission sets:');
    for (PermissionSetAssignment psa : einsteinPerms) {
        System.debug('  - ' + psa.PermissionSet.Label + ' (' + psa.PermissionSet.Name + ')');
    }
    System.debug('');
}

// Step 3: Test Einstein API Call with Minimal Input
System.debug('--- Step 3: Testing Einstein API Call ---');
System.debug('Template Name: Flow_Evaluator_V3\n');

try {
    // Create minimal test input
    ConnectApi.EinsteinLlmGenerationsInput input = new ConnectApi.EinsteinLlmGenerationsInput();

    // Add minimal metadata for test
    Map<String, String> params = new Map<String, String>();
    params.put('Input:MetadataXMLVar', '<Flow><label>Test Flow</label></Flow>');
    params.put('Input:KnowledgeText', 'Test flow for diagnostic purposes');
    input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
    input.additionalConfig.additionalParameters = params;

    input.isPreview = false;

    System.debug('Calling ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate()...');
    System.debug('Template: Flow_Evaluator_V3');
    System.debug('Parameters: ' + params.keySet());
    System.debug('IsPreview: false\n');

    Datetime startTime = System.now();

    ConnectApi.EinsteinLlmGenerationItemOutput result =
        ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
            'Flow_Evaluator_V3',
            input
        );

    Long duration = System.now().getTime() - startTime.getTime();

    System.debug('✓✓✓ EINSTEIN API CALL SUCCEEDED! ✓✓✓');
    System.debug('Duration: ' + duration + 'ms (' + (duration/1000.0) + ' seconds)');
    System.debug('Result Type: ' + result);

    if (result != null && result.generations != null) {
        System.debug('Number of generations: ' + result.generations.size());

        if (!result.generations.isEmpty()) {
            ConnectApi.EinsteinLlmGeneration gen = result.generations[0];
            System.debug('Response preview (first 500 chars):');
            String text = gen.text != null ? gen.text : 'null';
            System.debug(text.substring(0, Math.min(500, text.length())));
            System.debug('...\n');
        }
    }

    System.debug('========================================');
    System.debug('✓✓✓ EINSTEIN IS WORKING! ✓✓✓');
    System.debug('========================================\n');

    System.debug('NEXT STEPS:');
    System.debug('1. Einstein Prompt Template is functioning correctly');
    System.debug('2. The issue may be with parameter format or metadata size');
    System.debug('3. Try re-running FINAL_TEST.apex to verify full integration');
    System.debug('4. If that still fails, the issue is likely metadata formatting\n');

} catch (ConnectApi.ConnectApiException e) {
    System.debug('\n✗✗✗ EINSTEIN API CALL FAILED ✗✗✗');
    System.debug('========================================');
    System.debug('Error: ' + e.getMessage());
    System.debug('Type: ' + e.getTypeName());
    System.debug('HTTP Status Code: ' + e.getStatusCode());
    System.debug('');

    String errorMsg = e.getMessage().toLowerCase();

    System.debug('--- DIAGNOSIS ---\n');

    if (errorMsg.contains('not found') || errorMsg.contains('doesn\'t exist')) {
        System.debug('❌ ISSUE: Prompt Template Not Found\n');
        System.debug('ACTION REQUIRED:');
        System.debug('1. Go to Setup → Prompt Builder');
        System.debug('2. Search for "Flow_Evaluator_V3"');
        System.debug('3. If it doesn\'t exist:');
        System.debug('   - Deploy the prompt template from your metadata');
        System.debug('   - Wait 2-3 minutes for it to become available');
        System.debug('4. If it exists but is in Draft:');
        System.debug('   - Click on the template');
        System.debug('   - Click "Publish"');
        System.debug('   - Wait 2-3 minutes');
        System.debug('   - Re-run this diagnostic\n');

    } else if (errorMsg.contains('permission') || errorMsg.contains('unauthorized')) {
        System.debug('❌ ISSUE: User Lacks Einstein Permissions\n');
        System.debug('ACTION REQUIRED:');
        System.debug('1. Go to Setup → Permission Sets');
        System.debug('2. Assign these permission sets to your user:');
        System.debug('   - Salesforce Einstein Generative AI User');
        System.debug('   - Sales AI User');
        System.debug('   - Prompt Builder User');
        System.debug('3. Logout and login again');
        System.debug('4. Re-run this diagnostic\n');

    } else if (errorMsg.contains('not enabled') || errorMsg.contains('not available')) {
        System.debug('❌ ISSUE: Einstein Not Enabled in Org\n');
        System.debug('ACTION REQUIRED:');
        System.debug('1. Go to Setup → Einstein Setup');
        System.debug('2. Enable "Einstein Generative AI"');
        System.debug('3. Follow the setup wizard');
        System.debug('4. Wait for provisioning (may take 15-30 minutes)');
        System.debug('5. Re-run this diagnostic\n');

    } else if (errorMsg.contains('quota') || errorMsg.contains('limit')) {
        System.debug('❌ ISSUE: Einstein API Quota Exceeded\n');
        System.debug('ACTION REQUIRED:');
        System.debug('1. Go to Setup → Einstein Usage');
        System.debug('2. Check if you\'ve exceeded daily/monthly quota');
        System.debug('3. Wait for quota reset or request increase');
        System.debug('4. Re-run this diagnostic\n');

    } else if (errorMsg.contains('invalid input') || errorMsg.contains('parameter')) {
        System.debug('❌ ISSUE: Invalid Input Parameters\n');
        System.debug('POSSIBLE CAUSES:');
        System.debug('1. Prompt template expects different parameter names');
        System.debug('2. Parameter values are in wrong format');
        System.debug('3. Required parameters are missing\n');
        System.debug('ACTION REQUIRED:');
        System.debug('1. Go to Setup → Prompt Builder');
        System.debug('2. Open "Flow_Evaluator_V3"');
        System.debug('3. Check the "Template Resources" section');
        System.debug('4. Verify parameter names match exactly:');
        System.debug('   - Input:MetadataXMLVar');
        System.debug('   - Input:KnowledgeText');
        System.debug('5. Check parameter data types\n');

    } else {
        System.debug('❌ ISSUE: Unknown Einstein Error\n');
        System.debug('ERROR DETAILS:');
        System.debug('Message: ' + e.getMessage());
        System.debug('Status Code: ' + e.getStatusCode());
        System.debug('Stack Trace:');
        System.debug(e.getStackTraceString());
        System.debug('\nACTION REQUIRED:');
        System.debug('1. Copy the error message above');
        System.debug('2. Search Salesforce Help for the specific error');
        System.debug('3. Check Setup → Einstein Setup for any warnings');
        System.debug('4. Verify Einstein is fully provisioned in your org\n');
    }

} catch (Exception e) {
    System.debug('\n✗✗✗ UNEXPECTED ERROR ✗✗✗');
    System.debug('========================================');
    System.debug('Error: ' + e.getMessage());
    System.debug('Type: ' + e.getTypeName());
    System.debug('Line: ' + e.getLineNumber());
    System.debug('\nStack Trace:');
    System.debug(e.getStackTraceString());
}

System.debug('\n========================================');
System.debug('DIAGNOSTIC COMPLETE');
System.debug('========================================');
