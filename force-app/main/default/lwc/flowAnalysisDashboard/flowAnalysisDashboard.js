import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSummaryStats from '@salesforce/apex/FlowAnalysisDashboardController.getSummaryStats';
import getFlowAnalyses from '@salesforce/apex/FlowAnalysisDashboardController.getFlowAnalyses';
import syncFlowList from '@salesforce/apex/FlowAnalysisDashboardController.syncFlowList';
import reanalyzeFlow from '@salesforce/apex/FlowAnalysisDashboardController.reanalyzeFlow';
import deleteAllAnalyses from '@salesforce/apex/FlowAnalysisDashboardController.deleteAllAnalyses';
import deleteAnalyses from '@salesforce/apex/FlowAnalysisDashboardController.deleteAnalyses';
import getBatchProgress from '@salesforce/apex/FlowAnalysisDashboardController.getBatchProgress';
import updateFlowMetadata from '@salesforce/apex/FlowAnalysisDashboardController.updateFlowMetadata';
import generatePDF from '@salesforce/apex/FlowAnalysisPDFController.generatePDF';

const COLUMNS = [
    {
        label: 'Flow Name',
        fieldName: 'flowLabel',
        type: 'text',
        sortable: true,
        wrapText: true,
        initialWidth: 280
    },
    {
        label: 'Status',
        fieldName: 'status',
        type: 'text',
        sortable: true,
        cellAttributes: {
            class: { fieldName: 'statusClass' },
            alignment: 'center'
        },
        initialWidth: 110
    },
    {
        label: 'Score',
        fieldName: 'score',
        type: 'number',
        sortable: true,
        cellAttributes: { alignment: 'center' },
        initialWidth: 90
    },
    {
        label: 'Last Analyzed',
        fieldName: 'lastAnalyzed',
        type: 'date',
        sortable: true,
        typeAttributes: {
            year: 'numeric',
            month: 'short',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        },
        initialWidth: 170
    }
];

export default class FlowAnalysisDashboard extends LightningElement {
    @track summaryStats = {};
    @track flowAnalyses = [];
    @track filteredAnalyses = [];
    @track paginatedData = [];
    @track selectedStatus = 'All';
    @track searchTerm = '';
    @track selectedRows = [];
    @track isLoadingSimple = false;
    @track isAnalyzing = false;
    @track isBatchRunning = false;
    @track batchProgress = {};
    @track selectedFlow = null;
    @track showDetailModal = false;
    @track showHelpModal = false;

    // Pagination properties
    @track pageSize = 25;
    @track currentPage = 1;
    @track totalRecords = 0;
    @track startRecord = 0;
    @track endRecord = 0;

    // Fancy loading animation properties
    @track loadingMessage = 'Analyzing Flow...';
    @track loadingSubMessage = 'Einstein is reading your flow metadata';
    @track analysisProgress = 20;
    @track funTip = 'Einstein can analyze 12 different best practice categories!';

    columns = COLUMNS;
    statusOptions = [
        { label: 'All', value: 'All' },
        { label: 'Pass', value: 'Pass' },
        { label: 'Needs Work', value: 'Needs Work' },
        { label: 'Fail', value: 'Fail' },
        { label: 'Pending', value: 'Pending' },
        { label: 'Analyzing', value: 'Analyzing' },
        { label: 'Error', value: 'Error' }
    ];

    // Loading messages rotation
    loadingMessages = [
        { main: 'Fetching Flow Metadata...', sub: 'Connecting to Tooling API', progress: 20 },
        { main: 'Analyzing Flow Structure...', sub: 'Einstein is examining your flow design', progress: 40 },
        { main: 'Checking Best Practices...', sub: 'Evaluating against 12 categories', progress: 60 },
        { main: 'Generating Recommendations...', sub: 'Creating actionable insights', progress: 80 },
        { main: 'Almost Done...', sub: 'Finalizing analysis report', progress: 95 }
    ];

    funTips = [
        'Einstein can analyze 12 different best practice categories!',
        'Flows with proper error handling get higher scores 🎯',
        'Bulkification is key - avoid DML in loops! 🔄',
        'Did you know? Named variables improve flow readability 📝',
        'Pro tip: Use subflows to make your flows reusable! ♻️',
        'Einstein checks for governor limit risks automatically ⚡',
        'Flows should have clear descriptions and documentation 📚',
        'Security tip: Always check user permissions in flows 🔒'
    ];

    progressInterval;
    messageIndex = 0;

    // Wire methods
    wiredSummaryStatsResult;
    wiredFlowAnalysesResult;

    @wire(getSummaryStats)
    wiredSummaryStats(result) {
        this.wiredSummaryStatsResult = result;
        if (result.data) {
            this.summaryStats = result.data;
        } else if (result.error) {
            this.showToast('Error', 'Error loading summary statistics', 'error');
        }
    }

