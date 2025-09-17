package terraform.security

# Security Groups Policy
# Checks for dangerous ingress rules that expose resources to the internet

import rego.v1

# Get all security group resources from terraform plan
security_groups contains resource if {
	some resource in input.resource_changes
	resource.type == "aws_security_group"
	resource.change.actions[_] in ["create", "update"]
}

# Get all security group rule resources from terraform plan
security_group_rules contains resource if {
	some resource in input.resource_changes
	resource.type == "aws_security_group_rule"
	resource.change.actions[_] in ["create", "update"]
}

# Check for SSH (port 22) open to 0.0.0.0/0 in security groups
deny contains msg if {
	some sg in security_groups
	some ingress in sg.change.after.ingress
	ingress.from_port == 22
	ingress.to_port == 22
	ingress.protocol == "tcp"
	"0.0.0.0/0" in ingress.cidr_blocks
	msg := sprintf("Security group '%s' allows SSH (port 22) access from anywhere (0.0.0.0/0)", [sg.address])
}

# Check for RDP (port 3389) open to 0.0.0.0/0 in security groups
deny contains msg if {
	some sg in security_groups
	some ingress in sg.change.after.ingress
	ingress.from_port == 3389
	ingress.to_port == 3389
	ingress.protocol == "tcp"
	"0.0.0.0/0" in ingress.cidr_blocks
	msg := sprintf("Security group '%s' allows RDP (port 3389) access from anywhere (0.0.0.0/0)", [sg.address])
}

# Check for SSH (port 22) open to 0.0.0.0/0 in security group rules
deny contains msg if {
	some sgr in security_group_rules
	sgr.change.after.type == "ingress"
	sgr.change.after.from_port == 22
	sgr.change.after.to_port == 22
	sgr.change.after.protocol == "tcp"
	sgr.change.after.cidr_blocks[_] == "0.0.0.0/0"
	msg := sprintf("Security group rule '%s' allows SSH (port 22) access from anywhere (0.0.0.0/0)", [sgr.address])
}

# Check for RDP (port 3389) open to 0.0.0.0/0 in security group rules
deny contains msg if {
	some sgr in security_group_rules
	sgr.change.after.type == "ingress"
	sgr.change.after.from_port == 3389
	sgr.change.after.to_port == 3389
	sgr.change.after.protocol == "tcp"
	sgr.change.after.cidr_blocks[_] == "0.0.0.0/0"
	msg := sprintf("Security group rule '%s' allows RDP (port 3389) access from anywhere (0.0.0.0/0)", [sgr.address])
}

# Check for wide-open ingress rules (all ports from 0.0.0.0/0) in security groups
deny contains msg if {
	some sg in security_groups
	some ingress in sg.change.after.ingress
	ingress.from_port == 0
	ingress.to_port == 65535
	"0.0.0.0/0" in ingress.cidr_blocks
	msg := sprintf("Security group '%s' allows all traffic (ports 0-65535) from anywhere (0.0.0.0/0)", [sg.address])
}

# Check for wide-open ingress rules (all ports from 0.0.0.0/0) in security group rules
deny contains msg if {
	some sgr in security_group_rules
	sgr.change.after.type == "ingress"
	sgr.change.after.from_port == 0
	sgr.change.after.to_port == 65535
	sgr.change.after.cidr_blocks[_] == "0.0.0.0/0"
	msg := sprintf("Security group rule '%s' allows all traffic (ports 0-65535) from anywhere (0.0.0.0/0)", [sgr.address])
}

# Check for ingress rules allowing all traffic (-1 protocol) from 0.0.0.0/0
deny contains msg if {
	some sg in security_groups
	some ingress in sg.change.after.ingress
	ingress.protocol == "-1"
	"0.0.0.0/0" in ingress.cidr_blocks
	msg := sprintf("Security group '%s' allows ALL protocols from anywhere (0.0.0.0/0)", [sg.address])
}

# Check for ingress rules allowing all traffic (-1 protocol) from 0.0.0.0/0 in security group rules
deny contains msg if {
	some sgr in security_group_rules
	sgr.change.after.type == "ingress"
	sgr.change.after.protocol == "-1"
	sgr.change.after.cidr_blocks[_] == "0.0.0.0/0"
	msg := sprintf("Security group rule '%s' allows ALL protocols from anywhere (0.0.0.0/0)", [sgr.address])
}

# Warn about database ports open to 0.0.0.0/0
warn contains msg if {
	some sg in security_groups
	some ingress in sg.change.after.ingress
	ingress.from_port in {3306, 5432, 1433, 1521, 27017}  # MySQL, PostgreSQL, SQL Server, Oracle, MongoDB
	"0.0.0.0/0" in ingress.cidr_blocks
	msg := sprintf("Security group '%s' allows database port %d access from anywhere (0.0.0.0/0) - consider restricting access", [sg.address, ingress.from_port])
}

# Warn about common application ports that might not need internet access
warn contains msg if {
	some sg in security_groups
	some ingress in sg.change.after.ingress
	ingress.from_port in {8080, 9000, 9090, 3000, 4000, 5000}  # Common dev/app ports
	"0.0.0.0/0" in ingress.cidr_blocks
	msg := sprintf("Security group '%s' allows application port %d access from anywhere (0.0.0.0/0) - ensure this is intended for public access", [sg.address, ingress.from_port])
}