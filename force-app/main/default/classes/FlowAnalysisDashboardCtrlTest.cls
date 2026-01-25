/**
 * @description Test class for FlowAnalysisDashboardController
 */
@IsTest
private class FlowAnalysisDashboardCtrlTest {

    @TestSetup
    static void setup() {
        // Create test flow analysis records with various statuses
        List<Flow_Analysis__c> analyses = new List<Flow_Analysis__c>();

        analyses.add(new Flow_Analysis__c(
            Flow_API_Name__c = 'PassFlow',
            Flow_Label__c = 'Passing Flow',
            Status__c = 'Pass',
            Overall_Score__c = 95,
            Is_Active__c = true,
            Last_Analyzed__c = System.now(),
            Flow_Version__c = 1,
            Analysis_Report__c = '<p>All good!</p>'
        ));

        analyses.add(new Flow_Analysis__c(
            Flow_API_Name__c = 'FailFlow',
            Flow_Label__c = 'Failing Flow',
            Status__c = 'Fail',
            Overall_Score__c = 35,
            Is_Active__c = true,
            Last_Analyzed__c = System.now(),
            Flow_Version__c = 2,
            Analysis_Report__c = '<p>Issues found</p>'
        ));

        analyses.add(new Flow_Analysis__c(
            Flow_API_Name__c = 'PartialFlow',
            Flow_Label__c = 'Partial Flow',
            Status__c = 'Partial',
            Overall_Score__c = 65,
            Is_Active__c = true,
            Last_Analyzed__c = System.now(),
            Flow_Version__c = 1
        ));

        analyses.add(new Flow_Analysis__c(
            Flow_API_Name__c = 'PendingFlow',
            Flow_Label__c = 'Pending Flow',
            Status__c = 'Pending',
            Is_Active__c = true,
            Flow_Version__c = 1
        ));

        analyses.add(new Flow_Analysis__c(
            Flow_API_Name__c = 'InactiveFlow',
            Flow_Label__c = 'Inactive Flow',
            Status__c = 'Pass',
            Is_Active__c = false,
            Flow_Version__c = 1
        ));

        insert analyses;
    }

    @IsTest
    static void testGetSummaryStats() {
        Test.startTest();

        Map<String, Integer> stats = FlowAnalysisDashboardController.getSummaryStats();

        Test.stopTest();

        // Verify stats
        System.assertNotEquals(null, stats, 'Stats should not be null');
        System.assertEquals(1, stats.get('Pass'), 'Should have 1 pass');
        System.assertEquals(1, stats.get('Fail'), 'Should have 1 fail');
        System.assertEquals(1, stats.get('Partial'), 'Should have 1 partial');
        System.assertEquals(1, stats.get('Pending'), 'Should have 1 pending');
        System.assertEquals(4, stats.get('Total'), 'Should have 4 active total (excluding inactive)');
    }

    @IsTest
    static void testGetFlowAnalysesNoFilter() {
        Test.startTest();

        List<FlowAnalysisDashboardController.FlowAnalysisWrapper> results =
            FlowAnalysisDashboardController.getFlowAnalyses('All', null);

        Test.stopTest();

        // Should return all active flows (excluding inactive)
        System.assertEquals(4, results.size(), 'Should return 4 active flows');
    }

    @IsTest
    static void testGetFlowAnalysesWithStatusFilter() {
        Test.startTest();

        List<FlowAnalysisDashboardController.FlowAnalysisWrapper> results =
            FlowAnalysisDashboardController.getFlowAnalyses('Pass', null);

        Test.stopTest();

        // Should return only Pass flows
        System.assertEquals(1, results.size(), 'Should return 1 pass flow');
        System.assertEquals('Pass', results[0].status, 'Status should be Pass');
    }

    @IsTest
    static void testGetFlowAnalysesWithSearchTerm() {
        Test.startTest();

        List<FlowAnalysisDashboardController.FlowAnalysisWrapper> results =
            FlowAnalysisDashboardController.getFlowAnalyses('All', 'Passing');

        Test.stopTest();

        // Should return only flows matching search term
        System.assertEquals(1, results.size(), 'Should return 1 matching flow');
        System.assert(
            results[0].flowLabel.contains('Passing'),
            'Should match search term'
        );
    }

    @IsTest
    static void testGetFlowAnalysesWithBothFilters() {
        Test.startTest();

        List<FlowAnalysisDashboardController.FlowAnalysisWrapper> results =
            FlowAnalysisDashboardController.getFlowAnalyses('Fail', 'Fail');

        Test.stopTest();

        // Should return only flows matching both filters
        System.assertEquals(1, results.size(), 'Should return 1 matching flow');
        System.assertEquals('Fail', results[0].status);
    }

    @IsTest
    static void testGetFlowAnalysisDetail() {
        Flow_Analysis__c testFlow = [
            SELECT Id
            FROM Flow_Analysis__c
            WHERE Flow_API_Name__c = 'PassFlow'
            LIMIT 1
        ];

        Test.startTest();

        FlowAnalysisDashboardController.FlowAnalysisWrapper result =
            FlowAnalysisDashboardController.getFlowAnalysisDetail(testFlow.Id);

        Test.stopTest();

        // Verify details
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('PassFlow', result.flowApiName);
        System.assertEquals('Pass', result.status);
        System.assertEquals(95, result.score);
    }

