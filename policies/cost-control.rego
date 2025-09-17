package main

import rego.v1

# Cost Control Policy
# Checks for expensive instance types and configurations

# Get all EC2 instances from terraform plan
ec2_instances contains instance if {
	instance := input.resource_changes[_]
	instance.type == "aws_instance"
}

# Get all RDS instances from terraform plan
rds_instances contains instance if {
	instance := input.resource_changes[_]
	instance.type == "aws_db_instance"
}

# Get all RDS clusters from terraform plan
rds_clusters contains cluster if {
	cluster := input.resource_changes[_]
	cluster.type == "aws_rds_cluster"
}

# Expensive EC2 instance types
expensive_ec2_types := {
	"m5.24xlarge", "m5.16xlarge", "m5.12xlarge",
	"c5.24xlarge", "c5.18xlarge", "c5.12xlarge",
	"r5.24xlarge", "r5.16xlarge", "r5.12xlarge",
	"x1.32xlarge", "x1.16xlarge", "x1e.32xlarge",
	"p3.16xlarge", "p3.8xlarge", "p2.16xlarge",
	"g3.16xlarge", "g3.8xlarge", "g4dn.16xlarge"
}

# Expensive RDS instance types
expensive_rds_types := {
	"db.m5.24xlarge", "db.m5.16xlarge", "db.m5.12xlarge",
	"db.r5.24xlarge", "db.r5.16xlarge", "db.r5.12xlarge",
	"db.x1.32xlarge", "db.x1.16xlarge", "db.x1e.32xlarge"
}

# Deny expensive EC2 instance types
deny contains msg if {
	instance := ec2_instances[_]
	instance.change.after.instance_type in expensive_ec2_types
	msg := sprintf("EC2 instance '%s' uses expensive instance type '%s' - consider using a smaller instance type", [instance.address, instance.change.after.instance_type])
}

# Deny expensive RDS instance types
deny contains msg if {
	instance := rds_instances[_]
	instance.change.after.instance_class in expensive_rds_types
	msg := sprintf("RDS instance '%s' uses expensive instance class '%s' - consider using a smaller instance class", [instance.address, instance.change.after.instance_class])
}

# Deny RDS clusters without cost-effective configurations
deny contains msg if {
	cluster := rds_clusters[_]
	not cluster.change.after.deletion_protection
	msg := sprintf("RDS cluster '%s' does not have deletion protection enabled - this could lead to accidental expensive data loss", [cluster.address])
}

# Warn about instances without cost control tags
warn contains msg if {
	instance := ec2_instances[_]
	not instance.change.after.tags.CostCenter
	msg := sprintf("EC2 instance '%s' is missing 'CostCenter' tag for cost tracking", [instance.address])
}

warn contains msg if {
	instance := rds_instances[_]
	not instance.change.after.tags.CostCenter
	msg := sprintf("RDS instance '%s' is missing 'CostCenter' tag for cost tracking", [instance.address])
}

# Warn about production instances in expensive regions
warn contains msg if {
	instance := ec2_instances[_]
	instance.change.after.tags.Environment == "prod"
	# This is a simplified check - in practice you'd check the provider region
	msg := sprintf("Production EC2 instance '%s' - ensure you're using the most cost-effective region", [instance.address])
}

# Warn about instances without scheduled start/stop for dev environments
warn contains msg if {
	instance := ec2_instances[_]
	instance.change.after.tags.Environment == "dev"
	not instance.change.after.tags.Schedule
	msg := sprintf("Development EC2 instance '%s' is missing 'Schedule' tag - consider auto-shutdown to reduce costs", [instance.address])
}

# Warn about RDS instances without backup retention optimization
warn contains msg if {
	instance := rds_instances[_]
	instance.change.after.backup_retention_period > 7
	instance.change.after.tags.Environment == "dev"
	msg := sprintf("Development RDS instance '%s' has backup retention > 7 days - consider reducing for cost savings", [instance.address])
}

# Warn about instances with high storage allocation
warn contains msg if {
	instance := rds_instances[_]
	instance.change.after.allocated_storage > 1000
	msg := sprintf("RDS instance '%s' has high storage allocation (%d GB) - ensure this is necessary", [instance.address, instance.change.after.allocated_storage])
}