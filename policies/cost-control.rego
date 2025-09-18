package main

# Cost Control Policy
# Checks for expensive instance types and configurations

# Get all EC2 instances from terraform plan
ec2_instances[instance] {
	instance := input.resource_changes[_]
	instance.type == "aws_instance"
}

# Get all RDS instances from terraform plan
rds_instances[instance] {
	instance := input.resource_changes[_]
	instance.type == "aws_db_instance"
}

# Get all RDS clusters from terraform plan
rds_clusters[cluster] {
	cluster := input.resource_changes[_]
	cluster.type == "aws_rds_cluster"
}

# List of expensive EC2 instance types
expensive_ec2_types := {
	"m5.24xlarge", "m5.16xlarge", "m5.12xlarge",
	"r5.24xlarge", "r5.16xlarge", "r5.12xlarge",
	"c5.24xlarge", "c5.18xlarge", "c5.12xlarge",
	"x1.32xlarge", "x1.16xlarge",
	"r4.16xlarge", "r4.8xlarge",
	"m4.16xlarge", "m4.10xlarge",
	"c4.8xlarge",
	"p3.16xlarge", "p3.8xlarge", "p3.2xlarge",
	"p2.16xlarge", "p2.8xlarge",
	"g3.16xlarge", "g3.8xlarge"
}

# List of expensive RDS instance types
expensive_rds_types := {
	"db.r5.24xlarge", "db.r5.16xlarge", "db.r5.12xlarge",
	"db.r4.16xlarge", "db.r4.8xlarge",
	"db.m5.24xlarge", "db.m5.16xlarge", "db.m5.12xlarge",
	"db.m4.16xlarge", "db.m4.10xlarge",
	"db.x1.32xlarge", "db.x1.16xlarge"
}

# High-cost regions (typically more expensive than us-east-1)
high_cost_regions := {
	"ap-northeast-1", "ap-northeast-2", "ap-southeast-1", "ap-southeast-2",
	"eu-central-1", "eu-west-1", "eu-west-2", "eu-west-3",
	"sa-east-1"
}

# Deny expensive EC2 instance types
deny[msg] {
	instance := ec2_instances[_]
	expensive_ec2_types[instance.change.after.instance_type]
	msg := sprintf("EC2 instance '%s' uses expensive instance type '%s' - consider using a smaller instance type", [instance.address, instance.change.after.instance_type])
}

# Deny expensive RDS instance types
deny[msg] {
	instance := rds_instances[_]
	expensive_rds_types[instance.change.after.instance_class]
	msg := sprintf("RDS instance '%s' uses expensive instance type '%s' - consider using a smaller instance type", [instance.address, instance.change.after.instance_class])
}

# Deny RDS clusters without deletion protection in production
deny[msg] {
	cluster := rds_clusters[_]
	cluster.change.after.tags.Environment == "prod"
	not cluster.change.after.deletion_protection
	msg := sprintf("RDS cluster '%s' in production does not have deletion protection enabled", [cluster.address])
}

deny[msg] {
	cluster := rds_clusters[_]
	cluster.change.after.tags.Environment == "production"
	not cluster.change.after.deletion_protection
	msg := sprintf("RDS cluster '%s' in production does not have deletion protection enabled", [cluster.address])
}

# Warn about missing cost tracking tags
warn[msg] {
	instance := ec2_instances[_]
	not instance.change.after.tags.CostCenter
	msg := sprintf("EC2 instance '%s' is missing 'CostCenter' tag for cost tracking", [instance.address])
}

warn[msg] {
	instance := rds_instances[_]
	not instance.change.after.tags.CostCenter
	msg := sprintf("RDS instance '%s' is missing 'CostCenter' tag for cost tracking", [instance.address])
}

# Warn about instances in high-cost regions for production workloads
warn[msg] {
	instance := ec2_instances[_]
	instance.change.after.tags.Environment == "prod"
	provider_region := input.configuration.provider_config.aws.expressions.region.constant_value
	high_cost_regions[provider_region]
	msg := sprintf("Production EC2 instance '%s' - ensure you're using the most cost-effective region", [instance.address])
}

warn[msg] {
	instance := ec2_instances[_]
	instance.change.after.tags.Environment == "production"
	provider_region := input.configuration.provider_config.aws.expressions.region.constant_value
	high_cost_regions[provider_region]
	msg := sprintf("Production EC2 instance '%s' - ensure you're using the most cost-effective region", [instance.address])
}

# Warn about dev instances without auto-shutdown
warn[msg] {
	instance := ec2_instances[_]
	instance.change.after.tags.Environment == "dev"
	not instance.change.after.tags.AutoShutdown
	msg := sprintf("Development EC2 instance '%s' should have 'AutoShutdown' tag to reduce costs", [instance.address])
}

warn[msg] {
	instance := ec2_instances[_]
	instance.change.after.tags.Environment == "development"
	not instance.change.after.tags.AutoShutdown
	msg := sprintf("Development EC2 instance '%s' should have 'AutoShutdown' tag to reduce costs", [instance.address])
}