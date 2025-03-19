variable "aws_region" {
  description = "AWS region"
  default     = "eu-central-1"
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  default     = "hello-world-cluster"
}

variable "ecr_repository_name" {
  description = "Name of the AWS ECR repository"
  default     = "hello-world-app"
}
