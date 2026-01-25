/**
 * @description Batch class to analyze all active unmanaged flows in the org
 * Uses HTTP callouts to Tooling API to fetch flow metadata
 * Can handle 1000+ flows efficiently
 */
public class FlowAnalysisBatch implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful {

    private Integer totalProcessed = 0;
    private Integer totalSuccess = 0;
    private Integer totalErrors = 0;
    private List<String> flowApiNames;

    /**
     * @description Constructor - optionally pass pre-fetched flow names
     */
    public FlowAnalysisBatch() {
        this.flowApiNames = null;
    }

    public FlowAnalysisBatch(List<String> flowApiNames) {
        this.flowApiNames = flowApiNames;
    }

    /**
     * @description Start method - fetches all active unmanaged flow names
     */
    public Iterable<String> start(Database.BatchableContext bc) {
        // If flow names were provided, use them
        if (flowApiNames != null && !flowApiNames.isEmpty()) {
            return flowApiNames;
        }

        // Otherwise, fetch from Tooling API
        List<String> flowNames = new List<String>();

        try {
            String endpoint = URL.getOrgDomainUrl().toExternalForm() +
                '/services/data/v64.0/tooling/query?q=' +
                EncodingUtil.urlEncode(
                    'SELECT Definition.DeveloperName, Definition.MasterLabel ' +
                    'FROM Flow ' +
                    'WHERE Status = \'Active\' ' +
                    'AND Definition.ManageableState IN (\'unmanaged\', \'unmanagedReleased\') ' +
                    'ORDER BY Definition.MasterLabel',
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

                if (records != null) {
                    Set<String> uniqueFlowNames = new Set<String>();
                    for (Object record : records) {
                        Map<String, Object> flowRecord = (Map<String, Object>) record;
                        Map<String, Object> definition = (Map<String, Object>) flowRecord.get('Definition');
                        String devName = (String) definition.get('DeveloperName');
                        if (String.isNotBlank(devName)) {
                            uniqueFlowNames.add(devName);
                        }
                    }
                    flowNames.addAll(uniqueFlowNames);
                }
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error fetching flow names: ' + e.getMessage());
        }

        return flowNames;
    }

    /**
     * @description Execute method - processes each batch of flow names
     */
    public void execute(Database.BatchableContext bc, List<String> scope) {
        List<Flow_Analysis__c> analysesToUpsert = new List<Flow_Analysis__c>();

        for (String flowApiName : scope) {
            try {
                totalProcessed++;

                // Fetch flow metadata and details
                FlowMetadataResult flowData = fetchFlowMetadata(flowApiName);

                if (flowData == null || String.isBlank(flowData.metadata)) {
                    analysesToUpsert.add(createErrorAnalysis(flowApiName, 'No metadata found'));
                    continue;
                }

                // Analyze the flow
                Flow_Analysis__c analysis = FlowAnalysisService.analyzeFlow(
                    flowApiName,
                    flowData.metadata,
                    flowData.label != null ? flowData.label : flowApiName,
                    1
                );

                analysesToUpsert.add(analysis);

            } catch (Exception e) {
                totalErrors++;
                System.debug(LoggingLevel.ERROR, 'Error processing flow ' + flowApiName + ': ' + e.getMessage());
                analysesToUpsert.add(createErrorAnalysis(flowApiName, e.getMessage()));
            }
        }

        // Upsert all analysis records
        if (!analysesToUpsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(
                    analysesToUpsert,
                    Flow_Analysis__c.Flow_API_Name__c,
                    false
                );

                for (Database.UpsertResult result : results) {
                    if (result.isSuccess()) {
                        totalSuccess++;
                    } else {
                        totalErrors++;
                        for (Database.Error err : result.getErrors()) {
                            System.debug(LoggingLevel.ERROR, 'Upsert error: ' + err.getMessage());
                        }
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error upserting records: ' + e.getMessage());
            }
        }
    }

    /**
     * @description Finish method - logs summary
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('FlowAnalysisBatch completed:');
        System.debug('Total Processed: ' + totalProcessed);
        System.debug('Total Success: ' + totalSuccess);
        System.debug('Total Errors: ' + totalErrors);
    }

    /**
     * @description Fetches flow metadata via Tooling API
     */
    private FlowMetadataResult fetchFlowMetadata(String flowApiName) {
        try {
            String endpoint = URL.getOrgDomainUrl().toExternalForm() +
                '/services/data/v64.0/tooling/query?q=' +
                EncodingUtil.urlEncode(
                    'SELECT Id, Definition.MasterLabel, Metadata ' +
                    'FROM Flow ' +
                    'WHERE Definition.DeveloperName = \'' + String.escapeSingleQuotes(flowApiName) + '\' ' +
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
            System.debug(LoggingLevel.ERROR, 'Error fetching metadata for ' + flowApiName + ': ' + e.getMessage());
            return null;
        }
    }

    /**
     * @description Creates an error analysis record
     */
    private Flow_Analysis__c createErrorAnalysis(String flowApiName, String errorMessage) {
        return new Flow_Analysis__c(
            Flow_API_Name__c = flowApiName,
            Flow_Label__c = flowApiName,
            Status__c = 'Error',
            Analysis_Report__c = 'Error: ' + errorMessage,
            Last_Analyzed__c = System.now(),
            Is_Active__c = true
        );
    }

    /**
     * @description Helper method to run the batch job
     */
    public static Id runBatch(Integer batchSize) {
        if (batchSize == null || batchSize < 1) {
            batchSize = 10; // Conservative default due to HTTP callouts
        }
        if (batchSize > 20) {
            batchSize = 20; // Max 20 to stay within callout limits (100 per transaction)
        }

        FlowAnalysisBatch batch = new FlowAnalysisBatch();
        return Database.executeBatch(batch, batchSize);
    }

    /**
     * @description Inner class to hold flow metadata results
     */
    private class FlowMetadataResult {
        String label;
        String metadata;
    }
}
