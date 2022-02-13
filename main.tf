provider "aws" {
  region = var.region
}

resource "aws_vpc" "at-vpc" {
  cidr_block = "10.0.0.0/16"
  tags       = var.tags
}

resource "aws_subnet" "at-public-subnet" {
  vpc_id     = aws_vpc.at-vpc.id
  cidr_block = "10.0.1.0/24"
  tags = merge(
    var.tags,
    {
      Name = "Public subnet"
    }
  )
}

resource "aws_internet_gateway" "at-igw" {
  vpc_id = aws_vpc.vpc_id.id
  tags   = var.tags
}

resource "aws_route_table" "at-route-table" {
  vpc_id = aws_vpc.at-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.at-igw.id
  }
}

resource "aws_route_table_association" "at-public" {
  subnet_id      = aws_subnet.at-subnet.id
  route_table_id = aws_route_table.at-route-table.id
}

resource "aws_security_group" "at-sg" {
  description = "Security group"
  vpc_id      = aws_vpc.at-vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.access_ip
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.access_ip
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.tags
}

resource "aws_instance" "at-instance" {
  region_ami                  = "ami-098f16afa9edf40be" # us-east-1
  instance_type               = "t2.micro"
  key_name                    = var.keypair
  subnet_id                   = aws_subnet.at-public-subnet.id
  associate_public_ip_address = true
  security_groups             = [aws_security_group.at-sg.id]
  user_data                   = <<-EOF
    #!/bin/bash
    dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
    dnf -y install docker-ce firewalld ansible git
    usermod -aG docker ec2-user
    su - ec2-user
    systemctl enable docker --now
    systemctl disable firewalld
    sudo -u ec2-user pip3 install docker-compose --user

    sudo -u ec2-user git clone -b 13.0.0 https://github.com/ansible/awx.git /home/ec2-user/awx
    EOF
  tags                        = var.tags
}