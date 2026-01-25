# Contributing to Flow AI Audit Dashboard

First off, thank you for considering contributing to the Flow AI Audit Dashboard! It's people like you that make this tool better for the entire Salesforce community.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)

---

## Code of Conduct

This project and everyone participating in it is governed by our commitment to fostering an open and welcoming environment. By participating, you are expected to uphold this code:

- **Be Respectful**: Treat everyone with respect and kindness
- **Be Collaborative**: Work together to improve the project
- **Be Professional**: Maintain professional conduct in all interactions
- **Be Inclusive**: Welcome newcomers and diverse perspectives

---

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

**Bug Report Template:**

```markdown
**Description**
A clear description of the bug

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '...'
3. See error

**Expected Behavior**
What you expected to happen

**Screenshots**
If applicable, add screenshots

**Environment**
- Salesforce Edition: [e.g., Enterprise, Unlimited]
- API Version: [e.g., 64.0]
- Browser: [e.g., Chrome 120]
- Einstein Model: [e.g., Claude Sonnet 3.7]
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

**Enhancement Template:**

```markdown
**Is your feature request related to a problem?**
A clear description of the problem

**Describe the solution you'd like**
A clear description of what you want to happen

**Describe alternatives you've considered**
Any alternative solutions you've thought about

**Additional context**
Any other context or screenshots
```

### Your First Code Contribution

Unsure where to start? Look for issues labeled:

- `good first issue` - Simple issues perfect for beginners
- `help wanted` - Issues where we need community help
- `documentation` - Documentation improvements

---

## Development Setup

### Prerequisites

- Salesforce CLI (`sf` version 2.0+)
- Node.js (v18+)
- Git
- VS Code with Salesforce Extensions (recommended)

### Setup Steps

1. **Fork the Repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/FlowAIAudit.git
   cd FlowAIAudit
   ```

2. **Create a Scratch Org**
   ```bash
   sf org create scratch \
     --definition-file config/project-scratch-def.json \
     --alias flow-audit-dev \
     --set-default
   ```

3. **Deploy the Code**
   ```bash
   sf project deploy start --source-dir force-app
   ```

4. **Set Up Test Data** (if needed)
   ```bash
   sf apex run --file scripts/apex/setupTestData.apex
   ```

5. **Open the Org**
   ```bash
   sf org open
   ```

---

## Pull Request Process

### Before Submitting

1. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Your Changes**
   - Follow our [coding standards](#coding-standards)
   - Write tests for new functionality
   - Update documentation as needed

3. **Test Your Changes**
   ```bash
   # Run Apex tests
   sf apex test run --test-level RunLocalTests --result-format human --wait 10

   # Run LWC Jest tests (if applicable)
   npm run test:unit
   ```

4. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "feat: add amazing feature

   Detailed description of what changed and why.

   Closes #123"
   ```

### Commit Message Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `test:` Adding or updating tests
- `chore:` Maintenance tasks

**Examples:**
```
feat: add historical trend analysis to dashboard
fix: resolve JSON parsing issue for HTML-wrapped responses
docs: update Tooling API setup guide with screenshots
test: add unit tests for FlowMetadataService
```

### Submitting the Pull Request

1. **Push to Your Fork**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create Pull Request**
   - Go to the original repository
   - Click "New Pull Request"
   - Select your feature branch
   - Fill out the PR template

3. **PR Template**
   ```markdown
   ## Description
   Brief description of changes

   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update

   ## Testing
   - [ ] All tests pass
   - [ ] New tests added (if applicable)
   - [ ] Manual testing completed

   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Self-review completed
   - [ ] Comments added for complex logic
   - [ ] Documentation updated
   - [ ] No new warnings generated

   ## Related Issues
   Closes #123, Fixes #456
   ```

4. **Review Process**
   - Maintainers will review your PR
   - Address any requested changes
   - Once approved, your PR will be merged!

---

## Coding Standards

### Apex Standards

```apex
/**
 * @description Service class for flow metadata operations
 * @author Your Name
 * @date 2026-01-25
 */
public with sharing class FlowMetadataService {

    // Constants in SCREAMING_SNAKE_CASE
    private static final String ENDPOINT = 'callout:Salesforce_Tooling_API';

    /**
     * @description Fetches flow metadata from Tooling API
     * @param flowApiName The API name of the flow
     * @return String JSON response containing flow metadata
     */
    public static String fetchFlowMetadata(String flowApiName) {
        // Implementation
    }
}
```

**Apex Guidelines:**
- Use `with sharing` unless there's a specific reason not to
- Add class and method documentation using JavaDoc style
- Constants should be `private static final`
- Method names in camelCase
- Class names in PascalCase
- Max line length: 120 characters
- Always handle exceptions appropriately

### JavaScript (LWC) Standards

```javascript
import { LightningElement, track, wire } from 'lwc';
import getFlows from '@salesforce/apex/FlowAnalysisController.getFlows';

/**
 * Flow Analysis Dashboard Component
 * @description Main dashboard for flow analysis
 */
export default class FlowAnalysisDashboard extends LightningElement {
    @track flows = [];

    /**
     * Handles flow selection change
     * @param {Event} event - Selection change event
     */
    handleFlowChange(event) {
        // Implementation
    }
}
```

**JavaScript Guidelines:**
- Use ES6+ syntax
- Prefer `const` over `let`, avoid `var`
- Use arrow functions for callbacks
- Add JSDoc comments for methods
- Use descriptive variable names
- Follow [Salesforce LWC Best Practices](https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.create_components_best_practices)

### CSS Standards

```css
/* Component-specific styles */
.analysis-card {
    background: var(--lwc-colorBackgroundAlt);
    border-radius: var(--lwc-borderRadiusMedium);
    padding: var(--lwc-spacingMedium);
}

/* Use Lightning Design System tokens */
.status-badge {
    color: var(--lwc-colorTextInverse);
    padding: var(--lwc-spacingXxSmall) var(--lwc-spacingSmall);
}
```

**CSS Guidelines:**
- Use SLDS design tokens when possible
- Follow BEM naming convention
- Keep selectors simple and specific
- Avoid `!important` unless absolutely necessary
- Mobile-first responsive design

---

## Testing Guidelines

### Apex Test Coverage

**Minimum Requirements:**
- **75%** code coverage minimum per class
- **90%** code coverage target for new code
- All public methods must be tested
- Test positive, negative, and bulk scenarios

**Example:**

```apex
@isTest
private class FlowMetadataServiceTest {

    @isTest
    static void testFetchFlowMetadata_Success() {
        // Given
        Test.setMock(HttpCalloutMock.class, new FlowMetadataMock());

        // When
        Test.startTest();
        String result = FlowMetadataService.fetchFlowMetadata('Test_Flow');
        Test.stopTest();

        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('Flow'), 'Response should contain Flow data');
    }

    @isTest
    static void testFetchFlowMetadata_Bulk() {
        // Test with 200 flows
    }

    @isTest
    static void testFetchFlowMetadata_Error() {
        // Test error handling
    }
}
```

### LWC Jest Tests

```javascript
import { createElement } from 'lwc';
import FlowAnalysisDashboard from 'c/flowAnalysisDashboard';

describe('c-flow-analysis-dashboard', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders dashboard correctly', () => {
        const element = createElement('c-flow-analysis-dashboard', {
            is: FlowAnalysisDashboard
        });
        document.body.appendChild(element);

        const title = element.shadowRoot.querySelector('h1');
        expect(title.textContent).toBe('Flow AI Audit Dashboard');
    });
});
```

---

## Documentation

### Code Comments

**When to Comment:**
- Complex logic that isn't self-explanatory
- Business rules or requirements
- Workarounds or non-obvious solutions
- Public APIs and methods

**When NOT to Comment:**
- Obvious code (`i++; // increment i`)
- Redundant explanations of what code does
- Commented-out code (remove it instead)

### README Updates

If your change affects:
- Installation process
- Configuration steps
- Usage instructions
- API behavior

**You must update:**
- `README.md` - Main documentation
- Relevant files in `docs/` folder
- Code examples if applicable

---

## Release Process

Maintainers will:

1. Review and merge approved PRs
2. Update `CHANGELOG.md`
3. Create a new release tag
4. Publish updated package version
5. Update documentation

---

## Questions?

- **GitHub Issues**: For bugs and features
- **GitHub Discussions**: For questions and ideas
- **Email**: support@flowaiaudit.com

---

## Recognition

Contributors will be:
- Listed in `CONTRIBUTORS.md`
- Credited in release notes
- Acknowledged in the README

---

**Thank you for contributing to Flow AI Audit Dashboard!** 🎉

Your contributions help make Salesforce automation better for everyone.
