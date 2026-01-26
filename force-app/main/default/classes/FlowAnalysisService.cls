/**
 * @description Core service class for analyzing Salesforce Flows using AI
 * Handles the interaction with the Flow_Evaluator prompt template and parsing results
 */
public with sharing class FlowAnalysisService {

    private static final String PROMPT_TEMPLATE_NAME = 'FlowAIAudit';

    /**
     * @description Analyzes a single flow and returns the analysis record
     * @param flowApiName The API name of the flow to analyze
     * @param flowMetadataXml The flow's XML metadata
     * @param flowLabel The flow's label/name for display
     * @param flowVersion The flow version number
     * @return Flow_Analysis__c record (not yet inserted)
     */
    public static Flow_Analysis__c analyzeFlow(
        String flowApiName,
        String flowMetadataXml,
        String flowLabel,
        Integer flowVersion
    ) {
        Flow_Analysis__c analysis = new Flow_Analysis__c(
            Flow_API_Name__c = flowApiName,
            Flow_Label__c = flowLabel,
            Flow_Version__c = flowVersion,
            Status__c = 'Analyzing',
            Last_Analyzed__c = System.now(),
            Is_Active__c = true
        );

        try {
            // Call the AI prompt template
            Map<String, Object> promptInputs = new Map<String, Object>{
                'MetadataXMLVar' => flowMetadataXml,
                'KnowledgeText' => getAssessmentFramework()
            };

            // Call the prompt template (this is a placeholder - actual implementation depends on your AI setup)
            String aiResponse = callPromptTemplate(PROMPT_TEMPLATE_NAME, promptInputs);

            // Parse the AI response
            parseAndUpdateAnalysis(analysis, aiResponse);

        } catch (Exception e) {
            analysis.Status__c = 'Error';
            analysis.Analysis_Report__c = 'Error during analysis: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, 'Error analyzing flow ' + flowApiName + ': ' + e.getMessage());
        }

        return analysis;
    }

    /**
     * @description Calls the LLM provider (External BYO-LLM or Einstein GPT)
     * Priority: External LLM > Einstein GPT > Fallback error message
     * Falls back to basic analysis if no LLM is available
     */
    private static String callPromptTemplate(String templateName, Map<String, Object> inputs) {
        try {
            // Validate inputs
            String metadataXml = (String)inputs.get('MetadataXMLVar');
            String knowledge = (String)inputs.get('KnowledgeText');

            System.debug(LoggingLevel.INFO, 'Metadata XML length: ' + (metadataXml != null ? metadataXml.length() : 0));
            System.debug(LoggingLevel.INFO, 'Knowledge text length: ' + (knowledge != null ? knowledge.length() : 0));

            if (metadataXml == null || metadataXml.length() == 0) {
                throw new FlowAnalysisException('Metadata XML is empty or null');
            }

            if (knowledge == null || knowledge.length() == 0) {
                throw new FlowAnalysisException('Knowledge text is empty or null');
            }

            // PRIORITY 1: Try Einstein GPT first (no API key needed, uses org license)
            System.debug(LoggingLevel.INFO, 'Attempting Einstein GPT call with template: ' + templateName);

            try {

            // THIS IS THE EXACT CODE THAT WORKED IN THE DIAGNOSTIC TEST
            ConnectApi.EinsteinPromptTemplateGenerationsInput generationInput =
                new ConnectApi.EinsteinPromptTemplateGenerationsInput();

            Map<String, ConnectApi.WrappedValue> params = new Map<String, ConnectApi.WrappedValue>();

            ConnectApi.WrappedValue xmlVal = new ConnectApi.WrappedValue();
            xmlVal.value = metadataXml;
            params.put('Input:MetadataXMLVar', xmlVal);

            ConnectApi.WrappedValue knowledgeVal = new ConnectApi.WrappedValue();
            knowledgeVal.value = knowledge;
            params.put('Input:KnowledgeText', knowledgeVal);

            generationInput.inputParams = params;
            generationInput.isPreview = false;
            generationInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();

            System.debug(LoggingLevel.INFO, 'Calling Einstein LLM API...');

                // Call the prompt template
                ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response =
                    ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('FlowAIAudit', generationInput);

                System.debug(LoggingLevel.INFO, 'Einstein GPT API call completed successfully');

                // Log token usage if available
                if (response != null && response.generations != null && !response.generations.isEmpty()) {
                    ConnectApi.EinsteinLLMGenerationItemOutput generation = response.generations[0];

                    // Try to capture token usage from generation parameters
                    System.debug(LoggingLevel.INFO, 'Generation response: ' + JSON.serializePretty(generation));

                    return generation.text;
                } else {
                    throw new FlowAnalysisException('No response generated from Einstein GPT');
                }

            } catch (Exception einsteinError) {
                // Einstein GPT failed, try External BYO-LLM as fallback
                System.debug(LoggingLevel.WARN, 'Einstein GPT unavailable: ' + einsteinError.getMessage());
                System.debug(LoggingLevel.INFO, 'Attempting fallback to External BYO-LLM (HuggingFace)');

                // PRIORITY 2: Fallback to External BYO-LLM (HuggingFace for demos/prototypes)
                if (ExternalLLMService.isConfigured()) {
                    System.debug(LoggingLevel.INFO, 'Using External BYO-LLM provider as fallback');
                    try {
                        return ExternalLLMService.generateCompletion(metadataXml, knowledge);
                    } catch (Exception externalError) {
                        System.debug(LoggingLevel.ERROR, 'External LLM also failed: ' + externalError.getMessage());
                        // Both failed, return error response
                        String combinedError = 'Einstein GPT: ' + einsteinError.getMessage() +
                                             '; External LLM: ' + externalError.getMessage();
                        return generateFallbackResponse(combinedError);
                    }
                } else {
                    // No fallback available, return Einstein error
                    System.debug(LoggingLevel.ERROR, 'No External LLM configured for fallback');

                    String detailedError = einsteinError.getMessage();
                    if (einsteinError.getTypeName() != null) {
                        detailedError += ' [Type: ' + einsteinError.getTypeName() + ']';
                    }

                    return generateFallbackResponse(detailedError);
                }
            }

        } catch (Exception e) {
            // Catch any other unexpected errors
            System.debug(LoggingLevel.ERROR, 'Unexpected error in callPromptTemplate: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());

            String detailedError = e.getMessage();
            if (e.getTypeName() != null) {
                detailedError += ' [Type: ' + e.getTypeName() + ']';
            }

            return generateFallbackResponse(detailedError);
        }
    }

    /**
     * @description Generates a fallback response when no LLM is available
     * This provides clear guidance to the user about what needs to be configured
     */
    private static String generateFallbackResponse(String errorMessage) {
        // Create a structured text response explaining the issue
        String response = '⚠️ LLM CONFIGURATION REQUIRED\n\n';
        response += 'The flow analysis system is ready, but an LLM provider needs to be configured.\n\n';
        response += 'ERROR: ' + errorMessage + '\n\n';
        response += 'SETUP OPTIONS:\n\n';
        response += '═══════════════════════════════════════════════════════\n';
        response += 'OPTION 1: BYO-LLM (RECOMMENDED - FREE & LICENSE-FREE)\n';
        response += '═══════════════════════════════════════════════════════\n\n';
        response += '1. Get an API Key:\n';
        response += '   • Google Gemini: https://aistudio.google.com/apikey (FREE tier: 1500 req/day)\n';
        response += '   • Anthropic Claude: https://console.anthropic.com/settings/keys\n\n';
        response += '2. Configure Named Credential:\n';
        response += '   • Setup → Named Credentials → Google_Gemini_API or Anthropic_API\n';
        response += '   • Add custom header: "x-goog-api-key" (Google) or "x-api-key" (Anthropic)\n';
        response += '   • Paste your API key as the header value\n\n';
        response += '3. Activate Provider:\n';
        response += '   • Setup → Custom Metadata Types → LLM Configuration → Manage Records\n';
        response += '   • Edit "Google Gemini 1.5 Pro" or "Anthropic Claude 3.5 Sonnet"\n';
        response += '   • Check "Is Active"\n';
        response += '   • Save\n\n';
        response += '💰 Cost: ~$0.35 per 100 flows (Google) or ~$0.50 per 100 flows (Anthropic)\n';
        response += '📚 Full Setup Guide: BYO_LLM_SETUP.md\n\n';
        response += '═══════════════════════════════════════════════════════\n';
        response += 'OPTION 2: EINSTEIN GPT (REQUIRES LICENSE)\n';
        response += '═══════════════════════════════════════════════════════\n\n';
        response += '1. Deploy Prompt Template:\n';
        response += '   sf project deploy start -d force-app/main/default/genAiPromptTemplates\n\n';
        response += '2. Publish in Prompt Builder:\n';
        response += '   • Setup → Prompt Builder → FlowAIAudit → Publish\n\n';
        response += '3. Verify License:\n';
        response += '   • Requires: Einstein 1 Platform license\n\n';
        response += '💰 Cost: Uses org-level Einstein tokens\n';
        response += '📚 Full Setup Guide: AI_INTEGRATION_UPDATE.md\n\n';
        response += '═══════════════════════════════════════════════════════\n\n';
        response += 'Once configured, re-run the analysis to get AI-powered assessments.';

        return response;
    }

    /**
     * @description Parses the AI response and updates the analysis record
     * Expects either HTML or JSON format, or raw text from the LLM
     */
    private static void parseAndUpdateAnalysis(Flow_Analysis__c analysis, String aiResponse) {
        try {
            // Store raw response
            analysis.Raw_Findings__c = aiResponse.length() > 131000 ? aiResponse.substring(0, 131000) : aiResponse;

            // Try to parse as JSON first
            if (aiResponse.trim().startsWith('{')) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(aiResponse);

                // Extract or calculate status
                String status = (String) jsonResponse.get('status');
                if (status == null) {
                    status = calculateStatusFromCategories(jsonResponse);
                }
                analysis.Status__c = status;

                // Extract or calculate score
                Object scoreObj = jsonResponse.get('score');
                if (scoreObj != null) {
                    analysis.Overall_Score__c = scoreObj instanceof Decimal
                        ? (Decimal) scoreObj
                        : Decimal.valueOf(String.valueOf(scoreObj));
                } else {
                    analysis.Overall_Score__c = calculateScoreFromCategories(jsonResponse);
                }

                // Generate HTML report from JSON
                analysis.Analysis_Report__c = generateHtmlReport(jsonResponse);

            } else {
                // It's raw text/markdown from LLM - convert to HTML and store
                analysis.Analysis_Report__c = convertTextToHtml(aiResponse);

                // Try to extract status from text
                analysis.Status__c = extractStatusFromText(aiResponse);
                analysis.Overall_Score__c = extractScoreFromText(aiResponse);
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error parsing AI response: ' + e.getMessage());
            analysis.Analysis_Report__c = convertTextToHtml(aiResponse); // Store as HTML
            analysis.Status__c = 'Needs Work'; // Default to partial if parsing fails
        }
    }

    /**
     * @description Converts plain text/markdown to basic HTML
     */
    private static String convertTextToHtml(String text) {
        if (text == null) return '';

        String html = '<div style="font-family: Arial, sans-serif; padding: 20px; white-space: pre-wrap;">';
        html += text.replaceAll('\\n', '<br/>');
        html += '</div>';
        return html.length() > 131000 ? html.substring(0, 131000) : html;
    }

    /**
     * @description Calculates overall status based on category statuses
     */
    private static String calculateStatusFromCategories(Map<String, Object> jsonResponse) {
        List<Object> categories = (List<Object>) jsonResponse.get('categories');
        if (categories == null || categories.isEmpty()) return 'Needs Work';

        Integer issueCount = 0;
        Integer compliantCount = 0;
        Integer partialCount = 0;

        for (Object catObj : categories) {
            Map<String, Object> category = (Map<String, Object>) catObj;
            String status = (String) category.get('status');
            if (status == 'Issue') issueCount++;
            else if (status == 'Compliant') compliantCount++;
            else partialCount++;
        }

        // If more than 50% are issues, overall is Fail
        if (issueCount > categories.size() / 2) return 'Fail';
        // If more than 80% are compliant, overall is Pass
        if (compliantCount >= categories.size() * 0.8) return 'Pass';
        // Otherwise Needs Work
        return 'Needs Work';
    }

    /**
     * @description Calculates overall score based on category statuses
     */
    private static Decimal calculateScoreFromCategories(Map<String, Object> jsonResponse) {
        List<Object> categories = (List<Object>) jsonResponse.get('categories');
        if (categories == null || categories.isEmpty()) return 50;

        Integer compliantCount = 0;
        Integer partialCount = 0;

        for (Object catObj : categories) {
            Map<String, Object> category = (Map<String, Object>) catObj;
            String status = (String) category.get('status');
            if (status == 'Compliant') compliantCount++;
            else if (status == 'Needs Work') partialCount++;
        }

        // Compliant = 100%, Needs Work = 50%, Issue = 0%
        Decimal totalPoints = (compliantCount * 100) + (partialCount * 50);
        return (totalPoints / categories.size()).setScale(0);
    }

    /**
     * @description Extracts status from plain text response
     */
    private static String extractStatusFromText(String text) {
        if (text == null) return 'Pending';

        String lowerText = text.toLowerCase();

        // Count mentions of compliant/issue/partial
        Integer issueCount = lowerText.countMatches('issue');
        Integer compliantCount = lowerText.countMatches('compliant');
        Integer partialCount = lowerText.countMatches('partial');

        // Look for explicit overall status
        if (lowerText.contains('overall') && lowerText.contains('pass')) return 'Pass';
        if (lowerText.contains('overall') && lowerText.contains('fail')) return 'Fail';

        // Heuristic based on counts
        if (issueCount > 5) return 'Fail';
        if (compliantCount > 8) return 'Pass';
        return 'Needs Work';
    }

    /**
     * @description Extracts score from plain text response
     */
    private static Decimal extractScoreFromText(String text) {
        if (text == null) return null;

        // Look for patterns like "score: 85%" or "overall score: 85"
        // Convert to lowercase for case-insensitive matching
        String lowerText = text.toLowerCase();
        Pattern scorePattern = Pattern.compile('(?:overall\\s+)?score[:\\s]+([0-9]+\\.?[0-9]*)%?');
        Matcher matcher = scorePattern.matcher(lowerText);
        if (matcher.find()) {
            String scoreStr = matcher.group(1);
            try {
                return Decimal.valueOf(scoreStr);
            } catch (Exception e) {
                System.debug('Could not parse score: ' + scoreStr);
            }
        }
        return null;
    }

    /**
     * @description Generates HTML report from JSON response with scorecard
     */
    private static String generateHtmlReport(Map<String, Object> jsonResponse) {
        String html = '<div class="flow-analysis-report" style="font-family: Arial, sans-serif; padding: 20px;">';
        html += '<h1 style="color: #032e61; border-bottom: 3px solid #0176d3; padding-bottom: 10px;">Flow Analysis Report</h1>';

        // Add overall status and score
        String status = (String) jsonResponse.get('status');
        Object scoreObj = jsonResponse.get('score');

        html += '<div style="background: #f3f3f3; padding: 15px; margin: 20px 0; border-radius: 5px;">';
        if (status != null) {
            String statusColor = status == 'Pass' ? '#2e844a' : (status == 'Fail' ? '#c23934' : '#f49756');
            html += '<div style="display: inline-block; background: ' + statusColor + '; color: white; padding: 8px 16px; border-radius: 4px; font-weight: bold; margin-right: 15px;">';
            html += status.toUpperCase();
            html += '</div>';
        }
        if (scoreObj != null) {
            html += '<span style="font-size: 24px; font-weight: bold; color: #032e61;">Overall Score: ' + scoreObj + '%</span>';
        }
        html += '</div>';

        // Add scorecard table
        List<Object> categories = (List<Object>) jsonResponse.get('categories');
        if (categories != null && !categories.isEmpty()) {
            html += '<h2 style="color: #032e61; margin-top: 30px;">Scorecard by Category</h2>';
            html += '<table style="width: 100%; border-collapse: collapse; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">';
            html += '<thead><tr style="background: #0176d3; color: white;">';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Category</th>';
            html += '<th style="padding: 12px; text-align: center; border: 1px solid #ddd; width: 120px;">Status</th>';
            html += '<th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Key Findings</th>';
            html += '</tr></thead><tbody>';

            for (Object catObj : categories) {
                Map<String, Object> category = (Map<String, Object>) catObj;
                String catName = (String) category.get('name');
                String catStatus = (String) category.get('status');
                String catFindings = (String) category.get('findings');

                String rowColor = catStatus == 'Compliant' ? '#d4edda' : (catStatus == 'Issue' ? '#f8d7da' : '#fff3cd');
                html += '<tr style="background: ' + rowColor + ';">';
                html += '<td style="padding: 12px; border: 1px solid #ddd; font-weight: bold;">' + catName + '</td>';
                html += '<td style="padding: 12px; border: 1px solid #ddd; text-align: center;">' + catStatus + '</td>';
                html += '<td style="padding: 12px; border: 1px solid #ddd;">' + (catFindings != null ? catFindings : 'N/A') + '</td>';
                html += '</tr>';
            }
            html += '</tbody></table>';
        }

        // Add detailed findings
        List<Object> findings = (List<Object>) jsonResponse.get('findings');
        if (findings != null && !findings.isEmpty()) {
            html += '<h2 style="color: #032e61; margin-top: 30px;">Detailed Findings & Recommendations</h2>';
            html += '<div style="background: white; padding: 15px; border-left: 4px solid #0176d3; margin: 15px 0;">';
            for (Integer i = 0; i < findings.size(); i++) {
                Map<String, Object> finding = (Map<String, Object>) findings[i];

                // Handle both "area" and "category" keys (LLM may use either)
                String area = (String) finding.get('area');
                if (area == null) {
                    area = (String) finding.get('category');
                }

                // Handle both "explanation" and "issue" keys
                String explanation = (String) finding.get('explanation');
                if (explanation == null) {
                    explanation = (String) finding.get('issue');
                }

                String recommendation = (String) finding.get('recommendation');

                // Handle both "severity" for display
                String severity = (String) finding.get('severity');

                html += '<div style="margin-bottom: 20px; padding-bottom: 20px; border-bottom: 1px solid #e5e5e5;">';

                // Add severity badge if present
                String headerHtml = '<h3 style="color: #0176d3; margin-top: 0;">' + (i+1) + '. ';
                if (area != null && area != 'null') {
                    headerHtml += area;
                } else {
                    headerHtml += 'Finding ' + (i+1);
                }

                if (severity != null) {
                    String severityColor = severity == 'High' ? '#c23934' : (severity == 'Medium' ? '#f49756' : '#2e844a');
                    headerHtml += ' <span style="display: inline-block; background: ' + severityColor + '; color: white; padding: 4px 8px; border-radius: 3px; font-size: 12px; margin-left: 10px;">' + severity + '</span>';
                }
                headerHtml += '</h3>';
                html += headerHtml;

                if (explanation != null && explanation != 'null') {
                    html += '<p style="margin: 10px 0;"><strong>Issue:</strong> ' + explanation + '</p>';
                }
                if (recommendation != null && recommendation != 'null') {
                    html += '<p style="margin: 10px 0; padding: 10px; background: #f0f9ff; border-left: 3px solid #0176d3;"><strong>Recommendation:</strong> ' + recommendation + '</p>';
                }
                html += '</div>';
            }
            html += '</div>';
        }

        // Add summary table if present
        String summaryTable = (String) jsonResponse.get('summaryTable');
        if (summaryTable != null) {
            html += '<h2 style="color: #032e61; margin-top: 30px;">Summary Table</h2>';
            html += '<div style="background: white; padding: 15px; margin: 15px 0;">';
            html += summaryTable;
            html += '</div>';
        }

        html += '</div>';
        return html;
    }


    /**
     * @description Returns the comprehensive assessment framework text
     * This includes all 12 best practice categories with detailed criteria
     */
    private static String getAssessmentFramework() {
        return 'Salesforce Flow Review: Consolidated AI Assessment Prompts\n\n' +
            'Instructions for AI Review:\n' +
            'Carefully inspect each uploaded Salesforce Flow\'s metadata, answering every prompt below. For each section:\n' +
            '• Identify compliance or gaps.\n' +
            '• Explain the risk, impact, or reason.\n' +
            '• Give a practical, specific recommendation.\n' +
            '• DO NOT browse the web—rely only on the prompts and flow metadata.\n\n' +

            '1. Documentation, Naming, and Clarity\n' +
            '• Does the flow\'s description clearly explain its business purpose, triggered objects, scope, and integration points?\n' +
            '• Are all elements, variables, and logic blocks named clearly and consistently, following a naming convention?\n' +
            '• Are variables and complex elements documented with their purpose, intent, and any IDs/JIRA links?\n' +
            '• Are comments provided wherever advanced techniques, workarounds, or exceptions are used?\n' +
            'If not, recommend adding/expanding business context, naming, and in-flow documentation.\n\n' +

            '2. Logic Modularity & Reuse (Subflows, Invocable Actions)\n' +
            '• Are repeated tasks, permission elevation, or complex processes abstracted into subflows or invocable Apex actions for reuse?\n' +
            '• Are invocable Apex actions leveraged for data transformation, integration, or calculations not easily handled in Flow?\n' +
            '• Is the number of subflows appropriate (not excessive, not lacking)?\n' +
            'If not, suggest modularizing or consolidating flows using subflows/helpers as appropriate.\n\n' +

            '3. Bulkification & Loop Efficiency\n' +
            '• Is DML/SOQL always executed outside of loops, using batches/collections wherever possible?\n' +
            '• Does the flow use In/Not In operators and/or Transform elements for mass queries/updates rather than looping record-by-record?\n' +
            '• Are DML actions consolidated—e.g., single Update/Create/Delete operations per object wherever possible in a batch?\n' +
            'If not, advise refactoring logic to ensure governor limits won\'t be exceeded and performance is optimal for scale.\n\n' +

            '4. Null/Empty Checks and Defensive Design\n' +
            '• After every Get Records or Lookup, is there a Decision to check for null/empty results before using them?\n' +
            '• Are outputs from invocable actions/components and collections confirmed not empty before use?\n' +
            'If unchecked, direct user to add such validation for reliability.\n\n' +

            '5. Hard Coding, Data-Driven Design & Metadata\n' +
            '• Are hardcoded IDs (Owner, Queue, Group, RecordType, etc), business logic, or frequently changed values avoided?\n' +
            '• Is logic/criteria that may change (IDs, key thresholds, text) kept in Custom Metadata, Custom Settings, or Labels?\n' +
            'If found, replace with metadata, settings, or labels and use Get Records for entity lookups by DeveloperName.\n' +
            '• "Definition of Hard Coding": For this analysis, a "hardcoded value" includes not only record IDs but also any static string literals for picklist values (e.g., \'Active\', \'Vest\', \'Completed\'). These should be flagged with a recommendation to use Custom Labels or Custom Metadata.\n' +
            '• "Definition of Robust Error Handling": A flow is only considered to have robust error handling if every single data element (Get, Create, Update) has a fault path connected to a logging mechanism. The absence of even one fault path constitutes an "Issue."\n\n' +

            '6. Error Handling, Fault Paths, and Logging\n' +
            '• Are fault paths/handlers implemented for every DML, Action, and Subflow—for both admin alerts/logging and user feedback?\n' +
            '• Is there a centralized/error-handling subflow or integration with a logging framework?\n' +
            'If missing or unclear, require robust error handling and notification strategy.\n\n' +

            '7. Security, Flow Context, and Permissions\n' +
            'First, identify the flow type from the metadata (e.g., Screen Flow, Record-Triggered Flow, Autolaunched Flow).\n' +
            'If a Screen Flow:\n' +
            '• Is the run context explicitly set to "User" or "System," and is that choice appropriate for the actions being performed?\n' +
            '• Is data exposure on screens tightly scoped to prevent users from seeing fields or records they should not have access to?\n' +
            '• If running in System Context, is it justified and understood that this bypasses the user\'s own permissions?\n' +
            'If a Record-Triggered or Autolaunched Flow:\n' +
            '• Does the design account for the fact that it runs in the context of the user who triggered the automation?\n' +
            '• Before performing sensitive actions (e.g., deleting records, changing ownership, updating critical fields), are there Decision elements to check the running user\'s permissions (e.g., via $User.Profile.Name or a Custom Permission)?\n' +
            'For all flow types: Does the design prevent accidental elevation of privilege or unintended data exposure?\n' +
            'If security risks exist, highlight them. For a Screen Flow, recommend adjusting the run context. For a Record-Triggered Flow, recommend adding explicit permission-checking logic within the flow itself.\n\n' +

            '8. Automation/Tool Strategy & Organization\n' +
            '• Is there a clear automation strategy—one tool per object, Flow Trigger Order defined, and flows organized by function/role?\n' +
            '• Are record-triggered flows on each object kept to a reasonable number (not monolithic, nor excessive), with unique entry conditions to avoid conflicts and performance overhead?\n' +
            '• Is a bypass or exclusion implemented for data loading/sandbox seeding to avoid governor limits?\n' +
            'If not, recommend consolidation, trigger ordering, business-centric flow grouping, and implementing a bypass.\n\n' +

            '9. Scheduled/Bulk Operations, Governor Limits & Batching\n' +
            '• Is batch DML/query design applied for any scheduled, mass-update, or bulk processing flow?\n' +
            '• Are "one flow interview per record" and N² query patterns avoided for scheduled flows and large collections?\n' +
            '• Is batch size or scope for scheduled/bulk flows well-controlled?\n' +
            'If not, recommend best-practice batching strategies or consider moving to Apex for large data operations.\n\n' +

            '10. Synchronous vs. Asynchronous Processing\n' +
            '• Does any part of the flow risk exceeding synchronous transaction limits (CPU, DML, SOQL, API callouts)?\n' +
            '• For long-running/integration-heavy/high-volume processes, does the flow use the after-save Run Asynchronously path, scheduled paths, or queueable Apex?\n' +
            '• Is latency for user-triggered processes appropriate (sync for immediate feedback, async for heavy/batch work)?\n' +
            'If not, recommend shifting to async where necessary, or splitting business logic for optimal performance.\n\n' +

            '11. Flow vs. Apex Trigger/Hybrid: Tool Selection\n' +
            '• Is the logic governed by simple criteria, minimal data transformation, basic CRUD, or point-and-click needs ("Best for Flow")?\n' +
            '• Does the automation involve complex logic, high-volume processing, external system integration, advanced error handling/testing ("Best for Trigger/Apex")?\n' +
            '• Would a hybrid (Flow + invocable Apex + subflows) model be most robust?\n' +
            '• Based on business and technical criteria, what is the optimal tool and why? Clearly state: "This logic should remain in Flow," "Should be moved/built in Apex Trigger," or "Should use a Flow-Trigger hybrid," backed by rationale.\n\n' +

            '12. Summary Checklist\n' +
            '• Are all best practices above followed?\n' +
            '• If not, summarize major risks and list immediate priorities to address.\n' +
            '• Ensure review is clear, actionable, and prioritized for user implementation.\n\n' +

            'Assessment Output:\n' +
            '• For each area, state "Compliant," "Needs Work," or "Issue," with explanation and a fix.\n' +
            '• For each of the 12 points, first state your reasoning in a step-by-step manner based on the metadata, and then provide the \'Status\', \'Explanation\', and \'Recommendation\'.\n' +
            '• After completing the detailed analysis, provide a final summary formatted as a markdown table. The table must have exactly three columns: \'Area\', \'Status\', and \'Fix/Recommendation\'. Populate the table with one row for each of the primary assessment categories (Documentation, Modularity, Bulkification, etc.), providing a concise, one-sentence summary of the findings and recommendation for each.\n\n' +

            'Use this comprehensive prompt checklist for consistent, expert-level automation reviews directly from Flow metadata, always delivering actionable and tailored guidance.';
    }

    /**
     * @description Custom exception class
     */
    public class FlowAnalysisException extends Exception {}
}
