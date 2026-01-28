/**
 * @description Service class for integrating with external LLM providers (Google Gemini, Anthropic Claude, OpenAI)
 * Provides a unified interface for making API calls to different LLM providers
 * Configuration is managed via LLM_Configuration__mdt Custom Metadata
 */
public with sharing class ExternalLLMService {

    private static final Integer TIMEOUT_SECONDS = 120;
    private static final String GOOGLE_PROVIDER = 'Google';
    private static final String ANTHROPIC_PROVIDER = 'Anthropic';
    private static final String OPENAI_PROVIDER = 'OpenAI';
    private static final String HUGGINGFACE_PROVIDER = 'HuggingFace';

    /**
     * @description Checks if an external LLM provider is configured and active
     * @return True if a valid configuration exists
     */
    public static Boolean isConfigured() {
        try {
            LLM_Configuration__mdt config = getActiveConfiguration();
            return config != null;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * @description Main entry point for generating LLM completions
     * @param flowMetadataXml The flow's XML metadata
     * @param assessmentFramework The assessment framework/knowledge text
     * @return The LLM response as a string
     */
    public static String generateCompletion(String flowMetadataXml, String assessmentFramework) {

        // Get active configuration
        LLM_Configuration__mdt config = getActiveConfiguration();
        if (config == null) {
            throw new ExternalLLMException('No active LLM configuration found. Please configure an LLM provider in Setup > Custom Metadata Types > LLM Configuration');
        }


        // Build the complete prompt
        String prompt = buildPrompt(flowMetadataXml, assessmentFramework);

        // Route to appropriate provider
        String response;
        if (config.Provider_Name__c == GOOGLE_PROVIDER) {
            response = callGoogleGemini(prompt, config);
        } else if (config.Provider_Name__c == ANTHROPIC_PROVIDER) {
            response = callAnthropicClaude(prompt, config);
        } else if (config.Provider_Name__c == OPENAI_PROVIDER) {
            response = callOpenAI(prompt, config);
        } else if (config.Provider_Name__c == HUGGINGFACE_PROVIDER) {
            response = callHuggingFace(prompt, config);
        } else {
            throw new ExternalLLMException('Unsupported provider: ' + config.Provider_Name__c);
        }

        return response;
    }

    /**
     * @description Fetches the active LLM configuration from Custom Metadata
     * @return Active LLM_Configuration__mdt record or null
     */
    @TestVisible
    private static LLM_Configuration__mdt getActiveConfiguration() {
        List<LLM_Configuration__mdt> configs = [
            SELECT Provider_Name__c, API_Endpoint__c, Model_Name__c, API_Key_Name__c, API_Key__c,
                   Max_Tokens__c, Temperature__c, System_Prompt__c
            FROM LLM_Configuration__mdt
            WHERE Is_Active__c = true
            WITH USER_MODE
            LIMIT 1
        ];

        return configs.isEmpty() ? null : configs[0];
    }

    /**
     * @description Builds the complete prompt combining metadata and assessment framework
     * @param flowMetadataXml The flow's XML metadata
     * @param assessmentFramework The assessment framework text
     * @return Combined prompt string
     */
    @TestVisible
    private static String buildPrompt(String flowMetadataXml, String assessmentFramework) {
        String prompt = 'You are a Salesforce Flow expert performing a comprehensive best practice audit.\n\n';
        prompt += '# TASK\n';
        prompt += 'Analyze the provided Salesforce Flow metadata XML and assess it against the 12-point assessment framework below.\n\n';
        prompt += '# OUTPUT FORMAT\n';
        prompt += 'Return your analysis as a valid JSON object with this structure:\n';
        prompt += '{\n';
        prompt += '  "status": "Pass|Needs Work|Fail",\n';
        prompt += '  "score": 85,\n';
        prompt += '  "categories": [\n';
        prompt += '    {\n';
        prompt += '      "name": "Category Name",\n';
        prompt += '      "status": "Compliant|Needs Work|Issue",\n';
        prompt += '      "findings": "Brief summary of findings"\n';
        prompt += '    }\n';
        prompt += '  ],\n';
        prompt += '  "findings": [\n';
        prompt += '    {\n';
        prompt += '      "area": "Area Name",\n';
        prompt += '      "explanation": "Detailed explanation of the issue",\n';
        prompt += '      "recommendation": "Specific actionable recommendation"\n';
        prompt += '    }\n';
        prompt += '  ]\n';
        prompt += '}\n\n';
        prompt += '# ASSESSMENT FRAMEWORK\n';
        prompt += assessmentFramework + '\n\n';
        prompt += '# FLOW METADATA XML\n';
        prompt += flowMetadataXml;

        return prompt;
    }

    /**
     * @description Calls Google Gemini API
     * @param prompt The complete prompt text
     * @param config The LLM configuration
     * @return The API response text
     */
    @TestVisible
    private static String callGoogleGemini(String prompt, LLM_Configuration__mdt config) {

        // Validate API Key
        if (String.isBlank(config.API_Key__c)) {
            throw new ExternalLLMException('Google Gemini API Key is not configured. Please add your API key in Setup > Custom Metadata Types > LLM Configuration > Google Gemini 1.5 Pro > Edit > API Key field');
        }

        // Build request body
        Map<String, Object> requestBody = new Map<String, Object>{
            'contents' => new List<Object>{
                new Map<String, Object>{
                    'parts' => new List<Object>{
                        new Map<String, Object>{'text' => prompt}
                    }
                }
            },
            'generationConfig' => new Map<String, Object>{
                'temperature' => config.Temperature__c != null ? config.Temperature__c : 0.1,
                'maxOutputTokens' => config.Max_Tokens__c != null ? Integer.valueOf(config.Max_Tokens__c) : 8000
            }
        };

        // Build endpoint URL with API key as query parameter
        String endpoint = config.API_Endpoint__c + '?key=' + config.API_Key__c;

        // Make HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(TIMEOUT_SECONDS * 1000);
        req.setBody(JSON.serialize(requestBody));

        Http http = new Http();
        HttpResponse res = http.send(req);


        if (res.getStatusCode() != 200) {
            throw new ExternalLLMException('Google Gemini API error: ' + res.getStatusCode() + ' - ' + res.getBody());
        }

        // Parse response
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> candidates = (List<Object>) responseBody.get('candidates');

        if (candidates == null || candidates.isEmpty()) {
            throw new ExternalLLMException('No candidates returned from Google Gemini API');
        }

        Map<String, Object> candidate = (Map<String, Object>) candidates[0];
        Map<String, Object> content = (Map<String, Object>) candidate.get('content');
        List<Object> parts = (List<Object>) content.get('parts');
        Map<String, Object> part = (Map<String, Object>) parts[0];

        return (String) part.get('text');
    }

    /**
     * @description Calls Anthropic Claude API
     * @param prompt The complete prompt text
     * @param config The LLM configuration
     * @return The API response text
     */
    @TestVisible
    private static String callAnthropicClaude(String prompt, LLM_Configuration__mdt config) {

        // Validate API Key
        if (String.isBlank(config.API_Key__c)) {
            throw new ExternalLLMException('Anthropic Claude API Key is not configured. Please add your API key in Setup > Custom Metadata Types > LLM Configuration > Anthropic Claude 3.5 Sonnet > Edit > API Key field');
        }

        // Build request body
        Map<String, Object> requestBody = new Map<String, Object>{
            'model' => config.Model_Name__c,
            'max_tokens' => config.Max_Tokens__c != null ? Integer.valueOf(config.Max_Tokens__c) : 8000,
            'temperature' => config.Temperature__c != null ? config.Temperature__c : 0.1,
            'messages' => new List<Object>{
                new Map<String, Object>{
                    'role' => 'user',
                    'content' => prompt
                }
            }
        };

        // Add system prompt if configured
        if (String.isNotBlank(config.System_Prompt__c)) {
            requestBody.put('system', config.System_Prompt__c);
        }

        // Make HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(config.API_Endpoint__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('x-api-key', config.API_Key__c);
        req.setHeader('anthropic-version', '2023-06-01');
        req.setTimeout(TIMEOUT_SECONDS * 1000);
        req.setBody(JSON.serialize(requestBody));

        Http http = new Http();
        HttpResponse res = http.send(req);


        if (res.getStatusCode() != 200) {
            throw new ExternalLLMException('Anthropic Claude API error: ' + res.getStatusCode() + ' - ' + res.getBody());
        }

        // Parse response
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> contentList = (List<Object>) responseBody.get('content');

        if (contentList == null || contentList.isEmpty()) {
            throw new ExternalLLMException('No content returned from Anthropic Claude API');
        }

        Map<String, Object> contentBlock = (Map<String, Object>) contentList[0];
        return (String) contentBlock.get('text');
    }

    /**
     * @description Calls OpenAI API (placeholder for future implementation)
     * @param prompt The complete prompt text
     * @param config The LLM configuration
     * @return The API response text
     */
    @TestVisible
    private static String callOpenAI(String prompt, LLM_Configuration__mdt config) {
        throw new ExternalLLMException('OpenAI provider is not yet implemented');
    }

    /**
     * @description Calls Hugging Face Inference API (FREE)
     * @param prompt The complete prompt text
     * @param config The LLM configuration
     * @return The API response text
     */
    @TestVisible
    private static String callHuggingFace(String prompt, LLM_Configuration__mdt config) {

        // Validate API Key
        if (String.isBlank(config.API_Key__c)) {
            throw new ExternalLLMException('Hugging Face API Key is not configured. Please add your API key in Setup > Custom Metadata Types > LLM Configuration > Edit > API Key field. Get a FREE key at: https://huggingface.co/settings/tokens');
        }

        // Build request body for HF Router API (OpenAI-compatible Responses API format)
        Map<String, Object> requestBody = new Map<String, Object>{
            'model' => config.Model_Name__c,
            'input' => prompt
        };

        // Add system prompt if configured
        if (String.isNotBlank(config.System_Prompt__c)) {
            requestBody.put('instructions', config.System_Prompt__c);
        }

        // Make HTTP request to router.huggingface.co/v1/responses endpoint
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://router.huggingface.co/v1/responses');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + config.API_Key__c);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(TIMEOUT_SECONDS * 1000);
        req.setBody(JSON.serialize(requestBody));

        Http http = new Http();
        HttpResponse res = http.send(req);


        if (res.getStatusCode() != 200) {
            throw new ExternalLLMException('Hugging Face API error: ' + res.getStatusCode() + ' - ' + res.getBody());
        }

        // Parse response - Router API returns OpenAI-compatible format
        Map<String, Object> responseObj = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

        if (responseObj == null) {
            throw new ExternalLLMException('No response returned from Hugging Face API');
        }

        // Extract text from nested output structure: output[0].content[0].text
        List<Object> outputArray = (List<Object>) responseObj.get('output');

        if (outputArray == null || outputArray.isEmpty()) {
            throw new ExternalLLMException('Empty output array from Hugging Face API. Response: ' + res.getBody());
        }

        Map<String, Object> firstOutput = (Map<String, Object>) outputArray[0];
        List<Object> contentArray = (List<Object>) firstOutput.get('content');

        if (contentArray == null || contentArray.isEmpty()) {
            throw new ExternalLLMException('Empty content array from Hugging Face API. Response: ' + res.getBody());
        }

        Map<String, Object> contentObj = (Map<String, Object>) contentArray[0];
        String outputText = (String) contentObj.get('text');

        if (String.isBlank(outputText)) {
            throw new ExternalLLMException('Empty text from Hugging Face API. Response: ' + res.getBody());
        }

        // Clean up markdown code blocks if present (some models wrap JSON in ```json...```)
        outputText = outputText.trim();
        if (outputText.startsWith('```json')) {
            outputText = outputText.substring(7); // Remove ```json
        } else if (outputText.startsWith('```')) {
            outputText = outputText.substring(3); // Remove ```
        }
        if (outputText.endsWith('```')) {
            outputText = outputText.substring(0, outputText.length() - 3); // Remove trailing ```
        }
        outputText = outputText.trim();

        return outputText;
    }

    /**
     * @description Custom exception class for External LLM errors
     */
    public class ExternalLLMException extends Exception {}
}