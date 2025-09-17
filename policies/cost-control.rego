package terraform.cost

# Cost Control Policy
# Checks for expensive instance types, RDS configurations, and high-cost regions

# Expensive EC2 instance types (anything larger than t3.large)
expensive_ec2_types := {
	"m5.xlarge", "m5.2xlarge", "m5.4xlarge", "m5.8xlarge", "m5.12xlarge", "m5.16xlarge", "m5.24xlarge",
	"m5n.xlarge", "m5n.2xlarge", "m5n.4xlarge", "m5n.8xlarge", "m5n.12xlarge", "m5n.16xlarge", "m5n.24xlarge",
	"m6i.xlarge", "m6i.2xlarge", "m6i.4xlarge", "m6i.8xlarge", "m6i.12xlarge", "m6i.16xlarge", "m6i.24xlarge", "m6i.32xlarge",
	"c5.xlarge", "c5.2xlarge", "c5.4xlarge", "c5.9xlarge", "c5.12xlarge", "c5.18xlarge", "c5.24xlarge",
	"c6i.xlarge", "c6i.2xlarge", "c6i.4xlarge", "c6i.8xlarge", "c6i.12xlarge", "c6i.16xlarge", "c6i.24xlarge", "c6i.32xlarge",
	"r5.xlarge", "r5.2xlarge", "r5.4xlarge", "r5.8xlarge", "r5.12xlarge", "r5.16xlarge", "r5.24xlarge",
	"r6i.xlarge", "r6i.2xlarge", "r6i.4xlarge", "r6i.8xlarge", "r6i.12xlarge", "r6i.16xlarge", "r6i.24xlarge", "r6i.32xlarge",
	"x1.16xlarge", "x1.32xlarge", "x1e.xlarge", "x1e.2xlarge", "x1e.4xlarge", "x1e.8xlarge", "x1e.16xlarge", "x1e.32xlarge",
	"z1d.xlarge", "z1d.2xlarge", "z1d.3xlarge", "z1d.6xlarge", "z1d.12xlarge",
	"i3.xlarge", "i3.2xlarge", "i3.4xlarge", "i3.8xlarge", "i3.16xlarge",
	"g4dn.xlarge", "g4dn.2xlarge", "g4dn.4xlarge", "g4dn.8xlarge", "g4dn.12xlarge", "g4dn.16xlarge",
	"p3.2xlarge", "p3.8xlarge", "p3.16xlarge", "p3dn.24xlarge"
}

# Expensive RDS instance classes
expensive_rds_classes := {
	"db.m5.xlarge", "db.m5.2xlarge", "db.m5.4xlarge", "db.m5.8xlarge", "db.m5.12xlarge", "db.m5.16xlarge", "db.m5.24xlarge",
	"db.m6i.xlarge", "db.m6i.2xlarge", "db.m6i.4xlarge", "db.m6i.8xlarge", "db.m6i.12xlarge", "db.m6i.16xlarge", "db.m6i.24xlarge", "db.m6i.32xlarge",
	"db.r5.xlarge", "db.r5.2xlarge", "db.r5.4xlarge", "db.r5.8xlarge", "db.r5.12xlarge", "db.r5.16xlarge", "db.r5.24xlarge",
	"db.r6i.xlarge", "db.r6i.2xlarge", "db.r6i.4xlarge", "db.r6i.8xlarge", "db.r6i.12xlarge", "db.r6i.16xlarge", "db.r6i.24xlarge", "db.r6i.32xlarge",
	"db.x1.16xlarge", "db.x1.32xlarge", "db.x1e.xlarge", "db.x1e.2xlarge", "db.x1e.4xlarge", "db.x1e.8xlarge", "db.x1e.16xlarge", "db.x1e.32xlarge"
}

# High-cost AWS regions (generally more expensive than us-east-1)
expensive_regions := {
	"ap-northeast-1",  # Tokyo
	"ap-northeast-2",  # Seoul
	"ap-northeast-3",  # Osaka
	"ap-south-1",      # Mumbai
	"ap-southeast-1",  # Singapore
	"ap-southeast-2",  # Sydney
	"ca-central-1",    # Canada
	"eu-central-1",    # Frankfurt
	"eu-north-1",      # Stockholm
	"eu-west-2",       # London
	"eu-west-3",       # Paris
	"sa-east-1"        # São Paulo
}

