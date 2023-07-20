provider "aws"{
  region = "us-east-1"
  access_key = ""
  secret_key = ""
}

variable "vpc_cidr_block" {}
variable "subnet_1_cidr_block" {}
variable avail_zone {}
variable "env_prefix" {}
variable my_ip {}
variable instance_type {}
variable ssh_key {}

data "aws_ami" "amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

output "ami_id" {
  value = data.aws_ami.amazon-linux-image.id
}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_1_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}

resource "aws_security_group" "myapp-sg" {
  name = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.env_prefix}-security-group"
  }
}

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id

  tags = {
    Name = "${var.env_prefix}-internet-gateway"
  }
}

resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }

  #defasult route, map the VPC CIDR block to local

  tags = {
    Name = "${var.env_prefix}-route-table"
  }
}

resource "aws_route_table" "myapp-route-table-2" {
  vpc_id = aws_vpc.myapp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }

  #default route map the VPC CIDR block

  tags = {
    Name = "${var.env_prefix}-route-table"
  }
}

# Associate subnet with Route Table
resource "aws_route_table_association" "a-rtb-subnet" {
  route_table_id = aws_route_table.myapp-route-table.id
  subnet_id = aws_subnet.myapp-subnet-1.id
}

resource "aws_security_group" "myapp-sg-2" {
  name = "myapp-sg-2"
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.env_prefix}-sg"
  }
}

resource "aws_key_pair" "deployer" {
  key_name = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDx+4grN95gkqw8dzPTNdLC3uA9LNd/hvwVqw+4DYxezleLcnIB1UZ4cKhZ3bdaqHEW2FGrIjcD+dNuuxRahS6AN7IWsbpPuNMQPammIwetjiWDQz6Y0Sbrf4sGVOKSkQOwHrqbBZ8gZRVjjnlgZk0Zrl5sVEd13mKX1eRlVnky0DC8yrgaAW3kCXYXlcyODuG0i/IWsWi6DZMXRuVhtUGJmFF2+6DURSnq+eg8b1xFkIV83DAwAlX18aj4en1u/1iFFLpmOUb9N0Mot3NwmsTF/QfK9aAeYnriq+BADh9iboIph9NGVtywKsVnrRdH5v/Z6My5Bn1dgeZk9jxF8izD muadh@DESKTOP-IVP3NL8"
}

output "server-ip" {
  value = aws_instance.myapp-server.public_ip
}

resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.amazon-linux-image.id
  instance_type = var.instance_type
  key_name = "docker-server"
  associate_public_ip_address = true
  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone = var.avail_zone

  tags = {
    Name = "${var.env_prefix}-sever"
  }

  user_data = <<E0F
                  #!/bin/bash
                  apt-get update && apt-get install -y docker-ce
                  systemctl start docker
                  usermod -aG docker ec2-user
                  docker run -p 8080:8080 nginx
              E0F
}

resource "aws_instance" "myapp-server-two" {
  ami = data.aws_ami.amazon-linux-image.id
  instance_type = var.instance_type
  key_name = "docker-server"
  associate_public_ip_address = true
  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone = var.avail_zone

  tags = {
    Name = "${var.env_prefix}-sever-two"
  }

  user_data = <<E0F
                  #!/bin/bash
                  apt-get update && apt-get install -y docker-ce
                  systemctl start docker
                  usermod -aG docker ec2-user
                  docker run -p 8080:8080 nginx
              E0F
}

resource "aws_instance" "myapp-server-three" {
  ami = data.aws_ami.amazon-linux-image.id
  instance_type = var.instance_type
  key_name = "docker-server"
  associate_public_ip_address = true
  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone = var.avail_zone

  tags = {
    Name = "${var.env_prefix}-sever-three"
  }

  user_data = <<E0F
                  #!/bin/bash
                  apt-get update && apt-get install -y docker-ce
                  systemctl start docker
                  usermod -aG docker ec2-user
                  docker run -p 8080:8080 nginx
              E0F
}