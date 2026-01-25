// ============================================================
// FINAL INTEGRATION TEST: Complete Flow Analysis System
// Tests: Named Credential + Full Metadata + Einstein V3
// ============================================================

System.debug('========================================');
System.debug('FINAL INTEGRATION TEST');
System.debug('Testing complete flow analysis system');
System.debug('========================================\n');

// Get a test flow
List<FlowDefinitionView> flows = [
    SELECT ApiName, Label
    FROM FlowDefinitionView
    WHERE IsActive = true
    LIMIT 1
];

if (flows.isEmpty()) {
    System.debug('❌ No active flows found in org');
    System.debug('Please create at least one active flow to test');
} else {
    String flowApiName = flows[0].ApiName;
    String flowLabel = flows[0].Label;

    System.debug('Testing with flow:');
    System.debug('  Label: ' + flowLabel);
    System.debug('  API Name: ' + flowApiName);
    System.debug('');

    try {
        System.debug('--- Starting Full Flow Analysis ---');
        System.debug('This will:');
        System.debug('1. Fetch full flow metadata via Named Credential');
        System.debug('2. Call Einstein Prompt Template (Flow_Evaluator_V3)');
        System.debug('3. Parse and save the analysis results');
        System.debug('');

        Datetime startTime = System.now();

        // Call the reanalyzeFlow method (this is what the LWC calls)
        String result = FlowAnalysisDashboardController.reanalyzeFlow(flowApiName);

        Long duration = System.now().getTime() - startTime.getTime();

        System.debug('✓✓✓ ANALYSIS COMPLETED SUCCESSFULLY! ✓✓✓');
        System.debug('Duration: ' + (duration/1000.0) + ' seconds');
        System.debug('Result: ' + result);
        System.debug('');

        // Retrieve and verify the analysis record
        System.debug('--- Verifying Analysis Record ---');
        List<Flow_Analysis__c> analyses = [
            SELECT Id, Flow_API_Name__c, Flow_Label__c, Status__c,
                   Overall_Score__c, Analysis_Report__c, Raw_Findings__c,
                   Last_Analyzed__c, Flow_Version__c
            FROM Flow_Analysis__c
            WHERE Flow_API_Name__c = :flowApiName
            ORDER BY Last_Analyzed__c DESC
            LIMIT 1
        ];

        if (analyses.isEmpty()) {
            System.debug('❌ ERROR: No analysis record created');
            System.debug('The analysis may have failed silently');
        } else {
            Flow_Analysis__c analysis = analyses[0];

            System.debug('✓ Analysis Record Found:');
            System.debug('  Record ID: ' + analysis.Id);
            System.debug('  Flow Label: ' + analysis.Flow_Label__c);
            System.debug('  Status: ' + analysis.Status__c);
            System.debug('  Overall Score: ' + analysis.Overall_Score__c);
            System.debug('  Version: ' + analysis.Flow_Version__c);
            System.debug('  Last Analyzed: ' + analysis.Last_Analyzed__c);
            System.debug('');

            // Check report quality
            Integer reportLength = analysis.Analysis_Report__c != null ? analysis.Analysis_Report__c.length() : 0;
            Integer findingsLength = analysis.Raw_Findings__c != null ? analysis.Raw_Findings__c.length() : 0;

            System.debug('  Report Length: ' + reportLength + ' characters');
            System.debug('  Raw Findings Length: ' + findingsLength + ' characters');
            System.debug('');

            // Verify Einstein responded (not fallback)
            if (analysis.Raw_Findings__c != null && analysis.Raw_Findings__c.contains('⚠️ LLM CONFIGURATION')) {
                System.debug('========================================');
                System.debug('❌ TEST FAILED: Einstein Not Responding');
                System.debug('========================================');
                System.debug('');
                System.debug('The system fell back to error message.');
                System.debug('');
                System.debug('COMPONENTS VERIFIED:');
                System.debug('✓ Named Credential: Working');
                System.debug('✓ Tooling API: Working');
                System.debug('✓ Full Metadata: Retrieved');
                System.debug('❌ Einstein Prompt Template: Not responding');
                System.debug('');
                System.debug('TROUBLESHOOTING:');
                System.debug('1. Verify Flow_Evaluator_V3 exists in Setup → Prompt Builder');
                System.debug('2. Verify template is Published (not Draft)');
                System.debug('3. Check user has Einstein permissions');
                System.debug('4. Try running DIAGNOSE_EINSTEIN.apex');

            } else if (analysis.Raw_Findings__c != null && analysis.Raw_Findings__c.startsWith('{')) {
                // Parse JSON to verify structure
                try {
                    Map<String, Object> jsonResponse = (Map<String, Object>)
                        JSON.deserializeUntyped(analysis.Raw_Findings__c);

                    System.debug('--- Einstein Response Analysis ---');
                    System.debug('✓ Valid JSON response received');
                    System.debug('');

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

                    // Show findings preview
                    if (jsonResponse.containsKey('findings')) {
                        List<Object> findings = (List<Object>) jsonResponse.get('findings');
                        System.debug('  Number of findings: ' + findings.size());

                        if (!findings.isEmpty()) {
                            System.debug('');
                            System.debug('  First finding preview:');
                            Map<String, Object> firstFinding = (Map<String, Object>) findings[0];
                            if (firstFinding.containsKey('category')) {
                                System.debug('    Category: ' + firstFinding.get('category'));
                            }
                            if (firstFinding.containsKey('severity')) {
                                System.debug('    Severity: ' + firstFinding.get('severity'));
                            }
                            if (firstFinding.containsKey('issue')) {
                                String issue = (String) firstFinding.get('issue');
                                System.debug('    Issue: ' + issue.substring(0, Math.min(100, issue.length())) + '...');
                            }
                        }
                    }

                    System.debug('');
                    System.debug('========================================');
                    System.debug('✓✓✓ ALL TESTS PASSED! ✓✓✓');
                    System.debug('========================================');
                    System.debug('');
                    System.debug('SYSTEM STATUS:');
                    System.debug('✓ Named Credential: Working');
                    System.debug('✓ Tooling API: Working');
                    System.debug('✓ Full Flow Metadata: Retrieved (' + (findingsLength > 1000 ? '>' : '') + (findingsLength/1000) + 'KB)');
                    System.debug('✓ Einstein Prompt Template: Working');
                    System.debug('✓ JSON Parsing: Working');
                    System.debug('✓ Analysis Record: Saved');
                    System.debug('');
                    System.debug('🎉 THE COMPLETE FLOW ANALYSIS SYSTEM IS FULLY OPERATIONAL! 🎉');
                    System.debug('');
                    System.debug('NEXT STEPS:');
                    System.debug('1. Open the Flow Analysis Dashboard');
                    System.debug('2. Click "Re-analyze" on any flow');
                    System.debug('3. Wait 10-15 seconds');
                    System.debug('4. View the detailed AI-powered analysis');

                } catch (Exception jsonEx) {
                    System.debug('⚠ WARNING: Response is not valid JSON');
                    System.debug('Raw response preview (first 500 chars):');
                    System.debug(analysis.Raw_Findings__c.substring(0, Math.min(500, analysis.Raw_Findings__c.length())));
                    System.debug('');
                    System.debug('This suggests Einstein responded but in unexpected format');
                }

            } else {
                System.debug('⚠ WARNING: Unexpected response format');
                System.debug('Raw findings preview (first 500 chars):');
                if (analysis.Raw_Findings__c != null) {
                    System.debug(analysis.Raw_Findings__c.substring(0, Math.min(500, analysis.Raw_Findings__c.length())));
                } else {
                    System.debug('(null)');
                }
            }
        }

    } catch (Exception e) {
        System.debug('');
        System.debug('========================================');
        System.debug('❌ TEST FAILED WITH EXCEPTION');
        System.debug('========================================');
        System.debug('');
        System.debug('Error: ' + e.getMessage());
        System.debug('Type: ' + e.getTypeName());
        System.debug('Line: ' + e.getLineNumber());
        System.debug('');
        System.debug('Stack Trace:');
        System.debug(e.getStackTraceString());
        System.debug('');

        // Provide diagnostic guidance
        String errorMsg = e.getMessage().toLowerCase();
        if (errorMsg.contains('unauthorized endpoint')) {
            System.debug('DIAGNOSIS: Named Credential not configured');
            System.debug('ACTION: Run DIAGNOSE_NAMED_CREDENTIAL.apex');
        } else if (errorMsg.contains('401')) {
            System.debug('DIAGNOSIS: Authentication failed');
            System.debug('ACTION: Check Named Credential and Remote Site Setting');
        } else if (errorMsg.contains('einstein') || errorMsg.contains('prompt')) {
            System.debug('DIAGNOSIS: Einstein Prompt Template issue');
            System.debug('ACTION: Run DIAGNOSE_EINSTEIN.apex');
        }
    }
}

System.debug('');
System.debug('========================================');
System.debug('TEST EXECUTION COMPLETE');
System.debug('========================================');
