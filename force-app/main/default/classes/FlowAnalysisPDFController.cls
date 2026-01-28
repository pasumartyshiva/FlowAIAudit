/**
 * @description Controller for FlowAnalysisPDF Visualforce page
 * Handles PDF rendering and download for flow analysis reports
 */
public with sharing class FlowAnalysisPDFController {

    public Flow_Analysis__c flowAnalysis { get; set; }
    public String formattedReport { get; set; }

    /**
     * @description Constructor - loads the Flow Analysis record and formats the report
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
                
                // Parse and format the analysis report
                formattedReport = formatAnalysisReport(flowAnalysis.Analysis_Report__c);
                
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(
                    ApexPages.Severity.ERROR,
                    'Error loading Flow Analysis record: ' + e.getMessage()
                ));
            }
        }
    }
    
    /**
     * @description Formats the analysis report - converts JSON to HTML if needed
     */
    @TestVisible
    private String formatAnalysisReport(String reportText) {
        if (String.isBlank(reportText)) {
            return '<p>No analysis report available.</p>';
        }
        
        try {
            // Check if the report is JSON (starts with { after trimming)
            String trimmed = reportText.trim();
            
            // CRITICAL: Decode HTML entities (Salesforce may encode JSON as HTML)
            // This converts &quot; → " , &amp; → & , &#123; → { etc.
            trimmed = decodeHtmlEntities(trimmed);
            
            // Extract JSON from markdown code blocks if present
            String jsonText = extractJsonFromText(trimmed);
            
            if (jsonText != null && jsonText.startsWith('{')) {
                // Parse and format JSON
                Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(jsonText);
                return generateHtmlFromJson(jsonData);
            } else if (trimmed.startsWith('<')) {
                // Already HTML
                return reportText;
            } else {
                // Plain text - wrap in basic formatting
                return '<div style="white-space: pre-wrap; font-family: Arial, sans-serif;">' + 
                       reportText.escapeHtml4() + '</div>';
            }
        } catch (Exception e) {
            // Return as-is if parsing fails, but escape HTML to prevent rendering issues
            return '<div style="white-space: pre-wrap; font-family: monospace;">' + 
                   reportText.escapeHtml4() + '</div>';
        }
    }
    
    /**
     * @description Decodes common HTML entities back to their original characters
     */
    @TestVisible
    private String decodeHtmlEntities(String text) {
        if (String.isBlank(text)) return text;
        
        String decoded = text;
        
        // Decode named entities
        decoded = decoded.replace('&quot;', '"');
        decoded = decoded.replace('&apos;', '\'');
        decoded = decoded.replace('&amp;', '&');
        decoded = decoded.replace('&lt;', '<');
        decoded = decoded.replace('&gt;', '>');
        decoded = decoded.replace('&nbsp;', ' ');
        
        // Decode common numeric entities (ASCII range)
        decoded = decoded.replace('&#39;', '\'');  // Apostrophe
        decoded = decoded.replace('&#34;', '"');   // Quote
        decoded = decoded.replace('&#38;', '&');   // Ampersand
        decoded = decoded.replace('&#60;', '<');   // Less than
        decoded = decoded.replace('&#62;', '>');   // Greater than
        
        // Remove emoji/unicode numeric entities (not supported in PDF)
        Pattern numericPattern = Pattern.compile('&#\\d+;');
        decoded = numericPattern.matcher(decoded).replaceAll('');
        
        return decoded;
    }
    
    /**
     * @description Extracts JSON from markdown code blocks or plain text
     */
    @TestVisible
    private String extractJsonFromText(String text) {
        if (text == null) return null;
        
        // Check for markdown code block
        Pattern jsonBlockPattern = Pattern.compile('```(?:json)?\\s*([\\s\\S]*?)\\s*```');
        Matcher matcher = jsonBlockPattern.matcher(text);
        if (matcher.find()) {
            return matcher.group(1).trim();
        }
        
        // Check if it starts with {
        if (text.trim().startsWith('{')) {
            return text.trim();
        }
        
        // Try to find JSON within the text
        Integer startIdx = text.indexOf('{');
        Integer endIdx = text.lastIndexOf('}');
        if (startIdx >= 0 && endIdx > startIdx) {
            return text.substring(startIdx, endIdx + 1);
        }
        
        return null;
    }
    
    /**
     * @description Generates PDF-safe HTML using tables and bgcolor attributes (old-school HTML for PDF renderer)
     */
    @TestVisible
    private String generateHtmlFromJson(Map<String, Object> jsonData) {
        String html = '';
        
        // Overall Score Banner - using TABLE with bgcolor (PDF-safe)
        Object scoreObj = jsonData.get('overallScore');
        if (scoreObj == null) scoreObj = jsonData.get('score');
        String status = (String) jsonData.get('overallStatus');
        if (status == null) status = (String) jsonData.get('status');
        
        if (scoreObj != null || status != null) {
            html += '<table width="100%" cellpadding="20" cellspacing="0" bgcolor="#764ba2" style="border-radius: 6px; margin-bottom: 30px;">';
            html += '<tr><td align="center">';
            if (scoreObj != null) {
                // Round score to whole number
                Decimal scoreDecimal = scoreObj instanceof Decimal 
                    ? (Decimal) scoreObj 
                    : Decimal.valueOf(String.valueOf(scoreObj));
                Integer roundedScore = scoreDecimal.setScale(0, RoundingMode.HALF_UP).intValue();
                html += '<font color="#ffffff" size="7"><b>' + roundedScore + '%</b></font><br/><br/>';
            }
            if (status != null) {
                // Map PARTIAL to NEEDS WORK for display
                String displayStatus = getDisplayStatus(status);
                html += '<font color="#ffffff" size="5"><b>' + displayStatus.escapeHtml4() + '</b></font>';
            }
            html += '</td></tr></table>';
        }
        
        // Categories
        List<Object> categories = (List<Object>) jsonData.get('categories');
        if (categories != null && !categories.isEmpty()) {
            for (Object catObj : categories) {
                Map<String, Object> category = (Map<String, Object>) catObj;
                Object numberObj = category.get('number');
                String name = (String) category.get('name');
                String icon = (String) category.get('icon');
                String catStatus = (String) category.get('status');
                String analysis = (String) category.get('analysis');
                String explanation = (String) category.get('explanation');
                String recommendation = (String) category.get('recommendation');
                List<Object> details = (List<Object>) category.get('details');
                
                // Category container - page-break-inside:avoid keeps category together
                html += '<div style="page-break-inside: avoid; margin: 15px 0;">';
                html += '<table width="100%" cellpadding="15" cellspacing="0" bgcolor="#f9f9f9" style="border-left: 4px solid #0176d3;">';
                html += '<tr><td>';
                
                // Category Header
                html += '<font color="#032e61" size="4"><b>';
                if (icon != null) html += icon + ' ';
                if (numberObj != null) html += numberObj + '. ';
                html += (name != null ? name.escapeHtml4() : 'Category');
                html += '</b></font><br/><br/>';
                
                // Analysis
                if (String.isNotBlank(analysis)) {
                    html += '<i><font color="#333333">' + analysis.escapeHtml4() + '</font></i><br/><br/>';
                }
                
                // Details
                if (details != null && !details.isEmpty()) {
                    for (Object detailObj : details) {
                        Map<String, Object> detail = (Map<String, Object>) detailObj;
                        String heading = (String) detail.get('heading');
                        String content = (String) detail.get('content');
                        
                        if (String.isNotBlank(heading) && String.isNotBlank(content)) {
                            html += '<font color="#032e61"><b>' + heading.escapeHtml4() + ':</b></font> ' + content.escapeHtml4() + '<br/>';
                        }
                    }
                    html += '<br/>';
                }
                
                // Status Badge using table with bgcolor - map PARTIAL to NEEDS WORK
                if (String.isNotBlank(catStatus)) {
                    String badgeColor = getStatusColor(catStatus);
                    String displayStatus = getDisplayStatus(catStatus);
                    html += '<table cellpadding="8" cellspacing="0" bgcolor="' + badgeColor + '" style="border-radius: 4px; display: inline;">';
                    html += '<tr><td><font color="#ffffff"><b>Status: ' + displayStatus.escapeHtml4() + '</b></font></td></tr>';
                    html += '</table><br/><br/>';
                }
                
                // Explanation block
                if (String.isNotBlank(explanation)) {
                    html += '<table width="100%" cellpadding="12" cellspacing="0" bgcolor="#fffbf0" style="border-left: 4px solid #ffc107;">';
                    html += '<tr><td><b>Explanation:</b> ' + explanation.escapeHtml4() + '</td></tr>';
                    html += '</table><br/>';
                }
                
                // Recommendation block
                if (String.isNotBlank(recommendation)) {
                    html += '<table width="100%" cellpadding="12" cellspacing="0" bgcolor="#e7f3ff" style="border-left: 4px solid #0176d3;">';
                    html += '<tr><td><font color="#0176d3"><b>Recommendation:</b></font> ' + recommendation.escapeHtml4() + '</td></tr>';
                    html += '</table>';
                }
                
                html += '</td></tr></table>';
                html += '</div>'; // Close page-break-avoid container
            }
        }
        
        // Summary Table - proper formatting with borders
        List<Object> summaryTable = (List<Object>) jsonData.get('summaryTable');
        if (summaryTable != null && !summaryTable.isEmpty()) {
            html += '<div style="page-break-inside: avoid; margin-top: 30px;">';
            html += '<h2 style="color: #032e61; border-bottom: 2px solid #0176d3; padding-bottom: 8px;">Summary Table</h2>';
            html += '<table width="100%" cellpadding="10" cellspacing="0" border="1" style="border-collapse: collapse; border: 1px solid #cccccc;">';
            
            // Table header row with bgcolor
            html += '<tr bgcolor="#0176d3">';
            html += '<td width="20%" style="border: 1px solid #015696; padding: 12px;"><font color="#ffffff"><b>Area</b></font></td>';
            html += '<td width="15%" align="center" style="border: 1px solid #015696; padding: 12px;"><font color="#ffffff"><b>Status</b></font></td>';
            html += '<td width="65%" style="border: 1px solid #015696; padding: 12px;"><font color="#ffffff"><b>Fix/Recommendation</b></font></td>';
            html += '</tr>';
            
            // Table body rows with alternating colors
            Integer rowNum = 0;
            for (Object rowObj : summaryTable) {
                Map<String, Object> row = (Map<String, Object>) rowObj;
                String area = (String) row.get('area');
                String rowStatus = (String) row.get('status');
                String fix = (String) row.get('fix');
                
                String rowBgColor = (Math.mod(rowNum, 2) == 0) ? '#ffffff' : '#f8f9fa';
                html += '<tr bgcolor="' + rowBgColor + '">';
                html += '<td style="border: 1px solid #cccccc; padding: 10px;"><b>' + (area != null ? area.escapeHtml4() : '') + '</b></td>';
                
                // Status cell with color-coded badge
                String statusColor = getStatusColor(rowStatus);
                html += '<td align="center" style="border: 1px solid #cccccc; padding: 10px;">';
                if (String.isNotBlank(rowStatus)) {
                    html += '<table cellpadding="4" cellspacing="0" bgcolor="' + statusColor + '" align="center"><tr><td>';
                    html += '<font color="#ffffff" size="2"><b>' + rowStatus.escapeHtml4() + '</b></font>';
                    html += '</td></tr></table>';
                }
                html += '</td>';
                
                html += '<td style="border: 1px solid #cccccc; padding: 10px;">' + (fix != null ? fix.escapeHtml4() : '') + '</td>';
                html += '</tr>';
                rowNum++;
            }
            html += '</table>';
            html += '</div>'; // Close page-break-avoid container
        }
        
        // NEW FORMAT: Priorities Section
        Map<String, Object> priorities = (Map<String, Object>) jsonData.get('priorities');
        if (priorities != null) {
            // Must Fix (Critical)
            List<Object> mustFix = (List<Object>) priorities.get('mustFix');
            if (mustFix != null && !mustFix.isEmpty()) {
                html += '<div style="page-break-inside: avoid; margin: 20px 0;">';
                html += '<table width="100%" cellpadding="15" cellspacing="0" bgcolor="#fef2f2" style="border-left: 4px solid #c23934;">';
                html += '<tr><td>';
                html += '<font color="#c23934" size="4"><b>Must Fix (Critical)</b></font><br/><br/>';
                html += '<ul>';
                for (Object item : mustFix) {
                    html += '<li><font color="#7f1d1d">' + String.valueOf(item).escapeHtml4() + '</font></li>';
                }
                html += '</ul>';
                html += '</td></tr></table></div>';
            }
            
            // Should Fix
            List<Object> shouldFix = (List<Object>) priorities.get('shouldFix');
            if (shouldFix != null && !shouldFix.isEmpty()) {
                html += '<div style="page-break-inside: avoid; margin: 20px 0;">';
                html += '<table width="100%" cellpadding="15" cellspacing="0" bgcolor="#fffbeb" style="border-left: 4px solid #f49756;">';
                html += '<tr><td>';
                html += '<font color="#b45309" size="4"><b>Should Fix (Before Production)</b></font><br/><br/>';
                html += '<ul>';
                for (Object item : shouldFix) {
                    html += '<li><font color="#78350f">' + String.valueOf(item).escapeHtml4() + '</font></li>';
                }
                html += '</ul>';
                html += '</td></tr></table></div>';
            }
            
            // Consider
            List<Object> consider = (List<Object>) priorities.get('consider');
            if (consider != null && !consider.isEmpty()) {
                html += '<div style="page-break-inside: avoid; margin: 20px 0;">';
                html += '<table width="100%" cellpadding="15" cellspacing="0" bgcolor="#eff6ff" style="border-left: 4px solid #17a2b8;">';
                html += '<tr><td>';
                html += '<font color="#0369a1" size="4"><b>Consider (Future Improvements)</b></font><br/><br/>';
                html += '<ul>';
                for (Object item : consider) {
                    html += '<li><font color="#1e3a5f">' + String.valueOf(item).escapeHtml4() + '</font></li>';
                }
                html += '</ul>';
                html += '</td></tr></table></div>';
            }
        }
        
        // Strengths (new format - styled nicely)
        List<Object> strengths = (List<Object>) jsonData.get('strengths');
        if (strengths != null && !strengths.isEmpty()) {
            html += '<div style="page-break-inside: avoid; margin: 20px 0;">';
            html += '<table width="100%" cellpadding="15" cellspacing="0" bgcolor="#ecfdf5" style="border-left: 4px solid #2e844a;">';
            html += '<tr><td>';
            html += '<font color="#2e844a" size="4"><b>Strengths</b></font><br/><br/>';
            html += '<ul>';
            for (Object strength : strengths) {
                html += '<li><font color="#14532d">' + String.valueOf(strength).escapeHtml4() + '</font></li>';
            }
            html += '</ul>';
            html += '</td></tr></table></div>';
        }
        
        // OLD FORMAT SUPPORT: Findings
        List<Object> findings = (List<Object>) jsonData.get('findings');
        if (findings != null && !findings.isEmpty()) {
            html += '<h2 style="color: #032e61; margin-top: 30px; border-bottom: 2px solid #0176d3; padding-bottom: 10px;">Detailed Findings</h2>';
            
            Integer counter = 1;
            for (Object findingObj : findings) {
                Map<String, Object> finding = (Map<String, Object>) findingObj;
                String category = (String) finding.get('category');
                String severity = (String) finding.get('severity');
                String issue = (String) finding.get('issue');
                String rec = (String) finding.get('recommendation');
                
                html += '<div style="margin: 15px 0; padding: 12px; background: white; border-left: 4px solid #0176d3;">';
                html += '<h4 style="color: #0176d3; margin: 0 0 8px 0;">' + counter + '. ' + 
                        (category != null ? category.escapeHtml4() : 'Finding ' + counter);
                
                if (String.isNotBlank(severity)) {
                    String severityColor = getSeverityColor(severity);
                    html += ' <span style="background: ' + severityColor + '; color: white; padding: 2px 8px; border-radius: 3px; font-size: 10px; margin-left: 10px;">' + severity.escapeHtml4() + '</span>';
                }
                html += '</h4>';
                
                if (String.isNotBlank(issue)) {
                    html += '<p style="margin: 8px 0;"><strong>Issue:</strong> ' + issue.escapeHtml4() + '</p>';
                }
                
                if (String.isNotBlank(rec)) {
                    html += '<p style="margin: 8px 0; background: #f0f9ff; padding: 8px; border-radius: 3px;"><strong>Recommendation:</strong> ' + rec.escapeHtml4() + '</p>';
                }
                
                html += '</div>';
                counter++;
            }
        }
        
        // Summary (old format)
        String summary = (String) jsonData.get('summary');
        if (String.isNotBlank(summary)) {
            html += '<div style="background: #f0f9ff; padding: 15px; margin: 20px 0; border-left: 4px solid #0176d3;">';
            html += '<h3 style="margin: 0 0 10px 0; color: #032e61;">Summary</h3>';
            html += '<p style="margin: 0;">' + summary.escapeHtml4() + '</p>';
            html += '</div>';
        }
        
        // Risks (old format)
        List<Object> risks = (List<Object>) jsonData.get('risks');
        if (risks != null && !risks.isEmpty()) {
            html += '<h3 style="color: #c23934; margin-top: 20px;">Risks</h3>';
            html += '<ul style="color: #c23934;">';
            for (Object risk : risks) {
                html += '<li>' + String.valueOf(risk).escapeHtml4() + '</li>';
            }
            html += '</ul>';
        }
        
        html += '</div>';
        return html;
    }
    
    /**
     * @description Returns color code for status
     */
    @TestVisible
    private String getStatusColor(String status) {
        if (status == null) return '#666';
        String statusLower = status.toLowerCase();
        if (statusLower == 'pass' || statusLower == 'compliant') return '#2e844a';
        if (statusLower == 'minor') return '#17a2b8';
        if (statusLower == 'partial' || statusLower == 'needs work') return '#f49756';
        if (statusLower == 'fail' || statusLower == 'issue' || statusLower == 'critical') return '#c23934';
        if (statusLower == 'n/a') return '#6c757d';
        return '#666';
    }
    
    /**
     * @description Maps AI status to user-friendly display (PARTIAL -> NEEDS WORK)
     */
    @TestVisible
    private String getDisplayStatus(String status) {
        if (status == null) return '';
        String statusLower = status.toLowerCase();
        if (statusLower == 'partial') return 'NEEDS WORK';
        return status.toUpperCase();
    }
    
    /**
     * @description Returns CSS class for status badge
     */
    @TestVisible
    private String getStatusClass(String status) {
        if (status == null) return 'partial';
        String statusLower = status.toLowerCase();
        if (statusLower == 'pass' || statusLower == 'compliant') return 'compliant';
        if (statusLower == 'partial' || statusLower == 'needs work') return 'partial';
        if (statusLower == 'fail' || statusLower == 'issue') return 'issue';
        return 'partial';
    }
    
    /**
     * @description Returns color code for severity
     */
    @TestVisible
    private String getSeverityColor(String severity) {
        if (severity == null) return '#666';
        String severityLower = severity.toLowerCase();
        if (severityLower == 'high') return '#c23934';
        if (severityLower == 'medium') return '#f49756';
        if (severityLower == 'low') return '#2e844a';
        return '#666';
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

        } catch (AuraHandledException e) {
            // Re-throw AuraHandledException as-is to preserve the original message
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error generating PDF: ' + e.getMessage());
        }
    }
}