# AWS Elastic Kubernetes Service (EKS) with Private Networking and Elastic Container Registry (ECR)
# This configuration creates a private EKS cluster with ECR integration

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

# Random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Data source to get current AWS caller identity
data "aws_caller_identity" "current" {}

# Data source to get available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC for EKS cluster
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name                                        = "${var.resource_prefix}-vpc-${random_string.suffix.result}"
    "kubernetes.io/cluster/${var.resource_prefix}-eks-${random_string.suffix.result}" = "shared"
  })
}

# Internet Gateway for public subnets
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-igw-${random_string.suffix.result}"
  })
}

# Public subnets for NAT Gateways and ALB
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name                                        = "${var.resource_prefix}-public-${count.index + 1}-${random_string.suffix.result}"
    "kubernetes.io/cluster/${var.resource_prefix}-eks-${random_string.suffix.result}" = "shared"
    "kubernetes.io/role/elb"                   = "1"
  })
}

# Private subnets for EKS nodes
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name                                        = "${var.resource_prefix}-private-${count.index + 1}-${random_string.suffix.result}"
    "kubernetes.io/cluster/${var.resource_prefix}-eks-${random_string.suffix.result}" = "owned"
    "kubernetes.io/role/internal-elb"          = "1"
  })
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = length(aws_subnet.public)

  domain = "vpc"
  
  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-nat-eip-${count.index + 1}-${random_string.suffix.result}"
  })

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways for outbound internet access from private subnets
resource "aws_nat_gateway" "main" {
  count = length(aws_subnet.public)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-nat-${count.index + 1}-${random_string.suffix.result}"
  })

  depends_on = [aws_internet_gateway.main]
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-public-rt-${random_string.suffix.result}"
  })
}

# Route table associations for public subnets
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route tables for private subnets
resource "aws_route_table" "private" {
  count = length(aws_subnet.private)

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-private-rt-${count.index + 1}-${random_string.suffix.result}"
  })
}

# Route table associations for private subnets
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# VPC Endpoints for private EKS cluster
# EKS VPC Endpoint
resource "aws_vpc_endpoint" "eks" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.eks"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-eks-endpoint-${random_string.suffix.result}"
  })
}

# ECR API VPC Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-ecr-api-endpoint-${random_string.suffix.result}"
  })
}

# ECR Docker VPC Endpoint
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-ecr-dkr-endpoint-${random_string.suffix.result}"
  })
}

# S3 VPC Endpoint (Gateway type for ECR image layers)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-s3-endpoint-${random_string.suffix.result}"
  })
}

# CloudWatch VPC Endpoint
resource "aws_vpc_endpoint" "cloudwatch" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.monitoring"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-cloudwatch-endpoint-${random_string.suffix.result}"
  })
}

# CloudWatch Logs VPC Endpoint
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-logs-endpoint-${random_string.suffix.result}"
  })
}

# STS VPC Endpoint (for IAM role assumption)
resource "aws_vpc_endpoint" "sts" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-sts-endpoint-${random_string.suffix.result}"
  })
}

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.resource_prefix}-vpc-endpoints-${random_string.suffix.result}"
  vpc_id      = aws_vpc.main.id
  description = "Security group for VPC endpoints"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "HTTPS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-vpc-endpoints-sg-${random_string.suffix.result}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security group for EKS cluster
resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.resource_prefix}-eks-cluster-${random_string.suffix.result}"
  vpc_id      = aws_vpc.main.id
  description = "Security group for EKS cluster control plane"

  # Allow HTTPS inbound from VPC
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "HTTPS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-eks-cluster-sg-${random_string.suffix.result}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security group for EKS nodes
resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.resource_prefix}-eks-nodes-${random_string.suffix.result}"
  vpc_id      = aws_vpc.main.id
  description = "Security group for EKS worker nodes"

  # Allow nodes to communicate with each other
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
    description = "Node to node communication"
  }

  # Allow pods to communicate with cluster API Server
  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
    description     = "Allow pods to communicate with cluster API Server"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-eks-nodes-sg-${random_string.suffix.result}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Allow cluster to communicate with nodes
resource "aws_security_group_rule" "cluster_to_node" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
  description              = "Allow cluster API Server to communicate with nodes"
}

# CloudWatch Log Group for EKS cluster logs
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.resource_prefix}-eks-${random_string.suffix.result}/cluster"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-eks-logs-${random_string.suffix.result}"
  })
}

