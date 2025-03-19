terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.84.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name]
    command     = "aws"
  }
}

# Ensure Docker Image is pushed before EKS is created
resource "null_resource" "push_docker_image" {
  depends_on = [aws_ecr_repository.hello_world_ecr]

  provisioner "local-exec" {
    command = <<EOT
      aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.hello_world_ecr.repository_url}
      docker tag hello-world-app:latest ${aws_ecr_repository.hello_world_ecr.repository_url}:latest
      docker push ${aws_ecr_repository.hello_world_ecr.repository_url}:latest
    EOT
  }
}

resource "null_resource" "apply_kubernetes" {
  depends_on = [aws_eks_cluster.main]

  provisioner "local-exec" {
    command = <<EOT
      aws eks --region ${var.aws_region} update-kubeconfig --name ${var.eks_cluster_name}
      kubectl apply -f ../deployment.yaml
      kubectl apply -f ../service.yaml
    EOT
  }
}
