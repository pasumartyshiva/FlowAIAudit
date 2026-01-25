// ============================================================
// TEST: Simplified Re-analyze (No HTTP Callouts)
// Uses FlowDefinitionView SOQL instead of Tooling API
// ============================================================

// Find an active flow
List<FlowDefinitionView> flows = [
    SELECT ApiName, Label
    FROM FlowDefinitionView
    WHERE IsActive = true
    LIMIT 1
];

if (flows.isEmpty()) {
    System.debug('❌ No active flows found');
} else {
    String flowApiName = flows[0].ApiName;
    String flowLabel = flows[0].Label;

    System.debug('========================================');
    System.debug('Testing: ' + flowLabel);
    System.debug('API Name: ' + flowApiName);
    System.debug('========================================\n');

    try {
        Datetime start = System.now();

        // Call the reanalyze method
        String result = FlowAnalysisDashboardController.reanalyzeFlow(flowApiName);

        Long duration = System.now().getTime() - start.getTime();

        System.debug('✓✓✓ SUCCESS! ✓✓✓');
        System.debug('Duration: ' + duration + 'ms (' + (duration/1000.0) + 's)');
        System.debug('Result: ' + result + '\n');

        // Verify analysis was saved
        List<Flow_Analysis__c> analyses = [
            SELECT Status__c, Overall_Score__c, Analysis_Report__c, Raw_Findings__c
            FROM Flow_Analysis__c
            WHERE Flow_API_Name__c = :flowApiName
            ORDER BY Last_Analyzed__c DESC
            LIMIT 1
        ];

        if (!analyses.isEmpty()) {
            Flow_Analysis__c analysis = analyses[0];
            System.debug('✓ Analysis Record Found:');
            System.debug('  Status: ' + analysis.Status__c);
            System.debug('  Score: ' + analysis.Overall_Score__c);
            System.debug('  Report Length: ' + (analysis.Analysis_Report__c != null ? analysis.Analysis_Report__c.length() : 0));
            System.debug('  Findings Length: ' + (analysis.Raw_Findings__c != null ? analysis.Raw_Findings__c.length() : 0));

            if (analysis.Raw_Findings__c != null && analysis.Raw_Findings__c.length() > 0) {
                System.debug('\n--- First 500 chars of findings ---');
                System.debug(analysis.Raw_Findings__c.substring(0, Math.min(500, analysis.Raw_Findings__c.length())));
            }
        }

        System.debug('\n========================================');
        System.debug('✓✓✓ TEST PASSED ✓✓✓');
        System.debug('========================================');

    } catch (Exception e) {
        System.debug('\n========================================');
        System.debug('✗✗✗ TEST FAILED ✗✗✗');
        System.debug('========================================');
        System.debug('Error: ' + e.getMessage());
        System.debug('Type: ' + e.getTypeName());
        System.debug('Line: ' + e.getLineNumber());
        System.debug('\nStack Trace:');
        System.debug(e.getStackTraceString());
    }
}
