provider "aws" {
  region     = "us-east-1"
  access_key = "my-access-key"
  secret_key = "my-secret-key"
}

# Create a VPC with mentioned CIDR.
resource "aws_vpc" "Egress-VPC" {
  cidr_block           = var.Egress-vpc-cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "Egress VPC"
  }
}

# Create Internet Gateway

resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.Egress-VPC.id

  tags = {
    Name = "Internet-Gateway-Egress"
  }
}

# Creates 3 Private subnets each in different AZ's.
resource "aws_subnet" "PrivateSubnet1a" {
  vpc_id            = aws_vpc.Egress-VPC.id
  cidr_block        = var.Egress-Private-subnet1a-cidr
  availability_zone = "us-east-1a"
  tags = {
    Name = "PrivateSubnet1a-Egress"
  }
}

resource "aws_subnet" "PrivateSubnet1b" {
  vpc_id            = aws_vpc.Egress-VPC.id
  cidr_block        = var.Egress-Private-subnet1b-cidr
  availability_zone = "us-east-1b"
  tags = {
    Name = "PrivateSubnet1b-Egress"
  }
}

resource "aws_subnet" "PrivateSubnet1c" {
  vpc_id            = aws_vpc.Egress-VPC.id
  cidr_block        = var.Egress-Private-subnet1c-cidr
  availability_zone = "us-east-1c"
  tags = {
    Name = "PrivateSubnet1c-Egress"
  }
}

# Creates 3 Public subnets each in different AZ's.
resource "aws_subnet" "PublicSubnet1a" {
  vpc_id                  = aws_vpc.Egress-VPC.id
  cidr_block              = var.Egress-Public-subnet1a-cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  depends_on              = [aws_internet_gateway.IGW]
  tags = {
    Name = "PublicSubnet1a-Egress"
  }
}

resource "aws_subnet" "PublicSubnet1b" {
  vpc_id                  = aws_vpc.Egress-VPC.id
  cidr_block              = var.Egress-Public-subnet1b-cidr
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  depends_on              = [aws_internet_gateway.IGW]
  tags = {
    Name = "PublicSubnet1b-Egress"
  }
}

resource "aws_subnet" "PublicSubnet1c" {
  vpc_id                  = aws_vpc.Egress-VPC.id
  cidr_block              = var.Egress-Public-subnet1c-cidr
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true
  depends_on              = [aws_internet_gateway.IGW]
  tags = {
    Name = "PublicSubnet1c-Egress"
  }
}

# Creates Public subnet for NAT GW
resource "aws_subnet" "EgressSubnet" {
  vpc_id                  = aws_vpc.Egress-VPC.id
  cidr_block              = var.EgressSubnet-cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  depends_on              = [aws_internet_gateway.IGW]
  tags = {
    Name = "Subnet-Egress"
  }
}

# Create Network ACL and attach it to VPC.
resource "aws_network_acl" "EgressVPCNACL" {
  vpc_id = aws_vpc.Egress-VPC.id

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
    Name = "EgressVPCNACL"
  }
}

# Create NAT Gateway
resource "aws_eip" "NAT-EIP" {
  vpc = true
}
resource "aws_nat_gateway" "NAT-GW" {
  allocation_id = aws_eip.NAT-EIP.id
  subnet_id     = aws_subnet.EgressSubnet.id
  depends_on    = [aws_internet_gateway.IGW]
}

# Create Route Table for 3 Private Subnets
resource "aws_route_table" "Private-RT" {
  vpc_id = aws_vpc.Egress-VPC.id
  route {
    cidr_block         = "10.0.0.0/8"
    transit_gateway_id = "tgw-070f4a81473636c51"
  }

  tags = {
    Name = "Private-Route Table"
  }
}

# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "PrivateSubnet1a-RT-association" {
  subnet_id      = aws_subnet.PrivateSubnet1a.id
  route_table_id = aws_route_table.Private-RT.id
}
resource "aws_route_table_association" "PrivateSubnet1b-RT-association" {
  subnet_id      = aws_subnet.PrivateSubnet1b.id
  route_table_id = aws_route_table.Private-RT.id
}
resource "aws_route_table_association" "PrivateSubnet1c-RT-association" {
  subnet_id      = aws_subnet.PrivateSubnet1c.id
  route_table_id = aws_route_table.Private-RT.id
}

# Create Route Table for 3 Public Subnets
resource "aws_route_table" "Public-RT" {
  vpc_id = aws_vpc.Egress-VPC.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT-GW.id
  }

  tags = {
    Name = "Public-Route Table"
  }
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "PublicSubnet1a-RT-association" {
  subnet_id      = aws_subnet.PublicSubnet1a.id
  route_table_id = aws_route_table.Public-RT.id
}
resource "aws_route_table_association" "PublicSubnet1b-RT-association" {
  subnet_id      = aws_subnet.PublicSubnet1b.id
  route_table_id = aws_route_table.Public-RT.id
}
resource "aws_route_table_association" "PublicSubnet1c-RT-association" {
  subnet_id      = aws_subnet.PublicSubnet1c.id
  route_table_id = aws_route_table.Public-RT.id
}

# Create Route Table for NAT subnet
resource "aws_route_table" "NATGW-RT" {
  vpc_id = aws_vpc.Egress-VPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }

  tags = {
    Name = "NAT-GW-Route Table"
  }
}

# Associate NAT Subnets with NAT Route Table
resource "aws_route_table_association" "NAT-RT-association" {
  subnet_id      = aws_subnet.EgressSubnet.id
  route_table_id = aws_route_table.NATGW-RT.id
}