# IAM role for EKS cluster
resource "aws_iam_role" "eks_cluster" {
  name = "${var.resource_prefix}-eks-cluster-role-${random_string.suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach required policies to EKS cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# IAM role for EKS node group
resource "aws_iam_role" "eks_node_group" {
  name = "${var.resource_prefix}-eks-node-group-role-${random_string.suffix.result}"

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

  tags = var.tags
}

# Attach required policies to EKS node group role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group.name
}

# Additional policy for CloudWatch agent and VPC endpoints
resource "aws_iam_role_policy" "eks_node_additional" {
  name = "${var.resource_prefix}-eks-node-additional-${random_string.suffix.result}"
  role = aws_iam_role.eks_node_group.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "${var.resource_prefix}-eks-${random_string.suffix.result}"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    security_group_ids      = [aws_security_group.eks_cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = false  # Private cluster - no public access
  }

  # Enable logging
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Ensure proper IAM permissions are created first
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_cloudwatch_log_group.eks_cluster,
    aws_vpc_endpoint.eks,
    aws_vpc_endpoint.ecr_api,
    aws_vpc_endpoint.ecr_dkr,
    aws_vpc_endpoint.s3
  ]

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-eks-${random_string.suffix.result}"
  })
}

# EKS Node Group - System
resource "aws_eks_node_group" "system" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "system"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = [var.node_instance_type]
  ami_type        = "AL2_x86_64"
  capacity_type   = "ON_DEMAND"
  disk_size       = var.node_disk_size

  # Auto-scaling configuration
  scaling_config {
    desired_size = var.min_node_count
    max_size     = var.max_node_count
    min_size     = var.min_node_count
  }

  # Update configuration
  update_config {
    max_unavailable_percentage = 25
  }

  # Taints for system workloads only
  taint {
    key    = "CriticalAddonsOnly"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  # Labels
  labels = {
    "node-type" = "system"
    "workload"  = "system"
  }

  # Ensure proper IAM permissions are created first
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
    aws_iam_role_policy.eks_node_additional
  ]

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-system-nodes-${random_string.suffix.result}"
  })

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# EKS Node Group - Application
resource "aws_eks_node_group" "application" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "application"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = [var.node_instance_type]
  ami_type        = "AL2_x86_64"
  capacity_type   = "ON_DEMAND"
  disk_size       = var.node_disk_size

  # Auto-scaling configuration
  scaling_config {
    desired_size = var.min_node_count
    max_size     = var.max_node_count
    min_size     = var.min_node_count
  }

  # Update configuration
  update_config {
    max_unavailable_percentage = 25
  }

  # Taints for application workloads
  taint {
    key    = "workload"
    value  = "apps"
    effect = "NO_SCHEDULE"
  }

  # Labels
  labels = {
    "node-type" = "application"
    "workload"  = "applications"
    "tier"      = "standard"
  }

  # Ensure proper IAM permissions are created first
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
    aws_iam_role_policy.eks_node_additional
  ]

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-app-nodes-${random_string.suffix.result}"
  })

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# Elastic Container Registry
resource "aws_ecr_repository" "main" {
  name                 = "${var.resource_prefix}-ecr-${random_string.suffix.result}"
  image_tag_mutability = "MUTABLE"

  # Enable image scanning
  image_scanning_configuration {
    scan_on_push = true
  }

  # Encryption configuration
  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-ecr-${random_string.suffix.result}"
  })
}

# ECR Repository policy to allow EKS nodes to pull images
resource "aws_ecr_repository_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEKSNodesPull"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.eks_node_group.arn
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}

# ECR Lifecycle policy to manage image retention
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# EKS Addons

# AWS Load Balancer Controller addon
resource "aws_eks_addon" "aws_load_balancer_controller" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-load-balancer-controller"
  addon_version            = "v2.8.1-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [aws_eks_node_group.system]

  tags = var.tags
}

# VPC CNI addon
resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "vpc-cni"
  addon_version            = "v1.18.1-eksbuild.3"
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [aws_eks_node_group.system]

  tags = var.tags
}

# CoreDNS addon
resource "aws_eks_addon" "coredns" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "coredns"
  addon_version            = "v1.11.1-eksbuild.8"
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [aws_eks_node_group.system]

  tags = var.tags
}

# Kube-proxy addon
resource "aws_eks_addon" "kube_proxy" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "kube-proxy"
  addon_version            = "v1.29.3-eksbuild.2"
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [aws_eks_node_group.system]

  tags = var.tags
}

# EBS CSI Driver addon
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.31.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [aws_eks_node_group.system]

  tags = var.tags
}