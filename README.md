# hello-world-app

## Define the Project Scope & Architecture
Before diving into code, let's outline **what we’re building**:

1. **Node.js Web App**
   - A simple **Express.js** server that responds with "Hello, World!"
   - The server listens on **port 3000**

2. **Containerization with Docker**
   - Package the app inside a **Docker container**
   - Create a **Dockerfile** for building the container

3. **Orchestration with Kubernetes**
   - Deploy the Docker container on **Kubernetes**
   - Define a **Kubernetes Deployment & Service**

4. **Infrastructure as Code with Terraform**
   - Use Terraform to **provision AWS resources**
   - Deploy a **Kubernetes cluster on AWS (EKS)**
   - Create **networking, IAM roles, and security groups**

5. **Deployment to AWS**
   - Deploy the **Terraform infrastructure**
   - Deploy the **Kubernetes app on AWS EKS**

---

## Set Up Your Development Environment
Before we start coding, you need the following tools installed on your system:

✅ **Node.js & npm** (For the web app)
✅ **Docker** (For containerization)
✅ **Kubernetes (kubectl & minikube or AWS EKS CLI)**
✅ **Terraform** (For AWS infrastructure)
✅ **AWS CLI** (For cloud authentication & resource management)

Great! Let’s start with **Step 1: Creating the Node.js Web App.**

---

## **Step 1: Create a Simple Node.js Web App**
We'll build a **basic Express.js server** that listens on **port 3000** and responds with "Hello, World!"

### **1️⃣ Create a New Project Directory**
Open your terminal and run:
```sh
mkdir hello-world-app && cd hello-world-app
```

### **2️⃣ Initialize a Node.js Project**
Run the following command to create a `package.json` file:
```sh
npm init -y
```

This will generate a default `package.json` file.

### **3️⃣ Install Express.js**
We need Express.js to create a simple web server:
```sh
npm install express
```

### **4️⃣ Create the Server File**
Now, create a new file called `server.js`:
```sh
touch server.js
```

At this point, you should have:
```
hello-world-app/
│── package.json
│── package-lock.json
└── server.js
```
Awesome! Now, let’s **write the Node.js server code** inside `server.js`.

---

## **Step 2: Write the Server Code**
Open `server.js` in your editor and add the following code:

```javascript
const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
    res.send('Hello, World!');
});

app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
```

---

### **Explanation of the Code:**
1. Import **Express.js**
2. Create a new **Express app**
3. Define a **GET** route that responds with `"Hello, World!"`
4. Listen on **port 3000** (or any port set via `process.env.PORT`)
5. Print a message when the server starts

---

## **Step 3: Run the App Locally**
Before we move to **Docker**, let’s test our app.

Run the following command:
```sh
node server.js
```

If everything is working, you should see:
```
Server is running on http://localhost:3000
```
Now, open a browser and go to **http://localhost:3000**
You should see: **Hello, World!**

Great! Now, let’s **Dockerize the Node.js app** so we can run it inside a container.

---

## **Step 4: Create a Dockerfile**
A **Dockerfile** is a script that tells Docker how to build and run our application in a container.

### **1️⃣ Create a Dockerfile**
Inside your project directory (`hello-world-app`), create a file named `Dockerfile`:
```sh
touch Dockerfile
```

Now, open `Dockerfile` in your editor and add the following content:

```dockerfile
# Use an official Node.js image as the base image
FROM node:18-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json first (for better caching)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application files
COPY . .

# Expose the port that the app runs on
EXPOSE 3000

# Define the command to run the app
CMD ["node", "server.js"]
```

---

