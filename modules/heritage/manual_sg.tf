# This example creates a security group and two instances, we will associate the
# SG with the instances manually in the GUI, then try to delete it via Terraform
#
# This should be manually associated with the "Webserver" and "App Server"
# instances
resource "aws_security_group" "allow_access" {
  name        = "allow_access-${var.example_env}"
  description = "Allow access security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# The remainder of this example sets up two instances that are not allowed to
# talk to each other on port 8080. The reason for this being denied however is
# not obvious because the security groups explicitly allow communication on that
# port. The idea is that in order to understand why this isn't working you need
# to dig deeper and see that there is a network ACL which is preventing the
# communication. In fairness, the reachability analyser can answer this
# question.
resource "aws_subnet" "restricted-2a" {
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.9.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "Restricted 2a"
  }
}

resource "aws_subnet" "restricted-2b" {
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "eu-west-2b"

  tags = {
    Name = "Restricted 2b"
  }
}

// Create a route so that the instances can communicate with the internet. Use
// the internet gateway created by the VPC module
resource "aws_route_table_association" "restricted-2a" {
  subnet_id      = aws_subnet.restricted-2a.id
  route_table_id = var.public_route_table_ids[0]
}
resource "aws_route_table_association" "restricted-2b" {
  subnet_id      = aws_subnet.restricted-2b.id
  route_table_id = var.public_route_table_ids[0]
}

resource "aws_network_acl" "restricted" {
  vpc_id = var.vpc_id
  subnet_ids = [
    aws_subnet.restricted-2a.id,
    aws_subnet.restricted-2b.id
  ]

  tags = {
    "Name" = "Restricted Example"
  }
}

resource "aws_network_acl_rule" "allow_http" {
  network_acl_id = aws_network_acl.restricted.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "allow_ssh" {
  network_acl_id = aws_network_acl.restricted.id
  rule_number    = 102
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "allow_ephemeral" {
  network_acl_id = aws_network_acl.restricted.id
  rule_number    = 300
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "deny_high_ports" {
  network_acl_id = aws_network_acl.restricted.id
  rule_number    = 200
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 8000
  to_port        = 8100
}

resource "aws_network_acl_rule" "allow_outbound" {
  network_acl_id = aws_network_acl.restricted.id
  egress         = true
  rule_number    = 100
  protocol       = "all"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

# Use latest Amazon Linux 2 AMI via SSM for security patches
data "aws_ssm_parameter" "amzn2_latest" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "webserver" {
  ami           = data.aws_ssm_parameter.amzn2_latest.value
  instance_type = "t3.small" # Upgraded from t3.micro for cost analysis demo
  subnet_id     = aws_subnet.restricted-2a.id
  key_name      = "Demo Key Pair"

  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.instance_sg.id]

  # Root volume will be deleted on termination (default behavior)
  # This ensures clean state on instance replacement
  root_block_device {
    delete_on_termination = true
  }

  tags = {
    Name        = "Webserver"
    Environment = "dev"
  }
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ssm_parameter.amzn2_latest.value
  instance_type = "t3.small" # Upgraded from t3.micro for cost analysis demo
  subnet_id     = aws_subnet.restricted-2b.id
  key_name      = "Demo Key Pair"

  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.instance_sg.id]

  # Root volume will be deleted on termination (default behavior)
  # This ensures clean state on instance replacement
  root_block_device {
    delete_on_termination = true
  }

  tags = {
    Name        = "App Server"
    Environment = "dev"
  }
}

# This group is used to allow communication between the instances, or at least
# that's what you'd expect. However, the network ACL is blocking the
# communication
resource "aws_security_group" "instance_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

