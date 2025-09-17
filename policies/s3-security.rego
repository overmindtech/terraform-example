package terraform.s3

# S3 Security Policy
# Checks for missing required tags, encryption, and public access

# Required tags for all S3 buckets
required_tags := {"Owner", "Environment", "Project"}

# Get all S3 bucket resources from terraform plan
s3_buckets[resource] {
	resource := input.resource_changes[_]
	resource.type == "aws_s3_bucket"
	resource.change.actions[_] == "create"
}

s3_buckets[resource] {
	resource := input.resource_changes[_]
	resource.type == "aws_s3_bucket"
	resource.change.actions[_] == "update"
}

# Get all S3 bucket public access block resources
s3_public_access_blocks[resource] {
	resource := input.resource_changes[_]
	resource.type == "aws_s3_bucket_public_access_block"
	resource.change.actions[_] == "create"
}

s3_public_access_blocks[resource] {
	resource := input.resource_changes[_]
	resource.type == "aws_s3_bucket_public_access_block"
	resource.change.actions[_] == "update"
}

# Get all S3 bucket server side encryption resources
s3_encryption_configs[resource] {
	resource := input.resource_changes[_]
	resource.type == "aws_s3_bucket_server_side_encryption_configuration"
	resource.change.actions[_] == "create"
}

s3_encryption_configs[resource] {
	resource := input.resource_changes[_]
	resource.type == "aws_s3_bucket_server_side_encryption_configuration"
	resource.change.actions[_] == "update"
}

# Check for missing required tags
deny[msg] {
	bucket := s3_buckets[_]
	required_tag := required_tags[_]
	not bucket.change.after.tags[required_tag]
	msg := sprintf("S3 bucket '%s' is missing required tag '%s'", [bucket.address, required_tag])
}

# Check for unencrypted S3 buckets
deny[msg] {
	bucket := s3_buckets[_]
	bucket_name := bucket.change.after.bucket
	not has_encryption_config(bucket_name)
	msg := sprintf("S3 bucket '%s' does not have server-side encryption configured", [bucket.address])
}

# Check for S3 buckets without public access block
deny[msg] {
	bucket := s3_buckets[_]
	bucket_name := bucket.change.after.bucket
	not has_public_access_block(bucket_name)
	msg := sprintf("S3 bucket '%s' does not have public access block configured - consider adding aws_s3_bucket_public_access_block", [bucket.address])
}

# Check for explicitly allowed public read access (this might be intentional but should be flagged)
warn[msg] {
	pab := s3_public_access_blocks[_]
	pab.change.after.block_public_read_buckets == false
	msg := sprintf("S3 bucket public access block '%s' explicitly allows public read access - ensure this is intentional", [pab.address])
}

# Check for explicitly allowed public write access (this is almost never intentional)
deny[msg] {
	pab := s3_public_access_blocks[_]
	pab.change.after.block_public_write_buckets == false
	msg := sprintf("S3 bucket public access block '%s' allows public write access - this is a security risk", [pab.address])
}

# Helper function to check if bucket has encryption configuration
has_encryption_config(bucket_name) {
	encryption := s3_encryption_configs[_]
	encryption.change.after.bucket == bucket_name
}

# Helper function to check if bucket has public access block
has_public_access_block(bucket_name) {
	pab := s3_public_access_blocks[_]
	pab.change.after.bucket == bucket_name
}