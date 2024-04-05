#Added a hot fix to the code 
#Added another chnage to the hostfix

#variable "access_key" {
#  description = "aws access key"
#  type = string
#}

#variable "secret_key" {
#  description = "aws secret key"
#  type = string
#}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0.0"
    }
  }
  backend "s3" {
    bucket = "dilan-terraform-remote-state" # change to name of your bucket
    region = "us-east-1"                   # change to your region
    key    = "terraform.tfstate"
  }
}


provider "aws" {
  region = "us-east-1"
#  profile = "Admin-Access-637423571886"
#  access_key = var.access_key
#  secret_key = var.secret_key
}

#Create VPC ------------------------------
resource "aws_vpc" "dilan_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    name = "dilan_vpc"
  }
}


#Create Subnet ---------------------------
resource "aws_subnet" "dilan_subnet" {
  vpc_id = aws_vpc.dilan_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    name = "dilan_subnet"
  }
  depends_on = [ aws_vpc.dilan_vpc ]
}


#Create Inthernet Gateway ----------------
resource "aws_internet_gateway" "dilan_internet_gateway" {
  vpc_id = aws_vpc.dilan_vpc.id
  tags = {
    name = "dilan_internet_gateway"
  }
  depends_on = [ aws_vpc.dilan_vpc ]
}


#Create Route Table ---------------------
resource "aws_route_table" "dilan_route_table" {
  vpc_id = aws_vpc.dilan_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dilan_internet_gateway.id
  }
  
  tags = {
    name = "dilan_route_table"
  }
  depends_on = [ aws_internet_gateway.dilan_internet_gateway ]
}


#Create route table associations ----------
resource "aws_route_table_association" "dilan_internet_access" {
  subnet_id = aws_subnet.dilan_subnet.id
  route_table_id = aws_route_table.dilan_route_table.id
}


#Create Instance ---------------------------
resource "aws_instance" "dilan_ec2_instance" {
  ami = "ami-0440d3b780d96b29d"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.dilan_subnet.id
  availability_zone = "us-east-1a"
  key_name = "dilan-6374-account"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.dilan_security_group_01.id]
  user_data = <<-EOF
                #!/bin/bash
                sudo dnf update -y
                sudo dnf install -y httpd
                echo "This is a TEST Apache2 Server charly20412" > /var/www/html/index.html
                sudo systemctl start httpd
                sudo systemctl enable httpd
                EOF

}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.dilan_ec2_instance.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.dilan_ec2_instance.public_ip
}

#Create Security Group ---------------------
resource "aws_security_group" "dilan_security_group_01" {
  name = "allow inbound ssh access"
  description = "allow inbound ssh access"
  vpc_id = aws_vpc.dilan_vpc.id
  ingress {
    description = "ingress ssh from public internet"
    from_port = "22"
    to_port  = "22"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "access to port 80"
    from_port = "80"
    to_port = "80"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "access to port 443"
    from_port = "443"
    to_port = "443"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "0"
    to_port = "0"
    protocol = "-1"
  }

  tags = {
    name = "dilan_security_group_ssh"
  }
}
