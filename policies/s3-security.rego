package main

# S3 Security Policy
# Checks for S3 buckets without proper security configurations

# Get all S3 bucket resources from terraform plan
s3_buckets[bucket] {
	bucket := input.resource_changes[_]
	bucket.type == "aws_s3_bucket"
}

s3_bucket_public_access_blocks[block] {
	block := input.resource_changes[_]
	block.type == "aws_s3_bucket_public_access_block"
}

s3_bucket_encryption[encrypt] {
	encrypt := input.resource_changes[_]
	encrypt.type == "aws_s3_bucket_server_side_encryption_configuration"
}

# Deny S3 buckets without Environment tag
deny[msg] {
	bucket := s3_buckets[_]
	not bucket.change.after.tags.Environment
	msg := sprintf("S3 bucket '%s' is missing the required 'Environment' tag", [bucket.address])
}

# Deny S3 buckets without Name tag
deny[msg] {
	bucket := s3_buckets[_]
	not bucket.change.after.tags.Name
	msg := sprintf("S3 bucket '%s' is missing the required 'Name' tag", [bucket.address])
}

# Deny S3 buckets without Owner tag
deny[msg] {
	bucket := s3_buckets[_]
	not bucket.change.after.tags.Owner
	msg := sprintf("S3 bucket '%s' is missing the required 'Owner' tag", [bucket.address])
}

# Deny S3 buckets without Project tag
deny[msg] {
	bucket := s3_buckets[_]
	not bucket.change.after.tags.Project
	msg := sprintf("S3 bucket '%s' is missing the required 'Project' tag", [bucket.address])
}

# Deny S3 buckets without encryption
deny[msg] {
	bucket := s3_buckets[_]
	not has_bucket_encryption(bucket.change.after.bucket)
	msg := sprintf("S3 bucket '%s' does not have server-side encryption configured", [bucket.address])
}

# Warn about S3 buckets without public access block
warn[msg] {
	bucket := s3_buckets[_]
	not has_public_access_block(bucket.change.after.bucket)
	msg := sprintf("S3 bucket '%s' does not have public access block configured - consider adding one for security", [bucket.address])
}

# Warn about S3 buckets that might be publicly accessible
warn[msg] {
	bucket := s3_buckets[_]
	bucket.change.after.acl == "public-read"
	msg := sprintf("S3 bucket '%s' has public-read ACL - ensure this is intentional", [bucket.address])
}

warn[msg] {
	bucket := s3_buckets[_]
	bucket.change.after.acl == "public-read-write"
	msg := sprintf("S3 bucket '%s' has public-read-write ACL - this is a security risk", [bucket.address])
}

# Helper function to check if bucket has encryption configuration
has_bucket_encryption(bucket_name) {
	encryption := s3_bucket_encryption[_]
	encryption.change.after.bucket == bucket_name
}

# Helper function to check if bucket has public access block
has_public_access_block(bucket_name) {
	block := s3_bucket_public_access_blocks[_]
	block.change.after.bucket == bucket_name
}