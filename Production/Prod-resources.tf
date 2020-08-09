provider "aws" {
  region     = "us-east-1"
  access_key = "AKIA6N7UCHR4EO4YTLUK"
  secret_key = "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"
}

# Create a VPC with mentioned CIDR.
resource "aws_vpc" "Production-VPC" {
  cidr_block       = var.Prod-vpc-cidr
  instance_tenancy = "default"

  tags = {
    Name = "Production VPC"
  }
}
# Creates 3 subnet each in different AZ's.
resource "aws_subnet" "PrivateSubnet1a" {
  vpc_id            = aws_vpc.Production-VPC.id
  cidr_block        = var.Prod-subnet1a-cidr
  availability_zone = "us-east-1a"
  tags = {
    Name = "PrivateSubnet1a-Production"
  }
}

resource "aws_subnet" "PrivateSubnet1b" {
  vpc_id            = aws_vpc.Production-VPC.id
  cidr_block        = var.Prod-subnet1b-cidr
  availability_zone = "us-east-1b"
  tags = {
    Name = "PrivateSubnet1b-Production"
  }
}

resource "aws_subnet" "PrivateSubnet1c" {
  vpc_id            = aws_vpc.Production-VPC.id
  cidr_block        = var.Prod-subnet1c-cidr
  availability_zone = "us-east-1c"
  tags = {
    Name = "PrivateSubnet1c-Production"
  }
}
# Create Network ACL and attach it to VPC.
resource "aws_network_acl" "ProductionVPCNACL" {
  vpc_id = aws_vpc.Production-VPC.id

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
    Name = "ProductionVPCNACL"
  }
}

# Create an Security Group.

resource "aws_security_group" "sg_22" {
  name   = "sg_22"
  vpc_id = aws_vpc.Production-VPC.id
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
    Environment = "Prod-SG-22"
  }
}
resource "aws_security_group" "sg_80" {
  name   = "sg_80"
  vpc_id = aws_vpc.Production-VPC.id
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
    Environment = "Prod-SG-80"
  }
}

# Create a key pair
resource "tls_private_key" "ProdKP" {
  algorithm = "RSA"
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = "ProdKP"
  public_key = tls_private_key.ProdKP.public_key_openssh
}

# Create EC2 instance

resource "aws_instance" "webinstance1a" {
  ami                    = "ami-02354e95b39ca8dec"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1a"
  subnet_id              = aws_subnet.PrivateSubnet1a.id
  vpc_security_group_ids = [aws_security_group.sg_80.id, aws_security_group.sg_22.id]
  key_name               = "ProdKP"
  user_data              = file("install_apache_prod.sh")
  tags = {
    Name        = "WebInstance1a-Prod"
    Environment = "Production"
  }
  volume_tags = {
    Name        = "WebInstance1a-Prod"
    Environment = "Production"
  }
}

resource "aws_instance" "webinstance1b" {
  ami                    = "ami-02354e95b39ca8dec"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1b"
  subnet_id              = aws_subnet.PrivateSubnet1b.id
  vpc_security_group_ids = [aws_security_group.sg_80.id, aws_security_group.sg_22.id]
  key_name               = "ProdKP"
  user_data              = file("install_apache_prod.sh")
  tags = {
    Name        = "WebInstance1b-Prod"
    Environment = "Production"
  }
  volume_tags = {
    Name        = "WebInstance1b-Prod"
    Environment = "Production"
  }
}

resource "aws_instance" "webinstance1c" {
  ami                    = "ami-02354e95b39ca8dec"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1c"
  subnet_id              = aws_subnet.PrivateSubnet1c.id
  vpc_security_group_ids = [aws_security_group.sg_80.id, aws_security_group.sg_22.id]
  key_name               = "ProdKP"
  user_data              = file("install_apache_prod.sh")
  tags = {
    Name        = "WebInstance1c-Prod"
    Environment = "Production"
  }
  volume_tags = {
    Name        = "WebInstance1c-Prod"
    Environment = "Production"
  }
}

# Create Transit Gateway Attachment

resource "aws_ec2_transit_gateway_vpc_attachment" "ProdTGWattachment" {
  subnet_ids         = [aws_subnet.PrivateSubnet1a.id, aws_subnet.PrivateSubnet1b.id, aws_subnet.PrivateSubnet1c.id]
  transit_gateway_id = "tgw-070f4a81473636c51"
  vpc_id             = aws_vpc.Production-VPC.id
  dns_support        = "enable"
  tags = {
    Name        = "TGW-ProdAttachment"
    Environment = "Production"
  }

}
