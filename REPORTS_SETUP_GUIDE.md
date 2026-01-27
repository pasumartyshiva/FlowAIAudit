# Flow Analysis Reports - Setup Guide

Create Salesforce reports to track flow quality and trends.

---

## Data Model

### Flow_Analysis__c Object

| Field | Type | Description |
|-------|------|-------------|
| Flow_API_Name__c | Text | Flow's API name |
| Flow_Label__c | Text | Flow's display label |
| Flow_Version__c | Number | Active version number |
| Flow_Type__c | Text | Screen, Record-Triggered, Scheduled, etc. |
| Overall_Score__c | Number | Score from 0-100 (whole number) |
| Overall_Status__c | Formula | Calculated: PASS, NEEDS WORK, or FAIL |
| Status__c | Picklist | Analysis status (Pending, Analyzing, Pass, Needs Work, Fail, Error) |
| Analysis_Report__c | Long Text | JSON analysis data |
| Last_Analyzed__c | DateTime | When analysis was last run |
| Is_Active__c | Checkbox | Whether flow is still active |
| Error_Message__c | Long Text | Error details if analysis failed |

### Scoring Rubric

| Score Range | Status | Color | Action |
|-------------|--------|-------|--------|
| **70-100%** | PASS | Green | Minor improvements only |
| **40-69%** | NEEDS WORK | Yellow | Address recommendations |
| **0-39%** | FAIL | Red | Requires significant fixes |

### Category Severity Levels

| Severity | Points | Description |
|----------|--------|-------------|
| COMPLIANT | 8 pts | Meets best practices |
| MINOR | 6 pts | Small improvements suggested |
| NEEDS WORK | 4 pts | Notable issues to address |
| CRITICAL | 0 pts | Requires immediate attention |

**Score Calculation**: `(Total Points / 96) × 100` (12 categories × 8 max points)

---

## Report Type

**Name**: Flow Analysis Reports  
**Location**: Setup → Report Types → "Flow Analysis Reports"

---

## Creating Reports

### Report 1: Flow Analysis Summary

Overview of all flows grouped by status.

1. Reports → New Report → "Flow Analysis Reports"
2. Configure:
   - **Format**: Summary
   - **Group By**: Overall Status
   - **Filters**: Status = Pass, Needs Work, or Fail
   - **Columns**: Flow Label, Overall Score, Status, Last Analyzed
   - **Chart**: Horizontal Bar (Status vs Count)
3. Save to "Flow Analysis Reports" folder

### Report 2: Flows Needing Attention

Flows scoring below 70% (priority list).

1. Reports → New Report → "Flow Analysis Reports"
2. Configure:
   - **Format**: Tabular
   - **Filters**: Status = Needs Work OR Fail; Overall Score < 70
   - **Columns**: Flow Label, Overall Score, Overall Status, Flow Type, Last Analyzed
   - **Sort**: Overall Score (Ascending)
3. Save

### Report 3: Score Trends

Track average scores over time.

1. Reports → New Report → "Flow Analysis Reports"
2. Configure:
   - **Format**: Summary
   - **Group By**: Created Date (by Week)
   - **Filters**: Status = Pass, Needs Work, or Fail
   - **Summary**: Average of Overall Score
   - **Chart**: Line Chart (Week vs Avg Score)
3. Save

---

## Additional Report Ideas

| Report | Filter | Purpose |
|--------|--------|---------|
| Top Performing | Score ≥ 90 | Template candidates |
| Critical Failures | Score < 40 | Immediate attention |
| Error Analysis | Status = Error | Track failed analyses |
| By Flow Type | Group by Flow Type | Compare type performance |
| Weekly Activity | Group by Created Date | Track analysis volume |

---

## Building a Dashboard

1. **Dashboards** → New Dashboard → "Flow Quality Dashboard"
2. Add components:
   - Status breakdown (Bar Chart)
   - Score trends (Line Chart)
   - Flows needing attention (Table)
3. Set refresh schedule
4. Share with leadership

---

## Sample SOQL Queries

**All Completed Analyses**:
```sql
SELECT Flow_Label__c, Overall_Score__c, Overall_Status__c, Last_Analyzed__c
FROM Flow_Analysis__c
WHERE Status__c IN ('Pass', 'Needs Work', 'Fail')
ORDER BY Overall_Score__c ASC
```

**Flows Below Threshold**:
```sql
SELECT Flow_Label__c, Overall_Score__c, Flow_Type__c
FROM Flow_Analysis__c
WHERE Overall_Score__c < 70
AND Status__c IN ('Pass', 'Needs Work', 'Fail')
```

**Average Score by Flow Type**:
```sql
SELECT Flow_Type__c, AVG(Overall_Score__c)
FROM Flow_Analysis__c
WHERE Status__c IN ('Pass', 'Needs Work', 'Fail')
GROUP BY Flow_Type__c
```

---

## Best Practices

1. **Schedule weekly reports** to stakeholders
2. **Set governance standards** (e.g., all production flows must score 70%+)
3. **Track trends** month-over-month
4. **Prioritize FAIL status** flows for remediation
5. **Re-analyze after fixes** to verify improvement

---

*Repository: https://github.com/pasumartyshiva/FlowAIAudit*
