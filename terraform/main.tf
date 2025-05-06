provider "aws" {
  region = var.region
}

# Reference the existing default VPC
resource "aws_default_vpc" "default" {}

# Data source to reference the existing default subnet in us-east-1a
data "aws_subnet" "existing_default_a" {
  id = "subnet-05c1fad9d625903e9" 
}

# Create a default subnet in us-east-1b (if it doesn't exist)
resource "aws_default_subnet" "default_b" {
  availability_zone = "us-east-1b"
}

resource "aws_security_group" "db" {
  name        = "allow-postgres-redis"
  description = "Allow PostgreSQL and Redis inbound traffic"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  ingress {
    description     = "Redis from EKS nodes"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "eks_nodes" {
  name        = "eks-nodes-sg"
  description = "Allow EKS nodes access"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    protocol    = "tcp"
    from_port   = 8000
    to_port     = 8000
    cidr_blocks = ["0.0.0.0/0"] # Restrict to your CIDR range in production
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecr_repository" "app" {
  name = "django-microservice"
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}