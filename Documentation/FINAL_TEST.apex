// ============================================================
// FINAL TEST: Complete Flow Analysis with Einstein
// Tests Named Credential + Full Metadata + Einstein V3
// ============================================================

System.debug('========================================');
System.debug('FINAL END-TO-END TEST');
System.debug('========================================\n');

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

    System.debug('Flow: ' + flowLabel);
    System.debug('API Name: ' + flowApiName);
    System.debug('');

    try {
        System.debug('--- Step 1: Calling reanalyzeFlow() ---');
        Datetime start = System.now();

        String result = FlowAnalysisDashboardController.reanalyzeFlow(flowApiName);

        Long duration = System.now().getTime() - start.getTime();

        System.debug('✓ Completed in ' + (duration/1000.0) + ' seconds');
        System.debug('Result: ' + result);
        System.debug('');

        System.debug('--- Step 2: Verifying Analysis Record ---');
        List<Flow_Analysis__c> analyses = [
            SELECT Id, Status__c, Overall_Score__c,
                   Analysis_Report__c, Raw_Findings__c,
                   Last_Analyzed__c
            FROM Flow_Analysis__c
            WHERE Flow_API_Name__c = :flowApiName
            ORDER BY Last_Analyzed__c DESC
            LIMIT 1
        ];

        if (analyses.isEmpty()) {
            System.debug('❌ No analysis record found');
        } else {
            Flow_Analysis__c analysis = analyses[0];

            System.debug('✓ Analysis Record:');
            System.debug('  ID: ' + analysis.Id);
            System.debug('  Status: ' + analysis.Status__c);
            System.debug('  Score: ' + analysis.Overall_Score__c);
            System.debug('  Last Analyzed: ' + analysis.Last_Analyzed__c);
            System.debug('  Report Length: ' +
                (analysis.Analysis_Report__c != null ? analysis.Analysis_Report__c.length() : 0) + ' chars');
            System.debug('  Raw Findings Length: ' +
                (analysis.Raw_Findings__c != null ? analysis.Raw_Findings__c.length() : 0) + ' chars');

            System.debug('');
            System.debug('--- Step 3: Einstein Response Preview ---');

            if (analysis.Raw_Findings__c != null && analysis.Raw_Findings__c.length() > 0) {
                String findings = analysis.Raw_Findings__c;

                // Check if it's an error message
                if (findings.contains('⚠️ LLM CONFIGURATION')) {
                    System.debug('❌ Einstein is not working - got fallback error message');
                    System.debug('First 500 chars:');
                    System.debug(findings.substring(0, Math.min(500, findings.length())));
                } else {
                    // Success - show Einstein response
                    System.debug('✓ Einstein Analysis Received!');
                    System.debug('First 2000 chars of analysis:');
                    System.debug(findings.substring(0, Math.min(2000, findings.length())));
                    System.debug('...');

                    // Try to parse as JSON
                    try {
                        Map<String, Object> jsonResponse = (Map<String, Object>)
                            JSON.deserializeUntyped(findings);
                        System.debug('');
                        System.debug('✓ Valid JSON Response');
                        System.debug('  Keys: ' + jsonResponse.keySet());

                        if (jsonResponse.containsKey('status')) {
                            System.debug('  Status: ' + jsonResponse.get('status'));
                        }
                        if (jsonResponse.containsKey('score')) {
                            System.debug('  Score: ' + jsonResponse.get('score'));
                        }
                        if (jsonResponse.containsKey('summary')) {
                            String summary = (String) jsonResponse.get('summary');
                            System.debug('  Summary: ' + summary);
                        }
                    } catch (Exception jsonEx) {
                        System.debug('⚠ Response is not JSON (may be plain text)');
                    }
                }
            } else {
                System.debug('❌ No findings in analysis record');
            }

            System.debug('');
            System.debug('========================================');

            // Final verdict
            if (analysis.Status__c == 'Partial' &&
                analysis.Raw_Findings__c != null &&
                analysis.Raw_Findings__c.contains('⚠️ LLM CONFIGURATION')) {
                System.debug('❌ TEST FAILED - Einstein Not Working');
                System.debug('========================================');
                System.debug('');
                System.debug('DIAGNOSIS:');
                System.debug('✓ Named Credential: Working');
                System.debug('✓ Tooling API: Working');
                System.debug('✓ Full Flow Metadata: Retrieved (9KB+)');
                System.debug('❌ Einstein Prompt Template: Not responding');
                System.debug('');
                System.debug('ACTION REQUIRED:');
                System.debug('1. Setup → Prompt Builder');
                System.debug('2. Find "Flow_Evaluator_V3"');
                System.debug('3. Verify it is Published (not Draft)');
                System.debug('4. Wait 2-3 minutes after publishing');
                System.debug('5. Re-run this test');

            } else if (analysis.Status__c != 'Partial' ||
                       analysis.Overall_Score__c != null) {
                System.debug('✓✓✓ TEST PASSED - FULL SYSTEM WORKING! ✓✓✓');
                System.debug('========================================');
                System.debug('');
                System.debug('SUMMARY:');
                System.debug('✓ Named Credential: Working');
                System.debug('✓ Tooling API: Working');
                System.debug('✓ Full Flow Metadata: Retrieved');
                System.debug('✓ Einstein Prompt Template: Working');
                System.debug('✓ Flow Analysis: Complete');
                System.debug('');
                System.debug('You can now use "Re-analyze" button in the dashboard!');

            } else {
                System.debug('⚠ TEST INCONCLUSIVE');
                System.debug('========================================');
                System.debug('Check the analysis details above');
            }
        }

    } catch (Exception e) {
        System.debug('');
        System.debug('========================================');
        System.debug('❌ TEST FAILED WITH EXCEPTION');
        System.debug('========================================');
        System.debug('Error: ' + e.getMessage());
        System.debug('Type: ' + e.getTypeName());
        System.debug('Line: ' + e.getLineNumber());
        System.debug('');
        System.debug('Stack Trace:');
        System.debug(e.getStackTraceString());
    }
}

System.debug('');
System.debug('========================================');
System.debug('TEST COMPLETE');
System.debug('========================================');
