# This example creates a security group and two instances, we will associate the
# SG with the instances manually in the GUI, then try to delete it via Terraform

resource "aws_instance" "example_1" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"               # Make sure this is in the free tier in your region

  tags = {
    Name = "SG Removal Example Instance 1"
  }
}

resource "aws_instance" "example_2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"               # Ensure this instance type is eligible for the free tier in your region

  tags = {
    Name = "SG Removal Example Instance 1"
  }
}
