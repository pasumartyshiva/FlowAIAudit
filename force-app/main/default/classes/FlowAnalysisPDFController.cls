/**
 * @description Controller for FlowAnalysisPDF Visualforce page
 * Handles PDF rendering and download for flow analysis reports
 */
public with sharing class FlowAnalysisPDFController {

    public Flow_Analysis__c flowAnalysis { get; set; }

    /**
     * @description Constructor - loads the Flow Analysis record
     */
    public FlowAnalysisPDFController() {
        String recordId = ApexPages.currentPage().getParameters().get('id');

        if (String.isNotBlank(recordId)) {
            try {
                flowAnalysis = [
                    SELECT Id, Name, Flow_Label__c, Flow_API_Name__c, Flow_Version__c,
                           Status__c, Overall_Score__c, Analysis_Report__c, Last_Analyzed__c,
                           Model_Name__c, Tokens_Used__c
                    FROM Flow_Analysis__c
                    WHERE Id = :recordId
                    LIMIT 1
                ];
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(
                    ApexPages.Severity.ERROR,
                    'Error loading Flow Analysis record: ' + e.getMessage()
                ));
            }
        }
    }


    /**
     * @description Generates and returns PDF blob for download
     * Called from LWC via Apex method
     * @param recordId The Flow Analysis record ID
     * @return Base64 encoded PDF content
     */
    @AuraEnabled
    public static String generatePDF(String recordId) {
        try {
            if (String.isBlank(recordId)) {
                throw new AuraHandledException('Record ID is required');
            }

            // Verify record exists
            List<Flow_Analysis__c> records = [
                SELECT Id, Flow_Label__c
                FROM Flow_Analysis__c
                WHERE Id = :recordId
                LIMIT 1
            ];

            if (records.isEmpty()) {
                throw new AuraHandledException('Flow Analysis record not found');
            }

            // Generate PDF using Visualforce page
            PageReference pdfPage = Page.FlowAnalysisPDF;
            pdfPage.getParameters().put('id', recordId);

            Blob pdfBlob;

            // Use getContentAsPDF() in production, test mode returns empty blob
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Test PDF Content');
            } else {
                pdfBlob = pdfPage.getContentAsPDF();
            }

            // Return base64 encoded PDF
            return EncodingUtil.base64Encode(pdfBlob);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error generating PDF: ' + e.getMessage());
            throw new AuraHandledException('Error generating PDF: ' + e.getMessage());
        }
    }
}
