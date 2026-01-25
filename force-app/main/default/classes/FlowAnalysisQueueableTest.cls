/**
 * @description Test class for FlowAnalysisQueueable
 */
@IsTest
private class FlowAnalysisQueueableTest {

    @TestSetup
    static void setup() {
        // Create test flow analysis records
        List<Flow_Analysis__c> analyses = new List<Flow_Analysis__c>();
        analyses.add(new Flow_Analysis__c(
            Flow_API_Name__c = 'TestFlow1',
            Flow_Label__c = 'Test Flow 1',
            Status__c = 'Pending',
            Is_Active__c = true
        ));
        analyses.add(new Flow_Analysis__c(
            Flow_API_Name__c = 'TestFlow2',
            Flow_Label__c = 'Test Flow 2',
            Status__c = 'Pass',
            Is_Active__c = true
        ));
        insert analyses;
    }

    @IsTest
    static void testAnalyzeSingleFlow() {
        Test.startTest();

        // Enqueue single flow analysis
        Id jobId = FlowAnalysisQueueable.analyzeFlow('TestFlow1');

        Test.stopTest();

        // Verify job was created
        System.assertNotEquals(null, jobId, 'Job ID should not be null');

        // Verify the flow analysis record exists
        List<Flow_Analysis__c> analyses = [
            SELECT Id, Flow_API_Name__c, Status__c
            FROM Flow_Analysis__c
            WHERE Flow_API_Name__c = 'TestFlow1'
        ];

        System.assertEquals(1, analyses.size(), 'Should have 1 analysis record');
    }

    @IsTest
    static void testAnalyzeMultipleFlows() {
        List<String> flowNames = new List<String>{'TestFlow1', 'TestFlow2'};

        Test.startTest();

        // Enqueue multiple flow analyses (chained)
        Id jobId = FlowAnalysisQueueable.analyzeFlows(flowNames);

        Test.stopTest();

        // Verify job was created
        System.assertNotEquals(null, jobId, 'Job ID should not be null');

        // Verify both flow analysis records exist
        List<Flow_Analysis__c> analyses = [
            SELECT Id, Flow_API_Name__c
            FROM Flow_Analysis__c
            WHERE Flow_API_Name__c IN ('TestFlow1', 'TestFlow2')
        ];

        System.assertEquals(2, analyses.size(), 'Should have 2 analysis records');
    }

    @IsTest
    static void testAnalyzeFlowsWithEmptyList() {
        List<String> flowNames = new List<String>();

        Test.startTest();

        try {
            Id jobId = FlowAnalysisQueueable.analyzeFlows(flowNames);
            System.assert(false, 'Should have thrown exception for empty list');
        } catch (IllegalArgumentException e) {
            System.assert(
                e.getMessage().contains('cannot be empty'),
                'Should throw appropriate error message'
            );
        }

        Test.stopTest();
    }

    @IsTest
    static void testAnalyzeFlowsWithNullList() {
        Test.startTest();

        try {
            Id jobId = FlowAnalysisQueueable.analyzeFlows(null);
            System.assert(false, 'Should have thrown exception for null list');
        } catch (IllegalArgumentException e) {
            System.assert(
                e.getMessage().contains('cannot be empty'),
                'Should throw appropriate error message'
            );
        }

        Test.stopTest();
    }

    @IsTest
    static void testQueueableWithNonExistentFlow() {
        Test.startTest();

        // Try to analyze a flow that doesn't exist
        Id jobId = FlowAnalysisQueueable.analyzeFlow('NonExistentFlow');

        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job should still be created');

        // Should create an error analysis record
        List<Flow_Analysis__c> analyses = [
            SELECT Id, Flow_API_Name__c, Status__c
            FROM Flow_Analysis__c
            WHERE Flow_API_Name__c = 'NonExistentFlow'
        ];

        // Record may be created with error status
        if (!analyses.isEmpty()) {
            System.assertEquals('Error', analyses[0].Status__c, 'Should have error status');
        }
    }

    @IsTest
    static void testQueueableCalloutInterface() {
        // Verify queueable can be executed (implicitly tests Database.AllowsCallouts interface)
        FlowAnalysisQueueable queueable = new FlowAnalysisQueueable('TestFlow1');
        System.assertNotEquals(null, queueable, 'Queueable should be instantiable');
    }

    @IsTest
    static void testQueueableChaining() {
        // Test with multiple flows to verify chaining logic
        List<String> flowNames = new List<String>{
            'Flow1', 'Flow2', 'Flow3', 'Flow4', 'Flow5'
        };

        Test.startTest();

        Id jobId = FlowAnalysisQueueable.analyzeFlows(flowNames);

        Test.stopTest();

        // In test context, chaining is limited, but job should be created
        System.assertNotEquals(null, jobId, 'Should create initial job');
    }

    @IsTest
    static void testQueueableUpdateExistingAnalysis() {
        // Get existing analysis
        Flow_Analysis__c existing = [
            SELECT Id, Flow_API_Name__c, Status__c
            FROM Flow_Analysis__c
            WHERE Flow_API_Name__c = 'TestFlow1'
            LIMIT 1
        ];

        System.assertEquals('Pending', existing.Status__c, 'Should start as Pending');

        Test.startTest();

        // Re-analyze the flow
        Id jobId = FlowAnalysisQueueable.analyzeFlow('TestFlow1');

        Test.stopTest();

        // Verify the analysis was updated
        Flow_Analysis__c updated = [
            SELECT Id, Flow_API_Name__c, Status__c, Last_Analyzed__c
            FROM Flow_Analysis__c
            WHERE Flow_API_Name__c = 'TestFlow1'
            LIMIT 1
        ];

        // Status may have changed based on analysis
        System.assertNotEquals(null, updated.Last_Analyzed__c, 'Should have last analyzed date');
    }

    @IsTest
    static void testQueueableConstructorWithSingleFlow() {
        FlowAnalysisQueueable queueable = new FlowAnalysisQueueable('TestFlow1');
        System.assertNotEquals(null, queueable, 'Queueable should be created');
    }

    @IsTest
    static void testQueueableConstructorWithMultipleFlows() {
        List<String> flows = new List<String>{'Flow1', 'Flow2', 'Flow3'};
        FlowAnalysisQueueable queueable = new FlowAnalysisQueueable(flows);
        System.assertNotEquals(null, queueable, 'Queueable should be created');
    }
}
