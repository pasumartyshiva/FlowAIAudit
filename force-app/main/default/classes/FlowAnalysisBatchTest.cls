@IsTest
private class FlowAnalysisBatchTest {

    @TestSetup
    static void setup() {
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

    /**
     * @description Mock class to simulate Tooling API responses
     */
    public class ToolingAPIMock implements HttpCalloutMock {
        private Boolean success;
        private Boolean returnRecords;

        public ToolingAPIMock(Boolean success, Boolean returnRecords) {
            this.success = success;
            this.returnRecords = returnRecords;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String endpoint = req.getEndpoint();

            if (!success) {
                res.setStatusCode(500);
                res.setBody('{"message":"Internal Server Error"}');
                return res;
            }

            res.setStatusCode(200);

            // FIX: Check for 'Metadata' FIRST. 
            // Both queries contain 'Definition.DeveloperName' (one in SELECT, one in WHERE),
            // so checking Metadata first ensures we catch the Detail query correctly.
            if (endpoint.contains('Metadata')) {
                // Querying specific flow detail (execute method)
                if (returnRecords) {
                    String mockMetadata = '{' +
                        '"processType":"Flow",' +
                        '"status":"Active",' +
                        '"start":{"connector":{"targetReference":"screen1"}},' + 
                        '"screens":[{"name":"screen1","label":"Screen 1"}]' + 
                    '}';
                    // Escape quotes for JSON string wrapping
                    mockMetadata = mockMetadata.replace('"', '\\"');
                    
                    res.setBody('{"size":1,"totalSize":1,"done":true,"records":[{' +
                        '"Id":"301000000000001",' +
                        '"Definition":{"MasterLabel":"Test Flow Label"},' +
                        '"Metadata":' + mockMetadata + 
                        '}]}');
                } else {
                    res.setBody('{"size":0,"totalSize":0,"done":true,"records":[]}');
                }
            } 
            else if (endpoint.contains('Definition.DeveloperName')) {
                // Querying list of flows (start method)
                if (returnRecords) {
                    res.setBody('{"size":2,"totalSize":2,"done":true,"records":[' +
                        '{"Definition":{"DeveloperName":"TestFlow1","MasterLabel":"Test Flow 1"}},' +
                        '{"Definition":{"DeveloperName":"TestFlow2","MasterLabel":"Test Flow 2"}}' +
                        ']}');
                } else {
                    res.setBody('{"size":0,"totalSize":0,"done":true,"records":[]}');
                }
            }
            
            return res;
        }
    }

    @IsTest
    static void testBatchStartCalloutExecution() {
        Test.setMock(HttpCalloutMock.class, new ToolingAPIMock(true, true));

        Test.startTest();
        // This runs the default constructor -> start() calls API -> returns 2 flows -> execute() calls API for each
        Id jobId = FlowAnalysisBatch.runBatch(5);
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Batch job ID should not be null');
        
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed FROM AsyncApexJob WHERE Id = :jobId
        ];
        System.assertEquals('Completed', job.Status, 'Job should be completed');
        System.assert(job.JobItemsProcessed > 0, 'Should have processed batches');
    }



    @IsTest
    static void testBatchExecuteNoMetadataFound() {
        List<String> flowNames = new List<String>{'MissingFlow'};
        
        // Mock returns true for Start query, but false (empty) for Metadata query
        Test.setMock(HttpCalloutMock.class, new ToolingAPIMock(true, false));
        
        Test.startTest();
        FlowAnalysisBatch batch = new FlowAnalysisBatch(flowNames);
        Database.executeBatch(batch, 1);
        Test.stopTest();
        
        List<Flow_Analysis__c> results = [SELECT Id, Status__c, Analysis_Report__c FROM Flow_Analysis__c WHERE Flow_API_Name__c = 'MissingFlow'];
        System.assertEquals(1, results.size(), 'Should create record');
        System.assertEquals('Error', results[0].Status__c, 'Status should be Error');
        System.assert(results[0].Analysis_Report__c.contains('No metadata'), 'Report should contain error message: ' + results[0].Analysis_Report__c);
    }

    @IsTest
    static void testBatchExecuteApiFailure() {
        List<String> flowNames = new List<String>{'ErrorFlow'};
        
        // Mock returns 500 error
        Test.setMock(HttpCalloutMock.class, new ToolingAPIMock(false, false));
        
        Test.startTest();
        FlowAnalysisBatch batch = new FlowAnalysisBatch(flowNames);
        Database.executeBatch(batch, 1);
        Test.stopTest();
        
        List<Flow_Analysis__c> results = [SELECT Id, Status__c FROM Flow_Analysis__c WHERE Flow_API_Name__c = 'ErrorFlow'];
        System.assertEquals(1, results.size());
        System.assertEquals('Error', results[0].Status__c);
    }

    @IsTest
    static void testBatchWithEmptyFlowNames() {
        List<String> flowNames = new List<String>();
        
        Test.startTest();
        FlowAnalysisBatch batch = new FlowAnalysisBatch(flowNames);
        Database.executeBatch(batch, 5);
        Test.stopTest();
        
        AsyncApexJob job = [SELECT Id, Status, JobItemsProcessed FROM AsyncApexJob WHERE ApexClass.Name = 'FlowAnalysisBatch' ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals('Completed', job.Status);
    }

    @IsTest
    static void testRunBatchHelperMethods() {
        Test.setMock(HttpCalloutMock.class, new ToolingAPIMock(true, false));
        
        Test.startTest();
        Id jobId1 = FlowAnalysisBatch.runBatch(null); 
        Id jobId2 = FlowAnalysisBatch.runBatch(0);    
        Id jobId3 = FlowAnalysisBatch.runBatch(100);  
        Test.stopTest();

        System.assertNotEquals(null, jobId1);
        System.assertNotEquals(null, jobId2);
        System.assertNotEquals(null, jobId3);
    }
}