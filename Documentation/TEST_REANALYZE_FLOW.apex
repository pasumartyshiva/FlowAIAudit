// ============================================================
// TEST SCRIPT: Re-analyze Single Flow via Dashboard Controller
// Tests the complete synchronous flow analysis with Einstein
// ============================================================

// STEP 1: Find an existing flow to test
List<FlowDefinitionView> flows = [
    SELECT ApiName, Label
    FROM FlowDefinitionView
    WHERE IsActive = true
    LIMIT 1
];

if (flows.isEmpty()) {
    System.debug('❌ No active flows found in org');
} else {
    String flowApiName = flows[0].ApiName;
    String flowLabel = flows[0].Label;

    System.debug('========================================');
    System.debug('TESTING FLOW ANALYSIS');
    System.debug('========================================');
    System.debug('Flow API Name: ' + flowApiName);
    System.debug('Flow Label: ' + flowLabel);
    System.debug('');

    try {
        // STEP 2: Call the reanalyze method (same as clicking "Re-analyze" in UI)
        System.debug('--- Calling reanalyzeFlow() ---');
        Datetime startTime = System.now();

        String result = FlowAnalysisDashboardController.reanalyzeFlow(flowApiName);

        Long duration = System.now().getTime() - startTime.getTime();

        System.debug('✓✓✓ SUCCESS! ✓✓✓');
        System.debug('Result: ' + result);
        System.debug('Duration: ' + duration + 'ms (' + (duration/1000) + ' seconds)');
        System.debug('');

        // STEP 3: Verify the analysis was saved
        System.debug('--- Verifying Analysis Record ---');
        List<Flow_Analysis__c> analyses = [
            SELECT Id, Flow_API_Name__c, Flow_Label__c, Status__c,
                   Overall_Score__c, Last_Analyzed__c, Analysis_Report__c,
                   Raw_Findings__c
            FROM Flow_Analysis__c
            WHERE Flow_API_Name__c = :flowApiName
            ORDER BY Last_Analyzed__c DESC
            LIMIT 1
        ];

        if (analyses.isEmpty()) {
            System.debug('⚠ WARNING: No analysis record found');
        } else {
            Flow_Analysis__c analysis = analyses[0];
            System.debug('✓ Analysis record found');
            System.debug('  - Status: ' + analysis.Status__c);
            System.debug('  - Score: ' + analysis.Overall_Score__c);
            System.debug('  - Last Analyzed: ' + analysis.Last_Analyzed__c);
            System.debug('  - Report Length: ' +
                (analysis.Analysis_Report__c != null ? analysis.Analysis_Report__c.length() : 0) + ' chars');
            System.debug('  - Raw Findings Length: ' +
                (analysis.Raw_Findings__c != null ? analysis.Raw_Findings__c.length() : 0) + ' chars');

            // Show first 500 chars of raw findings
            if (analysis.Raw_Findings__c != null) {
                System.debug('');
                System.debug('--- Raw Findings Preview (first 500 chars) ---');
                System.debug(analysis.Raw_Findings__c.substring(0,
                    Math.min(500, analysis.Raw_Findings__c.length())));
                System.debug('...');
            }
        }

        System.debug('');
        System.debug('========================================');
        System.debug('✓✓✓ TEST COMPLETED SUCCESSFULLY ✓✓✓');
        System.debug('========================================');

    } catch (Exception e) {
        System.debug('');
        System.debug('========================================');
        System.debug('✗✗✗ TEST FAILED ✗✗✗');
        System.debug('========================================');
        System.debug('Error Type: ' + e.getTypeName());
        System.debug('Error Message: ' + e.getMessage());
        System.debug('Line Number: ' + e.getLineNumber());
        System.debug('Stack Trace:');
        System.debug(e.getStackTraceString());
        System.debug('');

        // Common error scenarios
        String errorMsg = e.getMessage().toLowerCase();

        if (errorMsg.contains('unauthorized endpoint')) {
            System.debug('⚠ LIKELY CAUSE: Remote Site Setting not configured');
            System.debug('');
            System.debug('SOLUTION:');
            System.debug('1. Go to Setup > Remote Site Settings');
            System.debug('2. Find "Salesforce_Instance"');
            System.debug('3. Verify it exists and is Active');
            System.debug('4. Verify URL matches your org domain');

        } else if (errorMsg.contains('session expired') || errorMsg.contains('invalid session')) {
            System.debug('⚠ LIKELY CAUSE: Session ID issue');
            System.debug('');
            System.debug('SOLUTION:');
            System.debug('1. This might happen in sandboxes');
            System.debug('2. Try running from Developer Console instead of CLI');

        } else if (errorMsg.contains('prompt template') || errorMsg.contains('einstein')) {
            System.debug('⚠ LIKELY CAUSE: Einstein Prompt Template issue');
            System.debug('');
            System.debug('SOLUTION:');
            System.debug('1. Verify Flow_Evaluator_V3 is published');
            System.debug('2. Setup > Prompt Builder > Flow_Evaluator_V3');
            System.debug('3. Check Einstein is enabled');

        } else {
            System.debug('⚠ UNKNOWN ERROR');
            System.debug('Check the error message and stack trace above');
        }

        System.debug('========================================');
    }
}
