package terraform.s3

# S3 Security Policy
# Checks for missing required tags, encryption, and public access

import rego.v1

# Required tags for all S3 buckets
required_tags := {"Owner", "Environment", "Project"}

# Get all S3 bucket resources from terraform plan
s3_buckets contains resource if {
	some resource in input.resource_changes
	resource.type == "aws_s3_bucket"
	resource.change.actions[_] in ["create", "update"]
}

# Get all S3 bucket public access block resources
s3_public_access_blocks contains resource if {
	some resource in input.resource_changes
	resource.type == "aws_s3_bucket_public_access_block"
	resource.change.actions[_] in ["create", "update"]
}

# Get all S3 bucket server side encryption resources
s3_encryption_configs contains resource if {
	some resource in input.resource_changes
	resource.type == "aws_s3_bucket_server_side_encryption_configuration"
	resource.change.actions[_] in ["create", "update"]
}

# Check for missing required tags
deny contains msg if {
	some bucket in s3_buckets
	some required_tag in required_tags
	not bucket.change.after.tags[required_tag]
	msg := sprintf("S3 bucket '%s' is missing required tag '%s'", [bucket.address, required_tag])
}

# Check for unencrypted S3 buckets
deny contains msg if {
	some bucket in s3_buckets
	bucket_name := bucket.change.after.bucket
	not has_encryption_config(bucket_name)
	msg := sprintf("S3 bucket '%s' does not have server-side encryption configured", [bucket.address])
}

# Check for S3 buckets without public access block
deny contains msg if {
	some bucket in s3_buckets
	bucket_name := bucket.change.after.bucket
	not has_public_access_block(bucket_name)
	msg := sprintf("S3 bucket '%s' does not have public access block configured - consider adding aws_s3_bucket_public_access_block", [bucket.address])
}

# Check for explicitly allowed public read access (this might be intentional but should be flagged)
warn contains msg if {
	some pab in s3_public_access_blocks
	pab.change.after.block_public_read_buckets == false
	msg := sprintf("S3 bucket public access block '%s' explicitly allows public read access - ensure this is intentional", [pab.address])
}

# Check for explicitly allowed public write access (this is almost never intentional)
deny contains msg if {
	some pab in s3_public_access_blocks
	pab.change.after.block_public_write_buckets == false
	msg := sprintf("S3 bucket public access block '%s' allows public write access - this is a security risk", [pab.address])
}

# Helper function to check if bucket has encryption configuration
has_encryption_config(bucket_name) if {
	some encryption in s3_encryption_configs
	encryption.change.after.bucket == bucket_name
}

# Helper function to check if bucket has public access block
has_public_access_block(bucket_name) if {
	some pab in s3_public_access_blocks
	pab.change.after.bucket == bucket_name
}