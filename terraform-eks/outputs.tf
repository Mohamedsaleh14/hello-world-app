output "ecr_repository_url" {
  value = aws_ecr_repository.hello_world_ecr.repository_url
}

output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public_subnets[*].id
}

output "eks_worker_security_group_id" {
  description = "Security group ID for worker nodes"
  value       = aws_security_group.eks_worker_sg.id
}
