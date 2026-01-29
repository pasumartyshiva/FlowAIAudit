/**
 * @description Controller for the Flow Analysis Dashboard LWC
 * Provides methods to query, filter, and manage flow analyses
 */
public with sharing class FlowAnalysisDashboardController {

    /**
     * @description Gets summary statistics for the dashboard
     * @return Map containing counts for each status
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getSummaryStats() {
        Map<String, Integer> stats = new Map<String, Integer>{
            'Pass' => 0,
            'Needs Work' => 0,
            'Fail' => 0,
            'Pending' => 0,
            'Analyzing' => 0,
            'Error' => 0,
            'Total' => 0
        };

        try {
            List<AggregateResult> results = [
                SELECT Status__c, COUNT(Id) cnt
                FROM Flow_Analysis__c
                WHERE Is_Active__c = true
                WITH USER_MODE
                GROUP BY Status__c
            ];

            for (AggregateResult ar : results) {
                String status = (String) ar.get('Status__c');
                Integer count = (Integer) ar.get('cnt');
                if (stats.containsKey(status)) {
                    stats.put(status, count);
                }
                stats.put('Total', stats.get('Total') + count);
            }

        } catch (Exception e) {
        }

        return stats;
    }

    /**
     * @description Gets all flow analysis records with optional filtering
     * @param statusFilter Optional status to filter by (Pass, Fail, Needs Work, etc.)
     * @param searchTerm Optional search term for flow name
     * @return List of flow analysis wrapper objects
     */
    @AuraEnabled(cacheable=true)
    public static List<FlowAnalysisWrapper> getFlowAnalyses(String statusFilter, String searchTerm) {
        List<FlowAnalysisWrapper> wrappers = new List<FlowAnalysisWrapper>();

        try {
            String query = 'SELECT Id, Flow_API_Name__c, Flow_Label__c, Status__c, ' +
                           'Overall_Score__c, Last_Analyzed__c, Flow_Version__c, ' +
                           'Analysis_Report__c, Raw_Findings__c ' +
                           'FROM Flow_Analysis__c ' +
                           'WHERE Is_Active__c = true ';

            // Add status filter
            if (String.isNotBlank(statusFilter) && statusFilter != 'All') {
                query += 'AND Status__c = :statusFilter ';
            }

            // Add search filter
            if (String.isNotBlank(searchTerm)) {
                query += 'AND (Flow_API_Name__c LIKE :searchPattern OR Flow_Label__c LIKE :searchPattern) ';
            }

            query += 'ORDER BY Last_Analyzed__c DESC NULLS LAST, Flow_Label__c ASC ' +
                     'LIMIT 1000';

            // Use Database.queryWithBinds for security (prevents SOQL injection)
            Map<String, Object> bindVars = new Map<String, Object>();
            if (String.isNotBlank(statusFilter) && statusFilter != 'All') {
                bindVars.put('statusFilter', statusFilter);
            }
            if (String.isNotBlank(searchTerm)) {
                bindVars.put('searchPattern', '%' + String.escapeSingleQuotes(searchTerm) + '%');
            }
            List<Flow_Analysis__c> analyses = Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE);

            for (Flow_Analysis__c analysis : analyses) {
                wrappers.add(new FlowAnalysisWrapper(analysis));
            }

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving flow analyses: ' + e.getMessage());
        }

        return wrappers;
    }

    /**
     * @description Gets detailed analysis for a single flow
     * @param recordId The Flow_Analysis__c record Id
     * @return Flow analysis wrapper with full details
     */
    @AuraEnabled
    public static FlowAnalysisWrapper getFlowAnalysisDetail(Id recordId) {
        try {
            Flow_Analysis__c analysis = [
                SELECT Id, Flow_API_Name__c, Flow_Label__c, Status__c,
                       Overall_Score__c, Last_Analyzed__c, Flow_Version__c,
                       Analysis_Report__c, Raw_Findings__c
                FROM Flow_Analysis__c
                WHERE Id = :recordId
                WITH USER_MODE
                LIMIT 1
            ];

            return new FlowAnalysisWrapper(analysis);

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving flow analysis: ' + e.getMessage());
        }
    }

    /**
     * @description Syncs the flow list - fetches all active flows and creates placeholder records
     * Does NOT run analysis - just populates the dashboard with flow records
     * @return Success message with count of flows synced
     */
    @AuraEnabled
    public static String syncFlowList() {
        try {
            // Get all active flows from FlowDefinitionView
            // Only fetch user-created flows (unmanaged), exclude managed packages
            List<FlowDefinitionView> flows = [
                SELECT ApiName, Label, Description, VersionNumber
                FROM FlowDefinitionView
                WHERE IsActive = true
                AND ManageableState = 'unmanaged'
                AND Label != null
                WITH USER_MODE
                ORDER BY Label
                LIMIT 2000
            ];

            if (flows.isEmpty()) {
                return 'No active flows found';
            }

            // Get existing analysis records to avoid duplicates
            Map<String, Flow_Analysis__c> existingAnalyses = new Map<String, Flow_Analysis__c>();
            for (Flow_Analysis__c analysis : [
                SELECT Id, Flow_API_Name__c, Flow_Label__c
                FROM Flow_Analysis__c
                WHERE Is_Active__c = true
                WITH USER_MODE
            ]) {
                existingAnalyses.put(analysis.Flow_API_Name__c, analysis);
            }

            // Create or update records (use map to deduplicate)
            Map<String, Flow_Analysis__c> recordsToUpsertMap = new Map<String, Flow_Analysis__c>();
            Integer newCount = 0;
            Integer existingCount = 0;

            for (FlowDefinitionView flow : flows) {
                // Skip if we've already processed this API name
                if (recordsToUpsertMap.containsKey(flow.ApiName)) {
                    continue;
                }

                Flow_Analysis__c analysis;

                if (existingAnalyses.containsKey(flow.ApiName)) {
                    // Update existing record (refresh label and version)
                    // Check FLS permissions before modifying existing record
                    if (!Schema.sObjectType.Flow_Analysis__c.fields.Flow_Label__c.isUpdateable() ||
                        !Schema.sObjectType.Flow_Analysis__c.fields.Flow_Version__c.isUpdateable()) {
                        throw new AuraHandledException('Insufficient permissions to update Flow_Analysis__c records');
                    }
                    analysis = existingAnalyses.get(flow.ApiName);
                    analysis.Flow_Label__c = flow.Label;
                    analysis.Flow_Version__c = flow.VersionNumber;
                    existingCount++;
                } else {
                    // Create new placeholder record
                    analysis = new Flow_Analysis__c(
                        Flow_API_Name__c = flow.ApiName,
                        Flow_Label__c = flow.Label,
                        Flow_Version__c = flow.VersionNumber,
                        Status__c = 'Pending',
                        Is_Active__c = true
                    );
                    newCount++;
                }

                recordsToUpsertMap.put(flow.ApiName, analysis);
            }

            // Upsert all records with FLS check
            if (!recordsToUpsertMap.isEmpty()) {
                // Check FLS permissions before DML
                if (!Schema.sObjectType.Flow_Analysis__c.fields.Flow_API_Name__c.isCreateable() ||
                    !Schema.sObjectType.Flow_Analysis__c.fields.Flow_Label__c.isCreateable() ||
                    !Schema.sObjectType.Flow_Analysis__c.fields.Flow_Version__c.isCreateable() ||
                    !Schema.sObjectType.Flow_Analysis__c.fields.Status__c.isCreateable() ||
                    !Schema.sObjectType.Flow_Analysis__c.fields.Is_Active__c.isCreateable()) {
                    throw new AuraHandledException('Insufficient permissions to create Flow_Analysis__c records');
                }
                if (!Schema.sObjectType.Flow_Analysis__c.fields.Flow_Label__c.isUpdateable() ||
                    !Schema.sObjectType.Flow_Analysis__c.fields.Flow_Version__c.isUpdateable()) {
                    throw new AuraHandledException('Insufficient permissions to update Flow_Analysis__c records');
                }

                upsert recordsToUpsertMap.values() Flow_Analysis__c.Flow_API_Name__c;
            }

            String message = 'Flow list synced successfully. ';
            message += 'Total: ' + recordsToUpsertMap.size() + ' unique flows ';
            message += '(' + newCount + ' new, ' + existingCount + ' existing). ';
            message += 'Use "Run Analysis" button to analyze individual flows.';

            return message;

        } catch (Exception e) {
            throw new AuraHandledException('Error syncing flow list: ' + e.getMessage());
        }
    }

    /**
     * @description Updates a single flow's metadata (label and version) from FlowDefinitionView
     * @param recordId The Flow_Analysis__c record ID to update
     * @return Success message indicating if version changed
     */
    @AuraEnabled
    public static String updateFlowMetadata(Id recordId) {
        try {
            if (recordId == null) {
                throw new AuraHandledException('Record ID is required');
            }

            // Get the existing analysis record
            Flow_Analysis__c analysis = [
                SELECT Id, Flow_API_Name__c, Flow_Label__c, Flow_Version__c
                FROM Flow_Analysis__c
                WHERE Id = :recordId
                WITH USER_MODE
                LIMIT 1
            ];

            // Get latest flow metadata from FlowDefinitionView
            List<FlowDefinitionView> flows = [
                SELECT ApiName, Label, VersionNumber
                FROM FlowDefinitionView
                WHERE ApiName = :analysis.Flow_API_Name__c
                AND IsActive = true
                WITH USER_MODE
                LIMIT 1
            ];

            if (flows.isEmpty()) {
                throw new AuraHandledException('Flow not found or is not active: ' + analysis.Flow_API_Name__c);
            }

            FlowDefinitionView flow = flows[0];
            Integer oldVersion = analysis.Flow_Version__c != null ? Integer.valueOf(analysis.Flow_Version__c) : 0;
            Integer newVersion = flow.VersionNumber;
            String oldLabel = analysis.Flow_Label__c;
            String newLabel = flow.Label;

            // Check what changed
            Boolean versionChanged = newVersion != oldVersion;
            Boolean labelChanged = oldLabel != newLabel;

            // Update the analysis record
            analysis.Flow_Label__c = newLabel;
            analysis.Flow_Version__c = newVersion;

            // If version changed, clear the old analysis to avoid confusion
            if (versionChanged) {
                analysis.Status__c = 'Pending';
                analysis.Overall_Score__c = null;
                analysis.Analysis_Report__c = null;
                analysis.Last_Analyzed__c = null;
            }

            // Check FLS permissions before update
            if (!Schema.sObjectType.Flow_Analysis__c.fields.Flow_Label__c.isUpdateable() ||
                !Schema.sObjectType.Flow_Analysis__c.fields.Flow_Version__c.isUpdateable() ||
                !Schema.sObjectType.Flow_Analysis__c.fields.Status__c.isUpdateable() ||
                !Schema.sObjectType.Flow_Analysis__c.fields.Overall_Score__c.isUpdateable() ||
                !Schema.sObjectType.Flow_Analysis__c.fields.Analysis_Report__c.isUpdateable() ||
                !Schema.sObjectType.Flow_Analysis__c.fields.Last_Analyzed__c.isUpdateable()) {
                throw new AuraHandledException('Insufficient permissions to update Flow_Analysis__c fields');
            }

            update analysis;

            // Return clear message based on what changed
            if (versionChanged && labelChanged) {
                return '✅ Flow updated! Version: v' + oldVersion + ' → v' + newVersion + ' | Label updated. Previous analysis cleared. Please re-run analysis to assess the new version.';
            } else if (versionChanged) {
                return '✅ New version detected! Updated from v' + oldVersion + ' to v' + newVersion + '. Previous analysis cleared. Please re-run analysis to assess the changes.';
            } else if (labelChanged) {
                return '✅ Flow label updated from "' + oldLabel + '" to "' + newLabel + '". Version unchanged (v' + newVersion + ').';
            } else {
                return 'ℹ️ No updates needed. Flow is already at the latest version (v' + newVersion + ') and label is current.';
            }

        } catch (Exception e) {
            throw new AuraHandledException('Error updating flow: ' + e.getMessage());
        }
    }

    /**
     * @description Updates all flows that have version changes from FlowDefinitionView
     * @return Summary message with count of updated flows
     */
    @AuraEnabled
    public static String refreshAllFlowVersions() {
        try {
            // Get all existing analysis records
            List<Flow_Analysis__c> analyses = [
                SELECT Id, Flow_API_Name__c, Flow_Label__c, Flow_Version__c
                FROM Flow_Analysis__c
                WHERE Is_Active__c = true
                WITH USER_MODE
            ];

            if (analyses.isEmpty()) {
                return 'No flow analyses found to refresh';
            }

            // Get API names to query
            Set<String> apiNames = new Set<String>();
            for (Flow_Analysis__c analysis : analyses) {
                apiNames.add(analysis.Flow_API_Name__c);
            }

            // Get latest flow metadata from FlowDefinitionView
            Map<String, FlowDefinitionView> flowMap = new Map<String, FlowDefinitionView>();
            for (FlowDefinitionView flow : [
                SELECT ApiName, Label, VersionNumber
                FROM FlowDefinitionView
                WHERE ApiName IN :apiNames
                AND IsActive = true
                WITH USER_MODE
                LIMIT 2000
            ]) {
                flowMap.put(flow.ApiName, flow);
            }

            // Update records that have changes
            List<Flow_Analysis__c> toUpdate = new List<Flow_Analysis__c>();
            Integer versionChanges = 0;
            Integer labelChanges = 0;

            for (Flow_Analysis__c analysis : analyses) {
                FlowDefinitionView flow = flowMap.get(analysis.Flow_API_Name__c);

                if (flow == null) {
                    continue; // Flow no longer exists or is inactive
                }

                Boolean hasChanges = false;
                Boolean versionChanged = false;
                Integer oldVersion = analysis.Flow_Version__c != null ? Integer.valueOf(analysis.Flow_Version__c) : 0;

                if (flow.VersionNumber != oldVersion) {
                    analysis.Flow_Version__c = flow.VersionNumber;
                    versionChanges++;
                    hasChanges = true;
                    versionChanged = true;

                    // Clear old analysis to avoid confusion
                    analysis.Status__c = 'Pending';
                    analysis.Overall_Score__c = null;
                    analysis.Analysis_Report__c = null;
                    analysis.Last_Analyzed__c = null;
                }

                if (flow.Label != analysis.Flow_Label__c) {
                    analysis.Flow_Label__c = flow.Label;
                    labelChanges++;
                    hasChanges = true;
                }

                if (hasChanges) {
                    toUpdate.add(analysis);
                }
            }

            if (!toUpdate.isEmpty()) {
                // Check FLS permissions before update
                if (!Schema.sObjectType.Flow_Analysis__c.fields.Flow_Label__c.isUpdateable() ||
                    !Schema.sObjectType.Flow_Analysis__c.fields.Flow_Version__c.isUpdateable() ||
                    !Schema.sObjectType.Flow_Analysis__c.fields.Status__c.isUpdateable() ||
                    !Schema.sObjectType.Flow_Analysis__c.fields.Overall_Score__c.isUpdateable() ||
                    !Schema.sObjectType.Flow_Analysis__c.fields.Analysis_Report__c.isUpdateable() ||
                    !Schema.sObjectType.Flow_Analysis__c.fields.Last_Analyzed__c.isUpdateable()) {
                    throw new AuraHandledException('Insufficient permissions to update Flow_Analysis__c fields');
                }

                update toUpdate;
            }

            String message = 'Refreshed ' + toUpdate.size() + ' flow(s). ';
            if (versionChanges > 0) {
                message += versionChanges + ' version update(s) - previous analyses cleared. ';
            }
            if (labelChanges > 0) {
                message += labelChanges + ' label update(s). ';
            }
            if (toUpdate.isEmpty()) {
                message = 'All flows are up to date. No changes detected.';
            } else if (versionChanges > 0) {
                message += 'Re-run analysis for updated flows to get fresh assessments.';
            }

            return message;

        } catch (Exception e) {
            throw new AuraHandledException('Error refreshing flows: ' + e.getMessage());
        }
    }

    /**
     * @description Deletes selected Flow_Analysis__c records by IDs
     * @param recordIds List of record IDs to delete
     * @return Success message with count of deleted records
     */
    @AuraEnabled
    public static String deleteAnalyses(List<Id> recordIds) {
        try {
            if (recordIds == null || recordIds.isEmpty()) {
                throw new AuraHandledException('No records selected for deletion');
            }

            List<Flow_Analysis__c> analysesToDelete = [
                SELECT Id
                FROM Flow_Analysis__c
                WHERE Id IN :recordIds
                WITH USER_MODE
            ];

            Integer count = analysesToDelete.size();

            if (count == 0) {
                return 'No records found to delete';
            }

            // Check delete permission before DML
            if (!Schema.sObjectType.Flow_Analysis__c.isDeletable()) {
                throw new AuraHandledException('Insufficient permissions to delete Flow_Analysis__c records');
            }

            delete analysesToDelete;

            return count + ' record(s) deleted successfully';

        } catch (Exception e) {
            throw new AuraHandledException('Error deleting records: ' + e.getMessage());
        }
    }

    /**
     * @description Deletes all Flow_Analysis__c records
     * @return Success message with count of deleted records
     */
    @AuraEnabled
    public static String deleteAllAnalyses() {
        try {
            List<Flow_Analysis__c> allAnalyses = [
                SELECT Id
                FROM Flow_Analysis__c
                WITH USER_MODE
            ];

            Integer count = allAnalyses.size();

            if (count == 0) {
                return 'No records to delete';
            }

            // Check delete permission before DML
            if (!Schema.sObjectType.Flow_Analysis__c.isDeletable()) {
                throw new AuraHandledException('Insufficient permissions to delete Flow_Analysis__c records');
            }

            delete allAnalyses;

            return 'Successfully deleted ' + count + ' flow analysis record(s)';

        } catch (Exception e) {
            throw new AuraHandledException('Error deleting analyses: ' + e.getMessage());
        }
    }

    /**
     * @description Runs analysis for all flows
     * NOTE: Batch processing is not supported with Einstein Prompt Templates
     * because they require a user session context. Use "Re-analyze" button
     * on individual flows instead.
     * @param batchSize Optional batch size (default 50)
     * @return Error message explaining the limitation
     */
    @AuraEnabled
    public static String runAllFlowsAnalysis(Integer batchSize) {
        throw new AuraHandledException(
            'Batch analysis is not supported when using Einstein Prompt Templates. ' +
            'Einstein GPT requires a user session context, which is not available in batch/queueable jobs. ' +
            '\n\nPlease use the "Re-analyze" button on individual flows instead. ' +
            '\n\nAlternatively, configure an external LLM provider (HuggingFace, Google Gemini, or Anthropic) ' +
            'which supports batch processing.'
        );
    }

    /**
     * @description Re-analyzes a single flow synchronously using Einstein Prompt Template
     * Runs in user session context, so Einstein GPT works properly
     *
     * This method fetches full flow metadata via Tooling API using a Named Credential
     * to avoid session ID authorization issues.
     *
     * SETUP REQUIRED: Named Credential "Salesforce_Tooling_API" must be configured
     * See Documentation/NAMED_CREDENTIAL_SETUP.md for setup instructions
     *
     * @param flowApiName The flow API name to analyze
     * @return Success message
     */
    @AuraEnabled
    public static String reanalyzeFlow(String flowApiName) {
        try {
            if (String.isBlank(flowApiName)) {
                throw new AuraHandledException('Flow API name is required');
            }

            // Fetch full flow metadata via Tooling API with Named Credential
            FlowMetadataResult flowData = fetchFlowMetadataWithNamedCredential(flowApiName);

            if (flowData == null || String.isBlank(flowData.metadata)) {
                throw new AuraHandledException('Flow not found or no metadata available: ' + flowApiName);
            }

            // Analyze the flow synchronously (Einstein will work here!)
            Flow_Analysis__c analysis = FlowAnalysisService.analyzeFlow(
                flowApiName,
                flowData.metadata,
                flowData.label,
                flowData.version
            );

            // Check FLS permissions before upsert
            if (!Schema.sObjectType.Flow_Analysis__c.fields.Flow_API_Name__c.isCreateable() ||
                !Schema.sObjectType.Flow_Analysis__c.fields.Flow_Label__c.isCreateable() ||
                !Schema.sObjectType.Flow_Analysis__c.fields.Flow_Version__c.isCreateable() ||
                !Schema.sObjectType.Flow_Analysis__c.fields.Status__c.isCreateable() ||
                !Schema.sObjectType.Flow_Analysis__c.fields.Last_Analyzed__c.isCreateable() ||
                !Schema.sObjectType.Flow_Analysis__c.fields.Is_Active__c.isCreateable()) {
                throw new AuraHandledException('Insufficient permissions to create Flow_Analysis__c records');
            }
            if (!Schema.sObjectType.Flow_Analysis__c.fields.Flow_Label__c.isUpdateable() ||
                !Schema.sObjectType.Flow_Analysis__c.fields.Flow_Version__c.isUpdateable() ||
                !Schema.sObjectType.Flow_Analysis__c.fields.Status__c.isUpdateable() ||
                !Schema.sObjectType.Flow_Analysis__c.fields.Overall_Score__c.isUpdateable() ||
                !Schema.sObjectType.Flow_Analysis__c.fields.Analysis_Report__c.isUpdateable() ||
                !Schema.sObjectType.Flow_Analysis__c.fields.Last_Analyzed__c.isUpdateable()) {
                throw new AuraHandledException('Insufficient permissions to update Flow_Analysis__c records');
            }

            // Upsert the analysis
            upsert analysis Flow_Analysis__c.Flow_API_Name__c;

            return 'Flow analyzed successfully';

        } catch (Exception e) {

            // Provide helpful error messages
            String errorMsg = e.getMessage();
            if (errorMsg.contains('Unauthorized endpoint')) {
                throw new AuraHandledException(
                    'Named Credential not configured. Please set up "Salesforce_Tooling_API" Named Credential. ' +
                    'See Documentation/NAMED_CREDENTIAL_SETUP.md for instructions.'
                );
            } else if (errorMsg.contains('401')) {
                throw new AuraHandledException(
                    'Authentication failed. Please verify Named Credential configuration. ' +
                    'Error: ' + errorMsg
                );
            }

            throw new AuraHandledException('Error re-analyzing flow: ' + errorMsg);
        }
    }

    /**
     * @description Fetches flow metadata using Named Credential
     * @param flowApiName The flow API name
     * @return FlowMetadataResult with metadata, label, and version
     */
    private static FlowMetadataResult fetchFlowMetadataWithNamedCredential(String flowApiName) {
        try {
            // Use Named Credential for Tooling API callout
            String endpoint = 'callout:Salesforce_Tooling_API/services/data/v64.0/tooling/query?q=' +
                EncodingUtil.urlEncode(
                    'SELECT Id, Definition.MasterLabel, Metadata, VersionNumber ' +
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
            req.setTimeout(60000); // 60 second timeout

            Http http = new Http();
            HttpResponse res = http.send(req);


            if (res.getStatusCode() == 200) {
                Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> records = (List<Object>) response.get('records');

                if (records != null && !records.isEmpty()) {
                    Map<String, Object> flowRecord = (Map<String, Object>) records[0];
                    Map<String, Object> definition = (Map<String, Object>) flowRecord.get('Definition');
                    Object metadata = flowRecord.get('Metadata');
                    Object versionNumber = flowRecord.get('VersionNumber');

                    // Get label from Definition.MasterLabel or fallback to FlowDefinitionView
                    String label = flowApiName;
                    if (definition != null && definition.get('MasterLabel') != null) {
                        label = (String) definition.get('MasterLabel');
                    } else {
                        // Fallback: query FlowDefinitionView for the label
                        List<FlowDefinitionView> flowDefs = [
                            SELECT Label FROM FlowDefinitionView
                            WHERE ApiName = :flowApiName AND IsActive = true 
                            WITH USER_MODE
                            LIMIT 1
                        ];
                        if (!flowDefs.isEmpty()) {
                            label = flowDefs[0].Label;
                        }
                    }

                    FlowMetadataResult result = new FlowMetadataResult();
                    result.metadata = metadata != null ? JSON.serialize(metadata) : null;
                    result.label = label;
                    result.version = versionNumber != null ? Integer.valueOf(String.valueOf(versionNumber)) : 1;

                    return result;
                } else {
                    throw new AuraHandledException('Flow not found or not accessible. This may be a managed package flow.');
                }
            } else {
                throw new AuraHandledException('Tooling API error: ' + res.getStatus());
            }

        } catch (Exception e) {
            throw e;
        }
    }

    /**
     * @description Wrapper class for flow metadata result
     */
    private class FlowMetadataResult {
        public String metadata;
        public String label;
        public Integer version;
    }


    /**
     * @description Checks if a batch job is currently running
     * @return True if a batch is running, false otherwise
     */
    @AuraEnabled(cacheable=false)
    public static Boolean isBatchRunning() {
        try {
            List<AsyncApexJob> runningJobs = [
                SELECT Id
                FROM AsyncApexJob
                WHERE ApexClass.Name = 'FlowAnalysisBatch'
                AND Status IN ('Queued', 'Processing', 'Preparing')
                WITH USER_MODE
                LIMIT 1
            ];

            return !runningJobs.isEmpty();

        } catch (Exception e) {
            return false;
        }
    }

    /**
     * @description Gets batch job progress
     * @return Map with job details (status, progress, etc.)
     */
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getBatchProgress() {
        Map<String, Object> progress = new Map<String, Object>{
            'isRunning' => false,
            'status' => 'Not Running',
            'jobItemsProcessed' => 0,
            'totalJobItems' => 0,
            'numberOfErrors' => 0
        };

        try {
            List<AsyncApexJob> jobs = [
                SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors,
                       CreatedDate, CompletedDate
                FROM AsyncApexJob
                WHERE ApexClass.Name = 'FlowAnalysisBatch'
                WITH USER_MODE
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            if (!jobs.isEmpty()) {
                AsyncApexJob job = jobs[0];
                progress.put('isRunning', job.Status == 'Queued' || job.Status == 'Processing' || job.Status == 'Preparing');
                progress.put('status', job.Status);
                progress.put('jobItemsProcessed', job.JobItemsProcessed);
                progress.put('totalJobItems', job.TotalJobItems);
                progress.put('numberOfErrors', job.NumberOfErrors);
                progress.put('createdDate', job.CreatedDate);
                progress.put('completedDate', job.CompletedDate);
            }

        } catch (Exception e) {
        }

        return progress;
    }

    /**
     * @description Wrapper class for Flow Analysis records
     */
    public class FlowAnalysisWrapper {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String flowApiName { get; set; }
        @AuraEnabled public String flowLabel { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Decimal score { get; set; }
        @AuraEnabled public DateTime lastAnalyzed { get; set; }
        @AuraEnabled public Integer flowVersion { get; set; }
        @AuraEnabled public String analysisReport { get; set; }
        @AuraEnabled public String rawFindings { get; set; }

        public FlowAnalysisWrapper(Flow_Analysis__c analysis) {
            this.id = analysis.Id;
            this.flowApiName = analysis.Flow_API_Name__c;
            this.flowLabel = analysis.Flow_Label__c;
            this.status = analysis.Status__c;
            this.score = analysis.Overall_Score__c;
            this.lastAnalyzed = analysis.Last_Analyzed__c;
            this.flowVersion = Integer.valueOf(analysis.Flow_Version__c);
            this.analysisReport = analysis.Analysis_Report__c;
            this.rawFindings = analysis.Raw_Findings__c;
        }
    }
}