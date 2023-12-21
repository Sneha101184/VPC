# Define VPC
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
}
# Create a subnet for above VPC
resource "aws_subnet" "main_subnet" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "eu-west-2a"
}
# Create a Securuty Group
resource "aws_security_group" "main_sg" {
  vpc_id = aws_vpc.main.id
  name = "main-sg"
  description = "allow SSH and HTTP traffic"

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
   egress {
    from_port        = 80
    to_port          = 80
     protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}
  # Launch an EC2 Instance
  resource "aws_instance" "main_Instance" {
  subnet_id = aws_subnet.main_subnet.id 
  ami           = "ami-0b1b00f4f0d09d131" 
  instance_type = "t2.micro"
  key_name = "terraformkeypair"
 
          
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<html><h1>Hello from Terraform EC2</h1></html>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "main_Instance"
  }
}
# create and associate IGW to VPC
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.main.id
}
# update route table
resource "aws_route" "internet_access" {
    route_table_id = aws_vpc.main.main_route_table_id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
}
# Define an EIP
resource "aws_eip" "lb" {
    instance = aws_instance.main_Instance.id
}
# Asscociate EIP with EC2 instance named main_instance
resource "aws_eip_association" "associate_lb" {
    instance_id = aws_instance.main_Instance.id
    allocation_id = aws_eip.lb.id
}
