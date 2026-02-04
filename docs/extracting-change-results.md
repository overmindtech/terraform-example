---
sidebar_position: 7
title: Extracting Change Data
---

# Extracting Data from Overmind Change Results

This guide explains how to extract and analyze data from Overmind's change results output for building dashboards, reports, and CI/CD integrations.

## Overview

When you submit a Terraform plan to Overmind for analysis, the results contain:

- **Risks** - Identified risks with severity and descriptions
- **Blast Radius** - Affected resources and their relationships
- **Hypotheses** - Investigation hypotheses and their outcomes
- **Observations** - Evidence gathered during analysis

## Getting the Results

### Using the Overmind CLI

```bash
# Submit a plan (outputs change URL to stdout)
overmind changes submit-plan tfplan.json \
  --ticket-link "https://github.com/org/repo/pull/123"

# Capture the change URL
CHANGE_URL=$(overmind changes submit-plan tfplan.json \
  --ticket-link "https://github.com/org/repo/pull/123")

# Get results as JSON (redirect stdout to file)
overmind changes get-change --uuid <change-uuid> --format json > change-results.json
```

### In CI/CD Pipelines

```yaml
# GitHub Actions example
- name: Submit to Overmind
  run: |
    CHANGE_URL=$(overmind changes submit-plan tfplan.json \
      --ticket-link "${{ github.server_url }}/${{ github.repository }}/pull/${{ github.event.pull_request.number }}")
    
    # Extract UUID from URL and get results
    CHANGE_UUID=$(echo "$CHANGE_URL" | grep -oE '[0-9a-f-]{36}')
    overmind changes get-change --uuid "$CHANGE_UUID" --format json > change-results.json
```

## JSON Structure Reference

### Top-Level Fields

| Field | Type | Description |
|-------|------|-------------|
| `risks` | array | List of identified risks |
| `hypotheses` | array | Investigation hypotheses |
| `change` | object | Metadata about the change and blast radius |
| `status` | string | Overall change status |

### Risk Object

Each risk contains:

```json
{
  "UUID": "base64-encoded-uuid",
  "title": "Opening SSH to 0.0.0.0/0 exposes instances to internet",
  "description": "This change adds an ingress rule allowing SSH from anywhere...",
  "severity": "SEVERITY_HIGH",
  "relatedItems": [
    {"type": "aws.ec2-instance", "uniqueAttributeValue": "web-1"},
    {"type": "aws.ec2-instance", "uniqueAttributeValue": "web-2"}
  ]
}
```

| Field | Type | Values |
|-------|------|--------|
| `title` | string | Short summary of the risk |
| `description` | string | Detailed explanation |
| `severity` | string | `SEVERITY_LOW`, `SEVERITY_MEDIUM`, `SEVERITY_HIGH` |
| `relatedItems` | array | References to affected resources |

### Change Metadata

```json
{
  "change": {
    "metadata": {
      "numAffectedItems": 847,
      "numAffectedEdges": 2108,
      "total_observations": 315
    }
  }
}
```

| Field | Description |
|-------|-------------|
| `numAffectedItems` | Number of resources in the blast radius |
| `numAffectedEdges` | Number of relationships between resources |
| `total_observations` | Evidence points gathered during analysis |

### Hypothesis Object

```json
{
  "title": "Security group changes may expose instances",
  "detail": "Investigating ingress rule modifications...",
  "status": "INVESTIGATED_HYPOTHESIS_STATUS_PROVEN",
  "numObservations": 42
}
```

| Field | Type | Values |
|-------|------|--------|
| `title` | string | Hypothesis being investigated |
| `status` | string | `INVESTIGATED_HYPOTHESIS_STATUS_FORMING`, `INVESTIGATED_HYPOTHESIS_STATUS_INVESTIGATING`, `INVESTIGATED_HYPOTHESIS_STATUS_PROVEN`, `INVESTIGATED_HYPOTHESIS_STATUS_DISPROVEN` |
| `numObservations` | number | Evidence gathered for this hypothesis |

### Not Included

The results file does not include analysis duration. If you need to track performance, measure it externally:

```bash
START_TIME=$(date +%s)
CHANGE_URL=$(overmind changes submit-plan tfplan.json --ticket-link "...")
DURATION=$(($(date +%s) - START_TIME))
echo "Analysis took ${DURATION}s"
```

## Extracting Data with jq

### Basic Metrics

```bash
# Count total risks
jq '.risks | length' change-results.json

# Count by severity
jq '[.risks[] | select(.severity == "SEVERITY_HIGH")] | length' change-results.json
jq '[.risks[] | select(.severity == "SEVERITY_MEDIUM")] | length' change-results.json
jq '[.risks[] | select(.severity == "SEVERITY_LOW")] | length' change-results.json

# Get blast radius size
jq '.change.metadata.numAffectedItems' change-results.json
jq '.change.metadata.numAffectedEdges' change-results.json

# Count observations
jq '.change.metadata.total_observations' change-results.json

# Count hypotheses
jq '.hypotheses | length' change-results.json
```

