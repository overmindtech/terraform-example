# =============================================================================
# Compute Scenarios
# Test scenarios that modify EC2/Lambda resources to trigger risks
# =============================================================================

# -----------------------------------------------------------------------------
# Note on compute scenarios
# -----------------------------------------------------------------------------
# 
# ec2_downgrade scenario:
#   Implemented via the module variable approach in main.tf.
#   Changes instance_type from t3.micro to t3.nano.
#   Expected risk: Performance degradation
#
# ec2_start_all and ec2_upgrade scenarios:
#   REMOVED - These scenarios have significant cost implications and are
#   disabled to prevent accidental cost increases.
#
# -----------------------------------------------------------------------------