# Create an Security Group.
resource "aws_security_group" "sg_22" {
  name   = "sg_22"
  vpc_id = aws_vpc.Egress-VPC.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Environment = "Egress-SG-22"
  }
}
resource "aws_security_group" "sg_3128" {
  name   = "sg_3128"
  vpc_id = aws_vpc.Egress-VPC.id
  ingress {
    from_port   = 3128
    to_port     = 3128
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Environment = "Egress-SG-3128"
  }
}
resource "aws_security_group" "sg_80" {
  name   = "sg_80"
  vpc_id = aws_vpc.Egress-VPC.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Environment = "Egress-SG-80"
  }
}

# Create a key pair
resource "tls_private_key" "EgressKP" {
  algorithm = "RSA"
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = "EgressKP"
  public_key = tls_private_key.EgressKP.public_key_openssh
}

# Create EC2 instance
resource "aws_instance" "Proxy-Firewall-1a" {
  ami                    = "ami-02354e95b39ca8dec"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1a"
  subnet_id              = aws_subnet.PrivateSubnet1a.id
  vpc_security_group_ids = [aws_security_group.sg_80.id, aws_security_group.sg_3128.id, aws_security_group.sg_22.id]
  user_data              = file("install_apache.sh")
  key_name               = "EgressKP"
  tags = {
    Name        = "Proxy-Firewall-1a-Egress"
    Environment = "Production"
  }
  volume_tags = {
    Name        = "Proxy-Firewall-1a-Egress"
    Environment = "Production"
  }
}

resource "aws_instance" "Proxy-Firewall-1b" {
  ami                    = "ami-02354e95b39ca8dec"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1b"
  subnet_id              = aws_subnet.PrivateSubnet1b.id
  vpc_security_group_ids = [aws_security_group.sg_80.id, aws_security_group.sg_22.id, aws_security_group.sg_3128.id]
  key_name               = "EgressKP"
  tags = {
    Name        = "Proxy-Firewall-1b-Egress"
    Environment = "Production"
  }
  volume_tags = {
    Name        = "Proxy-Firewall-1b-Egress"
    Environment = "Production"
  }
}

resource "aws_instance" "Proxy-Firewall-1c" {
  ami                    = "ami-02354e95b39ca8dec"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1c"
  subnet_id              = aws_subnet.PrivateSubnet1c.id
  vpc_security_group_ids = [aws_security_group.sg_80.id, aws_security_group.sg_22.id, aws_security_group.sg_3128.id]
  key_name               = "EgressKP"
  tags = {
    Name        = "Proxy-Firewall-1c-Egress"
    Environment = "Production"
  }
  volume_tags = {
    Name        = "Proxy-Firewall-1c-Egress"
    Environment = "Production"
  }
}

# Create 3 Public ENI's
resource "aws_network_interface" "Proxy-Firewall-1a-ENI" {
  subnet_id = aws_subnet.PublicSubnet1a.id

  attachment {
    instance     = aws_instance.Proxy-Firewall-1a.id
    device_index = 1
  }
}
resource "aws_network_interface" "Proxy-Firewall-1b-ENI" {
  subnet_id = aws_subnet.PublicSubnet1b.id

  attachment {
    instance     = aws_instance.Proxy-Firewall-1b.id
    device_index = 1
  }
}
resource "aws_network_interface" "Proxy-Firewall-1c-ENI" {
  subnet_id = aws_subnet.PublicSubnet1c.id

  attachment {
    instance     = aws_instance.Proxy-Firewall-1c.id
    device_index = 1
  }
}

# Create Egress NLB

resource "aws_lb" "EgressNLB" {
  name               = "EgressNLB"
  internal           = true
  load_balancer_type = "network"
  subnets            = [aws_subnet.PrivateSubnet1a.id, aws_subnet.PrivateSubnet1b.id, aws_subnet.PrivateSubnet1c.id]

  tags = {
    Environment = "Production"
  }
}

resource "aws_lb_target_group" "EgressNLB-TG" {
  name        = "EgressNLB-TargetGroup"
  port        = 3128
  protocol    = "TCP"
  vpc_id      = aws_vpc.Egress-VPC.id
  target_type = "instance"
}

resource "aws_lb_listener" "Egress-Forward-Listener" {
  load_balancer_arn = aws_lb.EgressNLB.arn
  port              = 3128
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.EgressNLB-TG.arn
  }
}

resource "aws_lb_target_group_attachment" "EgressNLB-Target1a" {
  target_group_arn = aws_lb_target_group.EgressNLB-TG.arn
  target_id        = aws_instance.Proxy-Firewall-1a.id
  port             = 3128
}

resource "aws_lb_target_group_attachment" "EgressNLB-Target1b" {
  target_group_arn = aws_lb_target_group.EgressNLB-TG.arn
  target_id        = aws_instance.Proxy-Firewall-1b.id
  port             = 3128
}

resource "aws_lb_target_group_attachment" "EgressNLB-Target1c" {
  target_group_arn = aws_lb_target_group.EgressNLB-TG.arn
  target_id        = aws_instance.Proxy-Firewall-1c.id
  port             = 3128
}

# Create Transit Gateway Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "EgressTGWattachment" {
  subnet_ids         = [aws_subnet.PrivateSubnet1a.id, aws_subnet.PrivateSubnet1b.id, aws_subnet.PrivateSubnet1c.id]
  transit_gateway_id = "tgw-070f4a81473636c51"
  vpc_id             = aws_vpc.Egress-VPC.id
  dns_support        = "enable"
  tags = {
    Name        = "TGW-EgressAttachment"
    Environment = "Production"
  }

}
