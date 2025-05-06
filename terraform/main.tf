provider "aws" {
  region = var.region
}

# Reference the existing default VPC
resource "aws_default_vpc" "default" {}

# Data source to reference the existing default subnet in us-east-1a
data "aws_subnet" "existing_default_a" {
  id = "subnet-05c1fad9d625903e9" # Existing subnet ID
}

# Create a default subnet in us-east-1b (if it doesn't exist)
resource "aws_default_subnet" "default_b" {
  availability_zone = "us-east-1b"
}

# Data source to reference the existing eks-nodes-sg security group
data "aws_security_group" "eks_nodes" {
  filter {
    name   = "group-name"
    values = ["eks-nodes-sg"]
  }
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}

# Data source to reference the existing allow-postgres-redis security group
data "aws_security_group" "db" {
  filter {
    name   = "group-name"
    values = ["allow-postgres-redis"]
  }
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}

# Data source to reference the existing django-microservice ECR repository
data "aws_ecr_repository" "app" {
  name = "django-microservice"
}

output "ecr_repository_url" {
  value = data.aws_ecr_repository.app.repository_url
}