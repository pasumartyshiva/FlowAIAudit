# Bulk Analysis Bug Fix - Parameter Mismatch

**Date**: January 26, 2026
**Issue**: Script-thrown exception in bulk analysis feature
**Status**: ✅ Fixed and Deployed

---

## Problem

When using the new "Analyze Selected (Max 5)" bulk analysis feature, users encountered a "Script-thrown exception" error. The debug log showed:

```
15:56:45.0 (3343548)|FATAL_ERROR|System.AuraHandledException: Script-thrown exception
Class.FlowAnalysisDashboardController.reanalyzeFlow: line 516, column 1
```

## Root Cause

**Parameter Name Mismatch**: The `handleAnalyzeSelected()` method in `flowAnalysisDashboard.js` was calling `reanalyzeFlow()` with the wrong parameter name.

### Incorrect Code (Line 867):
```javascript
return reanalyzeFlow({ recordId: flow.id })  // ❌ Wrong parameter name
```

### Apex Method Signature:
```apex
@AuraEnabled
public static String reanalyzeFlow(String flowApiName) {
    // Method expects 'flowApiName', not 'recordId'
}
```

The Apex method expected `flowApiName` but received `recordId`, causing the parameter to be null or invalid, which led to the exception at line 516 when trying to process the flow.

---

## Solution

Updated the method call to use the correct parameter name that matches the Apex method signature.

### Fixed Code (Line 867):
```javascript
return reanalyzeFlow({ flowApiName: flow.flowApiName })  // ✅ Correct parameter name
```

This aligns with the existing `handleReanalyze()` method (line 469) which correctly calls:
```javascript
reanalyzeFlow({ flowApiName: flowApiName })
```

---

## File Changed

**File**: `force-app/main/default/lwc/flowAnalysisDashboard/flowAnalysisDashboard.js`
**Line**: 867
**Change**: Single parameter name correction

```diff
  const flow = flowsToAnalyze[index];
- return reanalyzeFlow({ recordId: flow.id })
+ return reanalyzeFlow({ flowApiName: flow.flowApiName })
      .then(() => {
          successCount++;
          this.showToast('Success', `Analyzing: ${flow.flowLabel}`, 'success');
```

---

## How the Bug Was Found

1. **User reported error**: Debug log showing exception at line 516
2. **Read Apex code**: Examined `reanalyzeFlow()` method to understand expected parameters
3. **Found signature**: Method expects `String flowApiName` parameter
4. **Checked existing usage**: Found correct usage in `handleReanalyze()` method at line 469
5. **Identified mismatch**: New bulk analysis code was using `recordId` instead of `flowApiName`
6. **Applied fix**: Changed parameter name to match expected signature

---

## Testing

### Before Fix:
- Bulk analysis threw "Script-thrown exception" error
- No flows were analyzed
- Error appeared in debug logs

### After Fix (Expected Behavior):
- Bulk analysis should process flows sequentially
- Each flow should show "Analyzing: [Flow Name]" toast
- Success count should increment for each completed analysis
- Final summary should show: "✅ Success: X, ❌ Errors: Y"
- Dashboard should refresh to show updated analysis results

---

## Deployment

**Deployed to**: spasumarty.afhls2025@salesforce.com
**Deploy Status**: ✅ Succeeded
**Deploy ID**: 0AfKY00000EF5690AD
**Elapsed Time**: 35.74s

**GitHub Commit**: 9ec4ca8
**Repository**: https://github.com/pasumartyshiva/FlowAIAudit

---

## Related Code Patterns

### Data Structure
The `flow` object in the JavaScript code contains both properties:
```javascript
{
    id: '0afKY00000XXXXX',              // Salesforce record ID
    flowApiName: 'My_Flow_API_Name',    // Flow API name for Tooling API
    flowLabel: 'My Flow Display Name',   // User-friendly display name
    // ... other properties
}
```

### Correct Usage Pattern
When calling `reanalyzeFlow()` from JavaScript, always use:
```javascript
reanalyzeFlow({ flowApiName: flow.flowApiName })
```

**Never use**:
```javascript
reanalyzeFlow({ recordId: flow.id })           // ❌ Wrong
reanalyzeFlow({ id: flow.id })                 // ❌ Wrong
reanalyzeFlow({ flowName: flow.flowLabel })    // ❌ Wrong
```

---

## Key Lessons

1. **Check existing patterns**: Before adding new code, look for similar existing implementations (like `handleReanalyze()`)
2. **Match parameter names**: JavaScript object properties must match Apex `@AuraEnabled` parameter names exactly
3. **Use the right identifier**:
   - `flow.id` = Salesforce record ID (for Flow_Analysis__c)
   - `flow.flowApiName` = Flow API name (for Tooling API lookups)
4. **Debug with logs**: Debug logs clearly showed the error location (line 516)
5. **Read the signature**: Apex method signature tells you exactly what parameters are expected

---

## Prevention

To prevent similar issues in the future:

1. **Code Review Checklist**:
   - [ ] Parameter names match Apex method signature
   - [ ] Using correct identifier type (ID vs API name vs label)
   - [ ] Following existing patterns in the codebase
   - [ ] Testing with 2-3 flows before committing

2. **Documentation**:
   - Keep data structure documentation clear
   - Document which identifier to use for which API
   - Add JSDoc comments for Apex callouts

3. **Testing**:
   - Test new features immediately after deployment
   - Check debug logs for parameter mismatches
   - Verify toast messages appear correctly

---

## Status

✅ **Fixed and Deployed**
✅ **Committed to GitHub**
⏭️ **User testing pending**

The bulk analysis feature should now work correctly, processing up to 5 flows sequentially without overloading the system.

---

*Fix completed: January 26, 2026*
*Fixed by: Claude Sonnet 4.5*
