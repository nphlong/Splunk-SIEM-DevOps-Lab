resource "aws_vpc" "splunk_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "splunk-lab-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.splunk_vpc.id
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.splunk_vpc.id
  cidr_block              = "10.0.100.0/24"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.splunk_vpc.id
  cidr_block = "10.0.1.0/24"
}

# Route Table for Public Subnet (Bastion)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.splunk_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group for Bastion (Open to any IP per request)
resource "aws_security_group" "vpn_sg" {
  name   = "splunk-bastion-sg"
  vpc_id = aws_vpc.splunk_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Internal Security Group (Nodes talking to each other)
resource "aws_security_group" "splunk_internal" {
  name   = "splunk-internal-sg"
  vpc_id = aws_vpc.splunk_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}