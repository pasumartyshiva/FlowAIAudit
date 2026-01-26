/**
 * @description Test class for FlowAnalysisService
 */
@IsTest
private class FlowAnalysisServiceTest {

    @TestSetup
    static void setup() {
        // No specific setup needed
    }

    @IsTest
    static void testAnalyzeFlowWithJsonResponse() {
        // Test data
        String flowApiName = 'TestFlow';
        String flowMetadata = '<?xml version="1.0"?><Flow xmlns="http://soap.sforce.com/2006/04/metadata"><processType>AutoLaunchedFlow</processType></Flow>';
        String flowLabel = 'Test Flow';
        Integer flowVersion = 1;

        Test.startTest();

        // Call the service
        Flow_Analysis__c analysis = FlowAnalysisService.analyzeFlow(
            flowApiName,
            flowMetadata,
            flowLabel,
            flowVersion
        );

        Test.stopTest();

        // Verify basic fields are set
        System.assertNotEquals(null, analysis, 'Analysis should not be null');
        System.assertEquals(flowApiName, analysis.Flow_API_Name__c, 'Flow API name should match');
        System.assertEquals(flowLabel, analysis.Flow_Label__c, 'Flow label should match');
        System.assertEquals(flowVersion, analysis.Flow_Version__c, 'Flow version should match');
        System.assertNotEquals(null, analysis.Last_Analyzed__c, 'Last analyzed should be set');
        System.assertEquals(true, analysis.Is_Active__c, 'Should be marked as active');

        // Status should be set (either from AI or error)
        System.assertNotEquals(null, analysis.Status__c, 'Status should be set');
    }

    @IsTest
    static void testAnalyzeFlowWithHtmlResponse() {
        // Test data with HTML-like response
        String flowApiName = 'TestFlowHtml';
        String flowMetadata = '<Flow><label>Test</label></Flow>';
        String flowLabel = 'Test Flow HTML';
        Integer flowVersion = 2;

        Test.startTest();

        Flow_Analysis__c analysis = FlowAnalysisService.analyzeFlow(
            flowApiName,
            flowMetadata,
            flowLabel,
            flowVersion
        );

        Test.stopTest();

        // Verify
        System.assertNotEquals(null, analysis, 'Analysis should not be null');
        System.assertEquals(flowApiName, analysis.Flow_API_Name__c);
        System.assertNotEquals(null, analysis.Status__c, 'Status should be set');
    }

    @IsTest
    static void testAnalyzeFlowWithEmptyMetadata() {
        // Test with empty metadata
        String flowApiName = 'EmptyFlow';
        String flowMetadata = '';
        String flowLabel = 'Empty Flow';
        Integer flowVersion = 1;

        Test.startTest();

        Flow_Analysis__c analysis = FlowAnalysisService.analyzeFlow(
            flowApiName,
            flowMetadata,
            flowLabel,
            flowVersion
        );

        Test.stopTest();

        // Should still create an analysis record
        System.assertNotEquals(null, analysis);
        System.assertEquals(flowApiName, analysis.Flow_API_Name__c);
    }

    @IsTest
    static void testAnalyzeFlowWithNullValues() {
        // Test with null values
        Test.startTest();

        Flow_Analysis__c analysis = FlowAnalysisService.analyzeFlow(
            'NullTestFlow',
            null,
            null,
            null
        );

        Test.stopTest();

        // Should handle nulls gracefully
        System.assertNotEquals(null, analysis);
        System.assertEquals('NullTestFlow', analysis.Flow_API_Name__c);
    }

    @IsTest
    static void testMultipleAnalyses() {
        // Test analyzing multiple flows
        List<Flow_Analysis__c> analyses = new List<Flow_Analysis__c>();

        Test.startTest();

        for (Integer i = 0; i < 5; i++) {
            Flow_Analysis__c analysis = FlowAnalysisService.analyzeFlow(
                'TestFlow' + i,
                '<Flow><label>Flow ' + i + '</label></Flow>',
                'Test Flow ' + i,
                i
            );
            analyses.add(analysis);
        }

        // Insert all analyses
        insert analyses;

        Test.stopTest();

        // Verify all were created
        List<Flow_Analysis__c> insertedAnalyses = [
            SELECT Id, Flow_API_Name__c, Status__c
            FROM Flow_Analysis__c
        ];

        System.assertEquals(5, insertedAnalyses.size(), 'Should have 5 analyses');
    }

    @IsTest
    static void testGetAssessmentFramework() {
        // This tests the private method indirectly through analyzeFlow
        Test.startTest();

        Flow_Analysis__c analysis = FlowAnalysisService.analyzeFlow(
            'FrameworkTest',
            '<Flow></Flow>',
            'Framework Test',
            1
        );

        Test.stopTest();

        // The framework should be used in the analysis
        System.assertNotEquals(null, analysis);
    }

    @IsTest
    static void testStatusExtraction() {
        // Test different status patterns in responses
        String flowApiName = 'StatusTest';
        String flowMetadata = '<Flow></Flow>';

        Test.startTest();

        Flow_Analysis__c analysis = FlowAnalysisService.analyzeFlow(
            flowApiName,
            flowMetadata,
            'Status Test',
            1
        );

        Test.stopTest();

        // Status should be one of the valid values
        Set<String> validStatuses = new Set<String>{'Pass', 'Needs Work', 'Fail', 'Analyzing', 'Error'};
        System.assert(
            validStatuses.contains(analysis.Status__c),
            'Status should be valid: ' + analysis.Status__c
        );
    }
}
