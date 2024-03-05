# This example creates a security group and two instances, we will associate the
# SG with the instances manually in the GUI, then try to delete it via Terraform
resource "aws_security_group" "allow_access" {
  name        = "allow_access"
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
  instance_type = "t3.micro"               # Make sure this is in the free tier in your region

  tags = {
    Name = "ExampleInstance1"
  }
}

resource "aws_instance" "example_2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"               # Ensure this instance type is eligible for the free tier in your region

  tags = {
    Name = "ExampleInstance2"
  }
}
