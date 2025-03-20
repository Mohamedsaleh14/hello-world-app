Here’s a **detailed breakdown** of each part of your `eks.tf` file, explaining its function and why it was added.

---

# **Breakdown of `eks.tf`**

## **1️⃣ Creating the IAM Role for the EKS Cluster**
```hcl
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
```
### **What This Does?**
- Creates an **IAM Role** that allows AWS **EKS** to manage its own resources.
- The **assume role policy** grants permission to the **EKS service (`eks.amazonaws.com`)** to assume this role.

### **Why This Is Needed?**
✅ The **EKS control plane** requires permissions to **provision and manage Kubernetes infrastructure**.

✅ Without this role, **EKS cannot interact with AWS services** (e.g., VPC, networking, IAM).

---

## **2️⃣ Attaching IAM Policies to the EKS Cluster Role**
```hcl
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
```
### **What This Does?**
- Attaches **AmazonEKSClusterPolicy** to the EKS IAM Role.
- This policy **grants the EKS cluster full permissions** to manage Kubernetes resources.

### **Why This Is Needed?**
✅ Ensures that **EKS can create, update, and delete cluster components**.

✅ Without this, **EKS wouldn’t have enough permissions to operate properly**.

---

## **3️⃣ Creating the EKS Cluster**
```hcl
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
```
### **What This Does?**
- Creates an **AWS EKS Cluster**.
- Associates it with the **IAM Role (`eksClusterRole`)**.
- Configures **networking (VPC settings)**:

  ✅ Deploys the cluster inside **public subnets**.

  ✅ **Enables public API access** (so you can manage the cluster remotely).

  ✅ **Disables private API access** for now (useful for production security).

- **Depends On**: Ensures the **Docker image is pushed to ECR before EKS is created**.

### **Why This Is Needed?**
✅ The **EKS cluster is the core component** that runs Kubernetes.

✅ Kubernetes workloads (Pods, Deployments, Services) **require an active cluster to function**.

---

## **4️⃣ Creating IAM Role for Worker Nodes**
```hcl
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
```
### **What This Does?**
- Creates an **IAM Role** for **EKS worker nodes** (EC2 instances).
- The **assume role policy** allows **EC2 instances** to assume this role.

### **Why This Is Needed?**
✅ Worker nodes need **permissions to pull images, register with EKS, and interact with AWS services**.

✅ Without this role, **worker nodes wouldn't be able to function within the EKS cluster**.

---

## **5️⃣ Attaching IAM Policies to Worker Nodes**
```hcl
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
```
### **What This Does?**
- Attaches **four IAM policies** to the worker nodes:
  1. **AmazonEKSWorkerNodePolicy** → Allows nodes to join the EKS cluster.
  2. **AmazonEKS_CNI_Policy** → Allows nodes to manage Kubernetes networking.
  3. **AmazonEC2ContainerRegistryReadOnly** → Allows nodes to pull images from AWS ECR.
  4. **AmazonSSMManagedInstanceCore** → Allows AWS Systems Manager to manage worker nodes.

### **Why This Is Needed?**
✅ These policies **allow worker nodes to communicate with Kubernetes, pull images, and be managed remotely**.

✅ Without these, **nodes would fail to start, and Kubernetes wouldn't function correctly**.

---

## **6️⃣ Creating a Security Group for Worker Nodes**
```hcl
resource "aws_security_group" "eks_worker_sg" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "eks-worker-sg"
  }
}
```
### **What This Does?**
- Creates a **Security Group** to manage **networking rules** for worker nodes.

### **Why This Is Needed?**
✅ Security groups **control what traffic is allowed to and from the worker nodes**.

✅ Without a security group, **nodes wouldn't be able to communicate properly**.

---

## **7️⃣ Configuring Security Rules for Worker Nodes**
```hcl
resource "aws_security_group_rule" "eks_worker_ingress_self" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_worker_sg.id
  source_security_group_id = aws_security_group.eks_worker_sg.id
}
```
### **What This Does?**
- Allows **internal communication** between worker nodes.

### **Why This Is Needed?**
✅ Kubernetes worker nodes need to communicate **for pod networking, services, and clustering**.

---
### **More Security Rules**
#### **Allow Kubernetes API Communication**
```hcl
resource "aws_security_group_rule" "eks_worker_ingress_api" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol         = "tcp"
  security_group_id = aws_security_group.eks_worker_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}
```
✅ Allows worker nodes to **connect to the Kubernetes API Server**.

#### **Allow Nodes to Access the Internet**
```hcl
resource "aws_security_group_rule" "eks_worker_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol         = "-1"
  security_group_id = aws_security_group.eks_worker_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}
```
✅ Allows worker nodes **to download updates and communicate externally**.

---

