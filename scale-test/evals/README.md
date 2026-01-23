# PromptFoo Quality Evals for Risk Analysis

This directory contains PromptFoo configurations for evaluating the quality of Overmind's risk analysis results.

## Overview

These evals run **after** Overmind analyzes a terraform plan. They:

1. Read the `change-results.json` from Overmind
2. Validate that expected risks were detected
3. Use LLM-as-judge to score the quality of risk descriptions
4. Output metrics for tracking quality over time

## Running Locally

```bash
# Install dependencies
npm install

# Run evals against a results file
npx promptfoo eval --vars "results_file=../change-results.json"

# View results in browser
npx promptfoo view
```

## Running in CI

The evals run automatically in the `scale-test.yml` workflow after Overmind analysis completes.

Results are uploaded as artifacts: `promptfoo-results-<scenario>-<run_id>`

## Test Scenarios

| Scenario | What's Evaluated | Pass Criteria |
|----------|------------------|---------------|
| `shared_sg_open` | SSH to 0.0.0.0/0 detection | High-severity risk + mentions SSH |
| `lambda_timeout` | Timeout risk detection | Any risk + mentions timeout |
| `vpc_peering_change` | Network analysis quality | Relevant analysis (if any) |
| `central_sns_change` | SNS policy risk | Any risk + mentions SNS |
| `combined_network` | Multiple risk detection | High-severity + multiple risks |
| `shared_firewall_open` | GCP firewall detection | High-severity + mentions firewall |

## Metrics

Each test produces metrics:

- `has_risk` / `has_high_risk` - Boolean: were expected risks found?
- `mentions_*` - Boolean: does the description mention key terms?
- `quality_score` - LLM-as-judge score (0-1) for description quality

## Adding New Scenarios

Add a new test to `promptfooconfig.yaml`:

```yaml
- description: "my_scenario: Description"
  vars:
    scenario: my_scenario
    expected: "What should be detected"
  assert:
    - type: javascript
      value: "vars.risk_count > 0"
      metric: has_risk
    - type: llm-rubric
      value: |
        Describe what a good risk assessment looks like for this scenario.
      metric: quality_score
```

## Environment Variables

- `OPENAI_API_KEY` - Required for LLM-as-judge assertions

## Files

```
evals/
├── package.json           # Dependencies (promptfoo)
├── promptfooconfig.yaml   # Eval configuration
├── README.md              # This file
└── eval-results.json      # Output (generated, gitignored)
```
