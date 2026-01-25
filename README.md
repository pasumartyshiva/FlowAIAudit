# 🚀 Flow AI Audit Dashboard

<div align="center">

![Salesforce](https://img.shields.io/badge/Salesforce-00A1E0?style=for-the-badge&logo=salesforce&logoColor=white)
![Einstein](https://img.shields.io/badge/Einstein_AI-00D4FF?style=for-the-badge&logo=salesforce&logoColor=white)
![Lightning](https://img.shields.io/badge/Lightning_Web_Components-1798C1?style=for-the-badge&logo=salesforce&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**AI-Powered Salesforce Flow Analysis Tool**

Leverage Einstein AI to automatically audit your Salesforce Flows against 12 best practice categories and receive actionable recommendations.

[Features](#-features) • [Demo](#-demo) • [Installation](#-installation) • [Usage](#-usage) • [Documentation](#-documentation)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [Documentation](#-documentation)
- [Best Practices](#-best-practices)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Overview

The **Flow AI Audit Dashboard** is a comprehensive Salesforce application that uses Einstein Prompt Templates to analyze your Salesforce Flows against industry best practices. It provides detailed insights across 12 critical categories, helping you build robust, maintainable, and efficient automation.

### What It Does:

1. **Fetches Flow Metadata** - Uses Salesforce Tooling API to retrieve flow definitions
2. **AI-Powered Analysis** - Leverages Einstein (Claude Sonnet 3.7) to analyze flows
3. **Comprehensive Scoring** - Evaluates across 12 best practice categories
4. **Actionable Recommendations** - Provides specific fixes and improvements
5. **Professional Reporting** - Generates formatted analysis reports and PDFs
6. **Batch Processing** - Analyze multiple flows simultaneously

---

## ✨ Features

### 🔍 Comprehensive Analysis

Evaluates flows across **12 critical categories**:

1. 📋 **Documentation, Naming, and Clarity**
2. 🧩 **Logic Modularity & Reuse** (Subflows, Invocable Actions)
3. 🌪️ **Bulkification & Loop Efficiency**
4. ✔️ **Null/Empty Checks and Defensive Design**
5. 🔲 **Hard Coding, Data-Driven Design & Metadata**
6. 🚨 **Error Handling, Fault Paths, and Logging**
7. 🔒 **Security, Flow Context, and Permissions**
8. 🏗️ **Automation/Tool Strategy & Organization**
9. ⏳ **Scheduled/Bulk Operations, Governor Limits & Batching**
10. ⚡ **Synchronous vs. Asynchronous Processing**
11. ⚖️ **Flow vs. Apex Trigger/Hybrid: Tool Selection**
12. 📝 **Summary Checklist & Final Recommendations**

### 📊 Scoring System

- **COMPLIANT** (8.33 pts) - Meets best practices
- **PARTIAL** (4.17 pts) - Some improvements needed
- **ISSUE** (0 pts) - Requires immediate attention

**Overall Status:**
- 🟢 **PASS** (80-100%)
- 🟡 **PARTIAL** (50-79%)
- 🔴 **FAIL** (0-49%)

### 🎨 Beautiful UI

- **Interactive Dashboard** - Lightning Web Component with filtering and sorting
- **Formatted Analysis Cards** - Professional styling with emoji indicators
- **PDF Export** - Generate downloadable reports
- **Responsive Design** - Works on desktop and mobile

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Flow AI Audit Dashboard                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│               Lightning Web Component (LWC)                 │
│  • flowAnalysisDashboard (UI)                              │
│  • flowSelector (Multi-select picker)                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Apex Controllers                         │
│  • FlowAnalysisController (Main logic)                     │
│  • FlowMetadataService (Tooling API)                       │
│  • EinsteinService (AI analysis)                           │
│  • FlowAnalysisPDFController (PDF generation)              │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┴─────────────────────┐
        ▼                                           ▼
┌─────────────────────┐                 ┌─────────────────────┐
│  Tooling API        │                 │  Einstein API       │
│  • Flow Metadata    │                 │  • Prompt Template  │
│  • Named Credential │                 │  • Claude Sonnet    │
└─────────────────────┘                 └─────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                Custom Object: Flow_Analysis__c              │
│  • Flow_API_Name__c (Text)                                 │
│  • Analysis_Report__c (Long Text Area)                     │
│  • Overall_Score__c (Number)                               │
│  • Status__c (Picklist)                                    │
│  • Analyzed_By__c (Lookup to User)                         │
│  • Analysis_Date__c (DateTime)                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Prerequisites

### Salesforce Org Requirements:
- **API Version**: 64.0 or higher
- **Einstein AI**: Einstein 1 license with Prompt Builder access
- **User Permissions**:
  - System Administrator or custom profile with:
    - API Enabled
    - Customize Application
    - Modify Metadata
    - View Setup and Configuration

### Technical Requirements:
- Salesforce CLI (`sf`) version 2.0 or higher
- Git
- Connected App with OAuth 2.0 enabled
- Named Credential for Tooling API access

---

## 🚀 Installation

### Option 1: Deploy from GitHub (Recommended)

```bash
# 1. Clone the repository
git clone https://github.com/pasumartyshiva/FlowAIAudit.git
cd FlowAIAudit

# 2. Authenticate with your Salesforce org
sf org login web --set-default-dev-hub --alias my-hub
sf org login web --set-default --alias my-org

# 3. Deploy the metadata
sf project deploy start --source-dir force-app

# 4. Assign permission set
sf org assign permset --name Flow_AI_Audit_Dashboard_Access
```

### Option 2: Deploy Using Unlocked Package

```bash
# Install the package
sf package install --package 04t... --wait 10 --target-org my-org
```

### Option 3: Manual Deployment

1. Download the repository as ZIP
2. Extract to your local machine
3. Use Salesforce Extensions for VS Code to deploy:
   - Right-click on `force-app` folder
   - Select "SFDX: Deploy Source to Org"

---

## ⚙️ Configuration

### Step 1: Set Up Tooling API Access

Follow the comprehensive guide: [Tooling API Setup](docs/TOOLING_API_SETUP.md)

Quick summary:
1. Create Connected App with OAuth
2. Create Auth Provider (Salesforce type)
3. Create Named Credential (`Salesforce_Tooling_API`)
4. Authenticate and verify

### Step 2: Configure Einstein Prompt Template

1. Go to **Setup** → **Einstein** → **Prompt Templates**
2. Click **New Template**
3. Configure:
   - **Name**: `Flow_Best_Practices_Analysis`
   - **Template Type**: `Einstein for Flow`
   - **Model**: `Claude Sonnet 3.7` (or `Claude Sonnet 4.5`)
   - **Response Format**: `JSON`

4. Copy the prompt from: [PROPER_JSON_STRUCTURE.md](PROPER_JSON_STRUCTURE.md)
5. Paste into the template
6. Click **Save**

### Step 3: Create Custom Object Records Access

Grant users access to the `Flow_Analysis__c` custom object:

```bash
sf org assign permset --name Flow_AI_Audit_Dashboard_Access
```

Or manually:
1. **Setup** → **Permission Sets** → **New**
2. Add object permissions for `Flow_Analysis__c`
3. Assign to users

---

## 📖 Usage

### Running a Single Flow Analysis

1. Navigate to the **Flow AI Audit Dashboard** app
2. Select a flow from the dropdown
3. Click **"Run Analysis"**
4. Wait for the analysis to complete (typically 30-60 seconds)
5. Click **"View"** to see detailed results
6. Click **"Export PDF"** to download the report

### Running Batch Analysis

1. Click **"Select Multiple Flows"** button
2. Choose flows from the multi-select picker
3. Click **"Analyze Selected Flows"**
4. Monitor progress in the results table
5. View individual analyses as they complete

### Interpreting Results

#### Overall Score Banner
- Shows percentage score (0-100%)
- Status: PASS, PARTIAL, or FAIL
- Color-coded for quick visual assessment

#### Category Cards
Each of the 12 categories shows:
- **Icon**: Visual identifier
- **Status Badge**: COMPLIANT, PARTIAL, or ISSUE
- **Analysis**: Brief summary
- **Details**: Specific findings with headings
- **Explanation**: Why the status was assigned
- **Recommendation**: Actionable next steps

#### Summary Table
Quick reference showing all 12 categories with:
- Area name
- Status
- Recommended fix

---

## 📚 Documentation

### Core Documentation
- [Installation Guide](docs/INSTALLATION.md)
- [Tooling API Setup](docs/TOOLING_API_SETUP.md)
- [Einstein Configuration](docs/EINSTEIN_SETUP.md)
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)

### Developer Documentation
- [Architecture Overview](docs/ARCHITECTURE.md)
- [API Reference](docs/API_REFERENCE.md)
- [Code Structure](docs/CODE_STRUCTURE.md)
- [Contributing Guidelines](CONTRIBUTING.md)

### Reference Files
- [Prompt Template](PROPER_JSON_STRUCTURE.md)
- [JSON Parsing Fix](JSON_PARSING_FIX.md)
- [Change Log](CHANGELOG.md)

---

## 🎯 Best Practices

### For Administrators

1. **Regular Audits**: Schedule quarterly flow audits
2. **Track Improvements**: Monitor score trends over time
3. **Educate Builders**: Share analysis results with flow creators
4. **Prioritize Issues**: Focus on ISSUE-status categories first

### For Flow Developers

1. **Pre-Deployment Check**: Analyze flows before production deployment
2. **Iterative Improvement**: Address recommendations incrementally
3. **Learn from Results**: Use explanations to improve future flows
4. **Documentation**: Maintain clear flow descriptions and element naming

### For Architects

1. **Establish Standards**: Use consistent scoring as governance criteria
2. **Template Creation**: Build reusable subflows for common patterns
3. **Training Material**: Use analysis results for training examples
4. **Performance Baselines**: Set minimum score thresholds for production

---

## 🔧 Troubleshooting

### Common Issues

#### "Unauthorized endpoint" Error
**Solution**: Add Remote Site Setting for your Salesforce instance URL

#### JSON Not Parsing
**Solution**: Check Einstein response format is set to "JSON"

#### No Flows Showing in Dropdown
**Solution**: Verify Tooling API Named Credential is authenticated

#### Analysis Stuck in "Processing"
**Solution**: Check Einstein service limits and quotas

See full troubleshooting guide: [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### Reporting Issues
1. Check existing issues first
2. Use the issue template
3. Include screenshots and error messages
4. Provide org edition and API version

### Submitting Pull Requests
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup
```bash
git clone https://github.com/pasumartyshiva/FlowAIAudit.git
cd FlowAIAudit
sf org create scratch --definition-file config/project-scratch-def.json --alias flow-audit-dev
sf project deploy start --source-dir force-app --target-org flow-audit-dev
```

See: [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Salesforce Einstein Team** - For Einstein Prompt Templates
- **Anthropic** - For Claude AI models
- **Salesforce Community** - For flow best practices documentation
- **Contributors** - See [CONTRIBUTORS.md](CONTRIBUTORS.md)

---

## 📞 Support

- **Documentation**: [docs/](docs/)
- **Issues**: [GitHub Issues](https://github.com/pasumartyshiva/FlowAIAudit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/pasumartyshiva/FlowAIAudit/discussions)
- **Email**: support@flowaiaudit.com

---

## 🗺️ Roadmap

### Version 2.0 (Q2 2026)
- [ ] Support for Anthropic API direct integration
- [ ] Historical trend analysis
- [ ] Flow comparison tool
- [ ] Custom rule engine
- [ ] Multi-language support

### Version 2.1 (Q3 2026)
- [ ] Integration with Salesforce DevOps Center
- [ ] Slack/Teams notifications
- [ ] Automated scheduling
- [ ] Custom branding options

### Future Considerations
- Process Builder migration recommendations
- Workflow Rule analysis
- Apex Trigger best practices analysis
- Integration with CI/CD pipelines

---

## 📊 Stats

![GitHub stars](https://img.shields.io/github/stars/pasumartyshiva/FlowAIAudit?style=social)
![GitHub forks](https://img.shields.io/github/forks/pasumartyshiva/FlowAIAudit?style=social)
![GitHub issues](https://img.shields.io/github/issues/pasumartyshiva/FlowAIAudit)
![GitHub pull requests](https://img.shields.io/github/issues-pr/pasumartyshiva/FlowAIAudit)

---

<div align="center">

**Built with ❤️ for the Salesforce Community**

[⬆ Back to Top](#-flow-ai-audit-dashboard)

</div>
