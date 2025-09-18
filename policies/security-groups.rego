package main

# Get all security groups being created or modified
security_groups[sg] {
	sg := input.resource_changes[_]
	sg.type == "aws_security_group"
}

security_group_rules[rule] {
	rule := input.resource_changes[_]
	rule.type == "aws_security_group_rule"
}

# Deny SSH access from 0.0.0.0/0
deny[msg] {
	sg := security_groups[_]
	ingress := sg.change.after.ingress[_]
	ingress.from_port == 22
	"0.0.0.0/0" == ingress.cidr_blocks[_]
	msg := sprintf("Security group '%s' allows SSH (port 22) access from anywhere (0.0.0.0/0) - this is a security risk", [sg.address])
}

# Check for SSH via security group rules
deny[msg] {
	rule := security_group_rules[_]
	rule.change.after.type == "ingress"
	rule.change.after.from_port == 22
	"0.0.0.0/0" == rule.change.after.cidr_blocks[_]
	msg := sprintf("Security group rule '%s' allows SSH (port 22) access from anywhere (0.0.0.0/0) - this is a security risk", [rule.address])
}

# Deny RDP access from 0.0.0.0/0
deny[msg] {
	sg := security_groups[_]
	ingress := sg.change.after.ingress[_]
	ingress.from_port == 3389
	"0.0.0.0/0" == ingress.cidr_blocks[_]
	msg := sprintf("Security group '%s' allows RDP (port 3389) access from anywhere (0.0.0.0/0) - this is a security risk", [sg.address])
}

# Check for RDP via security group rules
deny[msg] {
	rule := security_group_rules[_]
	rule.change.after.type == "ingress"
	rule.change.after.from_port == 3389
	"0.0.0.0/0" == rule.change.after.cidr_blocks[_]
	msg := sprintf("Security group rule '%s' allows RDP (port 3389) access from anywhere (0.0.0.0/0) - this is a security risk", [rule.address])
}

# Deny overly permissive rules (all traffic from anywhere)
deny[msg] {
	sg := security_groups[_]
	ingress := sg.change.after.ingress[_]
	ingress.from_port == 0
	ingress.to_port == 65535
	"0.0.0.0/0" == ingress.cidr_blocks[_]
	msg := sprintf("Security group '%s' allows all traffic (0-65535) from anywhere (0.0.0.0/0) - this is extremely insecure", [sg.address])
}

# Check for overly permissive rules via security group rules
deny[msg] {
	rule := security_group_rules[_]
	rule.change.after.type == "ingress"
	rule.change.after.from_port == 0
	rule.change.after.to_port == 65535
	"0.0.0.0/0" == rule.change.after.cidr_blocks[_]
	msg := sprintf("Security group rule '%s' allows all traffic (0-65535) from anywhere (0.0.0.0/0) - this is extremely insecure", [rule.address])
}

# Deny wide port ranges from 0.0.0.0/0
deny[msg] {
	sg := security_groups[_]
	ingress := sg.change.after.ingress[_]
	ingress.to_port - ingress.from_port > 1000
	"0.0.0.0/0" == ingress.cidr_blocks[_]
	msg := sprintf("Security group '%s' allows a wide port range (%d-%d) from anywhere (0.0.0.0/0) - consider restricting the range", [sg.address, ingress.from_port, ingress.to_port])
}

# Warn about database ports open to 0.0.0.0/0
warn[msg] {
	sg := security_groups[_]
	ingress := sg.change.after.ingress[_]
	ingress.from_port == 3306  # MySQL
	"0.0.0.0/0" == ingress.cidr_blocks[_]
	msg := sprintf("Security group '%s' allows database port %d access from anywhere (0.0.0.0/0) - consider restricting access", [sg.address, ingress.from_port])
}

warn[msg] {
	sg := security_groups[_]
	ingress := sg.change.after.ingress[_]
	ingress.from_port == 5432  # PostgreSQL
	"0.0.0.0/0" == ingress.cidr_blocks[_]
	msg := sprintf("Security group '%s' allows database port %d access from anywhere (0.0.0.0/0) - consider restricting access", [sg.address, ingress.from_port])
}

warn[msg] {
	sg := security_groups[_]
	ingress := sg.change.after.ingress[_]
	ingress.from_port == 1433  # SQL Server
	"0.0.0.0/0" == ingress.cidr_blocks[_]
	msg := sprintf("Security group '%s' allows database port %d access from anywhere (0.0.0.0/0) - consider restricting access", [sg.address, ingress.from_port])
}

warn[msg] {
	sg := security_groups[_]
	ingress := sg.change.after.ingress[_]
	ingress.from_port == 1521  # Oracle
	"0.0.0.0/0" == ingress.cidr_blocks[_]
	msg := sprintf("Security group '%s' allows database port %d access from anywhere (0.0.0.0/0) - consider restricting access", [sg.address, ingress.from_port])
}

warn[msg] {
	sg := security_groups[_]
	ingress := sg.change.after.ingress[_]
	ingress.from_port == 27017  # MongoDB
	"0.0.0.0/0" == ingress.cidr_blocks[_]
	msg := sprintf("Security group '%s' allows database port %d access from anywhere (0.0.0.0/0) - consider restricting access", [sg.address, ingress.from_port])
}

# Warn about common application ports that might not need internet access
warn[msg] {
	sg := security_groups[_]
	ingress := sg.change.after.ingress[_]
	ingress.from_port == 8080
	"0.0.0.0/0" == ingress.cidr_blocks[_]
	msg := sprintf("Security group '%s' allows application port %d access from anywhere (0.0.0.0/0) - ensure this is intended for public access", [sg.address, ingress.from_port])
}

warn[msg] {
	sg := security_groups[_]
	ingress := sg.change.after.ingress[_]
	ingress.from_port == 9000
	"0.0.0.0/0" == ingress.cidr_blocks[_]
	msg := sprintf("Security group '%s' allows application port %d access from anywhere (0.0.0.0/0) - ensure this is intended for public access", [sg.address, ingress.from_port])
}

warn[msg] {
	sg := security_groups[_]
	ingress := sg.change.after.ingress[_]
	ingress.from_port == 9090
	"0.0.0.0/0" == ingress.cidr_blocks[_]
	msg := sprintf("Security group '%s' allows application port %d access from anywhere (0.0.0.0/0) - ensure this is intended for public access", [sg.address, ingress.from_port])
}

warn[msg] {
	sg := security_groups[_]
	ingress := sg.change.after.ingress[_]
	ingress.from_port == 3000
	"0.0.0.0/0" == ingress.cidr_blocks[_]
	msg := sprintf("Security group '%s' allows application port %d access from anywhere (0.0.0.0/0) - ensure this is intended for public access", [sg.address, ingress.from_port])
}

warn[msg] {
	sg := security_groups[_]
	ingress := sg.change.after.ingress[_]
	ingress.from_port == 4000
	"0.0.0.0/0" == ingress.cidr_blocks[_]
	msg := sprintf("Security group '%s' allows application port %d access from anywhere (0.0.0.0/0) - ensure this is intended for public access", [sg.address, ingress.from_port])
}

warn[msg] {
	sg := security_groups[_]
	ingress := sg.change.after.ingress[_]
	ingress.from_port == 5000
	"0.0.0.0/0" == ingress.cidr_blocks[_]
	msg := sprintf("Security group '%s' allows application port %d access from anywhere (0.0.0.0/0) - ensure this is intended for public access", [sg.address, ingress.from_port])
}