### **2️⃣ Explanation of the Dockerfile**
1. **FROM node:18-alpine** → Uses a lightweight **Node.js Alpine Linux** image
2. **WORKDIR /app** → Sets `/app` as the working directory inside the container
3. **COPY package*.json ./** → Copies `package.json` and `package-lock.json` first (for caching)
4. **RUN npm install** → Installs dependencies
5. **COPY . .** → Copies the rest of the application files
6. **EXPOSE 3000** → Informs Docker that the app runs on port `3000`
7. **CMD ["node", "server.js"]** → Defines the command to start the server

---

### **3️⃣ Create a `.dockerignore` File**
This prevents unnecessary files (like `node_modules`) from being copied into the container.

Run:
```sh
touch .dockerignore
```

Add the following inside `.dockerignore`:
```
node_modules
npm-debug.log
```

---

### **4️⃣ Build the Docker Image**
Now, let’s **build** the Docker image. Run:
```sh
docker build -t hello-world-app .
```

This will:
- Read the `Dockerfile`
- Download the **Node.js base image**
- Copy files into the container
- Install dependencies
- Create a **Docker image** named `hello-world-app`

---

### **5️⃣ Run the Docker Container**
After building, let’s **run the app in a container**:
```sh
docker run -p 3000:3000 hello-world-app
```

Now, open **http://localhost:3000** in your browser.
You should still see: **Hello, World!**

Great! Now, let's move on to **Step 5: Deploying the Dockerized App on Kubernetes**. 🚀

---

## **Step 5: Deploying the App on Kubernetes**
Now that we have our **Node.js app running in a Docker container**, we need to deploy it to **Kubernetes**.

### **1️⃣ Install & Set Up Kubernetes (if not already installed)**
To run Kubernetes locally, you can use **Minikube** or, if deploying on AWS later, use **EKS**.

- If using Minikube (for local Kubernetes):
  ```sh
  minikube start
  ```

- Verify that Kubernetes is running:
  ```sh
  kubectl get nodes
  ```

---

### **2️⃣ Create a Kubernetes Deployment**
A **Deployment** is responsible for managing replicas of our app.

#### **Create a new file called `deployment.yaml`:**
```sh
touch deployment.yaml
```

#### **Add the following content to `deployment.yaml`:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello-world-app
  template:
    metadata:
      labels:
        app: hello-world-app
    spec:
      containers:
        - name: hello-world-app
          image: hello-world-app:latest
          ports:
            - containerPort: 3000
```

---

### **3️⃣ Create a Kubernetes Service**
A **Service** allows us to expose the Deployment inside the cluster.

#### **Create a new file called `service.yaml`:**
```sh
touch service.yaml
```

#### **Add the following content to `service.yaml`:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-world-service
spec:
  selector:
    app: hello-world-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
  type: NodePort
```

---

### **4️⃣ Apply the Deployment & Service to Kubernetes**
Run the following commands:
```sh
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

Verify that everything is running:
```sh
kubectl get pods
kubectl get services
```

To access the service, find the NodePort:
```sh
kubectl describe service hello-world-service | grep NodePort
```
Then open in your browser:
`http://<minikube-ip>:<nodeport>`

For Minikube:
```sh
minikube service hello-world-service
```
---
### **1️⃣ What is a NodePort in Kubernetes?**
A **NodePort** is a way to expose a Kubernetes service to external traffic by opening a specific port on **every node** in the cluster.

**How it works:**
- Kubernetes assigns a port (between **30000-32767**) on every node.
- Any traffic sent to **`<NodeIP>:<NodePort>`** will be forwarded to the **service**, which directs it to the **pods**.

#### **Example**
If your NodePort is **30001**, you can access your service at:
```
http://<minikube-ip>:30001
```
or
```
http://<node-ip>:30001
```

---

### **2️⃣ What is the difference between having separate `deployment.yaml` and `service.yaml` vs. a single file?**
Both approaches work **exactly the same**, but the difference is in **organization and maintainability**.

#### **Separate Files (`deployment.yaml` & `service.yaml`)**
- **Better organization:** Easier to manage and edit different resources.
- **Reusability:** You can update or deploy only specific resources without modifying the entire file.
- **Clear versioning:** Useful when using Git or Infrastructure as Code.

#### **Single File (`hello-world.yaml` with both Deployment & Service)**
- **Less file clutter:** Everything is in one place.
- **Easier to apply:** One `kubectl apply -f hello-world.yaml` deploys both resources.
- **Good for small projects:** When you don’t have too many services.

✅ **Which one should you use?**
- For **small projects**, a single YAML file is fine.
- For **large projects**, separate files are better.

---

### **3️⃣ Breakdown of the YAML File**
Let’s analyze each part of the **combined deployment & service YAML**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world-app  # Name of the Deployment
spec:
  replicas: 2  # Number of pod replicas
  selector:
    matchLabels:
      app: hello-world  # Match pods with this label
  template:
    metadata:
      labels:
        app: hello-world  # Labels assigned to pods
    spec:
      containers:
      - name: hello-world-container  # Name of the container inside the pod
        image: hello-world-app  # Docker image to use
        ports:
        - containerPort: 3000  # Expose port 3000 inside the container
---
apiVersion: v1
kind: Service
metadata:
  name: hello-world-service  # Name of the service
spec:
  selector:
    app: hello-world  # This service targets pods with label "app: hello-world"
  ports:
    - protocol: TCP
      port: 80  # Port on the service (inside the cluster)
      targetPort: 3000  # Forward traffic to pod's container on port 3000
  type: NodePort  # Exposes service on a NodePort (external access)
```

---

### **4️⃣ How Everything Works Together**
1. **Deployment:**
   - Creates **2 replicas** (pods) of the app.
   - Each pod runs a container with the **hello-world-app** image.
   - The pods are assigned the label **app: hello-world**.

2. **Service:**
   - Selects pods with **app: hello-world**.
   - Routes incoming traffic on **port 80** to **port 3000** in the pods.
   - Uses **NodePort**, making the app accessible outside the cluster.

---

### **5️⃣ How to Apply the YAML Files**
For separate files:
```sh
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

For a single file:
```sh
kubectl apply -f hello-world.yaml
```
---

## Provisioning AWS Infrastructure with Terraform**
Now that we have our app and containerization set up, we need to provision our AWS infrastructure using **Terraform**.

### **1️⃣ Initialize Terraform**
Ensure Terraform is installed, then navigate to the directory containing your Terraform files and run:
```sh
terraform init
```
This initializes Terraform and downloads the required providers.

### **2️⃣ Validate Terraform Configuration**
To check for syntax errors and validate the Terraform configuration, run:
```sh
terraform validate
```

### **3️⃣ Format Terraform Files**
To ensure consistency in formatting:
```sh
terraform fmt
```

### **4️⃣ Plan the Infrastructure**
Before applying changes, review what Terraform will create:
```sh
terraform plan
```
This command shows a detailed preview of the resources Terraform will provision.

### **5️⃣ Apply Terraform Configuration**
To deploy the AWS infrastructure, run:
```sh
terraform apply -auto-approve
```
This creates the following AWS resources:
- **Amazon EKS Cluster** (`eks.tf`)
- **Amazon ECR Repository** (`ecr.tf`)
- **VPC and Subnets** (`vpc.tf`)
- **IAM Roles for EKS and Worker Nodes** (`eks.tf`)
- **Security Groups for EKS Cluster and Worker Nodes** (`eks.tf`)

### **6️⃣ Retrieve EKS Cluster Credentials**
Once the cluster is created, configure `kubectl` to interact with it:
```sh
aws eks --region eu-central-1 update-kubeconfig --name hello-world-cluster
```
This command updates your local kubeconfig to communicate with the newly created EKS cluster.

### **7️⃣ Deploy the Kubernetes Resources**
Apply the updated Kubernetes deployment and service files:
```sh
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

### **8️⃣ Verify Terraform State**
To check the current state of the Terraform-managed resources:
```sh
terraform state list
```
To get details of a specific resource:
```sh
terraform state show aws_eks_cluster.main
```

### **9️⃣ Destroy the Terraform Infrastructure (if needed)**
If you ever need to tear down the infrastructure, use:
```sh
terraform destroy -auto-approve
```
This will remove all the AWS resources created by Terraform.

---

## **Step 7: Updates in Kubernetes Configuration**
### **Changes in `deployment.yaml`**
We updated the container image to pull from **AWS ECR**:
```yaml
image: 850995538849.dkr.ecr.eu-central-1.amazonaws.com/hello-world-app:latest
```
**Reason:** Instead of using a local image, we now fetch the image directly from AWS ECR to ensure proper deployment in AWS EKS.

### **Changes in `service.yaml`**
We retained the `LoadBalancer` type service:
```yaml
type: LoadBalancer
```
**Reason:** This ensures that AWS automatically provisions an external Elastic Load Balancer (ELB) to expose our service to the internet.

---
## Notes:

If **EKS waits for the ECR image to be pushed** but **Kubernetes resources (Deployment & Service) are applied after EKS is ready**, this can cause a **deadlock** where:
1. **EKS waits for ECR** (because `depends_on` enforces that ECR must be ready).
2. **ECR waits for EKS** (because Kubernetes needs an active cluster to deploy).

### **✅ Solution: Use the Terraform Kubernetes Provider**
- By **moving Kubernetes resources (`deployment.yaml` & `service.yaml`) into Terraform**, we solve this issue.
- Terraform **automates everything**, ensuring:
  - **ECR is created** ✅
  - **Docker image is pushed** ✅
  - **EKS is created** ✅
  - **Kubernetes deployment is applied automatically** ✅ (without a deadlock)

---

### **✅ IAM Role Setup Should Be Fully Automated**
- We should **automate IAM policy creation** instead of manually defining IAM roles.
- Terraform will **dynamically attach required policies** to EKS & worker nodes.

## **1️⃣ Update `deployment.yaml` with Your AWS ECR Image URL**
- Terraform creates the **ECR repository**, but **you need to update the image reference in Kubernetes**.

### **📌 Open `deployment.yaml` and Update This Line:**
```yaml
image: "<aws-account-id>.dkr.ecr.<aws-region>.amazonaws.com/hello-world-app:latest"
```
### **Replace `<aws-account-id>` and `<aws-region>` with actual values.**
- **Find your ECR repository URL** by running:
  ```sh
  terraform output ecr_repository_url
  ```

Example:
```yaml
image: "123456789012.dkr.ecr.eu-west-1.amazonaws.com/hello-world-app:latest"
```

✅ **Now, Terraform will correctly deploy the container from AWS ECR.**

---

## **2️⃣ Ensure You Have the AWS CLI Installed**
Run:
```sh
aws --version
```
✅ If AWS CLI is missing, install it from [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).

---

## **3️⃣ Run Terraform Commands**
Now, run the Terraform setup step-by-step:

### **Step 1: Initialize Terraform**
```sh
terraform init
```

### **Step 2: Validate Configuration**
```sh
terraform validate
```
✅ **Ensure no errors appear.**

### **Step 3: Apply Terraform Configuration**
```sh
terraform apply -auto-approve
```
✅ **Terraform will:**
1. **Create AWS ECR**
2. **Push the Docker image to ECR**
3. **Deploy AWS EKS**
4. **Automatically apply Kubernetes resources (`deployment.yaml` & `service.yaml`)**

---

## **4️⃣ Verify the Deployment**
### **Check if Kubernetes Nodes are Ready**
```sh
kubectl get nodes
```
✅ Expected output:
```
NAME                                          STATUS   ROLES    AGE   VERSION
ip-10-0-1-34.eu-west-1.compute.internal       Ready    <none>   5m    v1.22
ip-10-0-2-45.eu-west-1.compute.internal       Ready    <none>   5m    v1.22
```

### **Check if Pods Are Running**
```sh
kubectl get pods
```
✅ Expected output:
```
NAME                             READY   STATUS    RESTARTS   AGE
hello-world-app-5678abcd89-xyz34  1/1     Running   0          2m
```

### **Check if the Service Has a LoadBalancer**
```sh
kubectl get services
```
✅ Expected output:
```
NAME                 TYPE           CLUSTER-IP       EXTERNAL-IP          PORT(S)        AGE
hello-world-service  LoadBalancer   10.100.200.100   abcdef123.elb.amazonaws.com   80:31234/TCP   10m
```

---

## **5️⃣ Access the Application**
Once the **LoadBalancer is created**, open:
```
http://<EXTERNAL-IP>
```
Example:
```
http://abcdef123.elb.amazonaws.com
```
✅ **You should see:**
```
Hello, World!
```

---

### **🚀 Final Confirmation**
✅ **No manual updates needed beyond updating `deployment.yaml`.**
✅ **Terraform now fully manages AWS ECR, EKS, and Kubernetes Deployment.**
✅ **You are now production-ready! 🎉**


### **Congratulations!** 🎉
You have successfully deployed a **Node.js application on AWS using Terraform, Kubernetes, and Docker**!

