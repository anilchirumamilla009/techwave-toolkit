---
name: compliance
description: 'This skill should be used when the user asks about "HIPAA compliance", "PCI DSS", "GDPR", "SOC 2", "compliance review", "data privacy check", "security audit for", "check regulatory requirements", "is this HIPAA compliant", "review for PCI", "GDPR requirements", "data protection", "healthcare compliance", "financial compliance", "EU privacy", "personal data handling", or any domain-specific regulatory validation. Pass the domain as an argument: /compliance health, /compliance finance, /compliance eu, /compliance soc2.'
version: 0.3.0
user-invocable: true
---

# Domain Compliance Skill

## Overview

This skill reviews a codebase or design against domain-specific regulatory requirements (HIPAA, PCI DSS, GDPR, SOC 2) and produces a structured checklist of pass/fail/not-applicable items with concrete code-level remediation guidance.

## When to Use

Invoke when the user wants to validate that their code or architecture meets regulatory or compliance requirements. Works on existing codebases (read and analyze) or proposed designs (analyze based on description).

## Step 0 — Build and Read the Knowledge Graph (REQUIRED)

**Complete all sub-steps before Step 1. Use Bash and Read tools directly — do not ask the user to run anything.**

**0.0 Read Stack Config (do this first)**
Use the Read tool: try `.github/tech-stack.md`, then `.claude/tech-stack.md`. If found, hold as **Stack Config** — if it declares a `Compliance domain` in the Notes section, use that to route to the correct reference file in Arguments Routing; skip auto-detection.

**0.1 Install graphify if missing**
```bash
command -v graphify || pip install graphifyy || pip3 install graphifyy
```

**0.2 Build the graph if missing**
```bash
test -f graphify-out/GRAPH_REPORT.md && echo "EXISTS" || (graphify . && graphify claude install && grep -qF "graphify-out/" .gitignore 2>/dev/null || printf "\n# graphify\ngraphify-out/\n" >> .gitignore)
```

**0.3 Read the graph**
Read `graphify-out/GRAPH_REPORT.md`. Extract: sensitive data flows (auth, payments, patient data), logging patterns, API endpoints handling sensitive data, existing compliance controls. Use this to target the review at real risk areas — do not scan every file when the graph shows you exactly where to look. Hold as **KG Context**.

Full protocol: `../shared/knowledge-graph.md`

---

## Arguments Routing

The user passes a domain as `$ARGUMENTS`. Route to the correct reference file:

| `$ARGUMENTS` value(s) | Domain | Reference file |
|---|---|---|
| `health`, `hipaa`, `healthcare`, `phi`, `medical` | Healthcare (HIPAA) | `references/hipaa.md` |
| `finance`, `pci`, `pci-dss`, `payment`, `fintech`, `card` | Finance (PCI DSS v4.0) | `references/pci-dss.md` |
| `eu`, `gdpr`, `privacy`, `europe`, `personal-data` | EU Privacy (GDPR) | `references/gdpr.md` |
| `general`, `soc2`, `soc`, `cloud`, `startup`, `saas` | General (SOC 2) | `references/soc2.md` |

**If `$ARGUMENTS` is empty or unrecognized:**

Run the codebase signal detection sequence below, then ask the user to confirm before proceeding.

## Codebase Signal Detection (when no argument given)

Search for domain signals in the codebase:

```bash
# Healthcare signals
grep -rli "hl7\|fhir\|patient\|phi\|hipaa\|dicom\|medical\|clinical" . --include="*.py" --include="*.ts" --include="*.js" --include="*.java" --include="*.go" 2>/dev/null | head -5

# Finance signals
grep -rli "card\|pan\|cvv\|pci\|stripe\|braintree\|payment\|transaction\|billing" . --include="*.py" --include="*.ts" --include="*.js" --include="*.java" --include="*.go" 2>/dev/null | head -5

# EU/GDPR signals
grep -rli "gdpr\|consent\|personal_data\|erasure\|right.to\|data.subject\|lawful.basis" . --include="*.py" --include="*.ts" --include="*.js" --include="*.java" --include="*.go" 2>/dev/null | head -5
```

- If healthcare signals found → suggest `health`
- If finance signals found → suggest `finance`
- If GDPR signals found → suggest `eu`
- If multiple domains detected → ask the user which to prioritize
- If no signals found → default to `soc2` (most general, applies to any SaaS)

## Step-by-Step Process

### 1. Load the Domain Reference

Load the appropriate reference file based on routing above. The reference file contains the compliance checklist mapped to code-level controls.

### 2. Read the Codebase (if available)

Use `Glob` and `Read` to examine:
- Authentication and authorization implementation
- Data storage and encryption patterns
- Logging statements (look for PII exposure)
- API endpoints that handle sensitive data
- Configuration files for secrets management
- Data retention or deletion mechanisms

### 3. Produce the Compliance Report

Structure the output as:

```
## Compliance Review: [Domain Name] ([Standard])

### Summary
- Total controls reviewed: [N]
- Passing: [N] ✓
- Failing: [N] ✗
- Not Applicable: [N] —
- Requires Manual Verification: [N] ⚠

---

### Control Checklist

#### [Control Category from Reference]

| Control | Status | Evidence / Location |
|---|---|---|
| [Control name] | ✓ Pass | [file:line or "config"] |
| [Control name] | ✗ Fail | [what was found] |
| [Control name] | — N/A | [why not applicable] |
| [Control name] | ⚠ Manual | [needs human verification] |

---

### Remediation Guidance

#### [Failing Control 1]
**Issue:** [What is wrong and why it violates the regulation]
**Fix:** [Specific code pattern to apply — show actual code, not just description]
**Effort:** [Low / Medium / High]

---

### Non-Technical Controls Required
[List controls that cannot be satisfied by code alone — policies, training, physical security, etc.]

### Remaining Gaps
[Controls that are partially addressed or unclear — need further investigation]
```

### 4. Remediation Code

For each failing control, provide a concrete before/after code example in the appropriate language, derived from the reference file patterns.

## Key Rules

- Always distinguish between technical controls (code-fixable) and non-technical controls (policy/process)
- Never mark a control as "Pass" without citing specific code evidence (file and approximate line)
- Mark controls as "Manual" when they require runtime verification (e.g., encryption at rest must be verified at the infrastructure level, not just the code level)
- If the codebase is very large, focus the review on the highest-risk areas first: authentication, data storage, logging, and external API calls
- Never provide legal advice — frame all findings as "engineering recommendations to satisfy [standard] technical requirements"
