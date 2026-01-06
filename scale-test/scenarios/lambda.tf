# =============================================================================
# Lambda Scenarios
# Test scenarios that modify Lambda functions to trigger reliability risks
# =============================================================================

# -----------------------------------------------------------------------------
# Scenario: lambda_timeout
# Reduces Lambda timeout from default (30s) to 1 second
# Expected Risk: Function failure - functions will timeout before completing
# 
# IMPLEMENTATION NOTE:
# This scenario is implemented via the module variable approach in main.tf.
# The local.scenario_lambda_timeout variable is passed to all AWS modules,
# which reduces the timeout when scenario = "lambda_timeout".
#
# No additional resources needed here - the modification happens at the
# module level, affecting all Lambda functions across all regions.
# -----------------------------------------------------------------------------

# The lambda_timeout scenario modifies:
# - us-east-1:      2 Lambda functions (at 1x) → 20 (at 10x) → 200 (at 100x)
# - us-west-2:      2 Lambda functions (at 1x) → 20 (at 10x) → 200 (at 100x)
# - eu-west-1:      2 Lambda functions (at 1x) → 20 (at 10x) → 200 (at 100x)
# - ap-southeast-1: 2 Lambda functions (at 1x) → 20 (at 10x) → 200 (at 100x)
#
# Total affected: 8 functions at 1x, 80 at 10x, 800 at 100x

# Expected blast radius includes:
# - Lambda functions themselves
# - CloudWatch Log Groups for each function
# - IAM roles attached to functions
# - SQS queues and SNS topics the functions are configured to use

