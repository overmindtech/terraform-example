# Example configuration for the Message Size Limit Breach scenario
# This file demonstrates both safe and dangerous configurations
# 
# To use this scenario, reference it from the main scenarios module:
#
# SAFE CONFIGURATION (25KB messages, works fine)
# Use these variable values:
# message_size_breach_max_size = 25600   # 25KB
# message_size_breach_batch_size = 10    # 10 messages × 25KB = 250KB < 256KB Lambda async limit ✅
#
# DANGEROUS CONFIGURATION (100KB messages, breaks Lambda)
# Use these variable values:
# message_size_breach_max_size = 102400  # 100KB - seems reasonable!
# message_size_breach_batch_size = 10    # 10 messages × 100KB = 1MB > 256KB Lambda async limit ❌
#
# The key insight: The risk isn't obvious from individual resource configs
# - SQS queue config looks fine (100KB messages allowed, SQS supports up to 1MB)
# - Lambda function config looks fine (3-minute timeout)
# - Batch size config looks fine (10 messages)
# - But together: 1MB > 256KB Lambda async limit = complete failure
#
# Overmind would catch this by analyzing:
# - Service integration limits (SQS batch size × message size vs Lambda limits)
# - Cost impact modeling (failed invocations waste money)
# - Timeline risk assessment (when this will fail under load)
# - Dependency chain analysis (all affected downstream services)
# - Resource impact count (47+ resources affected, not just the SQS queue)