    @wire(getFlowAnalyses, { statusFilter: '$selectedStatus', searchTerm: '$searchTerm' })
    wiredFlowAnalyses(result) {
        this.wiredFlowAnalysesResult = result;
        if (result.data) {
            this.flowAnalyses = result.data.map(analysis => ({
                ...analysis,
                statusClass: this.getStatusClass(analysis.status),
                isSelected: false
            }));
            this.filteredAnalyses = [...this.flowAnalyses];
            this.selectedRows = [];
            this.currentPage = 1; // Reset to first page on new data
            this.updatePaginatedData();
        } else if (result.error) {
            this.showToast('Error', 'Error loading flow analyses', 'error');
        }
    }

    connectedCallback() {
        // Poll for batch progress every 5 seconds if batch is running
        this.startProgressPolling();
    }

    disconnectedCallback() {
        // Stop polling when component is destroyed
        this.stopProgressPolling();
    }

    // Event handlers
    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
        this.refreshData();
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        this.refreshData();
    }

    handleRunAllFlows() {
        this.isLoadingSimple = true;
        syncFlowList()
            .then(result => {
                this.showToast('Success', result, 'success');
                // Refresh the data to show newly synced flows
                return Promise.all([
                    refreshApex(this.wiredSummaryStatsResult),
                    refreshApex(this.wiredFlowAnalysesResult)
                ]);
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || 'Error syncing flow list', 'error');
            })
            .finally(() => {
                this.isLoadingSimple = false;
            });
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'view_details':
                this.handleViewDetails(row);
                break;
            case 'reanalyze':
                this.handleReanalyze(row);
                break;
        }
    }

    handleViewDetails(row) {
        this.selectedFlow = row;
        this.showDetailModal = true;

        // Use setTimeout to ensure DOM is rendered before injecting content
        setTimeout(() => {
            const container = this.template.querySelector('.analysis-report-content');
            if (container && row.analysisReport) {
                const formattedHTML = this.parseAndFormatAnalysis(row.analysisReport);
                container.innerHTML = formattedHTML;
            }
        }, 100);
    }

    parseAndFormatAnalysis(reportText) {
        try {
            let trimmed = reportText.trim();
            
            console.log('🔍 Starting parseAndFormatAnalysis');
            console.log('📝 Input (first 200 chars):', trimmed.substring(0, 200));

            // Check if it's already formatted HTML (from the backend)
            if (trimmed.startsWith('<div') || trimmed.startsWith('<html')) {
                console.log('✅ Detected pre-formatted HTML, rendering directly');
                return trimmed;
            }

            // CRITICAL: Decode HTML entities (Salesforce encodes JSON as HTML)
            // This converts &quot; → " , &amp; → & , &#128203; → 📋 etc.
            if (trimmed.includes('&quot;') || trimmed.includes('&amp;') || trimmed.includes('&#')) {
                console.log('🔧 Detected HTML entities, decoding...');
                const textarea = document.createElement('textarea');
                textarea.innerHTML = trimmed;
                trimmed = textarea.value;
                console.log('✅ Decoded (first 200 chars):', trimmed.substring(0, 200));
            }

            // Check if it's HTML-wrapped JSON (old format)
            if (trimmed.startsWith('<') && !trimmed.startsWith('{')) {
                console.log('🔄 Detected HTML-wrapped content, extracting...');
                const tempDiv = document.createElement('div');
                tempDiv.innerHTML = trimmed;
                let extractedText = tempDiv.textContent || tempDiv.innerText || '';
                extractedText = extractedText.trim();
                console.log('📤 Extracted text (first 200 chars):', extractedText.substring(0, 200));
                
                if (!extractedText || extractedText.startsWith('<')) {
                    console.log('⚠️ Extraction failed, returning original');
                    return trimmed;
                }
                trimmed = extractedText;
            }

            // Remove markdown code block if present
            let jsonMatch = trimmed.match(/```json\s*([\s\S]*?)\s*```/);
            if (jsonMatch) {
                console.log('📦 Found JSON markdown block');
                trimmed = jsonMatch[1].trim();
            } else {
                jsonMatch = trimmed.match(/```\s*([\s\S]*?)\s*```/);
                if (jsonMatch) {
                    console.log('📦 Found generic markdown block');
                    trimmed = jsonMatch[1].trim();
                }
            }

            // Check if it's a JSON object (starts with {)
            if (!trimmed.startsWith('{')) {
                console.log('❌ Not a JSON object (first char: ' + trimmed.charAt(0) + '), returning as formatted text');
                return this.formatRawText(reportText);
            }

            // Parse the JSON
            console.log('🔄 Attempting to parse JSON...');
            const analysisData = JSON.parse(trimmed);
            console.log('✅ JSON parsed successfully');
            console.log('📊 Data keys:', Object.keys(analysisData));
            
            // Check if we have required data
            if (!analysisData.overallScore && !analysisData.score && !analysisData.categories && !analysisData.findings) {
                console.warn('⚠️ JSON missing expected fields, falling back to raw text');
                return this.formatRawText(reportText);
            }

            console.log('🎨 Generating HTML from JSON...');
            const html = this.generateHtmlFromJson(analysisData);
            console.log('✅ HTML generated successfully, length:', html.length);
            return html;

        } catch (error) {
            console.error('❌ Error parsing analysis report:', error);
            console.error('📋 Error message:', error.message);
            console.error('📄 Failed on text (first 500 chars):', reportText.substring(0, 500));
            return this.formatRawText(reportText);
        }
    }
    
    generateHtmlFromJson(analysisData) {
        console.log('🎨 Starting HTML generation from JSON');
        let html = '<div style="font-family: -apple-system, BlinkMacSystemFont, \'Segoe UI\', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333;">';

        // Overall Score Banner - Purple gradient with large score
        const score = analysisData.overallScore || analysisData.score;
        const status = analysisData.overallStatus || analysisData.status;
        
        if (score || status) {
            html += '<div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 40px 30px; border-radius: 8px; margin: 0 0 30px 0; text-align: center;">';
            if (score) {
                // Round score to whole number for display
                const roundedScore = Math.round(score);
                html += `<div style="font-size: 56px; font-weight: 700; margin-bottom: 10px;">${roundedScore}%</div>`;
            }
            if (status) {
                // Map PARTIAL to NEEDS WORK for display
                const displayStatus = this.getDisplayStatus(status);
                html += `<div style="font-size: 22px; font-weight: 600; text-transform: uppercase; letter-spacing: 2px;">${displayStatus}</div>`;
            }
            html += '</div>';
        }

            // Categories - Clean UI design with white boxes
            if (analysisData.categories && analysisData.categories.length > 0) {
                analysisData.categories.forEach(category => {
                    // Category container - white background with left border
                    html += '<div style="margin-bottom: 25px; padding: 20px; background: white; border-left: 4px solid #0176d3; border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">';

                    // Category Header with icon and number
                    const icon = category.icon || '';
                    const number = category.number || '';
                    const name = category.name || 'Category';
                    html += `<h3 style="color: #032e61; font-size: 20px; font-weight: 700; margin: 0 0 12px 0;">${icon} ${number}. ${this.escapeHtml(name)}</h3>`;

                    // Analysis/Overview in italics
                    if (category.analysis) {
                        html += `<p style="font-style: italic; color: #555; margin-bottom: 15px; font-size: 15px; line-height: 1.6;">${this.escapeHtml(category.analysis)}</p>`;
                    }

                    // Details with bold headings
                    if (category.details && category.details.length > 0) {
                        category.details.forEach(detail => {
                            if (detail.heading && detail.content) {
                                html += `<p style="margin: 10px 0; line-height: 1.6;"><strong style="color: #032e61;">${this.escapeHtml(detail.heading)}:</strong> ${this.escapeHtml(detail.content)}</p>`;
                            }
                        });
                    }

                    // Status Badge - map PARTIAL to NEEDS WORK for display
                    if (category.status) {
                        const statusColor = this.getStatusColor(category.status);
                        const displayStatus = this.getDisplayStatus(category.status);
                        html += '<div style="margin: 15px 0 12px 0;">';
                        html += `<span style="display: inline-block; background: ${statusColor}; color: white; padding: 6px 14px; border-radius: 4px; font-weight: 600; font-size: 12px;">Status: ${displayStatus}</span>`;
                        html += '</div>';
                    }

                    // Explanation - yellow/gold left border
                    if (category.explanation) {
                        html += '<div style="margin: 15px 0; padding: 12px 15px; background: #fffbf0; border-left: 4px solid #ffc107; border-radius: 3px;">';
                        html += `<p style="margin: 0; line-height: 1.6;"><strong>Explanation:</strong> ${this.escapeHtml(category.explanation)}</p>`;
                        html += '</div>';
                    }

                    // Recommendation - blue left border
                    if (category.recommendation) {
                        html += '<div style="margin: 15px 0; padding: 12px 15px; background: #e7f3ff; border-left: 4px solid #0176d3; border-radius: 3px;">';
                        html += `<p style="margin: 0; line-height: 1.6;"><strong style="color: #0176d3;">Recommendation:</strong> ${this.escapeHtml(category.recommendation)}</p>`;
                        html += '</div>';
                    }

                    html += '</div>';
                });
            }

            // Summary Table
            if (analysisData.summaryTable && analysisData.summaryTable.length > 0) {
                html += '<h2 style="color: #032e61; font-size: 24px; font-weight: 700; margin: 40px 0 20px 0; padding-bottom: 10px; border-bottom: 3px solid #0176d3;">📊 Final Summary Table</h2>';
                html += '<table style="width: 100%; border-collapse: collapse; margin: 20px 0; box-shadow: 0 4px 6px rgba(0,0,0,0.1); border-radius: 8px; overflow: hidden;">';
                html += '<thead>';
                html += '<tr style="background: linear-gradient(135deg, #032e61 0%, #0176d3 100%);">';
                html += '<th style="color: white; padding: 16px; text-align: left; font-weight: 700; font-size: 14px; text-transform: uppercase;">Area</th>';
                html += '<th style="color: white; padding: 16px; text-align: left; font-weight: 700; font-size: 14px; text-transform: uppercase;">Status</th>';
                html += '<th style="color: white; padding: 16px; text-align: left; font-weight: 700; font-size: 14px; text-transform: uppercase;">Fix/Recommendation</th>';
                html += '</tr>';
                html += '</thead>';
                html += '<tbody>';

                analysisData.summaryTable.forEach((row, index) => {
                    const bgColor = index % 2 === 0 ? 'white' : '#f8f9fa';
                    html += `<tr style="background: ${bgColor}; transition: background 0.2s;">`;
                    html += `<td style="padding: 14px; border-bottom: 1px solid #e0e0e0;"><strong>${this.escapeHtml(row.area || '')}</strong></td>`;
                    const statusColor = this.getStatusColor(row.status);
                    const displayStatus = this.getDisplayStatus(row.status);
                    html += `<td style="padding: 14px; border-bottom: 1px solid #e0e0e0;"><span style="background: ${statusColor}; color: white; padding: 4px 12px; border-radius: 4px; font-weight: 600; font-size: 12px; display: inline-block;">${displayStatus}</span></td>`;
                    html += `<td style="padding: 14px; border-bottom: 1px solid #e0e0e0;">${this.escapeHtml(row.fix || '')}</td>`;
                    html += '</tr>';
                });

                html += '</tbody>';
                html += '</table>';
            }

            // NEW FORMAT: Priorities Section (Must Fix, Should Fix, Consider)
            if (analysisData.priorities) {
                html += '<div style="margin-top: 40px;">';
                
                // Must Fix (Critical)
                if (analysisData.priorities.mustFix && analysisData.priorities.mustFix.length > 0) {
                    html += '<div style="background: #fef2f2; border-left: 4px solid #c23934; padding: 20px; margin: 15px 0; border-radius: 4px;">';
                    html += '<h3 style="color: #c23934; margin: 0 0 12px 0;">🚨 Must Fix (Critical)</h3>';
                    html += '<ul style="margin: 0; padding-left: 20px;">';
                    analysisData.priorities.mustFix.forEach(item => {
                        html += `<li style="margin: 8px 0; color: #7f1d1d;">${this.escapeHtml(item)}</li>`;
                    });
                    html += '</ul></div>';
                }
                
                // Should Fix (Needs Work)
                if (analysisData.priorities.shouldFix && analysisData.priorities.shouldFix.length > 0) {
                    html += '<div style="background: #fffbeb; border-left: 4px solid #f49756; padding: 20px; margin: 15px 0; border-radius: 4px;">';
                    html += '<h3 style="color: #b45309; margin: 0 0 12px 0;">⚠️ Should Fix (Before Production)</h3>';
                    html += '<ul style="margin: 0; padding-left: 20px;">';
                    analysisData.priorities.shouldFix.forEach(item => {
                        html += `<li style="margin: 8px 0; color: #78350f;">${this.escapeHtml(item)}</li>`;
                    });
                    html += '</ul></div>';
                }
                
                // Consider (Minor Suggestions)
                if (analysisData.priorities.consider && analysisData.priorities.consider.length > 0) {
                    html += '<div style="background: #eff6ff; border-left: 4px solid #17a2b8; padding: 20px; margin: 15px 0; border-radius: 4px;">';
                    html += '<h3 style="color: #0369a1; margin: 0 0 12px 0;">💡 Consider (Future Improvements)</h3>';
                    html += '<ul style="margin: 0; padding-left: 20px;">';
                    analysisData.priorities.consider.forEach(item => {
                        html += `<li style="margin: 8px 0; color: #1e3a5f;">${this.escapeHtml(item)}</li>`;
                    });
                    html += '</ul></div>';
                }
                
                html += '</div>';
            }

            // NEW FORMAT: Strengths Section
            if (analysisData.strengths && analysisData.strengths.length > 0) {
                html += '<div style="background: #ecfdf5; border-left: 4px solid #2e844a; padding: 20px; margin: 30px 0 15px 0; border-radius: 4px;">';
                html += '<h3 style="color: #2e844a; margin: 0 0 12px 0;">✅ Strengths</h3>';
                html += '<ul style="margin: 0; padding-left: 20px;">';
                analysisData.strengths.forEach(strength => {
                    html += `<li style="margin: 8px 0; color: #14532d;">${this.escapeHtml(String(strength))}</li>`;
                });
                html += '</ul></div>';
            }
            
            // OLD FORMAT SUPPORT: Summary
            if (analysisData.summary) {
                html += '<div style="background: #f0f9ff; padding: 20px; margin: 20px 0; border-left: 4px solid #0176d3; border-radius: 4px;">';
                html += `<p style="margin: 0; font-size: 16px; line-height: 1.6;">${this.escapeHtml(analysisData.summary)}</p>`;
                html += '</div>';
            }
            
            // OLD FORMAT: Findings (for backward compatibility)
            if (analysisData.findings && analysisData.findings.length > 0) {
                html += '<h2 style="color: #032e61; font-size: 24px; font-weight: 700; margin: 40px 0 20px 0;">Detailed Findings</h2>';
                analysisData.findings.forEach((finding, index) => {
                    html += '<div style="margin-bottom: 30px; padding: 20px; background: white; border-left: 5px solid #0176d3; border-radius: 4px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">';
                    html += `<h3 style="color: #0176d3; margin: 0 0 12px 0;">${index + 1}. ${this.escapeHtml(finding.category || 'Finding')}</h3>`;
                    
                    if (finding.severity) {
                        const sevColor = finding.severity === 'High' ? '#c23934' : (finding.severity === 'Medium' ? '#f49756' : '#2e844a');
                        html += `<span style="background: ${sevColor}; color: white; padding: 4px 10px; border-radius: 3px; font-size: 12px; font-weight: 600;">${this.escapeHtml(finding.severity)}</span>`;
                    }
                    
                    if (finding.issue) {
                        html += `<p style="margin: 12px 0;"><strong>Issue:</strong> ${this.escapeHtml(finding.issue)}</p>`;
                    }
                    
                    if (finding.recommendation) {
                        html += `<p style="margin: 12px 0; padding: 12px; background: #f0f9ff; border-radius: 4px;"><strong>Recommendation:</strong> ${this.escapeHtml(finding.recommendation)}</p>`;
                    }
                    
                    html += '</div>';
                });
            }
            
            // Risks (old format)
            if (analysisData.risks && analysisData.risks.length > 0) {
                html += '<h3 style="color: #c23934; margin-top: 30px;">⚠️ Risks</h3><ul style="color: #c23934;">';
                analysisData.risks.forEach(risk => {
                    html += `<li>${this.escapeHtml(String(risk))}</li>`;
                });
                html += '</ul>';
            }

            html += '</div>';
            return html;
    }

    formatRawText(text) {
        // Format raw JSON text with basic styling
        return `<div style="font-family: monospace; background: #f5f5f5; padding: 20px; border-radius: 4px; white-space: pre-wrap; word-wrap: break-word;">${this.escapeHtml(text)}</div>`;
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    getStatusColor(status) {
        if (!status) return '#666';
        const statusLower = status.toLowerCase();
        if (statusLower === 'pass' || statusLower === 'compliant') return '#2e844a';
        if (statusLower === 'minor') return '#17a2b8'; // Blue for minor suggestions
        if (statusLower === 'partial' || statusLower === 'needs work' || statusLower === 'needs_work') return '#f49756';
        if (statusLower === 'fail' || statusLower === 'issue' || statusLower === 'critical') return '#c23934';
        if (statusLower === 'n/a') return '#6c757d'; // Gray for N/A
        return '#666';
    }
    
    // Map AI status to user-friendly display
    getDisplayStatus(status) {
        if (!status) return '';
        const statusLower = status.toLowerCase();
        if (statusLower === 'partial') return 'NEEDS WORK';
        if (statusLower === 'n/a') return 'N/A';
        return status.toUpperCase();
    }

    getSeverityColor(severity) {
        const severityLower = severity.toLowerCase();
        if (severityLower === 'high') return '#c23934';
        if (severityLower === 'medium') return '#f49756';
        return '#2e844a'; // Low
    }

    extractBriefRecommendation(fullRecommendation) {
        // Extract first sentence or first 100 characters
        const sentences = fullRecommendation.split('. ');
        if (sentences.length > 0 && sentences[0].length < 150) {
            return sentences[0] + '.';
        }
        return fullRecommendation.substring(0, 100) + '...';
    }

    cleanAndEnhanceHTML(htmlText) {
        // Parse the HTML and fix missing background colors on severity badges
        const parser = new DOMParser();
        const doc = parser.parseFromString(htmlText, 'text/html');

        // Find all severity/priority badge spans that are missing background colors
        const badges = doc.querySelectorAll('span[style*="display: inline-block"]');
        badges.forEach(badge => {
            const text = badge.textContent.trim().toLowerCase();
            let bgColor = '';

            // Check if it's a severity badge
            if (text === 'high') {
                bgColor = '#c23934';
            } else if (text === 'medium') {
                bgColor = '#f49756';
            } else if (text === 'low') {
                bgColor = '#2e844a';
            } else if (text === 'fail' || text === 'issue') {
                bgColor = '#c23934';
            } else if (text === 'needs work' || text === 'needs_work') {
                bgColor = '#f49756';
            } else if (text === 'pass' || text === 'compliant') {
                bgColor = '#2e844a';
            }

            if (bgColor) {
                // Add background color and ensure white text
                badge.style.backgroundColor = bgColor;
                badge.style.color = 'white';
                badge.style.padding = '4px 10px';
                badge.style.borderRadius = '4px';
                badge.style.fontWeight = '600';
                badge.style.display = 'inline-block';
            }
        });

        // Return the enhanced HTML
        return doc.body.innerHTML;
    }

    handleCloseModal() {
        this.showDetailModal = false;
        this.selectedFlow = null;
    }

    handleOpenHelp() {
        this.showHelpModal = true;
    }

    handleCloseHelp() {
        this.showHelpModal = false;
    }

    handleExportPDF() {
        if (!this.selectedFlow) return;

        // Show loading message
        this.showToast('Info', 'Generating PDF...', 'info');

        // Call Apex to generate PDF
        generatePDF({ recordId: this.selectedFlow.id })
            .then(base64PDF => {
                // Convert base64 to binary
                const byteCharacters = atob(base64PDF);
                const byteNumbers = new Array(byteCharacters.length);
                for (let i = 0; i < byteCharacters.length; i++) {
                    byteNumbers[i] = byteCharacters.charCodeAt(i);
                }
                const byteArray = new Uint8Array(byteNumbers);
                const blob = new Blob([byteArray], { type: 'application/pdf' });

                // Create download link
                const link = document.createElement('a');
                link.href = window.URL.createObjectURL(blob);
                link.download = `${this.selectedFlow.flowApiName}_Analysis.pdf`;
                link.click();

                // Clean up
                window.URL.revokeObjectURL(link.href);

                this.showToast('Success', 'PDF exported successfully!', 'success');
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || 'Error generating PDF', 'error');
            });
    }


    handleReanalyze(row) {
        // Store flow label before refresh to avoid UI flicker
        const flowLabel = row.flowLabel;
        const flowApiName = row.flowApiName;

        // Start fancy loading animation
        this.startAnalysisAnimation();

        reanalyzeFlow({ flowApiName: flowApiName })
            .then(result => {
                this.stopAnalysisAnimation();
                this.showToast('Success', `✨ Flow analyzed successfully: ${flowLabel}`, 'success');
                // Small delay to ensure record is committed before refresh
                return new Promise(resolve => setTimeout(resolve, 500));
            })
            .then(() => {
                // Refresh data without showing loading spinner to avoid flicker
                return Promise.all([
                    refreshApex(this.wiredSummaryStatsResult),
                    refreshApex(this.wiredFlowAnalysesResult)
                ]);
            })
            .catch(error => {
                this.stopAnalysisAnimation();
                this.showToast('Error', error.body?.message || 'Error re-analyzing flow', 'error');
            });
    }

    startAnalysisAnimation() {
        this.isAnalyzing = true;
        this.messageIndex = 0;

        // Set initial message
        this.updateLoadingMessage();

        // Pick a random fun tip
        this.funTip = this.funTips[Math.floor(Math.random() * this.funTips.length)];

        // Update message every 3 seconds
        this.progressInterval = setInterval(() => {
            this.messageIndex = (this.messageIndex + 1) % this.loadingMessages.length;
            this.updateLoadingMessage();
        }, 3000);
    }

    stopAnalysisAnimation() {
        this.isAnalyzing = false;
        if (this.progressInterval) {
            clearInterval(this.progressInterval);
        }
    }

    updateLoadingMessage() {
        const message = this.loadingMessages[this.messageIndex];
        this.loadingMessage = message.main;
        this.loadingSubMessage = message.sub;
        this.analysisProgress = message.progress;
    }

    handleRunAnalysis(event) {
        const flowId = event.target.dataset.id;
        const flow = this.paginatedData.find(f => f.id === flowId);
        if (flow) {
            this.handleReanalyze(flow);
        }
    }

    handleViewAnalysis(event) {
        const flowId = event.target.dataset.id;
        const flow = this.paginatedData.find(f => f.id === flowId);
        if (flow) {
            this.handleViewDetails(flow);
        }
    }

    handleSelectAll(event) {
        const isChecked = event.target.checked;
        this.paginatedData = this.paginatedData.map(flow => ({
            ...flow,
            isSelected: isChecked
        }));

        if (isChecked) {
            this.selectedRows = this.paginatedData.map(f => f.id);
        } else {
            this.selectedRows = [];
        }
    }

    handleRowSelection(event) {
        const flowId = event.target.dataset.id;
        const isChecked = event.target.checked;

        this.paginatedData = this.paginatedData.map(flow => {
            if (flow.id === flowId) {
                return { ...flow, isSelected: isChecked };
            }
            return flow;
        });

        if (isChecked) {
            this.selectedRows = [...this.selectedRows, flowId];
        } else {
            this.selectedRows = this.selectedRows.filter(id => id !== flowId);
        }
    }

    handleDeleteSelected() {
        if (this.selectedRows.length === 0) return;

        const count = this.selectedRows.length;
        const message = `Are you sure you want to delete ${count} selected flow ${count === 1 ? 'analysis' : 'analyses'}?`;

        if (confirm(message)) {
            this.deleteRecords(this.selectedRows);
        }
    }

    handleDeleteSingle(event) {
        const flowId = event.target.dataset.id;
        const flow = this.paginatedData.find(f => f.id === flowId);

        if (confirm(`Are you sure you want to delete the analysis for "${flow.flowLabel}"?`)) {
            this.deleteRecords([flowId]);
        }
    }

    handleRefresh() {
        this.refreshData();
        this.checkBatchProgress();
    }

    deleteRecords(recordIds) {
        this.isLoading = true;
        deleteAnalyses({ recordIds: recordIds })
            .then(() => {
                this.showToast('Success', `${recordIds.length} record(s) deleted successfully`, 'success');
                return Promise.all([
                    refreshApex(this.wiredSummaryStatsResult),
                    refreshApex(this.wiredFlowAnalysesResult)
                ]);
            })
            .then(() => {
                this.selectedRows = [];
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || 'Error deleting records', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Helper methods
    refreshData() {
        this.isLoading = true;
        Promise.all([
            refreshApex(this.wiredSummaryStatsResult),
            refreshApex(this.wiredFlowAnalysesResult)
        ]).finally(() => {
            this.isLoading = false;
        });
    }

    startProgressPolling() {
        this.progressInterval = setInterval(() => {
            this.checkBatchProgress();
        }, 5000); // Poll every 5 seconds
    }

    stopProgressPolling() {
        if (this.progressInterval) {
            clearInterval(this.progressInterval);
        }
    }

    checkBatchProgress() {
        getBatchProgress()
            .then(progress => {
                this.batchProgress = progress;
                this.isBatchRunning = progress.isRunning;

                // If batch just finished, refresh data
                if (!progress.isRunning && this.wasBatchRunning) {
                    this.refreshData();
                }
                this.wasBatchRunning = progress.isRunning;
            })
            .catch(error => {
                console.error('Error checking batch progress:', error);
            });
    }

    getStatusClass(status) {
        const statusMap = {
            'Pass': 'slds-text-color_success',
            'Fail': 'slds-text-color_error',
            'Needs Work': 'slds-text-color_warning',
            'Pending': 'slds-text-color_weak',
            'Analyzing': 'slds-text-color_default',
            'Error': 'slds-text-color_error'
        };
        return statusMap[status] || '';
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    // Getters for computed properties
    get isAllSelected() {
        return this.paginatedData.length > 0 &&
               this.paginatedData.every(flow => flow.isSelected);
    }

    get hasNoSelection() {
        return this.selectedRows.length === 0;
    }

    get passCount() {
        return this.summaryStats.Pass || 0;
    }

    get failCount() {
        return this.summaryStats.Fail || 0;
    }

    get needsWorkCount() {
        return this.summaryStats['Needs Work'] || 0;
    }

    get pendingCount() {
        return this.summaryStats.Pending || 0;
    }

    get analyzingCount() {
        return this.summaryStats.Analyzing || 0;
    }

    get totalCount() {
        return this.summaryStats.Total || 0;
    }

    get hasFlows() {
        return this.filteredAnalyses && this.filteredAnalyses.length > 0;
    }

    get batchProgressText() {
        if (!this.isBatchRunning) return '';
        const processed = this.batchProgress.jobItemsProcessed || 0;
        const total = this.batchProgress.totalJobItems || 0;
        return `Processing: ${processed} of ${total}`;
    }

    get showBatchProgress() {
        return this.isBatchRunning;
    }

    get detailReportHtml() {
        return this.selectedFlow?.analysisReport || 'No analysis report available.';
    }

    // Pagination getters
    get pageLabel() {
        const totalPages = Math.ceil(this.totalRecords / this.pageSize);
        return `Page ${this.currentPage} of ${totalPages}`;
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        const totalPages = Math.ceil(this.totalRecords / this.pageSize);
        return this.currentPage >= totalPages;
    }

    get pageSize10Variant() {
        return this.pageSize === 10 ? 'brand' : 'neutral';
    }

    get pageSize25Variant() {
        return this.pageSize === 25 ? 'brand' : 'neutral';
    }

    get pageSize50Variant() {
        return this.pageSize === 50 ? 'brand' : 'neutral';
    }

    get pageSize100Variant() {
        return this.pageSize === 100 ? 'brand' : 'neutral';
    }

    // Pagination methods
    handlePageSize10() {
        this.pageSize = 10;
        this.currentPage = 1;
        this.updatePaginatedData();
    }

    handlePageSize25() {
        this.pageSize = 25;
        this.currentPage = 1;
        this.updatePaginatedData();
    }

    handlePageSize50() {
        this.pageSize = 50;
        this.currentPage = 1;
        this.updatePaginatedData();
    }

    handlePageSize100() {
        this.pageSize = 100;
        this.currentPage = 1;
        this.updatePaginatedData();
    }

    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePaginatedData();
        }
    }

    handleNextPage() {
        const totalPages = Math.ceil(this.totalRecords / this.pageSize);
        if (this.currentPage < totalPages) {
            this.currentPage++;
            this.updatePaginatedData();
        }
    }

    updatePaginatedData() {
        this.totalRecords = this.filteredAnalyses.length;
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;

        this.paginatedData = this.filteredAnalyses.slice(start, end);
        this.startRecord = this.totalRecords > 0 ? start + 1 : 0;
        this.endRecord = Math.min(end, this.totalRecords);
    }

    handleAnalyzeSelected() {
        if (this.selectedRows.length === 0) {
            this.showToast('Warning', 'Please select at least one flow to analyze', 'warning');
            return;
        }

        if (this.selectedRows.length > 5) {
            this.showToast('Warning', 'Please select maximum 5 flows at a time to avoid system overload', 'warning');
            return;
        }

        // Get selected flow records - allow re-analysis of any flow
        const flowsToAnalyze = this.paginatedData.filter(flow =>
            this.selectedRows.includes(flow.id)
        );

        // Confirm before proceeding
        const message = `Analyze ${flowsToAnalyze.length} flow(s)? This will use Einstein credits.`;
        if (!confirm(message)) {
            return;
        }

        // Start fancy loading animation
        this.startAnalysisAnimation();

        let successCount = 0;
        let errorCount = 0;
        const totalFlows = flowsToAnalyze.length;

        const analyzeNext = (index) => {
            if (index >= flowsToAnalyze.length) {
                // All done - stop animation
                this.stopAnalysisAnimation();
                this.showToast(
                    'Bulk Analysis Complete',
                    `✅ Success: ${successCount}, ❌ Errors: ${errorCount}`,
                    errorCount > 0 ? 'warning' : 'success'
                );
                return Promise.all([
                    refreshApex(this.wiredSummaryStatsResult),
                    refreshApex(this.wiredFlowAnalysesResult)
                ]);
            }

            const flow = flowsToAnalyze[index];
            const currentFlowNumber = index + 1;

            // Update loading message to show current flow being processed
            this.loadingMessage = `Analyzing Flow ${currentFlowNumber} of ${totalFlows}`;
            this.loadingSubMessage = `Processing: ${flow.flowLabel}`;
            this.analysisProgress = Math.round((currentFlowNumber / totalFlows) * 100);

            return reanalyzeFlow({ flowApiName: flow.flowApiName })
                .then(() => {
                    successCount++;
                    // Refresh data after each analysis
                    return Promise.all([
                        refreshApex(this.wiredSummaryStatsResult),
                        refreshApex(this.wiredFlowAnalysesResult)
                    ]);
                })
                .catch(error => {
                    errorCount++;
                    console.error(`Failed to analyze ${flow.flowLabel}:`, error);
                })
                .then(() => {
                    // Continue with next flow
                    return analyzeNext(index + 1);
                });
        };

        // Start the chain
        analyzeNext(0);
    }

    handleDeleteAll() {
        if (confirm('⚠️ Are you sure you want to delete ALL flow analysis records? This action cannot be undone!')) {
            this.isLoading = true;
            deleteAllAnalyses()
                .then(result => {
                    this.showToast('Success', result, 'success');
                    this.selectedRows = [];
                    return Promise.all([
                        refreshApex(this.wiredSummaryStatsResult),
                        refreshApex(this.wiredFlowAnalysesResult)
                    ]);
                })
                .catch(error => {
                    this.showToast('Error', error.body?.message || 'Error deleting records', 'error');
                })
                .finally(() => {
                    this.isLoading = false;
                });
        }
    }

    handleUpdateFlow(event) {
        const flowId = event.target.dataset.id;
        const flow = this.paginatedData.find(f => f.id === flowId);

        this.isLoading = true;
        updateFlowMetadata({ recordId: flowId })
            .then(result => {
                this.showToast('Success', result, 'success');
                return Promise.all([
                    refreshApex(this.wiredSummaryStatsResult),
                    refreshApex(this.wiredFlowAnalysesResult)
                ]);
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || 'Error updating flow', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}