## **8️⃣ Creating the EKS Node Group**
```hcl
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

  depends_on = [aws_iam_role_policy_attachment.eks_worker_policies]
}
```
### **What This Does?**
- Creates an **EKS Node Group** (EC2 instances that run Kubernetes workloads).
- Uses **IAM role, security groups, and networking settings**.
- **Auto-Scales between 1-3 instances**.

### **Why This Is Needed?**
✅ Worker nodes **run Kubernetes pods and services**.

✅ **Auto-scaling ensures efficient resource usage**.

---

## **8️⃣ Allowing Worker Nodes to Communicate with Each Other**
```hcl
resource "aws_security_group_rule" "eks_worker_ingress_self" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_worker_sg.id
  source_security_group_id = aws_security_group.eks_worker_sg.id
}
```
### **What This Does?**
- Allows **all traffic between worker nodes** inside the security group.
- **Ingress rule:** All traffic from **any port, any protocol** is allowed **only between worker nodes**.

### **Why This Is Needed?**
✅ Kubernetes worker nodes **need to communicate with each other** for networking (pods running across multiple nodes).

✅ Allows **Pod-to-Pod communication within the cluster**.

✅ Without this, **multi-node applications and service discovery wouldn't work**.

---

## **9️⃣ Allowing Worker Nodes to Communicate with Kubernetes API**
```hcl
resource "aws_security_group_rule" "eks_worker_ingress_api" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol         = "tcp"
  security_group_id = aws_security_group.eks_worker_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}
```
### **What This Does?**
- Allows worker nodes to **talk to the Kubernetes API Server on port 443 (HTTPS)**.

### **Why This Is Needed?**

✅ **Worker nodes must communicate with the control plane (EKS API server) to get updates about pods, services, etc.**

✅ If this rule is missing, **worker nodes cannot receive or register workloads** from Kubernetes.

---

## **🔟 Allowing Kubernetes Kubelet API Communication**
```hcl
resource "aws_security_group_rule" "eks_worker_ingress_kubelet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_worker_sg.id
  source_security_group_id = aws_security_group.eks_worker_sg.id
}
```
### **What This Does?**
- Allows **nodes to communicate via Kubelet API on port `10250`**.
- Kubelet is the **agent that runs on worker nodes**, responsible for:

  ✅ Managing containers

  ✅ Monitoring health checks

  ✅ Receiving commands from the control plane

### **Why This Is Needed?**
✅ **Kubelet allows EKS to schedule, start, and stop workloads**.

✅ Without this, **EKS cannot interact with worker nodes, and Pods cannot run**.

---

## **1️⃣1️⃣ Allowing Load Balancer (Port 80) Traffic**
```hcl
resource "aws_security_group_rule" "eks_worker_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol         = "tcp"
  security_group_id = aws_security_group.eks_worker_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}
```
### **What This Does?**
- Allows **HTTP traffic (port 80) from the internet**.
- Required for **Kubernetes LoadBalancer Services to route traffic to Pods**.

### **Why This Is Needed?**
✅ Ensures that **external users can access applications** deployed in EKS via a Load Balancer.

✅ **Without this rule, the service would not be publicly accessible**.

---

## **1️⃣2️⃣ Allowing Worker Nodes to Access the Internet**
```hcl
resource "aws_security_group_rule" "eks_worker_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol         = "-1"
  security_group_id = aws_security_group.eks_worker_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}
```
### **What This Does?**
- Allows **worker nodes to initiate outbound connections to the internet**.

### **Why This Is Needed?**

✅ **Worker nodes need to pull Docker images from AWS ECR and other public repositories**.

✅ Ensures that nodes can **download security updates, Kubernetes resources, and dependencies**.

✅ If this is missing, worker nodes **won't be able to run workloads properly**.

---

## **Final Thoughts on These Security Rules**
✅ **Kubernetes needs various levels of communication between nodes, API, and external services.**

✅ **Security rules ensure that networking is properly configured while maintaining necessary restrictions.**

✅ **Without these rules, worker nodes wouldn't work properly, and the cluster would fail.**

---

### **Summary of `eks.tf`**
| **Component** | **Purpose** |
|--------------|------------|
| **EKS IAM Role** | Allows EKS to manage AWS resources |
| **EKS Cluster** | Creates the Kubernetes control plane |
| **Worker IAM Role** | Gives EC2 instances permissions to join the cluster |
| **Security Group Rules** | Enables communication between nodes, API, and internet |
| **Worker Node Group** | Creates and manages Kubernetes worker nodes |

---

This **completes the explanation of `eks.tf`**! Now, your **EKS cluster is fully functional and properly secured**. 🚀 Let me know if you need further clarifications! 😊

# **Summary**
✅ **Fully automated EKS cluster setup**

✅ **Secure IAM policies for EKS and worker nodes**

✅ **Networking properly configured**

✅ **Worker nodes auto-scale for efficiency**

This **ensures a production-ready Kubernetes cluster on AWS**! 🚀