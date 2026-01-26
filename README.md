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
- **NEEDS_WORK** (4.17 pts) - Some improvements needed
- **ISSUE** (0 pts) - Requires immediate attention

**Overall Status:**
- 🟢 **PASS** (80-100%)
- 🟡 **NEEDS_WORK** (50-79%)
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

```bash
# 1. Clone the repository
git clone https://github.com/pasumartyshiva/FlowAIAudit.git
cd FlowAIAudit

# 2. Authenticate with your Salesforce org
sf org login web --alias my-org

# 3. Deploy the metadata
sf project deploy start --source-dir force-app/main/default --target-org my-org
```

For detailed deployment instructions, see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

---

## ⚙️ Configuration

### Set Up Tooling API Access

Create Named Credential, Auth Provider, and Connected App to enable flow metadata retrieval.

See detailed setup instructions in [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

### Grant User Access

Create a permission set to grant users access:

1. **Setup** → **Permission Sets** → **New**
2. Add object permissions for `Flow_Analysis__c` (CRUD + View/Modify All)
3. Add Apex class access for: FlowAnalysis*, ToolingAPIService, ExternalLLMService
4. Add Visualforce page access for: FlowAnalysisExport
5. Assign to users

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
- **Status Badge**: COMPLIANT, NEEDS_WORK, or ISSUE
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

- **[Quick Start Guide](QUICK_START.md)** - Beginner-friendly setup and usage guide
- **[Deployment Guide](DEPLOYMENT_GUIDE.md)** - How to install in any Salesforce org
- **[Reports Setup Guide](REPORTS_SETUP_GUIDE.md)** - Creating executive dashboards and reports

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

| Issue | Solution |
|-------|----------|
| Tooling API connection failed | Re-authenticate Named Credential |
| No flows appear | Check browser console, verify Tooling API access |
| Einstein API error | Verify Einstein is enabled and you have credits |
| Deployment fails | Update API version in sfdx-project.json |

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for more troubleshooting tips.

---

## 🤝 Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

For issues or feature requests, please use [GitHub Issues](https://github.com/pasumartyshiva/FlowAIAudit/issues)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Salesforce Einstein Team** - For Einstein Prompt Templates
- **Anthropic** - For Claude AI models
- **Salesforce Community** - For flow best practices documentation

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/pasumartyshiva/FlowAIAudit/issues)
- **Documentation**: See README.md, QUICK_START.md, DEPLOYMENT_GUIDE.md

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
