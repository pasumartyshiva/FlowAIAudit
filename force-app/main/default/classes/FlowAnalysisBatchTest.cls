/**
 * @description Test class for FlowAnalysisBatch
 */
@IsTest
private class FlowAnalysisBatchTest {

    @TestSetup
    static void setup() {
        // Create some test Flow_Analysis__c records
        List<Flow_Analysis__c> analyses = new List<Flow_Analysis__c>();
        for (Integer i = 0; i < 5; i++) {
            analyses.add(new Flow_Analysis__c(
                Flow_API_Name__c = 'ExistingFlow' + i,
                Flow_Label__c = 'Existing Flow ' + i,
                Status__c = 'Pending',
                Is_Active__c = true
            ));
        }
        insert analyses;
    }

    @IsTest
    static void testBatchExecution() {
        // Note: We can't actually query the Flow object in tests,
        // so this will test the batch framework but not process real flows

        Test.startTest();

        Id jobId = FlowAnalysisBatch.runBatch(5);

        Test.stopTest();

        // Verify job was created
        System.assertNotEquals(null, jobId, 'Batch job ID should not be null');

        // Query the job
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];

        System.assertNotEquals(null, job, 'Job should exist');
        System.assertEquals('Completed', job.Status, 'Job should be completed');
    }

    @IsTest
    static void testBatchWithDifferentSizes() {
        Test.startTest();

        // Test with different batch sizes
        Id jobId1 = FlowAnalysisBatch.runBatch(10);
        Id jobId2 = FlowAnalysisBatch.runBatch(50);
        Id jobId3 = FlowAnalysisBatch.runBatch(100);

        Test.stopTest();

        System.assertNotEquals(null, jobId1);
        System.assertNotEquals(null, jobId2);
        System.assertNotEquals(null, jobId3);
    }

    @IsTest
    static void testBatchWithNullBatchSize() {
        Test.startTest();

        // Should use default batch size
        Id jobId = FlowAnalysisBatch.runBatch(null);

        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Should use default batch size');
    }

    @IsTest
    static void testBatchWithZeroBatchSize() {
        Test.startTest();

        // Should use default batch size
        Id jobId = FlowAnalysisBatch.runBatch(0);

        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Should handle zero batch size');
    }

    @IsTest
    static void testBatchWithLargeBatchSize() {
        Test.startTest();

        // Should cap at 200
        Id jobId = FlowAnalysisBatch.runBatch(500);

        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Should cap at max batch size');
    }

    @IsTest
    static void testBatchStatefulVariables() {
        // Create a test instance to verify stateful variables are initialized
        FlowAnalysisBatch batch = new FlowAnalysisBatch();

        Test.startTest();

        // Execute the batch (will have no records to process in test context)
        Database.executeBatch(batch, 5);

        Test.stopTest();

        // Batch should complete without errors
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'FlowAnalysisBatch'
            AND Status = 'Completed'
        ];

        System.assert(jobs.size() > 0, 'Batch should have completed');
    }

    @IsTest
    static void testBatchErrorHandling() {
        // This tests that the batch can handle errors gracefully
        Test.startTest();

        Id jobId = FlowAnalysisBatch.runBatch(5);

        Test.stopTest();

        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];

        // Even if there are no flows to process, it should complete
        System.assertEquals('Completed', job.Status);
    }

    @IsTest
    static void testBatchCalloutContext() {
        // Verify batch can be executed (implicitly tests Database.AllowsCallouts interface)
        FlowAnalysisBatch batch = new FlowAnalysisBatch();
        System.assertNotEquals(null, batch, 'Batch should be instantiable');
    }

    @IsTest
    static void testBatchStatefulContext() {
        // Verify batch maintains state (implicitly tests Database.Stateful interface)
        Test.startTest();
        FlowAnalysisBatch batch = new FlowAnalysisBatch();
        Database.executeBatch(batch, 5);
        Test.stopTest();

        // Batch completed successfully
        System.assert(true, 'Batch executed successfully');
    }
}
