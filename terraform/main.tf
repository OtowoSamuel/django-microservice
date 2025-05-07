provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.django_microservice.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.django_microservice.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = [
      "eks",
      "get-token",
      "--cluster-name",
      data.aws_eks_cluster.django_microservice.name,
      "--region",
      var.region
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.django_microservice.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.django_microservice.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = [
        "eks",
        "get-token",
        "--cluster-name",
        data.aws_eks_cluster.django_microservice.name,
        "--region",
        var.region
      ]
    }
  }
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

# Data source to reference the existing EKS cluster IAM role
data "aws_iam_role" "eks_cluster" {
  name = "django-microservice-eks-cluster-role"
}

# Attach policies to EKS cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = data.aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = data.aws_iam_role.eks_cluster.name
}

# Data source to reference the existing EKS cluster
data "aws_eks_cluster" "django_microservice" {
  name = "django-microservice-cluster"

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller
  ]
}

# Data source to reference the existing EKS node group IAM role
data "aws_iam_role" "eks_node_group" {
  name = "django-microservice-eks-node-group-role"
}

# Attach policies to EKS node group role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = data.aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = data.aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = data.aws_iam_role.eks_node_group.name
}

# EKS node group
resource "aws_eks_node_group" "django_microservice" {
  cluster_name    = data.aws_eks_cluster.django_microservice.name
  node_group_name = "django-microservice-nodes"
  node_role_arn   = data.aws_iam_role.eks_node_group.arn
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

# IAM role for EBS CSI driver
resource "aws_iam_role" "ebs_csi_driver" {
  name = "django-microservice-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/oidc.eks.${var.region}.amazonaws.com/id/${basename(data.aws_eks_cluster.django_microservice.identity[0].oidc[0].issuer)}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "oidc.eks.${var.region}.amazonaws.com/id/${basename(data.aws_eks_cluster.django_microservice.identity[0].oidc[0].issuer)}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })
}

# Attach EBS CSI policy to the role
resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

# Install AWS EBS CSI driver via Helm
resource "helm_release" "ebs_csi_driver" {
  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  version    = "2.23.0"
  namespace  = "kube-system"

  set {
    name  = "controller.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = "ebs-csi-controller-sa"
  }

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.ebs_csi_driver.arn
  }

  set {
    name  = "enableDebugLogging"
    value = "true"
  }

  timeout = 600
  wait    = true

  depends_on = [
    aws_eks_node_group.django_microservice
  ]
}

# Define gp2 StorageClass
resource "kubernetes_storage_class" "gp2" {
  metadata {
    name = "gp2"
  }
  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"
  parameters = {
    type = "gp3"
  }

  depends_on = [
    helm_release.ebs_csi_driver
  ]
}

# Define Postgres PVC
resource "kubernetes_persistent_volume_claim" "postgres_pvc" {
  metadata {
    name      = "postgres-pvc"
    namespace = "default"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "8Gi"
      }
    }
    storage_class_name = "gp2"
  }

  depends_on = [
    kubernetes_storage_class.gp2
  ]
}

# Define Postgres Service
resource "kubernetes_service" "postgres_service" {
  metadata {
    name      = "db"
    namespace = "default"
  }
  spec {
    selector = {
      app = "postgres"
    }
    port {
      protocol    = "TCP"
      port        = 5432
      target_port = 5432
    }
    type = "ClusterIP"
  }
}

data "aws_caller_identity" "current" {}

output "ecr_repository_url" {
  value = data.aws_ecr_repository.app.repository_url
}

output "eks_cluster_endpoint" {
  value = data.aws_eks_cluster.django_microservice.endpoint
}

output "eks_cluster_name" {
  value = data.aws_eks_cluster.django_microservice.name
}