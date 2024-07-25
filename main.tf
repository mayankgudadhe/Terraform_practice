##############Providers#####################
provider "aws" {
        region = "ap-south-1"
        access_key = "AKIA5VK53CUJR7MY67OG"
        secret_key = "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"
        }
################Creating_VPC ####################

resource "aws_vpc" "VPC-B" {
  cidr_block = "10.20.0.0/16"
  tags = {
    Name = "VPC-B"
  }
}

###################### Creating_IGW #########################
resource "aws_internet_gateway" "IGW-B" {
  vpc_id = aws_vpc.VPC-B.id
  tags = {
    Name = "IGW-B"
  }
}

######################## Creating_Public_subnet ####################
resource "aws_subnet" "Subnet_B_Pub" {
  vpc_id            = aws_vpc.VPC-A.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "Public_Subnet_B"
  }
}

##################### Creating_Privat_Subnet #################
resource "aws_subnet" "Subnet_B_Pri" {
  vpc_id            = aws_vpc.VPC-B.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "Private_Subnet_B"
  }
}

##################### Creating_PUBLIC_ROUTE_TABLE ##################
resource "aws_route_table" "Public_RT" {
  vpc_id = aws_vpc.VPC-B.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW-B.id
  }
  tags = {
    Name = "Public-RT-B"
  }
}

########################## Route_table_association ####################
resource "aws_route_table_association" "Public-Subnet" {
  route_table_id = aws_route_table.Public_RT.id
  subnet_id      = aws_subnet.Subnet_B_Pub.id
}

########################## Security_Group ############################
resource "aws_security_group" "VPC-sec" {
  vpc_id = aws_vpc.VPC-B.id
  tags = {
    Name = "VPC-B_Security_grp"
  }
  
  ingress {
    description = "SSH_ALL"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP_ALL"
    from_port   = 80
    to_port     = 80
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

############ Machine_launch #######################3
resource "aws_instance" "machine" {
  ami             = "ami-0d1e92463a5acf79d"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.Subnet_B_Pub.id
  key_name        = "use"
  vpc_security_group_ids = [aws_security_group.VPC-sec.id]

  user_data = <<-EOF
    #!/bin/bash
    sudo yum install httpd -y
    sudo service httpd start
    echo "<h1> Hello This instance is created by Terraform</h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "Instance-A"
  }
}

################## Elastic_IP ###################
resource "aws_eip" "my_eip" {
  instance = aws_instance.machine.id
}
