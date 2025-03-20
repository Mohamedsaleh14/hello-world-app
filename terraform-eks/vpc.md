
# **Breakdown of `vpc.tf`**

## **1️⃣ Fetching Available AWS Availability Zones**
```hcl
data "aws_availability_zones" "available" {}
```
### **What This Does?**
- Retrieves the list of **available AWS Availability Zones** in the selected region.

### **Why This Is Needed?**
✅ Ensures that Terraform **dynamically selects valid availability zones** without hardcoding them.

✅ AWS regions have **different numbers of availability zones**, so this approach prevents errors when deploying across different regions.

---

## **2️⃣ Creating the Virtual Private Cloud (VPC)**
```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "eks-vpc"
  }
}
```
### **What This Does?**
- Creates a **VPC (Virtual Private Cloud)** that acts as an **isolated network** for AWS resources.
- The **CIDR block `10.0.0.0/16`** defines the **IP range** (allowing 65,536 private IPs).
- **DNS support and hostnames are enabled** for resolving internal AWS services.

### **Why This Is Needed?**
✅ The VPC provides **network isolation** for the EKS cluster.

✅ **Enables DNS resolution** for Kubernetes workloads (internal service discovery).

✅ Kubernetes requires **private networking** to run securely in AWS.

---

## **3️⃣ Creating Public Subnets**
```hcl
resource "aws_subnet" "public_subnets" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(["10.0.1.0/24", "10.0.2.0/24"], count.index)
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name                                      = "public-subnet-${count.index}"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb" = "1"
  }
}
```
### **What This Does?**
- **Creates two public subnets** (one per availability zone).
- Each subnet is assigned a **/24 CIDR block**, allowing **256 IP addresses per subnet**.
- **Automatically assigns public IPs** (`map_public_ip_on_launch = true`).
- The **availability zone is selected dynamically** based on available zones.

### **Why This Is Needed?**
✅ **Worker nodes need to be in public subnets** if using a public-facing Load Balancer.

✅ **Public subnets enable external access** (e.g., accessing an application from the internet).

✅ **Tagging (`kubernetes.io/role/elb = 1`)** allows AWS Load Balancers to use these subnets.

---

## **4️⃣ Creating an Internet Gateway**
```hcl
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "eks-internet-gateway"
  }
}
```
### **What This Does?**
- Creates an **Internet Gateway** that enables **internet access** for instances in the VPC.

### **Why This Is Needed?**
✅ Required **for public subnets to send traffic to and from the internet**.

✅ Without an Internet Gateway, **worker nodes wouldn’t be able to pull Docker images from AWS ECR or update packages**.

---

## **5️⃣ Creating a Public Route Table**
```hcl
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "eks-public-route-table"
  }
}
```
### **What This Does?**
- Creates a **route table** that controls **how traffic flows** within the VPC.
- Initially, the route table is empty and will be updated in the next step.

### **Why This Is Needed?**
✅ **Required for defining networking rules** in the VPC.

✅ Without a route table, **subnets cannot communicate with external networks**.

---

## **6️⃣ Attaching the Route Table to Public Subnets**
```hcl
resource "aws_route_table_association" "public_rt_assoc" {
  count          = length(aws_subnet.public_subnets[*].id)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.public_rt.id
}
```
### **What This Does?**
- Associates **each public subnet with the public route table**.

### **Why This Is Needed?**
✅ Ensures that **all public subnets use the correct networking rules** (internet access via the Internet Gateway).

✅ Without this, **public subnets wouldn't be able to send traffic to the internet**.

---

## **7️⃣ Creating the Default Route for Internet Access**
```hcl
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}
```
### **What This Does?**
- Adds a **default route (`0.0.0.0/0`)** to the **public route table**.
- All traffic that is not **internal to the VPC** is sent to the **Internet Gateway**.

### **Why This Is Needed?**
✅ Enables **internet connectivity** for worker nodes in public subnets.

✅ Without this, **public subnets wouldn’t be able to reach the internet**.

---

# **Summary of `vpc.tf`**
| **Component** | **Purpose** |
|--------------|------------|
| **VPC** | Creates an isolated network for EKS resources |
| **Subnets** | Provides IP ranges for Kubernetes worker nodes |
| **Internet Gateway** | Allows worker nodes to access the internet |
| **Route Table** | Defines how traffic flows inside and outside the VPC |
| **Route Table Association** | Links public subnets to the public route table |
| **Default Route** | Enables external access from public subnets |

---

### **Final Thoughts**
✅ **Fully configured VPC with public subnets** for EKS worker nodes.

✅ **Ensures proper internet access for worker nodes to pull images and communicate externally**.

✅ **This networking setup is a common standard for Kubernetes clusters on AWS**.
