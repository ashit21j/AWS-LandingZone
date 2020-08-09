provider "aws" {
  region     = "us-east-1"
  access_key = "my-access-key"
  secret_key = "my-secret-key"
}

# Create a VPC with mentioned CIDR.
resource "aws_vpc" "GatewayVPC" {
  cidr_block       = var.Gateway-vpc-cidr
  instance_tenancy = "default"

  tags = {
    Name = "Gateway VPC"
  }
}
# Creates 3 subnet each in different AZ's.
resource "aws_subnet" "PrivateSubnet1a" {
  vpc_id            = aws_vpc.GatewayVPC.id
  cidr_block        = var.Gateway-subnet1-cidr
  availability_zone = "us-east-1a"
  tags = {
    Name = "PrivateSubnet1a-Gateway"
  }
}

resource "aws_subnet" "PrivateSubnet1b" {
  vpc_id            = aws_vpc.GatewayVPC.id
  cidr_block        = var.Gateway-subnet2-cidr
  availability_zone = "us-east-1b"
  tags = {
    Name = "PrivateSubnet1b-Gateway"
  }
}

resource "aws_subnet" "PrivateSubnet1c" {
  vpc_id            = aws_vpc.GatewayVPC.id
  cidr_block        = var.Gateway-subnet3-cidr
  availability_zone = "us-east-1c"
  tags = {
    Name = "PrivateSubnet1c-Gateway"
  }
}
# Create Network ACL and attach it to VPC.
resource "aws_network_acl" "GatewayVPCNACL" {
  vpc_id = aws_vpc.GatewayVPC.id

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "GatewayVPCNACL"
  }
}
# Create AWS Transit Gateway.
resource "aws_ec2_transit_gateway" "TGW" {
  description                     = "Transit Gateway"
  amazon_side_asn                 = 64512
  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"
  tags = {
    Name = "TGW"
  }
}
