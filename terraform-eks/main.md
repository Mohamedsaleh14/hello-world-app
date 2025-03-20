
# **Breakdown of `main.tf`**

## **1️⃣ Defining Required Providers**
```hcl
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
```
### **What This Does?**
- Specifies that Terraform will use the **AWS provider** (for provisioning AWS resources) and the **Kubernetes provider** (for interacting with the EKS cluster).
- Ensures compatibility by defining the required **minimum versions** of the providers.
- By locking versions (`>= 5.84.0` for AWS, `~> 2.0` for Kubernetes), we avoid unexpected behavior due to breaking changes.

---

## **2️⃣ Configuring AWS Provider**
```hcl
provider "aws" {
  region = var.aws_region
}
```
### **What This Does?**
- Configures Terraform to use **AWS as the cloud provider**.
- The region is dynamically set using a variable (`var.aws_region`), making the configuration **reusable** across different AWS regions.

### **Why This Is Needed?**
- Without specifying a provider, Terraform wouldn’t know which cloud platform to provision resources on.
- Using a variable (`var.aws_region`) allows flexibility to **deploy the same infrastructure in different AWS regions**.

---

## **3️⃣ Configuring Kubernetes Provider**
```hcl
provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name]
    command     = "aws"
  }
}
```
### **What This Does?**
- Configures Terraform to **interact with the Kubernetes cluster** (`EKS` in AWS).
- Uses the **AWS EKS cluster’s API endpoint** and **certificate authority** to establish a secure connection.
- Uses AWS authentication (`eks get-token`) to interact with the Kubernetes cluster **securely**.

### **Why This Is Needed?**
- The Kubernetes provider enables Terraform to **apply Kubernetes manifests** (like Deployments & Services) after EKS is up.
- **Using AWS authentication (`eks get-token`) ensures secure access** without needing static credentials.
- The `base64decode(aws_eks_cluster.main.certificate_authority[0].data)` ensures we use the correct **TLS certificate** for secure Kubernetes API access.

---

## **4️⃣ Pushing Docker Image to AWS ECR Before EKS is Created**
```hcl
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
```
### **What This Does?**
- Executes **local commands** on the machine running Terraform to:
  1. Authenticate Docker with AWS ECR.
  2. Tag the local `hello-world-app` Docker image.
  3. Push the image to **AWS ECR**.

### **Why This Is Needed?**
- EKS **cannot pull an image if it does not exist in ECR**. This step ensures the image is **available** before Kubernetes tries to deploy it.
- Without this, Kubernetes pods **would fail** because they **would not find the container image in AWS ECR**.

### **Why Use `null_resource`?**
- Terraform **does not natively handle Docker builds** (that’s a separate provider).
- `null_resource` allows us to **execute shell commands inside Terraform** to integrate **Docker image pushes** into our workflow.

---

## **5️⃣ Applying Kubernetes Configuration Automatically After EKS Creation**
```hcl
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
```
### **What This Does?**
- Runs **local Kubernetes commands** to:
  1. Update the `kubectl` configuration to use the **new EKS cluster**.
  2. Apply the **deployment.yaml** and **service.yaml** files to Kubernetes.

### **Why This Is Needed?**
- **Kubernetes resources (Pods, Services, Deployments) need EKS to be available first.**
- Instead of **manually applying** Kubernetes manifests after Terraform completes, this step automates it.

### **Why Use `null_resource` Again?**
- Terraform **does not natively handle Kubernetes manifests** unless using the Kubernetes provider.
- Since we use **YAML files**, we need `kubectl` commands, and `null_resource` allows running those automatically.

---

## **6️⃣ Dependencies and Execution Order**
### **Why Do We Use `depends_on`?**
Terraform **does not guarantee execution order** unless explicitly specified using `depends_on`.

Here’s how dependencies are enforced:

1. **Pushing Docker Image Must Happen Before EKS Creation**
   ```hcl
   depends_on = [aws_ecr_repository.hello_world_ecr]
   ```
   - Ensures the **Docker image is in AWS ECR** before EKS is created.

2. **Applying Kubernetes Manifests Must Happen After EKS Creation**
   ```hcl
   depends_on = [aws_eks_cluster.main]
   ```
   - Ensures **EKS is ready** before deploying Kubernetes workloads.

---

# **Summary of Key Components**
| **Component**          | **Purpose** |
|----------------------|-------------|
| **Terraform Providers** | Defines AWS and Kubernetes as infrastructure providers. |
| **AWS Provider** | Configures Terraform to work with AWS. |
| **Kubernetes Provider** | Allows Terraform to interact with Kubernetes (EKS). |
| **Docker Image Push (`null_resource`)** | Ensures EKS can pull the correct image. |
| **Kubernetes Apply (`null_resource`)** | Automates Kubernetes deployment after EKS creation. |
| **Dependencies (`depends_on`)** | Ensures proper execution order of AWS, Docker, and Kubernetes. |

---

# **Why This Approach is Effective**
✅ **Fully automated deployment** – no manual `kubectl` or `docker push` required.

✅ **AWS EKS pulls the correct Docker image** because Terraform ensures it is available first.

✅ **Terraform manages AWS & Kubernetes together** without separate workflows.

✅ **Reproducible infrastructure** – running `terraform apply` provisions everything from scratch.

---

# **Potential Improvements**
1️⃣ **Use Terraform Kubernetes Provider Instead of `kubectl apply`**
   - Instead of `null_resource`, define Kubernetes resources inside Terraform.
   - Example:
   ```hcl
   resource "kubernetes_deployment" "hello_world" {
     metadata {
       name = "hello-world"
     }
     spec {
       replicas = 2
       selector {
         match_labels = {
           app = "hello-world"
         }
       }
       template {
         metadata {
           labels = {
             app = "hello-world"
           }
         }
         spec {
           container {
             image = aws_ecr_repository.hello_world_ecr.repository_url
             name  = "hello-world-container"
           }
         }
       }
     }
   }
   ```
   - **Benefit**: Terraform manages Kubernetes directly instead of calling `kubectl apply`.

2️⃣ **Separate Workloads into Modules**
   - Instead of a **single `main.tf`**, break it into:
     - `eks.tf` (EKS cluster)
     - `ecr.tf` (ECR repository)
     - `kubernetes.tf` (Kubernetes resources)
   - **Benefit**: Easier maintenance and reusability.

---

## **Final Thoughts**
This `main.tf` setup provides **a fully automated AWS infrastructure deployment** that:

✅ **Builds a secure AWS EKS cluster**

✅ **Pushes container images to AWS ECR**

✅ **Deploys Kubernetes workloads automatically**

It’s a **solid starting point** for building production-ready cloud applications! 🚀

