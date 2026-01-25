#!/bin/bash

# Flow AI Audit System 2.0 - Validation Script
# This script validates all components before deployment

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     Flow AI Audit System 2.0 - Validation Script              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

VALIDATION_PASSED=true

# Function to check file existence
check_file() {
    if [ -f "$1" ]; then
        echo "✓ $2"
    else
        echo "✗ $2 - NOT FOUND"
        VALIDATION_PASSED=false
    fi
}

# Function to check directory existence
check_dir() {
    if [ -d "$1" ]; then
        echo "✓ $2"
    else
        echo "✗ $2 - NOT FOUND"
        VALIDATION_PASSED=false
    fi
}

echo "Checking Custom Object..."
echo "────────────────────────────────────────────────────────────────"
check_file "force-app/main/default/objects/Flow_Analysis__c/Flow_Analysis__c.object-meta.xml" "Flow_Analysis__c object"
check_file "force-app/main/default/objects/Flow_Analysis__c/fields/Flow_API_Name__c.field-meta.xml" "Flow_API_Name__c field"
check_file "force-app/main/default/objects/Flow_Analysis__c/fields/Flow_Label__c.field-meta.xml" "Flow_Label__c field"
check_file "force-app/main/default/objects/Flow_Analysis__c/fields/Status__c.field-meta.xml" "Status__c field"
check_file "force-app/main/default/objects/Flow_Analysis__c/fields/Overall_Score__c.field-meta.xml" "Overall_Score__c field"
check_file "force-app/main/default/objects/Flow_Analysis__c/fields/Analysis_Report__c.field-meta.xml" "Analysis_Report__c field"
check_file "force-app/main/default/objects/Flow_Analysis__c/fields/Raw_Findings__c.field-meta.xml" "Raw_Findings__c field"
check_file "force-app/main/default/objects/Flow_Analysis__c/fields/Last_Analyzed__c.field-meta.xml" "Last_Analyzed__c field"
check_file "force-app/main/default/objects/Flow_Analysis__c/fields/Flow_Version__c.field-meta.xml" "Flow_Version__c field"
check_file "force-app/main/default/objects/Flow_Analysis__c/fields/Is_Active__c.field-meta.xml" "Is_Active__c field"

echo ""
echo "Checking Apex Classes..."
echo "────────────────────────────────────────────────────────────────"
check_file "force-app/main/default/classes/FlowAnalysisService.cls" "FlowAnalysisService class"
check_file "force-app/main/default/classes/FlowAnalysisService.cls-meta.xml" "FlowAnalysisService metadata"
check_file "force-app/main/default/classes/FlowAnalysisBatch.cls" "FlowAnalysisBatch class"
check_file "force-app/main/default/classes/FlowAnalysisBatch.cls-meta.xml" "FlowAnalysisBatch metadata"
check_file "force-app/main/default/classes/FlowAnalysisQueueable.cls" "FlowAnalysisQueueable class"
check_file "force-app/main/default/classes/FlowAnalysisQueueable.cls-meta.xml" "FlowAnalysisQueueable metadata"
check_file "force-app/main/default/classes/FlowAnalysisDashboardController.cls" "FlowAnalysisDashboardController class"
check_file "force-app/main/default/classes/FlowAnalysisDashboardController.cls-meta.xml" "FlowAnalysisDashboardController metadata"

echo ""
echo "Checking Test Classes..."
echo "────────────────────────────────────────────────────────────────"
check_file "force-app/main/default/classes/FlowAnalysisServiceTest.cls" "FlowAnalysisServiceTest class"
check_file "force-app/main/default/classes/FlowAnalysisServiceTest.cls-meta.xml" "FlowAnalysisServiceTest metadata"
check_file "force-app/main/default/classes/FlowAnalysisBatchTest.cls" "FlowAnalysisBatchTest class"
check_file "force-app/main/default/classes/FlowAnalysisBatchTest.cls-meta.xml" "FlowAnalysisBatchTest metadata"
check_file "force-app/main/default/classes/FlowAnalysisQueueableTest.cls" "FlowAnalysisQueueableTest class"
check_file "force-app/main/default/classes/FlowAnalysisQueueableTest.cls-meta.xml" "FlowAnalysisQueueableTest metadata"
check_file "force-app/main/default/classes/FlowAnalysisDashboardCtrlTest.cls" "FlowAnalysisDashboardCtrlTest class"
check_file "force-app/main/default/classes/FlowAnalysisDashboardCtrlTest.cls-meta.xml" "FlowAnalysisDashboardCtrlTest metadata"

echo ""
echo "Checking Lightning Web Component..."
echo "────────────────────────────────────────────────────────────────"
check_file "force-app/main/default/lwc/flowAnalysisDashboard/flowAnalysisDashboard.js" "LWC JavaScript"
check_file "force-app/main/default/lwc/flowAnalysisDashboard/flowAnalysisDashboard.html" "LWC HTML template"
check_file "force-app/main/default/lwc/flowAnalysisDashboard/flowAnalysisDashboard.css" "LWC CSS"
check_file "force-app/main/default/lwc/flowAnalysisDashboard/flowAnalysisDashboard.js-meta.xml" "LWC metadata"

echo ""
echo "Checking Prompt Template..."
echo "────────────────────────────────────────────────────────────────"
check_file "force-app/main/default/genAiPromptTemplates/Flow_Evaluator_V2.genAiPromptTemplate-meta.xml" "Flow_Evaluator_V2 template"

echo ""
echo "Checking Lightning Page..."
echo "────────────────────────────────────────────────────────────────"
check_file "force-app/main/default/flexipages/Flow_AI_Audit_Dashboard.flexipage-meta.xml" "Flow AI Audit Dashboard page"

echo ""
echo "Checking Documentation..."
echo "────────────────────────────────────────────────────────────────"
check_file "FLOW_AI_AUDIT_README.md" "Main README"
check_file "EINSTEIN_GPT_INTEGRATION.md" "Einstein GPT Integration Guide"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "Validation Summary"
echo "════════════════════════════════════════════════════════════════"

if [ "$VALIDATION_PASSED" = true ]; then
    echo ""
    echo "✓ All components validated successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Run: ./deploy.sh <org-alias>"
    echo "2. Follow post-deployment steps in FLOW_AI_AUDIT_README.md"
    echo ""
    exit 0
else
    echo ""
    echo "✗ Validation failed - some components are missing"
    echo ""
    echo "Please ensure all files are present before deployment."
    echo ""
    exit 1
fi
