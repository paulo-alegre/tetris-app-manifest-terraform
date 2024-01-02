# Tetris-DevSecOps-Pipeline Project

## Tools used in this project
- Jenkins (Port 8080)
- SonarQube (Port 9000)
- Trivy
- OWASP
- Grafana (Port 3000)
- Prometheus (Port 9090)
- Terraform
- Node Export (Port 9100)
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
- These resources will be created EC2 instance with Security group, IAM role with policy attachment & IAM instance profile
- And security group should contain inbound rule to open these ports: 80, 443, 22, 8080, 9000, 3000

 ### **Phase 1a: Infrastructure Provisioning** 
 - go to folder 'grafana-prometheus-terraform' and start executing these commands:

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
