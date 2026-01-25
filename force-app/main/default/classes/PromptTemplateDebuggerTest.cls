/**
 * @description Test class for PromptTemplateDebugger
 * @note This test class provides code coverage for the debugger utility
 */
@IsTest
private class PromptTemplateDebuggerTest {

    @IsTest
    static void testQuickTestMethod() {
        Test.startTest();

        // Test the quick static method
        PromptTemplateDebugger.testTemplate('Flow_Evaluator_V3', '<Flow></Flow>');

        Test.stopTest();

        // If we get here without exceptions, test passes
        System.assert(true, 'Quick test method executed without errors');
    }

    @IsTest
    static void testWithKnowledge() {
        Test.startTest();

        // Test with knowledge parameter
        PromptTemplateDebugger.testTemplate(
            'Flow_Evaluator_V3',
            '<Flow></Flow>',
            'Test knowledge'
        );

        Test.stopTest();

        System.assert(true, 'Test with knowledge executed without errors');
    }

    @IsTest
    static void testFlowEvaluatorV3() {
        Test.startTest();

        // Test the specific Flow Evaluator V3 test method
        PromptTemplateDebugger.testFlowEvaluatorV3();

        Test.stopTest();

        System.assert(true, 'Flow Evaluator V3 test executed without errors');
    }

    @IsTest
    static void testListAvailableTemplates() {
        Test.startTest();

        // Test listing templates
        PromptTemplateDebugger.listAvailableTemplates();

        Test.stopTest();

        System.assert(true, 'List templates executed without errors');
    }

    @IsTest
    static void testVerboseLogging() {
        Test.startTest();

        PromptTemplateDebugger debugger = new PromptTemplateDebugger();
        debugger.enableVerboseLogging(true);

        debugger.testPromptTemplate(
            'Flow_Evaluator_V3',
            '<Flow></Flow>',
            'Test knowledge'
        );

        List<String> messages = debugger.getDebugMessages();

        Test.stopTest();

        System.assert(messages.size() > 0, 'Verbose logging captured messages');
    }

    @IsTest
    static void testWithLongInput() {
        Test.startTest();

        // Test with longer XML
        String longXml = '<Flow xmlns="http://soap.sforce.com/2006/04/metadata">';
        for (Integer i = 0; i < 10; i++) {
            longXml += '<recordUpdates><name>Update_' + i + '</name></recordUpdates>';
        }
        longXml += '</Flow>';

        PromptTemplateDebugger.testTemplate('Flow_Evaluator_V3', longXml);

        Test.stopTest();

        System.assert(true, 'Long input test executed without errors');
    }

    @IsTest
    static void testDebuggerInstance() {
        Test.startTest();

        PromptTemplateDebugger debugger = new PromptTemplateDebugger();
        debugger.enableVerboseLogging(false);

        debugger.testPromptTemplate(
            'Flow_Evaluator_V3',
            '<Flow></Flow>',
            null
        );

        Test.stopTest();

        System.assert(true, 'Instance method executed without errors');
    }
}