# Get all EC2 instance resources from terraform plan
ec2_instances[resource] {
	resource := input.resource_changes[_]
	resource.type == "aws_instance"
	resource.change.actions[_] == "create"
}

ec2_instances[resource] {
	resource := input.resource_changes[_]
	resource.type == "aws_instance"
	resource.change.actions[_] == "update"
}

# Get all RDS instance resources from terraform plan
rds_instances[resource] {
	resource := input.resource_changes[_]
	resource.type == "aws_db_instance"
	resource.change.actions[_] == "create"
}

rds_instances[resource] {
	resource := input.resource_changes[_]
	resource.type == "aws_db_instance"
	resource.change.actions[_] == "update"
}

# Get all RDS cluster resources from terraform plan
rds_clusters[resource] {
	resource := input.resource_changes[_]
	resource.type == "aws_rds_cluster"
	resource.change.actions[_] == "create"
}

rds_clusters[resource] {
	resource := input.resource_changes[_]
	resource.type == "aws_rds_cluster"
	resource.change.actions[_] == "update"
}

# Get provider configuration to determine region
provider_region = region {
	provider := input.configuration.provider_config.aws[_]
	region := provider.expressions.region.constant_value
}

provider_region = "us-east-1" {
	not input.configuration.provider_config.aws[_].expressions.region.constant_value
}

# Check for expensive EC2 instance types
deny[msg] {
	instance := ec2_instances[_]
	instance_type := instance.change.after.instance_type
	expensive_ec2_types[instance_type]
	msg := sprintf("EC2 instance '%s' uses expensive instance type '%s' - consider using t3.large or smaller for cost optimization", [instance.address, instance_type])
}

# Check for expensive RDS instance classes
deny[msg] {
	rds := rds_instances[_]
	instance_class := rds.change.after.instance_class
	expensive_rds_classes[instance_class]
	msg := sprintf("RDS instance '%s' uses expensive instance class '%s' - consider using db.t3.medium or smaller for cost optimization", [rds.address, instance_class])
}

# Warn about expensive regions for EC2 instances
warn[msg] {
	instance := ec2_instances[_]
	expensive_regions[provider_region]
	msg := sprintf("EC2 instance '%s' will be created in expensive region '%s' - consider using us-east-1 or us-west-2 for lower costs", [instance.address, provider_region])
}

# Warn about expensive regions for RDS instances
warn[msg] {
	rds := rds_instances[_]
	expensive_regions[provider_region]
	msg := sprintf("RDS instance '%s' will be created in expensive region '%s' - consider using us-east-1 or us-west-2 for lower costs", [rds.address, provider_region])
}

# Check for RDS instances without appropriate backup retention (cost vs compliance)
warn[msg] {
	rds := rds_instances[_]
	backup_retention := rds.change.after.backup_retention_period
	backup_retention > 7
	msg := sprintf("RDS instance '%s' has backup retention period of %d days - consider if this is necessary for cost optimization", [rds.address, backup_retention])
}

# Check for RDS instances with multi-AZ enabled (higher cost)
warn[msg] {
	rds := rds_instances[_]
	rds.change.after.multi_az == true
	msg := sprintf("RDS instance '%s' has Multi-AZ enabled - ensure this is required for your availability needs as it doubles the cost", [rds.address])
}

# Warn about high IOPS provisioned storage
warn[msg] {
	rds := rds_instances[_]
	storage_type := rds.change.after.storage_type
	storage_type == "io1"
	iops := rds.change.after.iops
	iops > 1000
	msg := sprintf("RDS instance '%s' uses provisioned IOPS storage with %d IOPS - consider if gp2/gp3 storage would meet your needs at lower cost", [rds.address, iops])
}

# Check for large allocated storage
warn[msg] {
	rds := rds_instances[_]
	allocated_storage := rds.change.after.allocated_storage
	allocated_storage > 100
	msg := sprintf("RDS instance '%s' has %d GB allocated storage - ensure this storage size is necessary", [rds.address, allocated_storage])
}

# Check for RDS clusters with expensive instance classes
deny[msg] {
	cluster := rds_clusters[_]
	instance_class := cluster.change.after.instance_class
	expensive_rds_classes[instance_class]
	msg := sprintf("RDS cluster '%s' uses expensive instance class '%s' - consider using db.t3.medium or smaller for cost optimization", [cluster.address, instance_class])
}