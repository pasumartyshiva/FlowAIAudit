/**
 * @description Comprehensive test class for FlowAnalysisPDFController
 */
@isTest
private class FlowAnalysisPDFControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create test Flow Analysis record with JSON report
        Flow_Analysis__c testAnalysis = new Flow_Analysis__c(
            Flow_API_Name__c = 'Test_Flow',
            Flow_Label__c = 'Test Flow',
            Flow_Version__c = 1,
            Status__c = 'Pass',
            Overall_Score__c = 85,
            Analysis_Report__c = '{"overallScore": 85, "overallStatus": "Pass", "categories": [{"number": 1, "name": "Documentation", "status": "Compliant", "analysis": "Well documented"}], "strengths": ["Good naming"], "priorities": {"mustFix": ["Fix error handling"], "shouldFix": ["Add null checks"], "consider": ["Refactor loops"]}}',
            Last_Analyzed__c = System.now()
        );
        insert testAnalysis;
        
        // Create a second record with HTML report
        Flow_Analysis__c htmlAnalysis = new Flow_Analysis__c(
            Flow_API_Name__c = 'HTML_Flow',
            Flow_Label__c = 'HTML Flow',
            Flow_Version__c = 1,
            Status__c = 'Needs Work',
            Overall_Score__c = 55,
            Analysis_Report__c = '<h2>HTML Report</h2><p>This is already HTML.</p>',
            Last_Analyzed__c = System.now()
        );
        insert htmlAnalysis;
    }

    @isTest
    static void testControllerConstructor() {
        Flow_Analysis__c testRecord = [SELECT Id FROM Flow_Analysis__c WHERE Flow_API_Name__c = 'Test_Flow' LIMIT 1];

        Test.startTest();
        PageReference pageRef = Page.FlowAnalysisPDF;
        pageRef.getParameters().put('id', testRecord.Id);
        Test.setCurrentPage(pageRef);

        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        Test.stopTest();

        System.assertNotEquals(null, controller.flowAnalysis, 'Flow Analysis should be loaded');
        System.assertEquals('Test Flow', controller.flowAnalysis.Flow_Label__c, 'Flow label should match');
        System.assertNotEquals(null, controller.formattedReport, 'Formatted report should be generated');
    }

    @isTest
    static void testControllerWithNoId() {
        Test.startTest();
        PageReference pageRef = Page.FlowAnalysisPDF;
        Test.setCurrentPage(pageRef);

        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        Test.stopTest();

        System.assertEquals(null, controller.flowAnalysis, 'Flow Analysis should be null when no ID');
    }

    @isTest
    static void testControllerWithInvalidId() {
        Test.startTest();
        PageReference pageRef = Page.FlowAnalysisPDF;
        pageRef.getParameters().put('id', '001000000000000AAA');
        Test.setCurrentPage(pageRef);

        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        Test.stopTest();

        // Should handle exception gracefully
        System.assertEquals(null, controller.flowAnalysis, 'Flow Analysis should be null for invalid ID');
    }

    @isTest
    static void testGeneratePDF() {
        Flow_Analysis__c testRecord = [SELECT Id FROM Flow_Analysis__c WHERE Flow_API_Name__c = 'Test_Flow' LIMIT 1];

        Test.startTest();
        String pdfBase64 = FlowAnalysisPDFController.generatePDF(testRecord.Id);
        Test.stopTest();

        System.assertNotEquals(null, pdfBase64, 'PDF base64 should not be null');
        System.assert(pdfBase64.length() > 0, 'PDF base64 should have content');
    }

    @isTest
    static void testGeneratePDFWithInvalidId() {
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            FlowAnalysisPDFController.generatePDF('a0B000000000000AAA');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assertNotEquals(null, e.getMessage(), 'Should have error message');
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should throw exception for invalid ID');
    }

    @isTest
    static void testGeneratePDFWithBlankId() {
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            FlowAnalysisPDFController.generatePDF('');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assertNotEquals(null, e.getMessage(), 'Should have error message');
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should throw exception for blank ID');
    }

    @isTest
    static void testFormatAnalysisReport_EmptyReport() {
        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        
        Test.startTest();
        String result = controller.formatAnalysisReport('');
        Test.stopTest();
        
        System.assert(result.contains('No analysis report'), 'Should show no report message');
    }

    @isTest
    static void testFormatAnalysisReport_NullReport() {
        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        
        Test.startTest();
        String result = controller.formatAnalysisReport(null);
        Test.stopTest();
        
        System.assert(result.contains('No analysis report'), 'Should show no report message');
    }

    @isTest
    static void testFormatAnalysisReport_PlainText() {
        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        
        Test.startTest();
        String result = controller.formatAnalysisReport('This is plain text content');
        Test.stopTest();
        
        System.assert(result.contains('pre-wrap'), 'Should wrap in pre-wrap div');
    }

    @isTest
    static void testFormatAnalysisReport_HtmlContent() {
        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        
        Test.startTest();
        String result = controller.formatAnalysisReport('<div>HTML content</div>');
        Test.stopTest();
        
        System.assert(result.contains('HTML content'), 'Should return HTML as-is');
    }

    @isTest
    static void testFormatAnalysisReport_JsonWithCodeBlock() {
        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        String jsonInBlock = '```json\n{"overallScore": 75, "overallStatus": "Pass"}\n```';
        
        Test.startTest();
        String result = controller.formatAnalysisReport(jsonInBlock);
        Test.stopTest();
        
        System.assert(result.contains('75'), 'Should parse score from code block');
    }

    @isTest
    static void testDecodeHtmlEntities() {
        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        
        Test.startTest();
        String result = controller.decodeHtmlEntities('&quot;test&quot; &amp; &apos;more&apos; &lt;tag&gt;');
        Test.stopTest();
        
        System.assert(result.contains('"test"'), 'Should decode quotes');
        System.assert(result.contains('&'), 'Should decode ampersand');
        System.assert(result.contains('<tag>'), 'Should decode angle brackets');
    }

    @isTest
    static void testDecodeHtmlEntities_NumericEntities() {
        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        
        Test.startTest();
        String result = controller.decodeHtmlEntities('&#39;apostrophe&#39; &#34;quote&#34;');
        Test.stopTest();
        
        System.assert(result.contains('\'apostrophe\''), 'Should decode numeric apostrophe');
        System.assert(result.contains('"quote"'), 'Should decode numeric quote');
    }

    @isTest
    static void testDecodeHtmlEntities_Null() {
        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        
        Test.startTest();
        String result = controller.decodeHtmlEntities(null);
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should return null for null input');
    }

    @isTest
    static void testExtractJsonFromText_DirectJson() {
        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        
        Test.startTest();
        String result = controller.extractJsonFromText('{"status": "Pass"}');
        Test.stopTest();
        
        System.assert(result.startsWith('{'), 'Should extract JSON starting with brace');
    }

    @isTest
    static void testExtractJsonFromText_JsonInText() {
        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        
        Test.startTest();
        String result = controller.extractJsonFromText('Some text before {"status": "Pass"} and after');
        Test.stopTest();
        
        System.assert(result.contains('"status"'), 'Should extract embedded JSON');
    }

    @isTest
    static void testExtractJsonFromText_Null() {
        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        
        Test.startTest();
        String result = controller.extractJsonFromText(null);
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should return null for null input');
    }

    @isTest
    static void testExtractJsonFromText_NoJson() {
        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        
        Test.startTest();
        String result = controller.extractJsonFromText('No JSON here');
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should return null when no JSON found');
    }

    @isTest
    static void testGenerateHtmlFromJson_CompleteData() {
        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        
        Map<String, Object> jsonData = new Map<String, Object>{
            'overallScore' => 85,
            'overallStatus' => 'Pass',
            'categories' => new List<Object>{
                new Map<String, Object>{
                    'number' => 1,
                    'name' => 'Documentation',
                    'icon' => '📝',
                    'status' => 'Compliant',
                    'analysis' => 'Well documented',
                    'explanation' => 'All elements named properly',
                    'recommendation' => 'Continue good practices',
                    'details' => new List<Object>{
                        new Map<String, Object>{
                            'heading' => 'Finding',
                            'content' => 'Good naming conventions'
                        }
                    }
                }
            },
            'strengths' => new List<Object>{'Good error handling', 'Proper bulkification'},
            'priorities' => new Map<String, Object>{
                'mustFix' => new List<Object>{'Critical issue 1'},
                'shouldFix' => new List<Object>{'Important issue 1'},
                'consider' => new List<Object>{'Nice to have 1'}
            },
            'summaryTable' => new List<Object>{
                new Map<String, Object>{
                    'area' => 'Error Handling',
                    'status' => 'Pass',
                    'fix' => 'None needed'
                }
            },
            'findings' => new List<Object>{
                new Map<String, Object>{
                    'category' => 'Performance',
                    'severity' => 'Medium',
                    'issue' => 'Loop optimization needed',
                    'recommendation' => 'Refactor loops'
                }
            },
            'summary' => 'Overall good flow',
            'risks' => new List<Object>{'Minor risk 1'}
        };
        
        Test.startTest();
        String result = controller.generateHtmlFromJson(jsonData);
        Test.stopTest();
        
        System.assert(result.contains('85'), 'Should include score');
        System.assert(result.contains('Documentation'), 'Should include category name');
        System.assert(result.contains('Must Fix'), 'Should include must fix section');
        System.assert(result.contains('Strengths'), 'Should include strengths section');
    }

    @isTest
    static void testGenerateHtmlFromJson_PartialStatus() {
        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        
        Map<String, Object> jsonData = new Map<String, Object>{
            'score' => 55.7,
            'status' => 'Partial'
        };
        
        Test.startTest();
        String result = controller.generateHtmlFromJson(jsonData);
        Test.stopTest();
        
        System.assert(result.contains('56'), 'Should round score to 56');
        System.assert(result.contains('NEEDS WORK'), 'Should map Partial to NEEDS WORK');
    }

    @isTest
    static void testGetStatusColor() {
        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        
        Test.startTest();
        System.assertEquals('#2e844a', controller.getStatusColor('Pass'), 'Pass should be green');
        System.assertEquals('#2e844a', controller.getStatusColor('Compliant'), 'Compliant should be green');
        System.assertEquals('#f49756', controller.getStatusColor('Partial'), 'Partial should be orange');
        System.assertEquals('#f49756', controller.getStatusColor('Needs Work'), 'Needs Work should be orange');
        System.assertEquals('#c23934', controller.getStatusColor('Fail'), 'Fail should be red');
        System.assertEquals('#c23934', controller.getStatusColor('Critical'), 'Critical should be red');
        System.assertEquals('#17a2b8', controller.getStatusColor('Minor'), 'Minor should be teal');
        System.assertEquals('#6c757d', controller.getStatusColor('N/A'), 'N/A should be gray');
        System.assertEquals('#666', controller.getStatusColor(null), 'Null should be default gray');
        System.assertEquals('#666', controller.getStatusColor('Unknown'), 'Unknown should be default');
        Test.stopTest();
    }

    @isTest
    static void testGetDisplayStatus() {
        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        
        Test.startTest();
        System.assertEquals('NEEDS WORK', controller.getDisplayStatus('Partial'), 'Partial should become NEEDS WORK');
        System.assertEquals('PASS', controller.getDisplayStatus('Pass'), 'Pass should be uppercase');
        System.assertEquals('FAIL', controller.getDisplayStatus('Fail'), 'Fail should be uppercase');
        System.assertEquals('', controller.getDisplayStatus(null), 'Null should return empty');
        Test.stopTest();
    }

    @isTest
    static void testGetStatusClass() {
        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        
        Test.startTest();
        System.assertEquals('compliant', controller.getStatusClass('Pass'), 'Pass should be compliant');
        System.assertEquals('compliant', controller.getStatusClass('Compliant'), 'Compliant should be compliant');
        System.assertEquals('partial', controller.getStatusClass('Partial'), 'Partial should be partial');
        System.assertEquals('partial', controller.getStatusClass('Needs Work'), 'Needs Work should be partial');
        System.assertEquals('issue', controller.getStatusClass('Fail'), 'Fail should be issue');
        System.assertEquals('issue', controller.getStatusClass('Issue'), 'Issue should be issue');
        System.assertEquals('partial', controller.getStatusClass(null), 'Null should default to partial');
        System.assertEquals('partial', controller.getStatusClass('Unknown'), 'Unknown should default to partial');
        Test.stopTest();
    }

    @isTest
    static void testGetSeverityColor() {
        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        
        Test.startTest();
        System.assertEquals('#c23934', controller.getSeverityColor('High'), 'High should be red');
        System.assertEquals('#f49756', controller.getSeverityColor('Medium'), 'Medium should be orange');
        System.assertEquals('#2e844a', controller.getSeverityColor('Low'), 'Low should be green');
        System.assertEquals('#666', controller.getSeverityColor(null), 'Null should be default');
        System.assertEquals('#666', controller.getSeverityColor('Unknown'), 'Unknown should be default');
        Test.stopTest();
    }

    @isTest
    static void testControllerWithHtmlReport() {
        Flow_Analysis__c testRecord = [SELECT Id FROM Flow_Analysis__c WHERE Flow_API_Name__c = 'HTML_Flow' LIMIT 1];

        Test.startTest();
        PageReference pageRef = Page.FlowAnalysisPDF;
        pageRef.getParameters().put('id', testRecord.Id);
        Test.setCurrentPage(pageRef);

        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        Test.stopTest();

        System.assertNotEquals(null, controller.formattedReport, 'Should have formatted report');
        System.assert(controller.formattedReport.contains('HTML Report'), 'Should contain HTML content');
    }

    @isTest
    static void testFormatAnalysisReport_MalformedJson() {
        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        
        Test.startTest();
        String result = controller.formatAnalysisReport('{invalid json}');
        Test.stopTest();
        
        // Should handle gracefully with pre-wrap
        System.assert(result.contains('monospace'), 'Should fall back to monospace for malformed JSON');
    }

    @isTest
    static void testGenerateHtmlFromJson_EmptyCategories() {
        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        
        Map<String, Object> jsonData = new Map<String, Object>{
            'overallScore' => 90,
            'categories' => new List<Object>()
        };
        
        Test.startTest();
        String result = controller.generateHtmlFromJson(jsonData);
        Test.stopTest();
        
        System.assert(result.contains('90'), 'Should include score even with empty categories');
    }

    @isTest
    static void testGenerateHtmlFromJson_DecimalScore() {
        FlowAnalysisPDFController controller = new FlowAnalysisPDFController();
        
        Map<String, Object> jsonData = new Map<String, Object>{
            'overallScore' => 73.8
        };
        
        Test.startTest();
        String result = controller.generateHtmlFromJson(jsonData);
        Test.stopTest();
        
        System.assert(result.contains('74'), 'Should round 73.8 to 74');
    }
}