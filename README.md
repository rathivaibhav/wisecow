Accuknox DevOps Trainee Practical Assessment

Hello! This repository contains my complete solution for the Accuknox DevOps Trainee assessment. I forked the original wisecow application and have added all the required artifacts to containerize, deploy, monitor, and secure it.

1. Project Objective

The primary goal was to treat the wisecow application as a modern microservice. This involved:

Containerizing the application with Docker.

Deploying it to a Kubernetes cluster (Minikube).

Automating the build and deployment with a CI/CD pipeline.

Securing the application with TLS and a Zero-Trust KubeArmor policy.

Creating system administration scripts for monitoring.

2. Solution Breakdown

Problem 1: Containerization & Deployment (Wisecow)

I treated this as a standard GitOps workflow.

a. Dockerization

I created a Dockerfile based on ubuntu:latest.

It installs the required dependencies: fortune-mod, cowsay, and netcat-openbsd.

A key fix was adding /usr/games to the PATH environment variable, as this is where cowsay and fortune are installed on Ubuntu, allowing the wisecow.sh script to find them.

A .dockerignore file is included to ensure the build context is clean and builds are fast.

b. Kubernetes Deployment

All manifests are in the k8s/ directory.

namespace.yaml: Creates a wisecow namespace to isolate the application from other cluster services.

deployment.yaml: Deploys the application with 2 replicas for basic high availability. It's configured to pull the image from ghcr.io.

service.yaml: Creates a ClusterIP service to expose the wisecow pods internally to other services in the cluster.

c. CI/CD Pipeline (GitHub Actions)

The workflow is defined in .github/workflows/ci-cd.yaml.

Continuous Integration (CI): On every push to main, the "Build and Push" job runs. It logs into GitHub Container Registry (GHCR), builds the Docker image, and pushes it with two tags: latest and the commit SHA.

Continuous Deployment (CD): The "Deploy to K8s" job runs after the build. This job will only run if a repository secret named KUBECONFIG is present. It securely checks out the kubeconfig, replaces the image placeholder in k8s/deployment.yaml with the new image tag, and automatically applies the new manifest to the cluster.

d. TLS Implementation

This is handled by the k8s/ingress.yaml manifest.

It's configured to route traffic for the host wisecow.local to our wisecow-service.

It implements TLS by referencing a Kubernetes secret named wisecow-tls-secret, which would hold the tls.crt and tls.key files.

To ensure the private key is never committed to Git, I've added a .gitignore file to ignore all *.key files.

Problem 2: System & Application Monitoring Scripts

For this problem, I chose to create two distinct monitoring scripts using Bash, focusing on both system-level health and application-specific availability. These scripts are located in the Problem-Statement-2/ directory.

a. System Health Monitor (system-health.sh)

Purpose: Provides a general overview of the Linux system's resource utilization.

Checks Performed:

CPU Usage: Calculated from top. Alerts if usage exceeds 80%.

Memory Usage: Calculated from free. Alerts if usage exceeds 80%.

Disk Usage: Checks the root filesystem (/). Alerts if usage exceeds 80%.

Process Count: Counts running processes using ps. Alerts if count exceeds 300.

Critical Processes: Checks if essential processes like systemd and init are running using pgrep.

Output: Logs status messages to both the console (with color-coding) and a general log file (system-health.log). Critical alerts are also written to a dedicated alert log (system-alerts.log).

Usage:

cd Problem-Statement-2/
bash system-health.sh
# Check system-health.log and system-alerts.log for output


b. Application Health Checker (App-health.sh)

Purpose: Monitors the availability and responsiveness of a web application via HTTP/S requests. This is crucial for ensuring user-facing services are operational.

Checks Performed:

HTTP Status Code: Uses curl to make a request to the application URL.

Response Time: Measures the time taken for the request to complete.

Content Size: Records the size of the downloaded content (if any).

Uptime Tracking: Maintains a simple status file (app-status.dat) to calculate and display the duration the application has been continuously up since the last check.

Retries: Implements a retry mechanism (MAX_RETRIES=3, RETRY_DELAY=2s) to handle transient network issues.

Output: Provides a clear status (UP/DOWN/Error) on the console with color-coding and detailed metrics. Logs a history of checks and status changes to app-health.log.

Usage:

cd Problem-Statement-2/
# Check default URL (http://localhost:8080)
bash App-health.sh

Problem 3: KubeArmor Zero-Trust Policy

This was a challenging and insightful part of the assessment.

Policy: My zero-trust policy is in kubearmor/wisecow-zero-trust-policy.yaml. The goal was to create a policy that Allows only the specific processes, files, and capabilities the wisecow app needs and Audit everything else.

Debugging & Analysis: During testing, I discovered that my Minikube environment did not have a Linux Security Module (LSM) like AppArmor enabled. The KubeArmor agent log confirmed this with the message: Disabled KubeArmor Enforcer since No LSM is enabled.

The "Violation" (Proof): Because the enforcer was disabled, Block actions were not possible. I therefore adapted my policy to action: Audit. This is the correct "fail-safe" behavior for a security tool in a non-enforcing environment.

My screenshot in the PS-3-Kube-armor-working-Screenshots/ folder shows the KubeArmor agent log detecting my policy and then generating a telemetry/audit log for the /bin/ls process. This proves the policy is active and monitoring the pod for behavior that falls outside the "Allowed" list.

3. How to Test (Local Deployment)

While the CI/CD pipeline is the intended deployment method, here is how to run everything locally for testing:

Start Minikube:

minikube start --profile wisecow


Build & Load Local Image:

# Build the image from the Dockerfile
docker build -t wisecow:local .

# Load the image into the Minikube cluster
minikube image load wisecow:local --profile wisecow


Edit Deployment for Local Image:

Open k8s/deployment.yaml.

Change image: <IMAGE_PLACEHOLDER> to image: wisecow:local.

Change imagePullPolicy: Always to imagePullPolicy: IfNotPresent.

Apply Manifests:

# Apply the namespace first
kubectl apply -f k8s/namespace.yaml

# Apply all other manifests (deployment, service, ingress)
kubectl apply -f k8s/ -n wisecow


Test the Service:

# Forward the port
kubectl port-forward svc/wisecow-service -n wisecow 8080:80

# In a new terminal, test the app
curl http://localhost:8080


(You should see a wisecow with a fortune!)

Thank you for the opportunity.
