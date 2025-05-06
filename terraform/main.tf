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

# IAM role for EKS cluster
resource "aws_iam_role" "eks_cluster" {
  name = "django-microservice-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policies to EKS cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

# EKS cluster
resource "aws_eks_cluster" "django_microservice" {
  name     = "django-microservice-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = [
      data.aws_subnet.existing_default_a.id,
      aws_default_subnet.default_b.id
    ]
    security_group_ids = [data.aws_security_group.eks_nodes.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller
  ]
}

# IAM role for EKS node group
resource "aws_iam_role" "eks_node_group" {
  name = "django-microservice-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policies to EKS node group role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group.name
}

# EKS node group
resource "aws_eks_node_group" "django_microservice" {
  cluster_name    = aws_eks_cluster.django_microservice.name
  node_group_name = "django-microservice-nodes"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = [
    data.aws_subnet.existing_default_a.id,
    aws_default_subnet.default_b.id
  ]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_container_registry_read_only
  ]
}

output "ecr_repository_url" {
  value = data.aws_ecr_repository.app.repository_url
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.django_microservice.endpoint
}

output "eks_cluster_name" {
  value = aws_eks_cluster.django_microservice.name
}