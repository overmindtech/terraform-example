# =============================================================================
# High Fan-Out Scenarios
# Test scenarios that modify SHARED resources affecting many downstream items
# These create large blast radii for performance testing
# =============================================================================
#
# IMPORTANT: The shared_sg_open scenario is now implemented via the module's
# aws_security_group.high_fanout resource using dynamic ingress blocks.
# This ensures the plan shows a MODIFICATION of the existing SG (which has
# relationships to all EC2 instances) rather than creation of separate
# aws_security_group_rule resources that Overmind may not traverse from.
#
# The scenario is controlled by:
#   main.tf: local.scenario_open_ssh -> module variable open_ssh_to_internet
#   modules/aws/network.tf: dynamic "ingress" block on aws_security_group.high_fanout
#
# Scenarios using this mechanism:
#   - shared_sg_open:     Opens SSH (port 22) from 0.0.0.0/0
#   - combined_network:   Opens SSH (port 22) from 0.0.0.0/0 + VPC peering DNS
#   - combined_all:       Opens SSH (port 22) from 0.0.0.0/0 + VPC peering + SNS
#   - combined_max:       Opens ALL ports (0-65535) from 0.0.0.0/0 + everything
# =============================================================================
