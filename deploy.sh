gcloud functions deploy test-ip \
    --gen2 \
    --runtime=python311 \
    --region=asia-southeast1 \
    --source=./ \
    --entry-point=test_ip \
    --trigger-http \
    --allow-unauthenticated

gcloud functions deploy test-ip-2 \
    --gen2 \
    --runtime=python311 \
    --region=asia-southeast1 \
    --source=./ \
    --entry-point=test_ip_2 \
    --trigger-http \
    --allow-unauthenticated

# Create VPC

gcloud services enable compute.googleapis.com

gcloud compute networks create my-vpc \
    --subnet-mode=custom \
    --bgp-routing-mode=regional

# Create a Serverless VPC Access connectors 
gcloud services enable vpcaccess.googleapis.com

gcloud compute networks vpc-access connectors create functions-connector \
    --network my-vpc \
    --region asia-southeast1 \
    --range 10.8.0.0/28

# Waiting for few minutes...

# Grant Permissions 
export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
export PROJECT_NUMBER=$(gcloud projects list --filter="$PROJECT_ID" --format="value(PROJECT_NUMBER)")

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:service-$PROJECT_NUMBER@gcf-admin-robot.iam.gserviceaccount.com \
  --role=roles/viewer

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:service-$PROJECT_NUMBER@gcf-admin-robot.iam.gserviceaccount.com \
  --role=roles/compute.networkUser

# Reserve static IP
gcloud compute addresses create two-functions-static-ip \
    --region=asia-southeast1

gcloud compute addresses list
# NAME                 ADDRESS/RANGE  TYPE      PURPOSE  NETWORK  REGION           SUBNET  STATUS
# functions-static-ip  34.87.144.47   EXTERNAL                    asia-southeast1          RESERVED

# Creating the Cloud Router
gcloud compute routers create my-router \
    --network my-vpc \
    --region asia-southeast1

# Creating Cloud Nat
gcloud compute routers nats create my-cloud-nat-config \
    --router=my-router \
    --nat-external-ip-pool=functions-static-ip \
    --nat-all-subnet-ip-ranges \
    --enable-logging \
    --router-region=asia-southeast1

# Update (In case that you want to update the Cloud Nat)
gcloud compute routers nats update my-cloud-nat-config \
    --router=my-router \
    --nat-external-ip-pool=functions-static-ip,two-functions-static-ip \
    --nat-all-subnet-ip-ranges \
    --enable-logging \
    --router-region=asia-southeast1

# Test deploy

gcloud functions deploy test-ip \
    --gen2 \
    --runtime=python311 \
    --region=asia-southeast1 \
    --source=./ \
    --entry-point=test_ip \
    --trigger-http \
    --allow-unauthenticated \
    --vpc-connector functions-connector \
    --egress-settings all

gcloud functions deploy test-ip-2 \
    --gen2 \
    --runtime=python311 \
    --region=asia-southeast1 \
    --source=./ \
    --entry-point=test_ip_2 \
    --trigger-http \
    --allow-unauthenticated \
    --vpc-connector functions-connector \
    --egress-settings all
