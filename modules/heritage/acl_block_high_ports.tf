# This demo can be used to show quite a complex example where changing an ACL
# can break things within that subnet, that we can detect

# resource "aws_network_acl" "block_high_ports" {
#   vpc_id = "vpc-0be4b791e20954fea"

#   # Allow inbound SSH
#   ingress {
#     rule_no    = 100
#     protocol   = "tcp"
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 22
#     to_port    = 22
#   }

#   # Deny inbound high ports
#   ingress {
#     rule_no    = 200
#     protocol   = "tcp"
#     action     = "deny"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 10000
#     to_port    = 65535
#   }

#   # Allow all outbound traffic
#   egress {
#     rule_no    = 100
#     protocol   = "-1"
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 1
#     to_port    = 65535
#   }

#   tags = {
#     Name = "block-high-ports-nacl"
#   }
# }

# resource "aws_network_acl_association" "subnet_0f0702af871e6a71f" {
#   subnet_id      = "subnet-0f0702af871e6a71f"
#   network_acl_id = aws_network_acl.block_high_ports.id
# }

# resource "aws_network_acl_association" "subnet_05ef77bb39c151e08" {
#   subnet_id      = "subnet-05ef77bb39c151e08"
#   network_acl_id = aws_network_acl.block_high_ports.id
# }

# resource "aws_network_acl_association" "subnet_07e9f4f746f63ed3d" {
#   subnet_id      = "subnet-07e9f4f746f63ed3d"
#   network_acl_id = aws_network_acl.block_high_ports.id
# }

# resource "aws_network_acl_association" "subnet_0482035a966810071" {
#   subnet_id      = "subnet-0482035a966810071"
#   network_acl_id = aws_network_acl.block_high_ports.id
# }

