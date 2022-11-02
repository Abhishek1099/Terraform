##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = var.aws_access_key  
  secret_key = var.aws_secret_key
  region     = var.aws_region
}
 
##################################################################################
# DATA
##################################################################################

data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

##################################################################################
# RESOURCES
##################################################################################

# NETWORKING #
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames  

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

}

resource "aws_subnet" "subnet1" {
  cidr_block              = var.vpc_subnet1_cidr_block
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = var.map_public_ip_on_launch 
}

# ROUTING #
resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0" 
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta-subnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rtb.id
}

# SECURITY GROUPS #
# Nginx security group 
resource "aws_security_group" "nginx-sg" {
  name   = "nginx_sg"
  vpc_id = aws_vpc.vpc.id

ingress{

    from_port = 22

    to_port = 22

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]



}



ingress{

    from_port = 8082

    to_port = 8082

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]



}

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
 
# INSTANCES #
resource "aws_instance" "nginx1" {
  ami                    = data.aws_ssm_parameter.ami.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.nginx-sg.id]
  key_name = "Key1"

  

}
