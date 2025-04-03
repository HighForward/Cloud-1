locals {
  private_key_path = "./ec2-rsa-pem.pem"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
  #  access_key = ""
  #  secret_key = "
}

# Create a VPC
resource "aws_vpc" "cloud1" {
  cidr_block = "10.0.0.0/24"
}

resource "aws_subnet" "cloud1_subnet_public" {
  vpc_id                  = aws_vpc.cloud1.id
  cidr_block              = "10.0.0.0/25"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-3a"
  tags = {
    Name = "cloud1-public-subnet"
  }
}

resource "aws_internet_gateway" "cloud1_internet_gateway" {
  vpc_id = aws_vpc.cloud1.id
  tags = {
    Name = "cloud1-internet-gateway"
  }
}

resource "aws_route_table" "cloud1_route_table" {
  vpc_id = aws_vpc.cloud1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloud1_internet_gateway.id
  }
}

resource "aws_route_table_association" "subnet_route" {
  subnet_id      = aws_subnet.cloud1_subnet_public.id
  route_table_id = aws_route_table.cloud1_route_table.id
}

resource "aws_security_group" "cloud1_security_group" {
  name   = "ecs-security-group"
  vpc_id = aws_vpc.cloud1.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_instance" "cloud1_instance" {
  ami           = "ami-0160e8d70ebc43ee1"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.cloud1_subnet_public.id
  associate_public_ip_address = true
  security_groups = [aws_security_group.cloud1_security_group.id]
  key_name = "ec2-rsa-pem"

  provisioner "remote-exec" {
    inline = ["echo 'Wait until ssh is ready'"]

    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file(local.private_key_path)
      host = aws_instance.cloud1_instance.public_ip
    }
  }

#  provisioner "local-exec" {
#    command = "ansible-playbook -i ${aws_instance.cloud1_instance.public_ip}, --private-key ${local.private_key_path} cloud1.yml"
#  }
}

resource "null_resource" "ansible_playbook" {
  depends_on = [aws_instance.cloud1_instance]

  provisioner "local-exec" {
    command = "ansible-playbook -i ${aws_instance.cloud1_instance.public_ip}, --private-key ${local.private_key_path} --extra-vars 'cloud1_ec2_ip=${aws_instance.cloud1_instance.public_ip}' cloud1.yml"
  }
}


output "cloud1_ip" {
  value = aws_instance.cloud1_instance.public_ip
}