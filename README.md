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

   - to check the nodes, enter this command:
     
     ```bash
      kubectl get nodes
     ```
     
      ### ARGO CD SETUP
      - to install ArgoCD, use this link for installation guide https://archive.eksworkshop.com/intermediate/290_argocd/install/
      - then execute these commands to create namespace

       ```bash
        kubectl create namespace argocd
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.7/manifests/install.yaml
       ```
      - By default, argocde-server is not publicly exposed, but for this project we will use a load balancer service.

      ```bash
        kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
      ```

      - Wait for about 2 minutes to create the Load Balancer. Then install jq so we export the ArgoCD server

     ```bash
        sudo apt install jq -y
      ```

     ```bash
        export ARGOCD_SERVER=`kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`
      ```

     ```bash
        echo $ARGOCD_SERVER
      ```

     - for the password of the ARGOCD, you can get it by executing these commands:

     ```bash
        echo $ARGO_PWD
      ```
     
      ```bash
        echo $ARGOCD_SERVER
      ```

       ### ARGO CD Configuration
       - Manage your repositories Project Settings > Repositories > Connect Repo Using HTTPS
         - Type: git
         - Project: default
         - Repo URL: https://github.com/paulo-alegre/tetris-app-manifest-terraform.git
       - Test your connection
       - Click on Manage Your Application > New App, then provide the image details
         - Application Name: tetris
         - Project Name: default
         - Sync Policy: Automatic
         - Source: https://github.com/paulo-alegre/tetris-app-manifest-terraform.git
         - Revision: HEAD
         - Path: ./
         - Destination: https://kubernetes.default.svc
         - Namespace: default
      - Click on Create, then it will create your project and create another load balancer.
      - To check if the deployment went well, enter these command:

     ```bash
        kubectl get all
      ```

     ### **Configure Grafana and Prometheus EC2 Instance**

     Create a systemd unit configuration file for Prometheus:

     ```bash
     sudo vi /etc/systemd/system/prometheus.service
     ```
  
     Add the following content to the `prometheus.service` file:
  
     ```plaintext
     [Unit]
     Description=Prometheus
     Wants=network-online.target
     After=network-online.target
  
     StartLimitIntervalSec=500
     StartLimitBurst=5
  
     [Service]
     User=prometheus
     Group=prometheus
     Type=simple
     Restart=on-failure
     RestartSec=5s
     ExecStart=/usr/local/bin/prometheus \
       --config.file=/etc/prometheus/prometheus.yml \
       --storage.tsdb.path=/data \
       --web.console.templates=/etc/prometheus/consoles \
       --web.console.libraries=/etc/prometheus/console_libraries \
       --web.listen-address=0.0.0.0:9090 \
       --web.enable-lifecycle
  
     [Install]
     WantedBy=multi-user.target
     ```
  
     Here's a brief explanation of the key parts in this `prometheus.service` file:
  
     - `User` and `Group` specify the Linux user and group under which Prometheus will run.
  
     - `ExecStart` is where you specify the Prometheus binary path, the location of the configuration file (`prometheus.yml`), the storage directory, and other settings.
  
     - `web.listen-address` configures Prometheus to listen on all network interfaces on port 9090.
  
     - `web.enable-lifecycle` allows for management of Prometheus through API calls.
  
     Enable and start Prometheus:
  
     ```bash
     sudo systemctl enable prometheus
     sudo systemctl start prometheus
     ```
  
     Verify Prometheus's status:
  
     ```bash
     sudo systemctl status prometheus
     ```
  
     You can access Prometheus in a web browser using your server's IP and port 9090:
  
     `http://<your-server-ip>:9090`

     **Installing Node Exporter:**
     
      Create a systemd unit configuration file for Node Exporter:

     ```bash
     sudo vi /etc/systemd/system/node_exporter.service
     ```
  
     Add the following content to the `node_exporter.service` file:
  
     ```plaintext
     [Unit]
     Description=Node Exporter
     Wants=network-online.target
     After=network-online.target
  
     StartLimitIntervalSec=500
     StartLimitBurst=5
  
     [Service]
     User=node_exporter
     Group=node_exporter
     Type=simple
     Restart=on-failure
     RestartSec=5s
     ExecStart=/usr/local/bin/node_exporter --collector.logind
  
     [Install]
     WantedBy=multi-user.target
     ```
  
     Replace `--collector.logind` with any additional flags as needed.
  
     Enable and start Node Exporter:
  
     ```bash
     sudo systemctl enable node_exporter
     sudo systemctl start node_exporter
     ```
  
     Verify the Node Exporter's status:
  
     ```bash
     sudo systemctl status node_exporter
     ```
  
     You can access Node Exporter metrics in Prometheus.

     **Configure Prometheus Plugin Integration:**

     Integrate Jenkins with Prometheus to monitor the CI/CD pipeline.

     **Prometheus Configuration:**
  
     To configure Prometheus to scrape metrics from Node Exporter and Jenkins, you need to modify the `prometheus.yml` file. Here is an example `prometheus.yml` configuration for your setup:
  
     ```yaml
     global:
       scrape_interval: 15s
  
     scrape_configs:
       - job_name: 'node_exporter'
         static_configs:
           - targets: ['localhost:9100']
  
       - job_name: 'jenkins'
         metrics_path: '/prometheus'
         static_configs:
           - targets: ['<your-jenkins-ip>:<your-jenkins-port>']
     ```
  
     Make sure to replace `<your-jenkins-ip>` and `<your-jenkins-port>` with the appropriate values for your Jenkins setup.
  
     Check the validity of the configuration file:
  
     ```bash
     promtool check config /etc/prometheus/prometheus.yml
     ```
  
     Reload the Prometheus configuration without restarting:
  
     ```bash
     curl -X POST http://localhost:9090/-/reload
     ```
  
     You can access Prometheus targets at:
  
     `http://<your-prometheus-ip>:9090/targets`

     ####Grafana

      **Install Grafana on Ubuntu 22.04 and Set it up to Work with Prometheus**

       ** Access Grafana Web Interface:**

        Open a web browser and navigate to Grafana using your server's IP address. The default port for Grafana is 3000. For example:
        
        `http://<your-server-ip>:3000`
        
        You'll be prompted to log in to Grafana. The default username is "admin," and the default password is also "admin."
        
        **Step 8: Change the Default Password:**
        
        When you log in for the first time, Grafana will prompt you to change the default password for security reasons. Follow the prompts to set a new password.
        
        **Step 9: Add Prometheus Data Source:**
        
        To visualize metrics, you need to add a data source. Follow these steps:
        
        - Click on the gear icon (⚙️) in the left sidebar to open the "Configuration" menu.
        
        - Select "Data Sources."
        
        - Click on the "Add data source" button.
        
        - Choose "Prometheus" as the data source type.
        
        - In the "HTTP" section:
          - Set the "URL" to `http://localhost:9090` (assuming Prometheus is running on the same server).
          - Click the "Save & Test" button to ensure the data source is working.
        
        **Import a Dashboard:**
        
        To make it easier to view metrics, you can import a pre-configured dashboard. Follow these steps:
        
        - Click on the "+" (plus) icon in the left sidebar to open the "Create" menu.
        
        - Select "Dashboard."
        
        - Click on the "Import" dashboard option.
        
        - Enter the dashboard code you want to import (e.g., code 1860).
        
        - Click the "Load" button.
        
        - Select the data source you added (Prometheus) from the dropdown.
        
        - Click on the "Import" button.
        
        You should now have a Grafana dashboard set up to visualize metrics from Prometheus.
        
        Grafana is a powerful tool for creating visualizations and dashboards, and you can further customize it to suit your specific monitoring needs.
     
