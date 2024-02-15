CSYE-6225-Assignment-3

Steps to setup Google Cloud Platfrom (GCP) :

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

Steps to setup infrastructure using terrafrom :

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
