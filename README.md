# Flow AI Audit Dashboard

<div align="center">

![Salesforce](https://img.shields.io/badge/Salesforce-00A1E0?style=for-the-badge&logo=salesforce&logoColor=white)
![Einstein AI](https://img.shields.io/badge/Einstein_AI-032E61?style=for-the-badge&logo=salesforce&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**AI-Powered Salesforce Flow Analysis Tool**

*Leverage Einstein AI to automatically audit your Salesforce Flows against 12 best practice categories and receive actionable recommendations.*

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Documentation](#-documentation)

</div>

---

## Overview

The **Flow AI Audit Dashboard** is a comprehensive Salesforce application that uses Einstein Prompt Templates to analyze your Salesforce Flows against industry best practices. It provides detailed insights across 12 critical categories, helping you build robust, maintainable, and efficient automation.

### How It Works

```
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│   Your Flows     │───▶│  Einstein AI     │───▶│  Analysis Report │
│  (Metadata XML)  │    │  (Claude 3.7)    │    │  (Scored/PDF)    │
└──────────────────┘    └──────────────────┘    └──────────────────┘
```

1. **Fetches Flow Metadata** - Uses Salesforce Tooling API to retrieve flow definitions
2. **AI-Powered Analysis** - Leverages Einstein (Claude Sonnet 3.7) to analyze flows
3. **Comprehensive Scoring** - Evaluates across 12 best practice categories
4. **Actionable Recommendations** - Provides prioritized fixes grouped by severity
5. **Professional Reporting** - Generates formatted analysis reports and PDFs

---

## Features

### 12-Category Best Practice Analysis

| # | Category | Description |
|---|----------|-------------|
| 1 | **Documentation & Naming** | Flow descriptions, element naming, variable documentation |
| 2 | **Logic Modularity** | Subflows, invocable actions, code reuse |
| 3 | **Bulkification** | DML/SOQL outside loops, collection processing |
| 4 | **Defensive Design** | Null checks, input validation, error prevention |
| 5 | **Data-Driven Design** | Avoid hardcoding, use Custom Metadata/Labels |
| 6 | **Error Handling** | Fault paths, logging, user feedback |
| 7 | **Security** | Run context, permissions, data exposure |
| 8 | **Automation Strategy** | Organization, trigger order, bypass logic |
| 9 | **Bulk Operations** | Batching, governor limits, scheduled flows |
| 10 | **Async Processing** | Sync vs async, timeouts, CPU limits |
| 11 | **Tool Selection** | Flow vs Apex vs Hybrid approach |
| 12 | **Summary Checklist** | Overall assessment and top priorities |

### Context-Aware Scoring

The AI adapts its evaluation based on flow type:
- **Screen Flows** - Lenient on batch processing, focused on UX and security
- **Record-Triggered Flows** - Strict on bulkification, error handling, null checks
- **Scheduled Flows** - Strict on governor limits, batching, async patterns

### 4-Tier Severity System

| Severity | Points | Meaning |
|----------|--------|---------|
| **COMPLIANT** | 8 pts | Follows best practices well |
| **MINOR** | 6 pts | Small suggestions, not blocking |
| **NEEDS WORK** | 4 pts | Should address before production |
| **CRITICAL** | 0 pts | Must fix - will cause failures |

### Scoring Rubric

| Score | Status | Description |
|-------|--------|-------------|
| 70-100% | **PASS** | Ready for production |
| 40-69% | **NEEDS WORK** | Address issues before deployment |
| 0-39% | **FAIL** | Critical issues must be resolved |

### Prioritized Recommendations

Issues are grouped for easy action planning:
- **Must Fix** - Critical issues causing failures or security risks
- **Should Fix** - Important items for production readiness
- **Consider** - Minor suggestions for future improvement

---

## Installation

### Prerequisites

- Salesforce org with **Einstein 1 license** (for Einstein Prompt Templates)
- **API Version**: 64.0 or higher
- **Salesforce CLI** (`sf`) installed locally

### Quick Deploy

```bash
# 1. Clone the repository
git clone https://github.com/pasumartyshiva/FlowAIAudit.git
cd FlowAIAudit

# 2. Authenticate with your Salesforce org
sf org login web --alias my-org

# 3. Deploy the metadata
sf project deploy start --source-dir force-app --target-org my-org
```

### Post-Deployment Setup

1. **Configure Named Credential** for Tooling API access
   - See [Tooling API Setup Guide](docs/TOOLING_API_SETUP.md)

2. **Assign Permission Set** to users who need access

3. **Add Dashboard to Lightning App** or access via App Launcher

---

## Usage

### Analyzing a Flow

1. Navigate to the **Flow AI Audit Dashboard** app
2. Click **"Sync Flow List"** to fetch all active flows
3. Select a flow and click **"Run Analysis"**
4. Wait for analysis to complete (typically 30-60 seconds)
5. Click **"View Analysis"** to see detailed results
6. Click **"Export to PDF"** to download the report

### Understanding Results

#### Score Banner
Shows overall percentage and status (PASS/NEEDS WORK/FAIL)

#### Category Cards
Each category displays:
- Status badge with severity color
- Analysis summary
- Specific findings with details
- Explanation of the rating
- Actionable recommendation

#### Priority Section
- **Must Fix** - Red section for critical issues
- **Should Fix** - Orange section for production blockers
- **Consider** - Blue section for future improvements

#### Strengths
Highlights what the flow does well

---

## Documentation

| Guide | Description |
|-------|-------------|
| [Quick Start Guide](QUICK_START.md) | Beginner-friendly setup and usage |
| [Tooling API Setup](docs/TOOLING_API_SETUP.md) | Configure Named Credential for metadata access |
| [Reports Setup](REPORTS_SETUP_GUIDE.md) | Create executive dashboards and reports |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│               Lightning Web Component (LWC)                 │
│                   flowAnalysisDashboard                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Apex Controllers                         │
│  • FlowAnalysisDashboardController (Main logic)            │
│  • FlowAnalysisService (AI integration)                    │
│  • FlowAnalysisPDFController (PDF generation)              │
│  • ExternalLLMService (Optional: BYO-LLM support)          │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┴─────────────────────┐
        ▼                                           ▼
┌─────────────────────┐                 ┌─────────────────────┐
│  Tooling API        │                 │  Einstein API       │
│  (Flow Metadata)    │                 │  (Claude Sonnet)    │
└─────────────────────┘                 └─────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                Custom Object: Flow_Analysis__c              │
│  Stores analysis results, scores, and reports              │
└─────────────────────────────────────────────────────────────┘
```

---

## Security

This application follows Salesforce security best practices:

- All Apex classes use `with sharing` keyword
- SOQL queries use bind variables to prevent injection
- User input is escaped using `String.escapeSingleQuotes()`
- HTML output is escaped using `escapeHtml4()`
- API credentials stored in Custom Metadata (not hardcoded)
- Proper CRUD/FLS enforcement through sharing model

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- **Salesforce Einstein Team** - For Einstein Prompt Templates
- **Anthropic** - For Claude AI models
- **Salesforce Community** - For flow best practices documentation

---

<div align="center">

**Built with ❤️ for the Salesforce Community**

[Report Bug](https://github.com/pasumartyshiva/FlowAIAudit/issues) • [Request Feature](https://github.com/pasumartyshiva/FlowAIAudit/issues)

</div>
