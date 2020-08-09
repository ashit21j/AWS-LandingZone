provider "aws" {
  region     = "us-east-1"
  access_key = "my-access-key"
  secret_key = "my-secret-key"
}

# Create a VPC with mentioned CIDR.
resource "aws_vpc" "Non-Production-VPC" {
  cidr_block       = var.Non-Prod-vpc-cidr
  instance_tenancy = "default"

  tags = {
    Name = "Non-Production VPC"
  }
}
# Creates 3 subnet each in different AZ's.
resource "aws_subnet" "PrivateSubnet1a_np" {
  vpc_id            = aws_vpc.Non-Production-VPC.id
  cidr_block        = var.Non-Prod-subnet1a-cidr
  availability_zone = "us-east-1a"
  tags = {
    Name = "PrivateSubnet1a-Non-Production"
  }
}

resource "aws_subnet" "PrivateSubnet1b_np" {
  vpc_id            = aws_vpc.Non-Production-VPC.id
  cidr_block        = var.Non-Prod-subnet1b-cidr
  availability_zone = "us-east-1b"
  tags = {
    Name = "PrivateSubnet1b-Non-Production"
  }
}

resource "aws_subnet" "PrivateSubnet1c_np" {
  vpc_id            = aws_vpc.Non-Production-VPC.id
  cidr_block        = var.Non-Prod-subnet1c-cidr
  availability_zone = "us-east-1c"
  tags = {
    Name = "PrivateSubnet1c-Non-Production"
  }
}
# Create Network ACL and attach it to VPC.
resource "aws_network_acl" "Non-ProductionVPCNACL" {
  vpc_id = aws_vpc.Non-Production-VPC.id

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
    Name = "Non-ProductionVPCNACL"
  }
}

# Create an Security Group.

resource "aws_security_group" "sg_22_np" {
  name   = "sg_22_np"
  vpc_id = aws_vpc.Non-Production-VPC.id
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
    Environment = "Non-Prod-SG-22"
  }
}
resource "aws_security_group" "sg_80_np" {
  name   = "sg_80_np"
  vpc_id = aws_vpc.Non-Production-VPC.id
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
    Environment = "Non-Prod-SG-80"
  }
}

# Create a key pair
resource "tls_private_key" "Non-ProdKP" {
  algorithm = "RSA"
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = "Non-ProdKP"
  public_key = tls_private_key.Non-ProdKP.public_key_openssh
}

# Create EC2 instance

resource "aws_instance" "webinstance1a-NP" {
  ami                    = "ami-02354e95b39ca8dec"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1a"
  subnet_id              = aws_subnet.PrivateSubnet1a_np.id
  vpc_security_group_ids = [aws_security_group.sg_80_np.id, aws_security_group.sg_22_np.id]
  key_name               = "Non-ProdKP"
  user_data              = file("install_apache.sh")
  tags = {
    Name        = "WebInstance1a-Non-Prod"
    Environment = "Non-Production"
  }
  volume_tags = {
    Name        = "WebInstance1a-Non-Prod"
    Environment = "Non-Production"
  }
}

resource "aws_instance" "webinstance1b-NP" {
  ami                    = "ami-02354e95b39ca8dec"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1b"
  subnet_id              = aws_subnet.PrivateSubnet1b_np.id
  vpc_security_group_ids = [aws_security_group.sg_80_np.id, aws_security_group.sg_22_np.id]
  key_name               = "Non-ProdKP"
  user_data              = file("install_apache.sh")
  tags = {
    Name        = "WebInstance1b-Non-Prod"
    Environment = "Non-Production"
  }
  volume_tags = {
    Name        = "WebInstance1b-Non-Prod"
    Environment = "Non-Production"
  }
}

resource "aws_instance" "webinstance1c-NP" {
  ami                    = "ami-02354e95b39ca8dec"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1c"
  subnet_id              = aws_subnet.PrivateSubnet1c_np.id
  vpc_security_group_ids = [aws_security_group.sg_80_np.id, aws_security_group.sg_22_np.id]
  key_name               = "Non-ProdKP"
  user_data              = file("install_apache.sh")
  tags = {
    Name        = "WebInstance1c-Non-Prod"
    Environment = "Non-Production"
  }
  volume_tags = {
    Name        = "WebInstance1c-Non-Prod"
    Environment = "Non-Production"
  }
}

# Create Transit Gateway Attachment

resource "aws_ec2_transit_gateway_vpc_attachment" "Non-ProdTGWattachment" {
  subnet_ids         = [aws_subnet.PrivateSubnet1a_np.id, aws_subnet.PrivateSubnet1b_np.id, aws_subnet.PrivateSubnet1c_np.id]
  transit_gateway_id = "tgw-070f4a81473636c51"
  vpc_id             = aws_vpc.Non-Production-VPC.id
  dns_support        = "enable"
  tags = {
    Name        = "TGW-Non-ProdAttachment"
    Environment = "Non-Production"
  }

}
