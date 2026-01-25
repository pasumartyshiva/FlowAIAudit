#!/bin/bash

# Flow Guru - Fresh Org Deployment Script
# This script automates the complete deployment to a new Salesforce org

set -e  # Exit on any error

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Flow Guru - Fresh Org Deployment                       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "ℹ $1"
}

# Step 1: Check if Salesforce CLI is installed
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Checking Prerequisites"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! command -v sf &> /dev/null; then
    print_error "Salesforce CLI (sf) is not installed"
    echo "Install it from: https://developer.salesforce.com/tools/sfdxcli"
    exit 1
fi

print_success "Salesforce CLI is installed"
sf --version
echo ""

# Step 2: Authenticate to new org
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Authenticate to Your New Org"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_info "If you don't have a new org yet:"
echo "  → Visit: https://developer.salesforce.com/signup"
echo "  → Create a free Developer Edition org"
echo "  → Come back and continue this script"
echo ""
read -p "Press ENTER when you're ready to authenticate to your new org..."

# Authenticate
print_info "Opening browser for authentication..."
sf org login web --alias flow-guru-org --set-default

if [ $? -eq 0 ]; then
    print_success "Successfully authenticated to new org"
else
    print_error "Authentication failed"
    exit 1
fi

# Display org info
echo ""
print_info "Connected Org Details:"
sf org display --target-org flow-guru-org
echo ""

# Step 3: Confirm deployment
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Ready to Deploy"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_info "The following will be deployed to your new org:"
echo "  • Custom Objects (Flow_Analysis__c)"
echo "  • Custom Metadata Type (LLM_Configuration__mdt)"
echo "  • Apex Classes (FlowAnalysisService, ExternalLLMService, Batch, Queueable)"
echo "  • Test Classes (100% coverage)"
echo "  • Lightning Web Components (Dashboard UI)"
echo "  • Prompt Templates (Flow_Evaluator_V2, Flow_Evaluator_V3)"
echo "  • Provider Configs (Google Gemini, Anthropic, HuggingFace)"
echo "  • Remote Site Settings"
echo "  • Named Credentials"
echo ""
read -p "Continue with deployment? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Deployment cancelled by user"
    exit 0
fi

# Step 4: Deploy metadata
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Deploying Metadata"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

print_info "Starting deployment... (this may take 30-60 seconds)"
echo ""

sf project deploy start \
    --source-dir force-app/main/default \
    --target-org flow-guru-org \
    --wait 10 \
    --verbose

if [ $? -eq 0 ]; then
    print_success "Deployment completed successfully!"
else
    print_error "Deployment failed"
    echo ""
    print_info "Check the error messages above for details"
    exit 1
fi

# Step 5: Run tests
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 5: Running Tests (Optional)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "Run Apex tests to verify deployment? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Running all tests..."
    echo ""

    sf apex run test \
        --target-org flow-guru-org \
        --result-format human \
        --code-coverage \
        --wait 10

    if [ $? -eq 0 ]; then
        print_success "All tests passed!"
    else
        print_warning "Some tests failed, but deployment is complete"
    fi
fi

# Step 6: Next steps
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 6: Post-Deployment Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_success "Deployment completed successfully!"
echo ""
print_info "📋 Next Steps:"
echo ""
echo "OPTION 1: Use Einstein GPT (Production - No API Key Needed)"
echo "  1. Open your org: sf org open --target-org flow-guru-org"
echo "  2. Setup → Prompt Builder"
echo "  3. Find 'Flow_Evaluator_V3' and click 'Publish'"
echo "  4. Test: Run FlowAnalysisBatch.runBatch(1) in Developer Console"
echo ""
echo "OPTION 2: Use HuggingFace (Demo/Prototype - Free)"
echo "  1. Get API token: https://huggingface.co/settings/tokens"
echo "  2. Setup → Custom Metadata Types → LLM Configuration → Manage Records"
echo "  3. Edit 'HuggingFace Qwen 72B'"
echo "  4. Paste token in 'API Key' field"
echo "  5. Check 'Is Active' and Save"
echo "  6. Test: Run FlowAnalysisBatch.runBatch(1) in Developer Console"
echo ""
print_info "📚 Full Documentation:"
echo "  → EINSTEIN_GPT_SETUP.md"
echo "  → BYO_LLM_SETUP.md"
echo "  → HUGGINGFACE_SETUP.md"
echo ""

# Open the org
read -p "Open the new org in browser? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Opening org in browser..."
    sf org open --target-org flow-guru-org
fi

echo ""
print_success "Setup complete! 🎉"
echo ""
print_info "To analyze flows, navigate to: App Launcher → Flow AI Audit Dashboard"
echo ""
