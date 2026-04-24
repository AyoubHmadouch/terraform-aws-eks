# Creates the EKS cluster with VPC and access configuration
resource "aws_eks_cluster" "self" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
  }

  access_config {
    bootstrap_cluster_creator_admin_permissions = true
    authentication_mode                         = "API"
  }

  tags = local.common_tags

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy_attachment,
  ]
}

# IAM role for EKS cluster service to assume
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = local.common_tags
}

# Attaches required EKS cluster policy to the cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Grants IAM principals access to the EKS cluster through EKS access entries
resource "aws_eks_access_entry" "self" {
  for_each = var.access_entries

  cluster_name      = aws_eks_cluster.self.name
  principal_arn     = each.value.principal_arn
  kubernetes_groups = each.value.kubernetes_groups
  type              = each.value.type
  user_name         = each.value.user_name

  tags = local.common_tags
}

# Associates EKS managed access policies with access entries
resource "aws_eks_access_policy_association" "self" {
  for_each = local.access_policy_associations

  cluster_name  = aws_eks_cluster.self.name
  principal_arn = each.value.principal_arn
  policy_arn    = each.value.policy_arn

  access_scope {
    type       = each.value.access_scope.type
    namespaces = each.value.access_scope.namespaces
  }

  depends_on = [aws_eks_access_entry.self]
}

# Creates managed node groups for worker nodes
resource "aws_eks_node_group" "self" {
  for_each        = var.managed_node_group
  cluster_name    = aws_eks_cluster.self.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.eks_nodes_role.arn
  subnet_ids      = var.subnet_ids
  instance_types  = each.value.instance_types

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  tags = local.common_tags

  depends_on = [
    aws_iam_policy_attachment.eks_worker_node_policy_attachment,
    aws_iam_policy_attachment.eks_cni_policy_attachment,
    aws_iam_policy_attachment.eks_container_registry_ro_policy_attachment
  ]
}

# IAM role for EKS worker nodes to assume
resource "aws_iam_role" "eks_nodes_role" {
  name = "${var.cluster_name}-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

# Attaches worker node policy for EC2 instances
resource "aws_iam_policy_attachment" "eks_worker_node_policy_attachment" {
  name       = "${var.cluster_name}-eks-worker-node-policy-attachment"
  roles      = [aws_iam_role.eks_nodes_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Attaches CNI policy for pod networking
resource "aws_iam_policy_attachment" "eks_cni_policy_attachment" {
  name       = "${var.cluster_name}-eks-cni-policy-attachment"
  roles      = [aws_iam_role.eks_nodes_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Attaches ECR read-only policy for pulling container images
resource "aws_iam_policy_attachment" "eks_container_registry_ro_policy_attachment" {
  name       = "${var.cluster_name}-eks-container-registry-policy-attachment"
  roles      = [aws_iam_role.eks_nodes_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Creates Fargate profiles for serverless pod execution
resource "aws_eks_fargate_profile" "self" {
  for_each               = var.fargate_profile
  cluster_name           = aws_eks_cluster.self.name
  fargate_profile_name   = each.key
  pod_execution_role_arn = aws_iam_role.eks_fargate_pod_execution_role.arn
  subnet_ids             = var.subnet_ids

  selector {
    namespace = each.value.namespace
    labels    = each.value.labels
  }

  tags = local.common_tags

  depends_on = [
    aws_iam_role_policy_attachment.eks_fargate_pod_execution_role_policy_attachment
  ]
}

# IAM role for Fargate pod execution
resource "aws_iam_role" "eks_fargate_pod_execution_role" {
  name = "${var.cluster_name}-eks-fargate-pod-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

# Attaches Fargate pod execution policy
resource "aws_iam_role_policy_attachment" "eks_fargate_pod_execution_role_policy_attachment" {
  role       = aws_iam_role.eks_fargate_pod_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

# Installs EKS addons like VPC CNI, CoreDNS, kube-proxy
resource "aws_eks_addon" "self" {
  for_each      = var.eks_addons
  cluster_name  = aws_eks_cluster.self.name
  addon_name    = each.key
  addon_version = each.value.addon_version

  tags = local.common_tags

  depends_on = [aws_eks_node_group.self]
}
