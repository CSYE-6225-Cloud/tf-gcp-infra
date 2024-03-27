# CSYE-6225-Assignment-7

# Steps to setup Google Cloud Platfrom (GCP) :

1. Setup a billing account
2. Install google cloud CLI and set the path of it in home directory's bin
   command: export PATH=$PATH:/Users/payalkhatri/google-cloud-sdk/bin
3. gcloud auth login and gcloud auth application-default login
   command: gcloud auth application-default login
4. gcloud config set project
   command to list projects: gcloud projects list
   command to initalise cli and then create a config file: gcloud init
5. Create GCP project
   command: gcloud projects create csye6225-a03
6. Set zone and region
   command : gcloud compute project-info add-metadata \
   --metadata google-compute-default-region=us-east4,google-compute-default-zone=us-east4-c

# Steps to setup infrastructure using terrafrom :

1. Mention provider - Google
2. Create VPC using google_compute_network. Make auto_create_subnetworks as false to not create subnetworks automatically and delete_default_routes_on_create as true to delete default routes which are created on terraform apply
3. Create subnets webapp and db using google_compute_subnetwork
4. Create route using google_compute_route
5. Define variables in variables.tf and their values in terraform.tfvars
6. Initialise terraform
   command : terraform init
7. Format terraform files
   command: terraform fmt
8. Validate terraform
   command: terraform validate
9. Create terraform plan
   command: terraform plan
10. Apply terraform
    command: terraform apply
11. Destroy terraform
    command: terraform destroy

APIs that are enabled:
NAME TITLE

1. compute.googleapis.com Compute Engine API
2. oslogin.googleapis.com Cloud OS Login API


# Added Firewall rules:
1. To allow traffic from the internet to the webapp application port 3001. 
2. To not allow traffic to SSH port (22) from the internet.
3. Added firewall rule to allow vpc connector to the database instance 

# Project Progression: 

1. Created a VPC
2. Created a subnet inside the vpc for webapp instance
3. Created a google compute instance for the webapp
4. Created a database instance inside GCP's VPC and created database, user, password in it
5. Connected webapp instance with this database
6. Added a new service account for roles related to cloud function. Total there are 2 service accounts 
   a. Service account for webapp - roles: logging, monitoring and pubsub
   b. Service account for cloud function - roles: run.invoke 
7. Added pubsub subscriber which would push the topic messages to the cloud function
8. Removed storage bucket and object as they would be added manually and added data instead
9. Added appropriate cloud service account to the function
