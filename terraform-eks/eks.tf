resource "aws_iam_role" "eks_cluster_role" {
  name = "eksClusterRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "main" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids              = aws_subnet.public_subnets[*].id
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  depends_on = [null_resource.push_docker_image]
}

resource "aws_iam_role" "eks_worker_role" {
  name = "eksWorkerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Attach Necessary IAM Policies to Worker Nodes
resource "aws_iam_role_policy_attachment" "eks_worker_policies" {
  count = length([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = element([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ], count.index)
}

# Security Group for Worker Nodes
resource "aws_security_group" "eks_worker_sg" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "eks-worker-sg"
  }
}

# Allow Internal Node-to-Node Communication
resource "aws_security_group_rule" "eks_worker_ingress_self" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_worker_sg.id
  source_security_group_id = aws_security_group.eks_worker_sg.id
}

# Allow Kubernetes API Communication
resource "aws_security_group_rule" "eks_worker_ingress_api" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol         = "tcp"
  security_group_id = aws_security_group.eks_worker_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Allow Kubelet API on 10250
resource "aws_security_group_rule" "eks_worker_ingress_kubelet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_worker_sg.id
  source_security_group_id = aws_security_group.eks_worker_sg.id
}

# Allow Nodes to Access the Internet
resource "aws_security_group_rule" "eks_worker_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol         = "-1"
  security_group_id = aws_security_group.eks_worker_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "eks-workers"
  node_role_arn   = aws_iam_role.eks_worker_role.arn
  subnet_ids      = aws_subnet.public_subnets[*].id

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  instance_types = ["t2.micro"]
}
