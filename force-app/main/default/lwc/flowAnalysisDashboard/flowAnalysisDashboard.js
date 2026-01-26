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
        { label: 'Partial', value: 'Partial' },
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
            let jsonText = reportText.trim();

            // Check if the response is HTML-wrapped JSON
            if (jsonText.startsWith('<')) {
                console.log('Detected HTML-wrapped JSON, extracting...');

                // Extract text content from HTML
                const tempDiv = document.createElement('div');
                tempDiv.innerHTML = jsonText;
                jsonText = tempDiv.textContent || tempDiv.innerText || '';
                jsonText = jsonText.trim();

                console.log('Extracted text from HTML:', jsonText.substring(0, 200));
            }

            // Remove markdown code block if present
            const jsonMatch = jsonText.match(/```json\s*([\s\S]*?)\s*```/);
            if (jsonMatch) {
                jsonText = jsonMatch[1].trim();
            }

            // Check if it's a JSON object (starts with {)
            if (!jsonText.startsWith('{')) {
                console.log('Not a JSON object, returning raw text');
                return this.formatRawText(reportText);
            }

            // Parse the JSON
            console.log('Attempting to parse JSON...');
            const analysisData = JSON.parse(jsonText);
            console.log('JSON parsed successfully:', analysisData);

            // Format as HTML matching the guru format
            let html = '<div style="font-family: -apple-system, BlinkMacSystemFont, \'Segoe UI\', Roboto, Helvetica, Arial, sans-serif; line-height: 1.8; color: #333; max-width: 1200px;">';

            // Overall Score Banner
            html += '<div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 8px; margin-bottom: 30px; text-align: center;">';
            html += `<div style="font-size: 48px; font-weight: 700; margin-bottom: 10px;">${analysisData.overallScore}%</div>`;
            html += `<div style="font-size: 20px; font-weight: 600; text-transform: uppercase; letter-spacing: 2px;">${analysisData.overallStatus}</div>`;
            html += '</div>';

            // Categories
            if (analysisData.categories && analysisData.categories.length > 0) {
                analysisData.categories.forEach(category => {
                    html += '<div style="margin-bottom: 40px; padding: 25px; background: #f8f9fa; border-radius: 8px; border-left: 5px solid #0176d3;">';

                    // Category Header
                    html += `<h2 style="color: #032e61; font-size: 22px; font-weight: 700; margin: 0 0 15px 0;">${category.icon} ${category.number}. ${category.name}</h2>`;

                    // Analysis
                    html += `<p style="font-style: italic; color: #555; margin-bottom: 20px; font-size: 15px;">${category.analysis}</p>`;

                    // Details
                    if (category.details && category.details.length > 0) {
                        category.details.forEach(detail => {
                            html += `<p style="margin: 12px 0;"><strong style="color: #032e61;">${detail.heading}:</strong> ${detail.content}</p>`;
                        });
                    }

                    // Status Badge
                    const statusColor = this.getStatusColor(category.status);
                    html += '<div style="margin: 20px 0;">';
                    html += `<span style="background: ${statusColor}; color: white; padding: 6px 14px; border-radius: 4px; font-weight: 600; font-size: 13px; display: inline-block;">Status: ${category.status}</span>`;
                    html += '</div>';

                    // Explanation
                    html += `<p style="background: white; padding: 15px; border-left: 4px solid #ffc107; margin: 15px 0; border-radius: 4px;"><strong>Explanation:</strong> ${category.explanation}</p>`;

                    // Recommendation
                    html += `<p style="background: #e7f3ff; padding: 15px; border-left: 4px solid #0176d3; margin: 15px 0; border-radius: 4px;"><strong style="color: #0176d3;">Recommendation:</strong> ${category.recommendation}</p>`;

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
                    html += `<td style="padding: 14px; border-bottom: 1px solid #e0e0e0;"><strong>${row.area}</strong></td>`;
                    const statusColor = this.getStatusColor(row.status);
                    html += `<td style="padding: 14px; border-bottom: 1px solid #e0e0e0;"><span style="background: ${statusColor}; color: white; padding: 4px 12px; border-radius: 4px; font-weight: 600; font-size: 12px; display: inline-block;">${row.status}</span></td>`;
                    html += `<td style="padding: 14px; border-bottom: 1px solid #e0e0e0;">${row.fix}</td>`;
                    html += '</tr>';
                });

                html += '</tbody>';
                html += '</table>';
            }

            html += '</div>';

            return html;

        } catch (error) {
            console.error('Error parsing analysis report:', error);
            console.error('Error details:', error.message);
            console.error('JSON text that failed:', reportText.substring(0, 500));
            // Return formatted raw text if parsing fails
            return this.formatRawText(reportText);
        }
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
        const statusLower = status.toLowerCase();
        if (statusLower === 'pass' || statusLower === 'compliant') return '#2e844a';
        if (statusLower === 'partial') return '#f49756';
        return '#c23934'; // Issue/Fail
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
            } else if (text === 'partial') {
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
            'Partial': 'slds-text-color_warning',
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

    get partialCount() {
        return this.summaryStats.Partial || 0;
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

        // Get selected flow records
        const selectedFlows = this.paginatedData.filter(flow =>
            this.selectedRows.includes(flow.id)
        );

        // Filter out flows that already have analysis in progress or completed
        const flowsToAnalyze = selectedFlows.filter(flow =>
            flow.status === 'Pending' || flow.status === 'Error'
        );

        if (flowsToAnalyze.length === 0) {
            this.showToast('Info', 'All selected flows already have analysis completed or in progress', 'info');
            return;
        }

        if (flowsToAnalyze.length < selectedFlows.length) {
            const skippedCount = selectedFlows.length - flowsToAnalyze.length;
            this.showToast('Info', `Skipping ${skippedCount} flow(s) that already have analysis`, 'info');
        }

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
