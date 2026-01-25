/**
 * @description Test class for FlowAnalysisPDFController
 */
@isTest
private class FlowAnalysisPDFControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create test Flow Analysis record
        Flow_Analysis__c testAnalysis = new Flow_Analysis__c(
            Flow_API_Name__c = 'Test_Flow',
            Flow_Label__c = 'Test Flow',
            Flow_Version__c = 1,
            Status__c = 'Pass',
            Overall_Score__c = 85,
            Analysis_Report__c = '<h2>Test Report</h2><p>This is a test analysis report.</p>',
            Last_Analyzed__c = System.now()
        );
        insert testAnalysis;
    }

    @isTest
    static void testControllerConstructor() {
        Flow_Analysis__c testRecord = [SELECT Id FROM Flow_Analysis__c LIMIT 1];

        Test.startTest();
        PageReference pageRef = Page.FlowAnalysisPDF;
        pageRef.getParameters().put('id', testRecord.Id);
        Test.setCurrentPage(pageRef);

        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        Test.stopTest();

        System.assertNotEquals(null, controller.flowAnalysis, 'Flow Analysis should be loaded');
        System.assertEquals('Test Flow', controller.flowAnalysis.Flow_Label__c, 'Flow label should match');
    }

    @isTest
    static void testGeneratePDF() {
        Flow_Analysis__c testRecord = [SELECT Id FROM Flow_Analysis__c LIMIT 1];

        Test.startTest();
        String pdfBase64 = FlowAnalysisPDFController.generatePDF(testRecord.Id);
        Test.stopTest();

        System.assertNotEquals(null, pdfBase64, 'PDF base64 should not be null');
        System.assert(pdfBase64.length() > 0, 'PDF base64 should have content');
    }

    @isTest
    static void testGeneratePDFWithInvalidId() {
        Test.startTest();
        try {
            FlowAnalysisPDFController.generatePDF('invalid_id');
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Flow Analysis record not found'), 'Should throw record not found error');
        }
        Test.stopTest();
    }

    @isTest
    static void testGeneratePDFWithBlankId() {
        Test.startTest();
        try {
            FlowAnalysisPDFController.generatePDF('');
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Record ID is required'), 'Should throw ID required error');
        }
        Test.stopTest();
    }
}
