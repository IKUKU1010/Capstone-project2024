# ARCHITECTURAL DIAGRAM OF INFRASTRUCTURE

![eks cluster microservice architecture diagram](./Images/eks%20cluster%20microservice%20architecture%20diagram.png)
<br>
<br>
# Capstone-project2024

This brief documentation outlines the essential steps and considerations for setting up a CI/CD pipeline using GitHub Actions, providing a clear guide for automating the deployment of SOCK SHOP app to an EKS cluster.


## CI/CD Pipeline with GitHub Actions for SOCK SHOP App

## Prerequisites

- **GitHub Repository**: Ensure your project code is hosted on GitHub and contain all the required manifest files.

- **EKS Cluster**: An existing EKS (Elastic Kubernetes Service) cluster or any Kubernetes provider.

- **Terraform & Helm**: Scripts and configurations for provisioning infrastructure and deploying applications.

- **AWS CLI**: Configured with access to your AWS account.

- **kubectl**: Kubernetes CLI tool to manage your cluster.


## Step 1: Setup GitHub Actions Workflow

GitHub Actions Workflow is like a set of instructions or tasks that you want your project to automatically do whenever something happens in your code repository. These tasks can include things like running tests, building your code, deploying your application, or anything else you might want to automate.

Here’s a simple breakdown of a classic workflow:

**Trigger**: This is what starts the workflow. It could be something like pushing new code, opening a pull request, or even on a scheduled basis. Think of it as the event that says, “Hey, start doing these tasks!”

**Jobs**: These are the tasks that you want to run. Each job can do something specific, like testing your code to make sure it works, building your application, or deploying it to a server.

**Steps**: Each job is made up of steps. A step is a single action, like running a command or a script. Steps are what make up the job and are executed in order.

**Runners**: This is where your jobs are run. A runner is a server that GitHub provides (or you can use your own) to execute the steps in your workflow. It’s like the machine that actually does the work.

YAML File: The workflow is written in a YAML file, which is just a way to organize all these instructions in a text file. This file lives in your repository, usually in the .github/workflows/ directory.



In action Here’s how a workflow might look:

Trigger: Whenever you push code to the main branch;

Job 1: Test the Code: Run tests to make sure everything is working.

Job 2: Build the Site: If the tests pass, build the website.

Job 3: Deploy: Once the site is built, deploy it to your hosting service.

This entire process is automated by GitHub Actions, so once you set it up, you don’t have to manually do these tasks every time.


### This the clsassic template of an Example Workflow

```yaml
name: Deploy to EKS

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Set up Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}

    - name: Terraform Init
      run: terraform init
      working-directory: ./terraform

    - name: Terraform Apply
      run: terraform apply --auto-approve
      working-directory: ./terraform

    - name: Configure AWS Credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-west-1

    - name: Update kubeconfig
      run: aws eks update-kubeconfig --name socks-shop-EMAPCH75 --region us-west-1

    - name: Install Helm
      run: |
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
        helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx/
        helm repo update

    - name: Deploy Application with Helm
      run: |
        helm install capstoneapp app --namespace sock-shop
        helm install ingress-nginx ingress-nginx/ingress-nginx --namespace sock-shop
        helm install prometheus prometheus-community/kube-prometheus-stack --namespace sock-shop

    - name: Apply Ingress Configuration
      run: kubectl apply -f ingress.yml

Explanation

Checkout Code: Fetches your code from the repository.

Setup Terraform: Initializes and applies Terraform scripts to provision infrastructure (EKS cluster, networking, etc.).

AWS Credentials: Configures AWS credentials to interact with EKS.

Update kubeconfig: Updates the Kubernetes configuration file to manage the EKS cluster.

Install Helm: Adds necessary Helm repositories and updates them.

Deploy Application: Deploys the Socky app, Nginx ingress, and monitoring tools using Helm.

Apply Ingress: Configures the ingress resources to expose the application to the internet.

```
## Step 2: Setup Secrets in GitHub

Secrets and Variables are very vital in github actions and git-ops. It provides are secure wauy of storing private authetication data nd passwords in a github secure vault and passed as into your workflow like a library. 


For this project we will add the following secrets to the GitHub repository:

AWS_ACCESS_KEY_ID: user AWS IAM access key.
AWS_SECRET_ACCESS_KEY: user AWS IAM secret access key.
TF_API_TOKEN: Token for Terraform (if using Terraform Cloud).

These secrets allow GitHub Actions to securely interact with your AWS account and other services.


![github secrets](./Images/github%20secrets.png)

<br>

![github secrets 2](./Images/github%20secrets%202.png)


## Step 3: Trigger the Pipeline

After writing your manifest files and placing them in the correct branches of your repository, the workflow will then be triggered. 
The workflow pipeline is automatically triggered whenever there’s a push to the main branch. This automation ensures that your application is always up-to-date and running with the latest changes.


## Step 4: Monitor the Deployment

After triggering the pipeline, you can monitor the deployment progress in the "Actions" tab of your GitHub repository. Any issues or errors encountered during the process will be logged here, providing insights for troubleshooting.


This CI/CD pipeline setup automates the deployment of the SOCK SHOP app, ensuring a consistent and reliable process for getting changes into production.


Below are picture evidence of my work flow deployment:
<br>

![Successful deployment of cicd pipeline](./Images/Github%20Actions%20CICD.png)


<br>

![cluster created via cicd pipeline](./Images/cluster%20created%20via%20cicd%20pipeline.png)

<br>

![EC2 instanced created by pipeline](./Images/EC2%20instanced%20created%20by%20pipeline.png)

<br>

![terrafom state files on cicd s3 bucket](./Images/terrafom%20state%20files%20on%20cicd%20s3%20bucket.png)

<br>

![s3 bucket on cicd infastructure](./Images/s3%20bucket%20on%20cicd%20infastructure.png)
















