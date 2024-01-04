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

  ### Instance Requirements
  - 1 EC2 T2 Large (Jenkins & Argo)
  - 1 EC2 T2 Medium (EKS Cluster for 1 Node)
  - 1 EC2 T2 Medium (Grafana, Prometheus & ELK)

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

 ### **Phase 2: Configure Jenkins EC2 Instance** 
 - SSH to Jenkins instance public IP which you can in AWS instance.
 - Execute these commands to check the installed packages:
   
```bash
    trivy --version
 ```

```bash
    docker --version
 ```

```bash
   aws --version
 ```

```bash
   terraform --version
 ```

```bash
   kubectl version
 ```
- Check if the sonar is running in a container

  To access: 
  publicIP:9000 (by default username & password is admin)
  
```bash
   docker ps
 ```

 ### **Configure Jenkins Application** 
  
  To access jenkins: 
  publicIP:8080 

  To jenkins password:
  
  ```bash
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
 ```
 - Install recommended plugins and skip the creation of user
 - Go to Manage Jenkins > Plugins > Available Plugins > Search 'Terraform' > Update the selected plugins
 - Go back to Manage Jenkins > Tools > Terraform Installations
    use this path '/usr/bin/' in the Install Directory
 - Apply and Save
 - Create an item pipeline for EKS Cluster provisioning > check the 'This projects is parameterized'
    Name: 'action'
    Choices: 'apply'
             'destroy'
 - Apply and Save
 - Use the JenkinsFile from 'eks-terraform' folder. You can use the JenkinsFile or copy the contents to pipeline script section.
 - Once saved, click the 'Build with Parameters' > action 'apply' > Build
 - If the pipeline is successful, you can check now the resources created in the AWS Console for your EKS Cluster.
 - If the pipeline is failed, please check the console output and see the root cause of the errors.
   
 ### **Install Additional Plugins for Jenkins Application** 
 - Go to Manage Jenkins > Plugins > Available Plugins > Search and check these plugins
    - Eclipse Temurin Installer (Java 17)
    - Sonarqube Scanner
    - NodeJs
    - Owasp Dependency-Check
    - Docker
    - Docker Commons
    - Docker Pipeline
    - Docker API
    - Docker-build-step
 - After the installation of the plugins, go to Manage Jenkins > Tools > Tick all 'Install Automatically'
    - Configure JDK17 (install from adoptium.net)
    - Configure NodeJs use version 16.2.0
    - Configure Sonarqube use latest version
    - Configure Dependency-Check use version 6.5.1
    - Configure Docker use the latest version
    *** Note: Remember name you input because it is case sensitive when you it in the pipeline script.

  ### **Configure Sonar Server in Manage Jenkins**
   - go to your Jenkins EC2 instance, <PublicIP:9000> Administration > Security > Users > Tokens and Update Token > Generate a token for the Admin User
   - copy the token, then go back to Jenkins Application > Manage Jenkins > Credentials > Add Secret Text
      - Secret: paste the token here
      - ID: sonar-token
      - Description: sonar-token
   - Create a webhook for the jenkins, go to Administration > Configuration > Webhooks > Create
      - Name: Jenkins
      - URL: <http://jenkins-public-ip:8080>/sonarqube-webhook/
   - go to Jenkins Application Dashboard > Manage Jenkins > System (to add the SonarQube Server in Jenkins System)
      - Name: sonar-server
      - Server URL: http://<publicIP.:9000
      - Token: choose 'sonar-token'
   - Apply and Save
   - Create another credential for your docker account, Manage Jenkins > Credentials > Global > Add Credential > Add Username and Password
      - Username: ipau
      - Password: xxxxxxxxxx
      - ID: docker
      - Desc: docker
    - go back to Dashboard and create a pipeline for your Tetris application
      - either use the JenkinsFile from 'jenkins-terraform' folder or copy the contents and paste in the pipeline script.
      - comment out these stages first, stage('Checkout Deployment Manifest') &  stage('Update Deployment File'). Since we haven't configure the EKS cluster and install ARGO CD.
    - Then build the pipeline, if the pipeline is successful it will build, scan, create docker image and push to your dockerhub and scan again the image.
    
   ### **Configure EKS Cluster in Jenkins EC2 Instance**
   - to update the kube-config, execute these commands
   - make sure to check your terraform files and see the configuration for EKS Cluster
   
   ```bash
      aws eks update-kubeconfig --name TETRIS_EKS_CLOUD --region ap-southeast-1
   ```