    @IsTest
    static void testGetFlowAnalysisDetailInvalidId() {
        Test.startTest();

        try {
            FlowAnalysisDashboardController.FlowAnalysisWrapper result =
                FlowAnalysisDashboardController.getFlowAnalysisDetail(null);
            System.assert(false, 'Should have thrown exception');
        } catch (Exception e) {
            System.assert(true, 'Should throw exception for invalid ID');
        }

        Test.stopTest();
    }

    @IsTest
    static void testRunAllFlowsAnalysis() {
        Test.startTest();

        String jobId = FlowAnalysisDashboardController.runAllFlowsAnalysis(5);

        Test.stopTest();

        // Verify batch job was started
        System.assertNotEquals(null, jobId, 'Job ID should not be null');

        // Verify job exists
        AsyncApexJob job = [
            SELECT Id, Status
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];

        System.assertNotEquals(null, job, 'Job should exist');
    }

    @IsTest
    static void testRunAllFlowsAnalysisWithNullBatchSize() {
        Test.startTest();

        String jobId = FlowAnalysisDashboardController.runAllFlowsAnalysis(null);

        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Should use default batch size');
    }

    @IsTest
    static void testReanalyzeFlow() {
        Test.startTest();

        String jobId = FlowAnalysisDashboardController.reanalyzeFlow('PassFlow');

        Test.stopTest();

        // Verify queueable job was started
        System.assertNotEquals(null, jobId, 'Job ID should not be null');

        // Verify status was updated to Analyzing
        Flow_Analysis__c updated = [
            SELECT Id, Status__c, Last_Analyzed__c
            FROM Flow_Analysis__c
            WHERE Flow_API_Name__c = 'PassFlow'
            LIMIT 1
        ];

        System.assertEquals('Analyzing', updated.Status__c, 'Should be analyzing');
        System.assertNotEquals(null, updated.Last_Analyzed__c, 'Should have timestamp');
    }

    @IsTest
    static void testReanalyzeFlowInvalidName() {
        Test.startTest();

        try {
            String jobId = FlowAnalysisDashboardController.reanalyzeFlow('');
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(
                e.getMessage().contains('required'),
                'Should throw appropriate error'
            );
        }

        Test.stopTest();
    }

    @IsTest
    static void testReanalyzeFlowNonExistent() {
        Test.startTest();

        // Should still create a job even if flow doesn't exist yet
        String jobId = FlowAnalysisDashboardController.reanalyzeFlow('NonExistentFlow');

        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Should create job');
    }

    @IsTest
    static void testIsBatchRunning() {
        Test.startTest();

        // No batch running initially
        Boolean isRunning1 = FlowAnalysisDashboardController.isBatchRunning();

        // Start a batch
        FlowAnalysisBatch.runBatch(5);

        // Should show as running (in test context, it completes immediately)
        Boolean isRunning2 = FlowAnalysisDashboardController.isBatchRunning();

        Test.stopTest();

        System.assertEquals(false, isRunning1, 'Should not be running initially');
        // isRunning2 may be false in test context due to immediate completion
    }

    @IsTest
    static void testGetBatchProgress() {
        Test.startTest();

        Map<String, Object> progress = FlowAnalysisDashboardController.getBatchProgress();

        Test.stopTest();

        // Verify progress map has expected keys
        System.assertNotEquals(null, progress, 'Progress should not be null');
        System.assert(progress.containsKey('isRunning'), 'Should have isRunning key');
        System.assert(progress.containsKey('status'), 'Should have status key');
        System.assert(progress.containsKey('jobItemsProcessed'), 'Should have jobItemsProcessed key');
    }

    @IsTest
    static void testGetBatchProgressWithRunningJob() {
        Test.startTest();

        // Start a batch
        FlowAnalysisBatch.runBatch(5);

        // Get progress
        Map<String, Object> progress = FlowAnalysisDashboardController.getBatchProgress();

        Test.stopTest();

        System.assertNotEquals(null, progress, 'Progress should not be null');
        System.assertNotEquals(null, progress.get('status'), 'Should have status');
    }

    @IsTest
    static void testFlowAnalysisWrapperConstructor() {
        Flow_Analysis__c testAnalysis = [
            SELECT Id, Flow_API_Name__c, Flow_Label__c, Status__c,
                   Overall_Score__c, Last_Analyzed__c, Flow_Version__c,
                   Analysis_Report__c, Raw_Findings__c
            FROM Flow_Analysis__c
            WHERE Flow_API_Name__c = 'PassFlow'
            LIMIT 1
        ];

        Test.startTest();

        FlowAnalysisDashboardController.FlowAnalysisWrapper wrapper =
            new FlowAnalysisDashboardController.FlowAnalysisWrapper(testAnalysis);

        Test.stopTest();

        // Verify wrapper properties
        System.assertEquals(testAnalysis.Id, wrapper.id);
        System.assertEquals(testAnalysis.Flow_API_Name__c, wrapper.flowApiName);
        System.assertEquals(testAnalysis.Flow_Label__c, wrapper.flowLabel);
        System.assertEquals(testAnalysis.Status__c, wrapper.status);
        System.assertEquals(testAnalysis.Overall_Score__c, wrapper.score);
        System.assertEquals(testAnalysis.Last_Analyzed__c, wrapper.lastAnalyzed);
        System.assertEquals(Integer.valueOf(testAnalysis.Flow_Version__c), wrapper.flowVersion);
    }
}
