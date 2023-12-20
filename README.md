# HOW TO SET STATIC IP ADDRESS ON GOOGLE CLOUD FUNCTION

## Steps to set static IP address on Google Cloud Function


### 1. Create VPC
  
```bash
gcloud services enable compute.googleapis.com
```
This command enables the Compute Engine API, which is required to create and manage virtual machines in Google Cloud Platform (GCP).

```bash
gcloud compute networks create my-vpc \
  --subnet-mode=custom \
  --bgp-routing-mode=regional
```
This command creates a new VPC network called `my-vpc` with custom subnet mode and regional BGP routing mode. A VPC network is a virtual private network that provides networking functionality to GCP resources.

### 2. Create Serverless VPC Access connector

```bash 
gcloud services enable vpcaccess.googleapis.com
```
This command enables the Serverless VPC Access API, which allows you to connect to resources in your VPC network from a serverless environment.

```bash
gcloud compute networks vpc-access connectors create functions-connector \
    --network my-vpc \
    --region asia-southeast1 \
    --range 10.8.0.0/28
```
This command creates a new Serverless VPC Access connector called `functions-connector` in the `my-vpc` network and the `asia-southeast1` region. The connector is assigned a range of IP addresses from `10.8.0.0` to `10.8.0.15`.

NOTE: This step may take a few minutes to complete.

### 3.Grant permission to the connector service account to access the VPC network.

```bash
export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
export PROJECT_NUMBER=$(gcloud projects list --filter="$PROJECT_ID" --format="value(PROJECT_NUMBER)")
```
This command gets the project ID and project number of your project.

```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:service-$PROJECT_NUMBER@gcf-admin-robot.iam.gserviceaccount.com \
  --role=roles/viewer
```
This command grants the Serverless VPC Access connector service account the Viewer role on your project. This role is required to access the VPC network.

```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:service-$PROJECT_NUMBER@gcf-admin-robot.iam.gserviceaccount.com \
  --role=roles/compute.networkUser
```
This command grants the Serverless VPC Access connector service account the Compute Network User role on your project. This role is required to access the VPC network.

### 4. Reserve a static IP address

```bash
gcloud compute addresses create functions-static-ip \
    --region=asia-southeast1
```
This command reserves a static IP address called `functions-static-ip` in the `asia-southeast1` region.

### 5. Create a Cloud router

```bash
gcloud compute routers create my-router \
    --network my-vpc \
    --region asia-southeast1
```
This command creates a Cloud Router called `my-router` in the `my-vpc` network and the `asia-southeast1` region. A Cloud Router is a VPC resource that advertises your VPC network IP addresses to the Google network.

### 6. Create a Cloud NAT

```bash
gcloud compute routers nats create my-cloud-nat-config \
    --router=my-router \
    --nat-external-ip-pool=functions-static-ip \
    --nat-all-subnet-ip-ranges \
    --enable-logging \
    --router-region=asia-southeast1
```
This command creates a Cloud NAT called `my-cloud-nat-config` in the `my-router` router and the `asia-southeast1` region. A Cloud NAT is a VPC resource that allows you to provision your VPC network with outbound NAT gateway to provide internet connectivity to your instances.

### 7. Create a Cloud function

```bash
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
```
This command deploys a Cloud Function called `test-ip` in the `asia-southeast1` region. The Cloud Function is assigned a static IP address from the `functions-static-ip` IP address pool. The Cloud Function is connected to the `functions-connector` Serverless VPC Access connector. The Cloud Function is configured to allow outbound connections to the internet.
