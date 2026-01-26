# 📊 Flow Analysis Reports - Setup Guide

**Purpose**: Create executive-level Salesforce reports to track flow quality and trends for leadership visibility.

---

## ✅ What Was Deployed

The following have been deployed to your Salesforce org:

### Custom Fields Added:
1. **Overall_Status__c** (Formula) - Calculates PASS/NEEDS_WORK/FAIL based on score
   - PASS: Score >= 80%
   - NEEDS_WORK: Score 50-79%
   - FAIL: Score < 50%

2. **Flow_Type__c** (Text) - Stores flow type (Screen, Record-Triggered, etc.)

3. **Error_Message__c** (Long Text Area) - Stores error details for failed analyses

### Report Type Created:
- **Flow Analysis Reports** - Custom report type based on Flow_Analysis__c object
- Location: Setup → Report Types → "Flow Analysis Reports"

---

## 📈 How to Create Reports (Manual)

Due to a deployment timing issue, the sample reports need to be created manually. Follow these steps:

### Report 1: Flow Analysis Summary (Executive Dashboard)

**Purpose**: High-level overview of all flow scores grouped by status

**Steps**:
1. Go to Reports tab → New Report
2. Search for "Flow Analysis Reports" report type
3. Select it and click Continue
4. Configure:
   ```
   Report Name: Flow Analysis Summary
   Format: Summary Report
   Group By: Overall Status
   Filters: Status = Completed
   Date Range: Last 90 Days (Created Date)

   Columns to add:
   - Flow Label
   - Overall Score
   - Status
   - Last Modified Date

   Summary Fields:
   - Average of Overall Score
   - Record Count
   ```

5. Add Chart:
   - Type: Horizontal Bar
   - X-Axis: Overall Status
   - Y-Axis: Record Count

6. Save to folder: "Flow Analysis Reports" (Public)

### Report 2: Flows Needing Attention

**Purpose**: List flows with scores below 80% sorted by worst first

**Steps**:
1. Go to Reports tab → New Report
2. Select "Flow Analysis Reports" report type
3. Configure:
   ```
   Report Name: Flows Needing Attention
   Format: Tabular
   Filters:
   - Status = Completed
   - Overall Score < 80

   Columns:
   - Flow Label
   - Overall Score
   - Overall Status
   - Flow Type
   - Last Modified Date

   Sort By: Overall Score (Ascending - worst first)
   ```

4. Save to folder: "Flow Analysis Reports" (Public)

### Report 3: Flow Score Trends Over Time

**Purpose**: Track how average scores change week by week

**Steps**:
1. Go to Reports tab → New Report
2. Select "Flow Analysis Reports" report type
3. Configure:
   ```
   Report Name: Flow Score Trends
   Format: Summary Report
   Group By: Created Date (by Week)
   Filters: Status = Completed
   Date Range: Last 90 Days

   Columns:
   - Flow Label
   - Overall Score
   - Overall Status

   Summary Fields:
   - Average of Overall Score
   ```

5. Add Chart:
   - Type: Line Chart
   - X-Axis: Created Date (Week)
   - Y-Axis: Average Overall Score
   - Title: "Average Flow Score Over Time"

6. Save to folder: "Flow Analysis Reports" (Public)

---

## 🎯 Additional Report Ideas

### Report 4: Top Performing Flows
```
Filters:
- Status = Completed
- Overall Score >= 90

Sort: Overall Score (Descending)
Purpose: Identify flows that can serve as templates
```

### Report 5: Error Analysis
```
Filters:
- Status = Error

Columns:
- Flow Label
- Error Message
- Last Modified Date

Purpose: Track which flows are failing analysis
```

### Report 6: Analysis Activity
```
Group By: Created Date (by Day)
Summary: Record Count

Purpose: Track how many analyses are being run daily
```

### Report 7: Flow Type Comparison
```
Group By: Flow Type
Columns: Flow Label, Overall Score
Summary: Average Score

Purpose: See which flow types score higher/lower
```

---

## 📊 Creating a Dashboard

Once you have reports, create a dashboard for leadership:

1. **Dashboards** tab → New Dashboard
2. Name: "Flow Quality Dashboard"
3. Add components:
   - Flow Analysis Summary (Bar Chart)
   - Flow Score Trends (Line Chart)
   - Flows Needing Attention (Table)
   - Top Performing Flows (Table)

4. Set refresh schedule (daily/weekly)
5. Share with executives/leadership

---

## 💡 Best Practices

