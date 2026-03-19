# CI/CD Pipeline — Jenkins · Terraform · ECR · Helm · Argo CD

Production-ready CI/CD infrastructure automating the full deployment lifecycle of a Django application on Kubernetes.

## What this project does

- Builds Docker images using **Kaniko** (no Docker daemon required)
- Pushes images to **Amazon ECR**
- Updates **Helm charts** in Git with the correct image tag
- Triggers automatic sync via **Argo CD** on Git changes

## Pipeline Flow
```
Developer push → Jenkins detects change
                       ↓
              Build & push image → ECR
                       ↓
           Update Helm chart → Git commit
                       ↓
         Argo CD detects change → sync
                       ↓
              Deploy to Kubernetes ✓
```

## Project Structure
```
Project/
├── main.tf                    # Main Terraform configuration
├── modules.tf                 # Module definitions
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── backend.tf                 # Backend configuration
├── terraform.tfvars           # Default variable values
├── Jenkinsfile                # Jenkins pipeline definition
│
├── modules/
│   ├── s3-backend/            # S3 + DynamoDB for remote state
│   ├── vpc/                   # VPC, subnets, gateways
│   ├── ecr/                   # ECR repository
│   ├── eks/                   # EKS cluster
│   ├── jenkins/               # Jenkins via Helm
│   └── argo_cd/               # Argo CD via Helm
│       └── charts/
│           └── templates/
│               ├── application.yaml
│               └── repository.yaml
│
└── charts/
    └── django-app/            # Application Helm chart
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── hpa.yaml
            └── configmap.yaml
```

## Prerequisites

| Tool | Version |
|------|---------|
| Terraform | >= 1.0 |
| kubectl | >= 1.28 |
| Helm | >= 3.10 |
| AWS CLI | configured |

**Required AWS permissions:** EC2, EKS, ECR, S3, DynamoDB, IAM

## Setup

### 1. Clone & configure
```bash
git clone https://github.com/your-username/lesson-8-9.git
cd lesson-8-9
git checkout lesson-8-9
```
```bash
cat > .env << 'EOF'
export TF_VAR_jenkins_admin_password="your-secure-password"
export TF_VAR_docker_username="your-docker-username"
export TF_VAR_docker_password="your-docker-token"
export TF_VAR_docker_email="your-email@example.com"
export TF_VAR_argocd_admin_password="your-secure-password"
export TF_VAR_django_app_repo="https://github.com/your-username/django-app.git"
EOF

source .env
```

### 2. Bootstrap S3 backend (first run only)
```bash
cat > backend-init.tf << 'EOF'
terraform {
  backend "local" {
    path = "terraform.tfstate.local"
  }
}
EOF

terraform init
terraform apply -target=module.s3_backend

STATE_BUCKET=$(terraform output -raw s3_bucket_id)
STATE_TABLE=$(terraform output -raw dynamodb_table_name)

rm backend-init.tf
```

### 3. Migrate to remote backend
```bash
terraform init \
  -backend-config="bucket=${STATE_BUCKET}" \
  -backend-config="dynamodb_table=${STATE_TABLE}"
```

### 4. Deploy infrastructure
```bash
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

**Resources created:** VPC · EKS cluster · ECR repository · Jenkins · Argo CD

### 5. Connect to the cluster
```bash
aws eks update-kubeconfig --name cicd-pipeline-eks --region us-east-1
kubectl get nodes
```

## Jenkins Configuration
```bash
# Port-forward
kubectl port-forward -n jenkins svc/jenkins-controller 8080:80 &

# Get admin password
kubectl get secret -n jenkins jenkins \
  -o jsonpath='{.data.jenkins-admin-password}' | base64 -d
```

**Credentials to configure in Jenkins:**

| ID | Type | Purpose |
|----|------|---------|
| `github-ssh-key` | SSH Key | GitHub access |
| `ecr-registry-url` | AWS | Push to ECR |

**Pipeline job:** New Item → Pipeline → SCM: Git → Script Path: `Jenkinsfile`

## Argo CD
```bash
kubectl port-forward -n argocd svc/argo-cd-argocd-server 8443:443 &

kubectl get secret -n argocd argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
```
```bash
# Monitor sync status
argocd app get django-app
argocd app wait django-app --sync
```

## End-to-end workflow
```bash
# 1. Push code
git push origin main

# 2. Jenkins builds image, pushes to ECR, updates Helm values, commits to Git

# 3. Argo CD detects the commit and syncs the deployment

# 4. Verify
kubectl get pods -n default
kubectl describe deployment django-app -n default
```

## Security notes

- Never commit `.env` or `terraform.tfvars` with credentials to Git
- EKS nodes run in **private subnets** — NAT gateway handles outbound traffic
- Jenkins and Argo CD service accounts use **least-privilege RBAC**
- ECR scans images on every push; use AWS Inspector for continuous monitoring

## Cleanup
```bash
kubectl delete all -n jenkins
kubectl delete all -n argocd
kubectl delete all -n default

terraform destroy
```
```bash
# Remove S3 state bucket manually after destroy
aws s3 rm s3://${STATE_BUCKET} --recursive
aws s3api delete-bucket --bucket ${STATE_BUCKET}
aws dynamodb delete-table --table-name ${STATE_TABLE}
```