### Extract Risk Details

```bash
# Get all risk titles and severities
jq '.risks[] | {title, severity}' change-results.json

# Get high-severity risks only
jq '.risks[] | select(.severity == "SEVERITY_HIGH") | {title, description}' change-results.json

# Extract as compact JSON array (for APIs)
jq -c '[.risks[] | {title: .title, severity: .severity, description: .description}]' change-results.json

# Get related resources for each risk
jq '.risks[] | {title, relatedItems}' change-results.json
```

### Extract Hypothesis Details

```bash
# List all hypotheses with status
jq '.hypotheses[] | {title, status, numObservations}' change-results.json

# Get only proven hypotheses
jq '.hypotheses[] | select(.status == "INVESTIGATED_HYPOTHESIS_STATUS_PROVEN")' change-results.json

# Count by status
jq '[.hypotheses[] | .status] | group_by(.) | map({status: .[0], count: length})' change-results.json
```

### Generate Summary Report

```bash
# Human-readable summary
jq -r '
  "=== Overmind Change Analysis ===",
  "",
  "Blast Radius: \(.change.metadata.numAffectedItems) resources, \(.change.metadata.numAffectedEdges) edges",
  "Observations: \(.change.metadata.total_observations)",
  "",
  "Risks: \(.risks | length) total",
  "  High: \([.risks[] | select(.severity == "SEVERITY_HIGH")] | length)",
  "  Medium: \([.risks[] | select(.severity == "SEVERITY_MEDIUM")] | length)",
  "  Low: \([.risks[] | select(.severity == "SEVERITY_LOW")] | length)",
  "",
  "Hypotheses: \(.hypotheses | length)",
  "",
  "Risk Details:",
  (.risks[] | "  [\(.severity | gsub("SEVERITY_"; ""))] \(.title)")
' change-results.json
```

## CI/CD Integration Examples

### GitHub Actions - PR Comment

```yaml
- name: Extract Overmind Results
  id: overmind
  run: |
    RISK_COUNT=$(jq '.risks | length' change-results.json)
    HIGH_RISK_COUNT=$(jq '[.risks[] | select(.severity == "SEVERITY_HIGH")] | length' change-results.json)
    BLAST_RADIUS=$(jq '.change.metadata.numAffectedItems' change-results.json)
    
    echo "risk_count=$RISK_COUNT" >> $GITHUB_OUTPUT
    echo "high_risk_count=$HIGH_RISK_COUNT" >> $GITHUB_OUTPUT
    echo "blast_radius=$BLAST_RADIUS" >> $GITHUB_OUTPUT

- name: Comment on PR
  uses: actions/github-script@v7
  with:
    script: |
      const risks = ${{ steps.overmind.outputs.risk_count }};
      const highRisks = ${{ steps.overmind.outputs.high_risk_count }};
      const blastRadius = ${{ steps.overmind.outputs.blast_radius }};
      
      let status = '✅';
      if (highRisks > 0) status = '🔴';
      else if (risks > 0) status = '🟡';
      
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: `## ${status} Overmind Analysis\n\n` +
              `| Metric | Value |\n|--------|-------|\n` +
              `| Blast Radius | ${blastRadius} resources |\n` +
              `| Total Risks | ${risks} |\n` +
              `| High Risks | ${highRisks} |`
      });
```

### GitHub Actions - Job Summary

```yaml
- name: Add to Job Summary
  run: |
    echo "## Overmind Analysis Results" >> $GITHUB_STEP_SUMMARY
    echo "" >> $GITHUB_STEP_SUMMARY
    
    BLAST_RADIUS=$(jq '.change.metadata.numAffectedItems' change-results.json)
    EDGES=$(jq '.change.metadata.numAffectedEdges' change-results.json)
    OBSERVATIONS=$(jq '.change.metadata.total_observations' change-results.json)
    
    echo "| Metric | Value |" >> $GITHUB_STEP_SUMMARY
    echo "|--------|-------|" >> $GITHUB_STEP_SUMMARY
    echo "| Blast Radius | $BLAST_RADIUS resources |" >> $GITHUB_STEP_SUMMARY
    echo "| Relationships | $EDGES edges |" >> $GITHUB_STEP_SUMMARY
    echo "| Observations | $OBSERVATIONS |" >> $GITHUB_STEP_SUMMARY
    echo "" >> $GITHUB_STEP_SUMMARY
    
    echo "### Risks" >> $GITHUB_STEP_SUMMARY
    RISK_COUNT=$(jq '.risks | length' change-results.json)
    if [ "$RISK_COUNT" -gt 0 ]; then
      jq -r '.risks[] | "- **[\(.severity | gsub("SEVERITY_"; ""))]** \(.title)"' change-results.json >> $GITHUB_STEP_SUMMARY
    else
      echo "_No risks detected_" >> $GITHUB_STEP_SUMMARY
    fi
