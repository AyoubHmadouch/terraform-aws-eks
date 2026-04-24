output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.self.id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.self.arn
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = aws_eks_cluster.self.endpoint
}

output "cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = aws_eks_cluster.self.version
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.self.vpc_config[0].cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.self.certificate_authority[0].data
}

output "node_groups" {
  description = "EKS node groups"
  value       = aws_eks_node_group.self
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "node_iam_role_arn" {
  description = "IAM role ARN of the EKS node group"
  value       = aws_iam_role.eks_nodes_role.arn
}

output "access_entries" {
  description = "EKS access entries"
  value       = aws_eks_access_entry.self
}

output "access_policy_associations" {
  description = "EKS access policy associations"
  value       = aws_eks_access_policy_association.self
}
