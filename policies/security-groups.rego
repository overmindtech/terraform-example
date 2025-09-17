package terraform.security

# Security Groups Policy
# Checks for dangerous ingress rules that expose resources to the internet

# Get all security group resources from terraform plan
security_groups[resource] {
	resource := input.resource_changes[_]
	resource.type == "aws_security_group"
	resource.change.actions[_] == "create"
}

security_groups[resource] {
	resource := input.resource_changes[_]
	resource.type == "aws_security_group"
	resource.change.actions[_] == "update"
}

# Get all security group rule resources from terraform plan
security_group_rules[resource] {
	resource := input.resource_changes[_]
	resource.type == "aws_security_group_rule"
	resource.change.actions[_] == "create"
}

security_group_rules[resource] {
	resource := input.resource_changes[_]
	resource.type == "aws_security_group_rule"
	resource.change.actions[_] == "update"
}

# Check for SSH (port 22) open to 0.0.0.0/0 in security groups
deny[msg] {
	sg := security_groups[_]
	ingress := sg.change.after.ingress[_]
	ingress.from_port == 22
	ingress.to_port == 22
	ingress.protocol == "tcp"
	"0.0.0.0/0" == ingress.cidr_blocks[_]
	msg := sprintf("Security group '%s' allows SSH (port 22) access from anywhere (0.0.0.0/0)", [sg.address])
}

# Check for RDP (port 3389) open to 0.0.0.0/0 in security groups
deny[msg] {
	sg := security_groups[_]
	ingress := sg.change.after.ingress[_]
	ingress.from_port == 3389
	ingress.to_port == 3389
	ingress.protocol == "tcp"
	"0.0.0.0/0" == ingress.cidr_blocks[_]
	msg := sprintf("Security group '%s' allows RDP (port 3389) access from anywhere (0.0.0.0/0)", [sg.address])
}

# Check for SSH (port 22) open to 0.0.0.0/0 in security group rules
deny[msg] {
	sgr := security_group_rules[_]
	sgr.change.after.type == "ingress"
	sgr.change.after.from_port == 22
	sgr.change.after.to_port == 22
	sgr.change.after.protocol == "tcp"
	sgr.change.after.cidr_blocks[_] == "0.0.0.0/0"
	msg := sprintf("Security group rule '%s' allows SSH (port 22) access from anywhere (0.0.0.0/0)", [sgr.address])
}

# Check for RDP (port 3389) open to 0.0.0.0/0 in security group rules
deny[msg] {
	sgr := security_group_rules[_]
	sgr.change.after.type == "ingress"
	sgr.change.after.from_port == 3389
	sgr.change.after.to_port == 3389
	sgr.change.after.protocol == "tcp"
	sgr.change.after.cidr_blocks[_] == "0.0.0.0/0"
	msg := sprintf("Security group rule '%s' allows RDP (port 3389) access from anywhere (0.0.0.0/0)", [sgr.address])
}

# Check for wide-open ingress rules (all ports from 0.0.0.0/0) in security groups
deny[msg] {
	sg := security_groups[_]
	ingress := sg.change.after.ingress[_]
	ingress.from_port == 0
	ingress.to_port == 65535
	"0.0.0.0/0" == ingress.cidr_blocks[_]
	msg := sprintf("Security group '%s' allows all traffic (ports 0-65535) from anywhere (0.0.0.0/0)", [sg.address])
}

# Check for wide-open ingress rules (all ports from 0.0.0.0/0) in security group rules
deny[msg] {
	sgr := security_group_rules[_]
	sgr.change.after.type == "ingress"
	sgr.change.after.from_port == 0
	sgr.change.after.to_port == 65535
	sgr.change.after.cidr_blocks[_] == "0.0.0.0/0"
	msg := sprintf("Security group rule '%s' allows all traffic (ports 0-65535) from anywhere (0.0.0.0/0)", [sgr.address])
}

# Check for ingress rules allowing all traffic (-1 protocol) from 0.0.0.0/0
deny[msg] {
	sg := security_groups[_]
	ingress := sg.change.after.ingress[_]
	ingress.protocol == "-1"
	"0.0.0.0/0" == ingress.cidr_blocks[_]
	msg := sprintf("Security group '%s' allows ALL protocols from anywhere (0.0.0.0/0)", [sg.address])
}

# Check for ingress rules allowing all traffic (-1 protocol) from 0.0.0.0/0 in security group rules
deny[msg] {
	sgr := security_group_rules[_]
	sgr.change.after.type == "ingress"
	sgr.change.after.protocol == "-1"
	sgr.change.after.cidr_blocks[_] == "0.0.0.0/0"
	msg := sprintf("Security group rule '%s' allows ALL protocols from anywhere (0.0.0.0/0)", [sgr.address])
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