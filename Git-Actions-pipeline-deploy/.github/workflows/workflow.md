name: CI/CD Workflow

on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ vars.REGION }}

      - name: Install kubectl
        uses: azure/setup-kubectl@v3 

      - name: Install helm
        uses: azure/setup-helm@v4.2.0 

      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v2 

      - name: Create S3 bucket
        run: |
          if aws s3api head-bucket --bucket "sock-bucket" >/dev/null 2>&1; then
            echo "Bucket already exists, skipping creation."
          else
            echo "Bucket does not exist, creating it."
            aws s3 mb s3://"sock-bucket"
          fi

      - name: Create DynamoDB table
        run: |
          if aws dynamodb describe-table --table-name "terraform-lock" >/dev/null 2>&1; then
            echo "DynamoDB table already exists, skipping creation."
          else
            aws dynamodb create-table \
              --table-name "terraform-lock" \
              --attribute-definitions AttributeName=LockID,AttributeType=S \
              --key-schema AttributeName=LockID,KeyType=HASH \
              --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
          fi

      - name: Deploy Terraform
        run: |
          terraform -chdir=terraform/ init
          terraform -chdir=terraform/ apply --auto-approve

      - name: Change Back to Project Root
        run: cd ..
      
      - name: Update kubeconfig
        run: |
          aws eks update-kubeconfig --name socks-shop-CICD001 --region ${{ vars.REGION }}

      - name: Apply aws-auth ConfigMap
        run: kubectl apply -f aws-auth.yaml --validate=false
      
      - name: Create namespace sock-shop
        run: kubectl get namespace sock-shop || kubectl create namespace sock-shop

      - name: Update kubeconfig
        run: |
          aws eks update-kubeconfig --name socks-shop-CICD001 --region ${{ vars.REGION }}

      - name: Deploy application
        run: helm upgrade --install capstoneapp helm/app --namespace sock-shop

      - name: Deploy Let's Encrypt
        run: |
          helm repo add jetstack https://charts.jetstack.io --force-update
          helm repo update jetstack
          helm upgrade --install cert-manager jetstack/cert-manager \
            --namespace sock-shop \
            --version v1.15.2 \
            --set crds.enabled=true

      - name: Deploy Prometheus and Grafana
        run: |
          helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
          helm repo update
          helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --namespace sock-shop

      - name: Deploy Nginx Ingress Controller
        run: |
          helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx/
          helm repo update
          helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace sock-shop

      - name: Delay
        run: sleep 40s

      - name: Change Back to Project Root
        run: cd ..

      - name: Deploy Ingress Resources
        run: kubectl apply -f ingress.yml

      - name: Apply Cluster Issuer
        run: kubectl apply -f cluster-Issuer.yml

      - name: Apply Certificate
        run: kubectl apply -f certificate.yaml
               

