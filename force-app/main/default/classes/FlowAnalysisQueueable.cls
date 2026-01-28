/**
 * @description Queueable class to analyze individual flows
 * Uses HTTP callouts to Tooling API to fetch flow metadata
 * Can be chained for processing multiple flows asynchronously
 */
public class FlowAnalysisQueueable implements Queueable, Database.AllowsCallouts {

    private String flowApiName;
    private List<String> remainingFlowApiNames;

    /**
     * @description Constructor for single flow analysis
     */
    public FlowAnalysisQueueable(String flowApiName) {
        this.flowApiName = flowApiName;
        this.remainingFlowApiNames = new List<String>();
    }

    /**
     * @description Constructor for multiple flow analysis (chained)
     */
    public FlowAnalysisQueueable(List<String> flowApiNames) {
        if (flowApiNames != null && !flowApiNames.isEmpty()) {
            this.flowApiName = flowApiNames[0];
            this.remainingFlowApiNames = new List<String>();
            for (Integer i = 1; i < flowApiNames.size(); i++) {
                this.remainingFlowApiNames.add(flowApiNames[i]);
            }
        }
    }

    /**
     * @description Execute method - analyzes the flow
     */
    public void execute(QueueableContext context) {
        try {
            // Fetch flow metadata via Tooling API
            FlowMetadataResult flowData = fetchFlowMetadata(flowApiName);

            if (flowData == null || String.isBlank(flowData.metadata)) {
                createErrorAnalysis('Flow not found or no metadata available');
            } else {
                processFlow(flowData);
            }

        } catch (Exception e) {
            createErrorAnalysis('Error: ' + e.getMessage());
        }

        // Chain to next flow if any remain
        if (!remainingFlowApiNames.isEmpty() && !Test.isRunningTest()) {
            System.enqueueJob(new FlowAnalysisQueueable(remainingFlowApiNames));
        }
    }

    /**
     * @description Processes flow metadata
     */
    private void processFlow(FlowMetadataResult flowData) {
        try {
            // Analyze the flow
            Flow_Analysis__c analysis = FlowAnalysisService.analyzeFlow(
                flowApiName,
                flowData.metadata,
                flowData.label != null ? flowData.label : flowApiName,
                1
            );

            // Upsert the analysis
            upsert analysis Flow_Analysis__c.Flow_API_Name__c;

        } catch (Exception e) {
            createErrorAnalysis('Error processing flow: ' + e.getMessage());
        }
    }

    /**
     * @description Fetches flow metadata via Tooling API
     */
    private FlowMetadataResult fetchFlowMetadata(String apiName) {
        try {
            String endpoint = URL.getOrgDomainUrl().toExternalForm() +
                '/services/data/v64.0/tooling/query?q=' +
                EncodingUtil.urlEncode(
                    'SELECT Id, Definition.MasterLabel, Metadata ' +
                    'FROM Flow ' +
                    'WHERE Definition.DeveloperName = \'' + String.escapeSingleQuotes(apiName) + '\' ' +
                    'AND Status = \'Active\' ' +
                    'LIMIT 1',
                    'UTF-8'
                );

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            req.setHeader('Content-Type', 'application/json');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> records = (List<Object>) response.get('records');

                if (records != null && !records.isEmpty()) {
                    Map<String, Object> flowRecord = (Map<String, Object>) records[0];
                    Map<String, Object> definition = (Map<String, Object>) flowRecord.get('Definition');
                    Object metadata = flowRecord.get('Metadata');

                    FlowMetadataResult result = new FlowMetadataResult();
                    result.label = (String) definition.get('MasterLabel');
                    result.metadata = metadata != null ? JSON.serialize(metadata) : null;
                    return result;
                }
            }

            return null;

        } catch (Exception e) {
            return null;
        }
    }

    /**
     * @description Creates an error analysis record
     */
    private void createErrorAnalysis(String errorMessage) {
        Flow_Analysis__c errorAnalysis = new Flow_Analysis__c(
            Flow_API_Name__c = flowApiName,
            Flow_Label__c = flowApiName,
            Status__c = 'Error',
            Analysis_Report__c = errorMessage,
            Last_Analyzed__c = System.now(),
            Is_Active__c = true
        );

        try {
            upsert errorAnalysis Flow_Analysis__c.Flow_API_Name__c;
        } catch (Exception e) {
        }
    }

    /**
     * @description Static method to enqueue a single flow analysis
     */
    public static Id analyzeFlow(String flowApiName) {
        return System.enqueueJob(new FlowAnalysisQueueable(flowApiName));
    }

    /**
     * @description Static method to enqueue multiple flow analyses (chained)
     */
    public static Id analyzeFlows(List<String> flowApiNames) {
        if (flowApiNames == null || flowApiNames.isEmpty()) {
            throw new IllegalArgumentException('Flow API names list cannot be empty');
        }
        return System.enqueueJob(new FlowAnalysisQueueable(flowApiNames));
    }

    /**
     * @description Inner class to hold flow metadata results
     */
    private class FlowMetadataResult {
        String label;
        String metadata;
    }
}