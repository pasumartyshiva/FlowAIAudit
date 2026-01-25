# Proper JSON Response Structure for Einstein Prompt Template

## Einstein Prompt Template Configuration

### Response Section Settings:
- **Format**: JSON
- **Response Structure**: (leave blank or use the structure below)

### Prompt Instructions:

```
You are a Salesforce Flow best practices expert. Analyze the provided flow metadata against 12 key categories and return a structured JSON response.

CATEGORIES TO EVALUATE:
1. Documentation, Naming, and Clarity
2. Logic Modularity & Reuse (Subflows, Invocable Actions)
3. Bulkification & Loop Efficiency
4. Null/Empty Checks and Defensive Design
5. Hard Coding, Data-Driven Design & Metadata
6. Error Handling, Fault Paths, and Logging
7. Security, Flow Context, and Permissions
8. Automation/Tool Strategy & Organization
9. Scheduled/Bulk Operations, Governor Limits & Batching
10. Synchronous vs. Asynchronous Processing
11. Flow vs. Apex Trigger/Hybrid: Tool Selection
12. Summary Checklist & Final Recommendations

SCORING:
- Each category: COMPLIANT (8.33 pts), PARTIAL (4.17 pts), or ISSUE (0 pts)
- Overall: PASS (80-100%), PARTIAL (50-79%), FAIL (0-49%)

RESPONSE FORMAT - Return JSON:

{
  "overallScore": 62,
  "overallStatus": "PARTIAL",
  "categories": [
    {
      "number": 1,
      "name": "Documentation, Naming, and Clarity",
      "icon": "📋",
      "status": "PARTIAL",
      "analysis": "My analysis shows that the flow has a solid foundation in documentation and naming but could be improved with more granular detail.",
      "details": [
        {
          "heading": "Flow Description",
          "content": "The main flow description clearly explains its triggering event, business purpose, and primary actions."
        },
        {
          "heading": "Element Naming",
          "content": "Element labels are descriptive and follow a consistent convention, making the flow's path easy to follow."
        },
        {
          "heading": "Variable Documentation",
          "content": "While variables are well-named, there is no inline documentation describing their specific purpose."
        }
      ],
      "explanation": "The flow has a good high-level description and consistently named elements. However, it lacks detailed, inline documentation for variables and complex logic.",
      "recommendation": "Add detailed descriptions to all variable resources and complex elements like decisions and formulas."
    }
  ],
  "summaryTable": [
    {
      "area": "Documentation",
      "status": "PARTIAL",
      "fix": "Add detailed descriptions to all variables and complex logic elements."
    }
  ]
}

For each of the 12 categories, provide:
- number: category number (1-12)
- name: full category name
- icon: emoji that represents the category
- status: COMPLIANT, PARTIAL, or ISSUE
- analysis: 1-2 sentence overview
- details: array of sub-points with heading and content (2-4 items)
- explanation: explanation of the status
- recommendation: specific actionable recommendation

Keep explanations concise (2-3 sentences max per section) to fit all 12 categories.

FLOW METADATA:
{!$Input:FlowMetadata}
```

---

## Expected JSON Structure:

```json
{
  "overallScore": 62,
  "overallStatus": "PARTIAL",
  "categories": [
    {
      "number": 1,
      "name": "Documentation, Naming, and Clarity",
      "icon": "📋",
      "status": "PARTIAL",
      "analysis": "The flow has a solid foundation but could be improved with more detail.",
      "details": [
        {
          "heading": "Flow Description",
          "content": "Description clearly explains triggering event and business purpose."
        },
        {
          "heading": "Element Naming",
          "content": "Elements follow consistent naming convention."
        }
      ],
      "explanation": "Good high-level documentation but lacks inline detail for variables.",
      "recommendation": "Add detailed descriptions to all variables and complex logic."
    },
    {
      "number": 2,
      "name": "Logic Modularity & Reuse",
      "icon": "🧩",
      "status": "COMPLIANT",
      "analysis": "The flow demonstrates good understanding of modularity.",
      "details": [
        {
          "heading": "Subflows",
          "content": "Uses subflows appropriately for repeated logic."
        }
      ],
      "explanation": "Correctly abstracts repeated tasks into reusable subflows.",
      "recommendation": "No changes required."
    }
  ],
  "summaryTable": [
    {
      "area": "Documentation",
      "status": "PARTIAL",
      "fix": "Add detailed descriptions to variables"
    },
    {
      "area": "Modularity",
      "status": "COMPLIANT",
      "fix": "No action required"
    }
  ]
}
```

---

## Icon Mapping for Each Category:

1. Documentation, Naming, and Clarity → 📋
2. Logic Modularity & Reuse → 🧩
3. Bulkification & Loop Efficiency → 🌪️
4. Null/Empty Checks → ✔️
5. Hard Coding, Data-Driven Design → 🔲
6. Error Handling → 🚨
7. Security, Flow Context → 🔒
8. Automation/Tool Strategy → 🏗️
9. Governor Limits & Batching → ⏳
10. Synchronous vs. Asynchronous → ⚡
11. Flow vs. Apex → ⚖️
12. Summary Checklist → 📝
