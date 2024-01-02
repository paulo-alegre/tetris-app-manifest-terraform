# Tetris-DevSecOps-Pipeline Project

## Tools used in this project
- Jenkins
- SonarQube
- Trivy
- OWASP
- Grafana
- Prometheus
- Terraform
- Git
- Docker
- Argo CD
- AWS CLI
- AWS Services (EC2, S3, EKS Cluster, IAM User, Role & Policy)

## PRE-REQUISITE Requirements
- Create an IAM User and attach a policy (AdministratorAccess)
- Create an access key for this user and download the .csv file
- Create an S3 bucket where we will store the terraform states.
- Install AWS CLI -> https://docs.aws.amazon.com/cli/latest/userguide/getting-started-version.html
- Open a terminal and configure it

 ```bash
    aws configure
 ```
- set the access key, secret access key, region
- then install Terraform -> https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
 
 ```bash
    terraform --version
 ```
- clone the tetris application version 1 repository
  
```bash
    git clone https://github.com/paulo-alegre/tetris-v1-app.git
 ```
- clone the tetris application version 2 repository
  
```bash
    git clone https://github.com/paulo-alegre/tetris-v2-app.git
 ```

### **Phase 1: Infrastructure Provisioning**
- Clone the terraform and manifest repository

```bash
    git clone https://github.com/paulo-alegre/tetris-app-manifest-terraform.git
 ```
- go to folder 'jenkins-terraform' and start executing these commands:

 ```bash
    terraform init
 ```

 ```bash
    terraform validate
 ```

 ```bash
    terraform plan
 ```

 ```bash
    terraform apply
 ```
- After completion of the apply, go and check the created AWS resources in your console.
