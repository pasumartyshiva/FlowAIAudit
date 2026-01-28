@IsTest
private class FlowAnalysisServiceTest {

    @IsTest
    static void testAnalyzeFlowMainEntry() {
        // Tests the public entry point.
        // Note: In a test context without mocks, callPromptTemplate throws an exception.
        // This confirms the method handles errors gracefully and returns a record.
        Test.startTest();
        Flow_Analysis__c result = FlowAnalysisService.analyzeFlow(
            'Test_Flow_API', 
            '<Flow xmlns="http://soap.sforce.com/2006/04/metadata"></Flow>', 
            'Test Flow Label', 
            1
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Service should return a Flow_Analysis__c object');
        System.assertEquals('Test_Flow_API', result.Flow_API_Name__c, 'API Name should match input');
        // Since we can't mock Einstein natively, we expect it to hit the catch block or return error status
        System.assertNotEquals(null, result.Status__c); 
    }

    @IsTest
    static void testParseDeepAnalysisLogic() {
        // We build the JSON using Maps to ensure syntax is perfect
        Map<String, Object> jsonMap = new Map<String, Object>{
            'overallScore' => 95,
            'overallStatus' => 'Pass',
            'summary' => 'Excellent bulkification.',
            'categories' => new List<Object>{
                new Map<String, Object>{
                    'name' => 'Bulkification',
                    'status' => 'Compliant',
                    'icon' => '✅',
                    'analysis' => 'Loop logic is sound.'
                }
            }
        };

        String validJson = JSON.serialize(jsonMap);
        
        // Wrap in markdown to test the extraction logic
        String aiResponse = 'Here is the report:\n```json\n' + validJson + '\n```';

        Flow_Analysis__c analysis = new Flow_Analysis__c();

        Test.startTest();
        // Call the private parsing logic directly via @TestVisible
        FlowAnalysisService.parseAndUpdateAnalysis(analysis, aiResponse);
        Test.stopTest();

        // 1. Assert Status and Score parsing
        System.assertEquals('Pass', analysis.Status__c, 'Status should be parsed from JSON');
        System.assertEquals(95, analysis.Overall_Score__c, 'Score should be parsed from JSON');
        
        // 2. Check for JSON content
        System.assert(analysis.Analysis_Report__c.contains('"overallScore":95'), 'Report should contain the raw JSON data');
    }

    @IsTest
    static void testParseLegacyFormat() {
        // Tests backward compatibility with older prompt versions (Findings array)
        Map<String, Object> oldJsonMap = new Map<String, Object>{
            'score' => 40,
            'status' => 'Needs Work',
            'findings' => new List<Object>{
                new Map<String, Object>{
                    'area' => 'Hardcoding', 
                    'severity' => 'High', 
                    'explanation' => 'IDs found'
                }
            }
        };
        
        Flow_Analysis__c analysis = new Flow_Analysis__c();
        
        Test.startTest();
        FlowAnalysisService.parseAndUpdateAnalysis(analysis, JSON.serialize(oldJsonMap));
        Test.stopTest();

        System.assertEquals('Needs Work', analysis.Status__c);
        System.assertEquals(40, analysis.Overall_Score__c);
        // Verify raw JSON is stored
        System.assert(analysis.Analysis_Report__c.contains('Hardcoding'), 'Report should contain findings');
    }

    @IsTest
    static void testMathAndColors() {
        // Test utility helper methods logic
        Test.startTest();
        
        // Color Mapping
        System.assertEquals('#2e844a', FlowAnalysisService.getStatusColorForHtml('Pass'));
        System.assertEquals('#c23934', FlowAnalysisService.getStatusColorForHtml('Fail'));
        System.assertEquals('#f49756', FlowAnalysisService.getSeverityColorForHtml('Medium'));
        
        // Category Scoring Algorithm
        Map<String, Object> categoryData = new Map<String, Object>{
            'categories' => new List<Object>{
                new Map<String, Object>{'status' => 'Compliant'}, // 100 points
                new Map<String, Object>{'status' => 'Issue'}      // 0 points
            }
        };
        // (100 + 0) / 2 = 50
        Decimal score = FlowAnalysisService.calculateScoreFromCategories(categoryData);
        System.assertEquals(50, score, 'Score calculation logic is incorrect');

        Test.stopTest();
    }
    
    @IsTest
    static void testTextFallbackLogic() {
        Test.startTest();
        
        // 1. Test Text Status Extraction
        String statusPass = FlowAnalysisService.extractStatusFromText('This flow is an overall pass and compliant.');
        String statusFail = FlowAnalysisService.extractStatusFromText('This flow is an overall fail.');
        String statusHeuristic = FlowAnalysisService.extractStatusFromText('issue issue issue issue issue issue'); // >5 issues = Fail

        // 2. Test Score Extraction (FIXED INPUTS)
        // Regex expects "score:" or "score " followed by numbers
        Decimal score1 = FlowAnalysisService.extractScoreFromText('Score: 90%');
        Decimal score2 = FlowAnalysisService.extractScoreFromText('Overall Score 85');
        
        // 3. Test HTML conversion (used in catch blocks)
        String html = FlowAnalysisService.convertTextToHtml('Simple Line\nLine 2');
        String fallback = FlowAnalysisService.generateFallbackResponse('Test Error');
        
        Test.stopTest();

        // Assertions
        System.assertEquals('Pass', statusPass);
        System.assertEquals('Fail', statusFail);
        System.assertEquals('Fail', statusHeuristic);
        
        System.assertEquals(90, score1, 'Regex should match "Score: 90%"');
        System.assertEquals(85, score2, 'Regex should match "Overall Score 85"');
        
        System.assert(html.contains('<br/>'));
        System.assert(fallback.contains('LLM CONFIGURATION REQUIRED'));
    }
    
    @IsTest
    static void testCalculateStatusFromCategories() {
        Test.startTest();

        // SCENARIO 1: Test Category Logic (No Score provided)
        // 3 Compliant, 1 Issue = 75% Compliant = Pass
        Map<String, Object> passMap = new Map<String, Object>{
            'categories' => new List<Object>{
                new Map<String, Object>{'status' => 'Compliant'},
                new Map<String, Object>{'status' => 'Pass'},
                new Map<String, Object>{'status' => 'Compliant'},
                new Map<String, Object>{'status' => 'Issue'}
            }
        };
        String resultPass = FlowAnalysisService.calculateStatusFromCategories(passMap);
        System.assertEquals('Pass', resultPass, '3/4 Compliant should result in Pass');

        // SCENARIO 2: Test Category Logic - Partial Threshold
        // 2 Compliant, 2 Issue = 50% Compliant = Partial
        Map<String, Object> partialMap = new Map<String, Object>{
            'categories' => new List<Object>{
                new Map<String, Object>{'status' => 'Compliant'},
                new Map<String, Object>{'status' => 'Compliant'},
                new Map<String, Object>{'status' => 'Fail'},
                new Map<String, Object>{'status' => 'Issue'}
            }
        };
        String resultPartial = FlowAnalysisService.calculateStatusFromCategories(partialMap);
        System.assertEquals('Partial', resultPartial, '50% Compliant should result in Partial');

        // SCENARIO 3: Test Category Logic - Fail Threshold
        // 1 Compliant, 3 Issue = 25% Compliant = Fail
        Map<String, Object> failMap = new Map<String, Object>{
            'categories' => new List<Object>{
                new Map<String, Object>{'status' => 'Compliant'},
                new Map<String, Object>{'status' => 'Fail'},
                new Map<String, Object>{'status' => 'Fail'},
                new Map<String, Object>{'status' => 'Issue'}
            }
        };
        String resultFail = FlowAnalysisService.calculateStatusFromCategories(failMap);
        System.assertEquals('Fail', resultFail, '<50% Compliant should result in Fail');

        // SCENARIO 4: Test Findings Logic (Legacy/Prompt Fallback)
        // This branch is taken if 'findings' exist and 'score' is null
        Map<String, Object> findingsMap = new Map<String, Object>{
            'findings' => new List<Object>{
                new Map<String, Object>{'severity' => 'High'},
                new Map<String, Object>{'severity' => 'High'},
                new Map<String, Object>{'severity' => 'High'}
            }
        };
        String resultFindings = FlowAnalysisService.calculateStatusFromCategories(findingsMap);
        System.assertEquals('Fail', resultFindings, '3 High severity findings should result in Fail');

        // SCENARIO 5: Integration Check - parseAndUpdateAnalysis without Score
        // This ensures the main parser actually falls back to this method
        Map<String, Object> jsonNoScore = new Map<String, Object>{
            'categories' => new List<Object>{
                new Map<String, Object>{'status' => 'Compliant'}, // 100%
                new Map<String, Object>{'status' => 'Compliant'}
            }
        };
        Flow_Analysis__c analysis = new Flow_Analysis__c();
        FlowAnalysisService.parseAndUpdateAnalysis(analysis, JSON.serialize(jsonNoScore));
        
        System.assertEquals('Pass', analysis.Status__c, 'Parser should fallback to category logic when score is missing');
        // It should also calculate a score from the categories (100 in this case)
        System.assertEquals(100, analysis.Overall_Score__c, 'Parser should calculate implicit score from categories');

        Test.stopTest();
    }

    @IsTest
    static void testParseAndUpdateWithExceptions() {
        // This covers the catch blocks inside parseAndUpdateAnalysis
        Flow_Analysis__c analysis = new Flow_Analysis__c();
        
        Test.startTest();
        // Sending invalid JSON (missing bracket) triggers the JSON parser exception
        // This forces the "catch" block in parseAndUpdateAnalysis to run
        FlowAnalysisService.parseAndUpdateAnalysis(analysis, '{ "invalid_json": '); 
        Test.stopTest();
        
        System.assertEquals('Partial', analysis.Status__c, 'Should fallback to Partial on parsing error');
    }
}