### For Administrators:
1. **Schedule reports** to run weekly and email to stakeholders
2. **Set alerts** for when average score drops below threshold
3. **Track trends** month-over-month to measure improvement
4. **Export to Excel** for presentations using Salesforce's export feature

### For Leadership:
1. **Focus on trends** not individual scores
2. **Celebrate improvements** when scores increase
3. **Prioritize FAIL status** flows for remediation
4. **Use as KPIs** in quarterly business reviews

### For Governance:
1. **Set minimum standards** (e.g., all prod flows must score 70%+)
2. **Track compliance** over time
3. **Document exceptions** for flows that legitimately score lower
4. **Include in deployment checklist** - must analyze before prod

---

## 📤 Exporting Data

### Option 1: Export from Report
1. Open any report
2. Click "Export" button
3. Choose format:
   - **Formatted Report (Excel)** - Best for presentations
   - **Details Only (Excel)** - Raw data for analysis
   - **Details Only (CSV)** - For data import/processing

### Option 2: Data Loader
```bash
# Export all Flow Analysis records
sf data export tree --query "SELECT Id, Flow_Label__c, Flow_API_Name__c, Overall_Score__c, Overall_Status__c, Status__c, LastModifiedDate, CreatedDate FROM Flow_Analysis__c WHERE Status__c = 'Completed' ORDER BY Overall_Score__c ASC" --output-dir exports --plan
```

This creates a JSON file you can:
- Import to Excel
- Process with Python/R for advanced analytics
- Visualize in Tableau/Power BI
- Archive for historical comparison

---

## 🔍 Sample SOQL Queries

For custom reporting needs:

### All Completed Analyses:
```sql
SELECT Flow_Label__c, Overall_Score__c, Overall_Status__c, LastModifiedDate
FROM Flow_Analysis__c
WHERE Status__c = 'Completed'
ORDER BY Overall_Score__c ASC
```

### Flows Analyzed This Month:
```sql
SELECT Flow_Label__c, Overall_Score__c, CreatedDate
FROM Flow_Analysis__c
WHERE CreatedDate = THIS_MONTH
AND Status__c = 'Completed'
```

### Average Score by Status:
```sql
SELECT Overall_Status__c, AVG(Overall_Score__c)
FROM Flow_Analysis__c
WHERE Status__c = 'Completed'
GROUP BY Overall_Status__c
```

### Top 10 Worst Performing Flows:
```sql
SELECT Flow_Label__c, Overall_Score__c
FROM Flow_Analysis__c
WHERE Status__c = 'Completed'
ORDER BY Overall_Score__c ASC
LIMIT 10
```

---

## 🎨 Visualization Tips

### Color Coding:
- **Green**: Scores 80-100% (PASS)
- **Yellow**: Scores 50-79% (NEEDS_WORK)
- **Red**: Scores 0-49% (FAIL)

### Key Metrics to Track:
1. Average score across all flows
2. Percentage of flows in each status (PASS/NEEDS_WORK/FAIL)
3. Trend line (improving or declining)
4. Number of flows analyzed per week
5. Top 5 worst performing flows

### Dashboard Layout Recommendation:
```
┌─────────────────────────────────────────────────┐
│ Flow Quality Dashboard                           │
├─────────────────────────────────────────────────┤
│ KPIs (Metrics)                                  │
│ [Avg Score: 75%] [Total: 50] [Pass Rate: 60%]  │
├──────────────────┬──────────────────────────────┤
│ Status Breakdown │  Score Trend (Line Chart)    │
│  (Bar Chart)     │                              │
├──────────────────┴──────────────────────────────┤
│ Flows Needing Attention (Table - Bottom 10)    │
└─────────────────────────────────────────────────┘
```

---

## ✅ Verification

After creating reports, verify:

1. **Reports appear** in Reports tab
2. **Data populates** correctly
3. **Charts render** as expected
4. **Filters work** (try changing date range)
5. **Export works** (try exporting to Excel)
6. **Sharing works** (share with a colleague)

---

## 🚀 Next Steps

1. ✅ Create the 3 main reports above
2. ✅ Build executive dashboard
3. ✅ Schedule weekly email reports
4. ✅ Set up alerts for score drops
5. ✅ Train leadership on how to interpret
6. ✅ Include in monthly governance meetings

---

## 📞 Support

If you encounter issues creating reports:
- Check Setup → Report Types → "Flow Analysis Reports" exists
- Verify Flow_Analysis__c records exist with Status = "Completed"
- Ensure you have "Run Reports" permission
- Try creating a simple tabular report first to test

---

*Created: January 26, 2026*
*Repository: https://github.com/pasumartyshiva/FlowAIAudit*
