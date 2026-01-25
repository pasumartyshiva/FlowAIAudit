#!/bin/bash

# Flow AI Audit System 2.0 - Deployment Script
# This script deploys all components to your target Salesforce org

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║        Flow AI Audit System 2.0 - Deployment Script           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Function to print colored output
print_status() {
    echo "✓ $1"
}

print_error() {
    echo "✗ $1"
}

print_info() {
    echo "ℹ $1"
}

# Check for target org alias
if [ -z "$1" ]; then
    echo "Usage: ./deploy.sh <org-alias>"
    echo ""
    echo "Available orgs:"
    sf org list
    echo ""
    echo "Example: ./deploy.sh my-dev-org"
    exit 1
fi

TARGET_ORG=$1

echo "Target Org: $TARGET_ORG"
echo ""

# Verify org connection
print_info "Verifying org connection..."
if sf org display -o "$TARGET_ORG" > /dev/null 2>&1; then
    print_status "Org connection verified"
else
    print_error "Cannot connect to org: $TARGET_ORG"
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "Step 1: Deploying Custom Object (Flow_Analysis__c)"
echo "════════════════════════════════════════════════════════════════"

sf project deploy start \
    -d force-app/main/default/objects/Flow_Analysis__c \
    -o "$TARGET_ORG" \
    --wait 10

print_status "Custom object deployed"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "Step 2: Deploying Apex Classes"
echo "════════════════════════════════════════════════════════════════"

sf project deploy start \
    -d force-app/main/default/classes \
    -o "$TARGET_ORG" \
    --wait 10 \
    --test-level RunLocalTests

print_status "Apex classes deployed"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "Step 3: Deploying Lightning Web Component"
echo "════════════════════════════════════════════════════════════════"

sf project deploy start \
    -d force-app/main/default/lwc/flowAnalysisDashboard \
    -o "$TARGET_ORG" \
    --wait 10

print_status "LWC deployed"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "Step 4: Deploying Prompt Template"
echo "════════════════════════════════════════════════════════════════"

if [ -d "force-app/main/default/genAiPromptTemplates" ]; then
    sf project deploy start \
        -d force-app/main/default/genAiPromptTemplates \
        -o "$TARGET_ORG" \
        --wait 10
    print_status "Prompt template deployed"
else
    print_info "Prompt template directory not found, skipping..."
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "Step 5: Deploying Lightning Page"
echo "════════════════════════════════════════════════════════════════"

sf project deploy start \
    -d force-app/main/default/flexipages \
    -o "$TARGET_ORG" \
    --wait 10

print_status "Lightning page deployed"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "Deployment Summary"
echo "════════════════════════════════════════════════════════════════"

print_status "Custom Object: Flow_Analysis__c"
print_status "Apex Classes: 4 classes + 4 test classes"
print_status "LWC: flowAnalysisDashboard"
print_status "Prompt Template: Flow_Evaluator_V2"
print_status "Lightning Page: Flow_AI_Audit_Dashboard"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "Post-Deployment Steps"
echo "════════════════════════════════════════════════════════════════"

echo ""
echo "1. Add the dashboard to your app:"
echo "   Setup → App Manager → Edit your app → Add 'Flow AI Audit Dashboard' tab"
echo ""
echo "2. Assign permissions:"
echo "   - Flow_Analysis__c object: Read, Create, Edit"
echo "   - Apex classes: Execute permissions"
echo "   - Lightning page: Access"
echo ""
echo "3. Configure Einstein GPT:"
echo "   - Ensure Einstein 1 Platform license is active"
echo "   - Publish Flow_Evaluator_V2 prompt template"
echo "   - Configure model access (Claude 3.7 Sonnet)"
echo ""
echo "4. Implement the AI integration:"
echo "   See EINSTEIN_GPT_INTEGRATION.md for detailed instructions"
echo ""
echo "5. Test the deployment:"
echo "   - Navigate to Flow AI Audit Dashboard"
echo "   - Click 'Run All Flows' to analyze flows"
echo "   - Monitor progress and review results"
echo ""

print_status "Deployment completed successfully!"
echo ""
echo "For troubleshooting, see: FLOW_AI_AUDIT_README.md"
echo ""
