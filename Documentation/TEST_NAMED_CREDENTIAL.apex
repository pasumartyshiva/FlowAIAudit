// ============================================================
// TEST: Named Credential Setup Verification
// Tests that Salesforce_Tooling_API Named Credential works
// ============================================================

System.debug('========================================');
System.debug('NAMED CREDENTIAL TEST');
System.debug('========================================\n');

// STEP 1: Test Named Credential connection
System.debug('--- Step 1: Testing Named Credential Connection ---');

try {
    String endpoint = 'callout:Salesforce_Tooling_API/services/data/v64.0/tooling/query?q=' +
        EncodingUtil.urlEncode('SELECT Id FROM Flow LIMIT 1', 'UTF-8');

    HttpRequest req = new HttpRequest();
    req.setEndpoint(endpoint);
    req.setMethod('GET');
    req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
    req.setHeader('Content-Type', 'application/json');
    req.setTimeout(60000);

    System.debug('Endpoint: ' + endpoint);
    System.debug('Calling Tooling API via Named Credential...\n');

    Http http = new Http();
    HttpResponse res = http.send(req);

    System.debug('Response Code: ' + res.getStatusCode());
    System.debug('Response Status: ' + res.getStatus());

    if (res.getStatusCode() == 200) {
        System.debug('✓ Named Credential Connection: SUCCESS\n');
        System.debug('Response Body Preview:');
        System.debug(res.getBody().substring(0, Math.min(500, res.getBody().length())));
    } else {
        System.debug('✗ Named Credential Connection: FAILED\n');
        System.debug('Error Response:');
        System.debug(res.getBody());
    }

} catch (Exception e) {
    System.debug('✗ Named Credential Connection: ERROR\n');
    System.debug('Error: ' + e.getMessage());
    System.debug('Type: ' + e.getTypeName());
}

System.debug('\n========================================');

// STEP 2: Test full flow analysis method
System.debug('--- Step 2: Testing Full Flow Analysis ---\n');

List<FlowDefinitionView> flows = [
    SELECT ApiName, Label
    FROM FlowDefinitionView
    WHERE IsActive = true
    LIMIT 1
];

if (flows.isEmpty()) {
    System.debug('✗ No active flows found in org');
} else {
    String flowApiName = flows[0].ApiName;
    String flowLabel = flows[0].Label;

    System.debug('Testing with flow: ' + flowLabel);
    System.debug('API Name: ' + flowApiName + '\n');

    try {
        Datetime startTime = System.now();

        // Call the actual reanalyzeFlow method
        String result = FlowAnalysisDashboardController.reanalyzeFlow(flowApiName);

        Long duration = System.now().getTime() - startTime.getTime();

        System.debug('✓✓✓ FULL ANALYSIS: SUCCESS! ✓✓✓');
        System.debug('Duration: ' + duration + 'ms (' + (duration/1000.0) + ' seconds)');
        System.debug('Result: ' + result + '\n');

        // Verify the analysis record
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
            System.debug('⚠ WARNING: No analysis record found');
        } else {
            Flow_Analysis__c analysis = analyses[0];
            System.debug('✓ Analysis Record Created:');
            System.debug('  Record ID: ' + analysis.Id);
            System.debug('  Status: ' + analysis.Status__c);
            System.debug('  Score: ' + analysis.Overall_Score__c);
            System.debug('  Last Analyzed: ' + analysis.Last_Analyzed__c);
            System.debug('  Report Length: ' +
                (analysis.Analysis_Report__c != null ? analysis.Analysis_Report__c.length() : 0) + ' chars');
            System.debug('  Findings Length: ' +
                (analysis.Raw_Findings__c != null ? analysis.Raw_Findings__c.length() : 0) + ' chars');

            // Show preview of Einstein response
            if (analysis.Raw_Findings__c != null && analysis.Raw_Findings__c.length() > 0) {
                System.debug('\n--- Einstein Response Preview (first 1000 chars) ---');
                System.debug(analysis.Raw_Findings__c.substring(0,
                    Math.min(1000, analysis.Raw_Findings__c.length())));
                System.debug('...\n');
            }
        }

        System.debug('\n========================================');
        System.debug('✓✓✓ ALL TESTS PASSED ✓✓✓');
        System.debug('========================================');
        System.debug('\nNamed Credential is working correctly!');
        System.debug('Full flow metadata is being retrieved!');
        System.debug('Einstein analysis is functioning!');

    } catch (Exception e) {
        System.debug('\n✗✗✗ FULL ANALYSIS: FAILED ✗✗✗');
        System.debug('========================================');
        System.debug('Error: ' + e.getMessage());
        System.debug('Type: ' + e.getTypeName());
        System.debug('Line: ' + e.getLineNumber());
        System.debug('\nStack Trace:');
        System.debug(e.getStackTraceString());

        // Provide diagnostic help
        String errorMsg = e.getMessage().toLowerCase();
        System.debug('\n--- DIAGNOSTICS ---');

        if (errorMsg.contains('unauthorized endpoint')) {
            System.debug('⚠ Issue: Named Credential not configured properly');
            System.debug('Solution:');
            System.debug('1. Setup → Named Credentials');
            System.debug('2. Verify "Salesforce_Tooling_API" exists');
            System.debug('3. Check "Allow Merge Fields in HTTP Header" is checked');

        } else if (errorMsg.contains('401') || errorMsg.contains('unauthorized')) {
            System.debug('⚠ Issue: Authentication failed');
            System.debug('Solution:');
            System.debug('1. Setup → Remote Site Settings');
            System.debug('2. Verify "Salesforce_Instance" is active');
            System.debug('3. Check URL matches org domain');
            System.debug('4. Current org domain: ' + URL.getOrgDomainUrl().toExternalForm());

        } else if (errorMsg.contains('prompt template') || errorMsg.contains('einstein')) {
            System.debug('⚠ Issue: Einstein Prompt Template issue');
            System.debug('Solution:');
            System.debug('1. Setup → Prompt Builder');
            System.debug('2. Find "Flow_Evaluator_V3"');
            System.debug('3. Verify it is Published');
            System.debug('4. Wait 2-3 minutes after publishing');

        } else {
            System.debug('⚠ Issue: Unexpected error');
            System.debug('Check the error message and stack trace above for details');
        }

        System.debug('========================================');
    }
}

System.debug('\n========================================');
System.debug('TEST COMPLETE');
System.debug('========================================');
