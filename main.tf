terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
  }
}


# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

#Create EC2 instance
resource "aws_instance" "Jenkins-Server" {
  ami                    = "ami-0fff1b9a61dec8a5f"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.MyJenkinsKey.key_name
  vpc_security_group_ids = [aws_security_group.Jenkins_sg.id]

  #Supply user data script for Jenkins install and bootstrap
  user_data = file("userdata.sh")

  tags = {
    Name = "Jenkins-Instance"
  }
}

#Generate public key pair
resource "aws_key_pair" "MyJenkinsKey" {
  key_name   = "MyJenkinsKey"
  public_key = tls_private_key.generated.public_key_openssh
}

#Generate private key pair
resource "tls_private_key" "generated" {
  algorithm = "RSA"
}
resource "local_file" "private_key_pem" {
  content  = tls_private_key.generated.private_key_pem
  filename = "MyJenkinsKey.pem"
}

#Create security group
resource "aws_security_group" "Jenkins_sg" {
  name        = "Jenkins_sg"
  description = "Allow SSH and port 8080 inbound traffic"
  vpc_id      = "vpc-0eab2318bbf5b8244"

  tags = {
    Name = "Jenkins_sg"
  }

  #Security group ingress rule SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    #Enter your Cloud 9 instance public IPv4 address below
    cidr_blocks = ["0.0.0.0/0"] 
  }

  #Security group ingress rule allow 8080
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    #Enter your personal IPv4 address below
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Security group egress rule to allow all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Create S3 bucket for Jenkins artifacts
resource "aws_s3_bucket" "jenkins-bucket" {
  bucket = "my-tf-jenkins-bucket"
}

resource "aws_s3_bucket_public_access_block" "jenkins-bucket" {
  bucket = aws_s3_bucket.jenkins-bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
