# This example creates a security group and two instances, we will associate the
# SG with the instances manually in the GUI, then try to delete it via Terraform
resource "aws_security_group" "allow_access" {
  name        = "allow_access-${var.example_env}"
  description = "Allow access security group"

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

resource "aws_instance" "example_1" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro" # Make sure this is in the free tier in your region

  tags = {
    Name = "SG Removal Example Instance 1"
  }
}

resource "aws_instance" "example_2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro" # Ensure this instance type is eligible for the free tier in your region

  tags = {
    Name = "SG Removal Example Instance 1"
  }
}

resource "aws_subnet" "restricted" {
  vpc_id            = module.vpc.vpc_id
  cidr_block        = "10.0.9.0/24"
  availability_zone = "eu-west-2a"
}

resource "aws_network_acl" "acl" {
  vpc_id = module.vpc.vpc_id
}

resource "aws_network_acl_rule" "allow_http" {
  network_acl_id = aws_network_acl.acl.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "allow_ephemeral" {
  network_acl_id = aws_network_acl.acl.id
  rule_number    = 101
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "deny_high_ports" {
  network_acl_id = aws_network_acl.acl.id
  rule_number    = 200
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 8000
  to_port        = 8100
}

resource "aws_instance" "webserver" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.restricted.id
  security_groups = [aws_security_group.instance_sg.name]

  tags = {
    Name = "Webserver"
  }
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.restricted.id
  security_groups = [aws_security_group.instance_sg.name]

  tags = {
    Name = "App Server"
  }
}

resource "aws_security_group" "instance_sg" {
  vpc_id = module.vpc.vpc_id

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