```

### Fail on High Risks

```yaml
- name: Check for High Risks
  run: |
    HIGH_RISKS=$(jq '[.risks[] | select(.severity == "SEVERITY_HIGH")] | length' change-results.json)
    
    if [ "$HIGH_RISKS" -gt 0 ]; then
      echo "::error::Found $HIGH_RISKS high-severity risks"
      jq -r '.risks[] | select(.severity == "SEVERITY_HIGH") | "  - \(.title)"' change-results.json
      exit 1
    fi
    
    echo "No high-severity risks found"
```

### GitLab CI

```yaml
analyze:
  script:
    - |
      CHANGE_URL=$(overmind changes submit-plan tfplan.json --ticket-link "$CI_PIPELINE_URL")
      CHANGE_UUID=$(echo "$CHANGE_URL" | grep -oE '[0-9a-f-]{36}')
      overmind changes get-change --uuid "$CHANGE_UUID" --format json > results.json
    - |
      RISK_COUNT=$(jq '.risks | length' results.json)
      HIGH_RISKS=$(jq '[.risks[] | select(.severity == "SEVERITY_HIGH")] | length' results.json)
      
      if [ "$HIGH_RISKS" -gt 0 ]; then
        echo "Found $HIGH_RISKS high-severity risks"
        exit 1
      fi
  artifacts:
    paths:
      - results.json
```

## Building a Dashboard

### Posting to a Webhook

```bash
# Extract metrics and POST to your dashboard
PAYLOAD=$(jq -c '{
  timestamp: now | todate,
  risks: {
    total: (.risks | length),
    high: ([.risks[] | select(.severity == "SEVERITY_HIGH")] | length),
    medium: ([.risks[] | select(.severity == "SEVERITY_MEDIUM")] | length),
    low: ([.risks[] | select(.severity == "SEVERITY_LOW")] | length)
  },
  blastRadius: {
    nodes: .change.metadata.numAffectedItems,
    edges: .change.metadata.numAffectedEdges
  },
  observations: .change.metadata.total_observations,
  hypotheses: (.hypotheses | length)
}' change-results.json)

curl -X POST "https://your-dashboard.com/api/results" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d "$PAYLOAD"
```

### Store to Environment Variables

```bash
# Export for use in subsequent steps
export RISK_COUNT=$(jq '.risks | length' change-results.json)
export HIGH_RISK_COUNT=$(jq '[.risks[] | select(.severity == "SEVERITY_HIGH")] | length' change-results.json)
export MEDIUM_RISK_COUNT=$(jq '[.risks[] | select(.severity == "SEVERITY_MEDIUM")] | length' change-results.json)
export BLAST_RADIUS=$(jq '.change.metadata.numAffectedItems' change-results.json)
export EDGES=$(jq '.change.metadata.numAffectedEdges' change-results.json)
export OBSERVATIONS=$(jq '.change.metadata.total_observations' change-results.json)

# Use in scripts
echo "Analyzed $BLAST_RADIUS resources, found $RISK_COUNT risks"
```

## Metrics to Track Over Time

For trend analysis, consider tracking these metrics per run:

| Metric | jq Command | Use Case |
|--------|------------|----------|
| Blast radius size | `.change.metadata.numAffectedItems` | Scope of changes |
| Edge count | `.change.metadata.numAffectedEdges` | Relationship complexity |
| Observation count | `.change.metadata.total_observations` | Analysis depth |
| Total risks | `.risks \| length` | Risk identification |
| High/Medium/Low | `select(.severity == "SEVERITY_X")` | Risk breakdown |
| Hypotheses | `.hypotheses \| length` | Investigation coverage |

### Example: CSV Export for Analysis

```bash
# Append to CSV for each run
echo "$(date -Iseconds),\
$(jq '.change.metadata.numAffectedItems' change-results.json),\
$(jq '.change.metadata.numAffectedEdges' change-results.json),\
$(jq '.change.metadata.total_observations' change-results.json),\
$(jq '.risks | length' change-results.json),\
$(jq '[.risks[] | select(.severity == "SEVERITY_HIGH")] | length' change-results.json)" \
>> overmind-metrics.csv
```

## Error Handling

Always handle cases where fields may be missing:

```bash
# Use // to provide defaults
RISK_COUNT=$(jq '.risks | length // 0' change-results.json)
BLAST_RADIUS=$(jq '.change.metadata.numAffectedItems // 0' change-results.json)

# Check if file exists
if [ ! -f "change-results.json" ]; then
  echo "Results file not found"
  exit 1
fi

# Validate JSON
if ! jq empty change-results.json 2>/dev/null; then
  echo "Invalid JSON in results file"
  exit 1
fi
```

## Next Steps

- Set up automated tracking of these metrics in your CI/CD pipeline
- Build a dashboard to visualize trends over time
- Configure alerts for high-risk changes
- Integrate with your existing monitoring tools (Datadog, Grafana, etc.)
