// ============================================================
// DIAGNOSTIC: Check Named Credential Setup
// Helps identify what's wrong with the Named Credential
// ============================================================

System.debug('========================================');
System.debug('NAMED CREDENTIAL DIAGNOSTIC');
System.debug('========================================\n');

// Step 1: Check what the actual org URL should be
System.debug('--- Your Org Information ---');
System.debug('Org Domain URL: ' + URL.getOrgDomainUrl().toExternalForm());
System.debug('Session ID exists: ' + (UserInfo.getSessionId() != null));
System.debug('Current User: ' + UserInfo.getUserName());
System.debug('\n');

// Step 2: Test different Named Credential configurations
System.debug('--- Testing Named Credential Access ---\n');

// Test 1: Using the Named Credential
System.debug('Test 1: Calling via Named Credential "Salesforce_Tooling_API"');
try {
    String endpoint = 'callout:Salesforce_Tooling_API/services/data/v64.0/tooling/query?q=' +
        EncodingUtil.urlEncode('SELECT Id FROM Flow LIMIT 1', 'UTF-8');

    HttpRequest req = new HttpRequest();
    req.setEndpoint(endpoint);
    req.setMethod('GET');
    req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
    req.setHeader('Content-Type', 'application/json');
    req.setTimeout(30000);

    Http http = new Http();
    HttpResponse res = http.send(req);

    System.debug('  Status Code: ' + res.getStatusCode());
    System.debug('  Status: ' + res.getStatus());

    if (res.getStatusCode() == 200) {
        System.debug('  ✓ SUCCESS: Named Credential is working!\n');
    } else {
        System.debug('  ✗ FAILED: Got response but not 200 OK');
        System.debug('  Response: ' + res.getBody() + '\n');
    }

} catch (System.CalloutException e) {
    System.debug('  ✗ FAILED: ' + e.getMessage());

    if (e.getMessage().contains('might not exist')) {
        System.debug('\n  ⚠ DIAGNOSIS: Named Credential not found\n');
        System.debug('  ACTION REQUIRED:');
        System.debug('  1. Go to Setup → Named Credentials');
        System.debug('  2. Look for "Salesforce_Tooling_API"');
        System.debug('  3. If it doesn\'t exist, create it with these EXACT settings:\n');
        System.debug('     Name (API Name): Salesforce_Tooling_API');
        System.debug('     Label: Salesforce Tooling API');
        System.debug('     URL: callout:Salesforce_Instance');
        System.debug('     Identity Type: Anonymous');
        System.debug('     Authentication Protocol: No Authentication');
        System.debug('     Generate Authorization Header: UNCHECKED');
        System.debug('     Allow Merge Fields in HTTP Header: CHECKED');
        System.debug('     Allow Merge Fields in HTTP Body: UNCHECKED\n');

    } else if (e.getMessage().contains('Unauthorized endpoint')) {
        System.debug('\n  ⚠ DIAGNOSIS: Remote Site Setting missing\n');
        System.debug('  ACTION REQUIRED:');
        System.debug('  1. Go to Setup → Remote Site Settings');
        System.debug('  2. Click "New Remote Site"');
        System.debug('  3. Use these settings:\n');
        System.debug('     Remote Site Name: Salesforce_Instance');
        System.debug('     Remote Site URL: ' + URL.getOrgDomainUrl().toExternalForm());
        System.debug('     Active: CHECKED\n');
    }
    System.debug('');
}

// Test 2: Try with Remote Site Setting directly (without Named Credential)
System.debug('Test 2: Calling via Remote Site Setting directly');
try {
    String endpoint = 'callout:Salesforce_Instance/services/data/v64.0/tooling/query?q=' +
        EncodingUtil.urlEncode('SELECT Id FROM Flow LIMIT 1', 'UTF-8');

    HttpRequest req = new HttpRequest();
    req.setEndpoint(endpoint);
    req.setMethod('GET');
    req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
    req.setHeader('Content-Type', 'application/json');
    req.setTimeout(30000);

    Http http = new Http();
    HttpResponse res = http.send(req);

    System.debug('  Status Code: ' + res.getStatusCode());
    System.debug('  Status: ' + res.getStatus());

    if (res.getStatusCode() == 200) {
        System.debug('  ✓ SUCCESS: Remote Site Setting works!\n');
        System.debug('  This means the issue is with the Named Credential configuration.');
        System.debug('  The Named Credential should point to: callout:Salesforce_Instance\n');
    } else {
        System.debug('  ✗ FAILED: Got response but not 200 OK');
        System.debug('  Response: ' + res.getBody() + '\n');
    }

} catch (System.CalloutException e) {
    System.debug('  ✗ FAILED: ' + e.getMessage());

    if (e.getMessage().contains('Unauthorized endpoint')) {
        System.debug('\n  ⚠ DIAGNOSIS: Remote Site Setting not configured\n');
        System.debug('  ACTION REQUIRED:');
        System.debug('  Setup → Remote Site Settings → New');
        System.debug('  Name: Salesforce_Instance');
        System.debug('  URL: ' + URL.getOrgDomainUrl().toExternalForm());
        System.debug('  Active: CHECKED\n');
    } else if (e.getMessage().contains('401')) {
        System.debug('\n  ⚠ DIAGNOSIS: Authentication issue\n');
        System.debug('  The session ID approach may not work in your org.');
        System.debug('  Consider using external LLM providers instead.\n');
    }
    System.debug('');
}

System.debug('========================================');
System.debug('DIAGNOSTIC COMPLETE');
System.debug('========================================\n');

System.debug('SUMMARY:');
System.debug('1. Check Setup → Named Credentials for "Salesforce_Tooling_API"');
System.debug('2. Check Setup → Remote Site Settings for "Salesforce_Instance"');
System.debug('3. Make sure the Named Credential URL is: callout:Salesforce_Instance');
System.debug('4. Make sure the Remote Site Setting URL is: ' + URL.getOrgDomainUrl().toExternalForm());
System.debug('\nIf both tests above failed, the session-based approach may not work.');
System.debug('Alternative: Use external LLM providers (Google Gemini, Anthropic) instead.');
