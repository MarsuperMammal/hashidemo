## hashi-demo

This repository contains code used to satisfy the technical exercise for a Solutions Engineering Candidate. The contained code will utilize Packer, Terraform, Consul and Vault.

### Prerequisites

This code assumes the following:
- An AWS account is available
- API credentials for an IAM user with the Predefined "Admin Access" IAM Policy or equivalent
- API credentials for a Hashicorp's Atlas account.

### Packer


### Terraform

The terraform code in this repo is separated into parts. These parts are:
  - acct
  - network
  - foundation
  - app

In this design, it is intended that each of the above groups of infrastructure be created with their own terraform apply, to create a separate terraform_remote_state file. This is done to ease cross team use of common elements of an AWS deployment, such as IAM configurations, VPCs, and common foundational services where needed.

#### Generating certs and keys
```
cd setup/
gen-key.sh <ENVIRONMENT>
mv <ENVIRONMENT>* secrets
gen-cert.sh <DOMAIN> <COMPANY>
mv *.crt *.csr *.key secrets/
```
#### Provisioning your account and network
```
aws s3api create-bucket --bucket <your_bucket_name> --acl private --region us-east-1
aws s3api put-bucket-versioning --bucket <your_bucket_name> --versioning-configuration Status=Enabled
cd terraform/implementation/acct
terraform remote config -backend=s3 -backend-config="bucket=<your_bucket_name>" -backend-config="key=acct.tfstate"
# Ensure needed values are set in terraform.tfvars
terraform apply
```
```
cd terraform/implementation/network
terraform remote config -backend=s3 -backend-config="bucket=<your_bucket_name>" -backend-config="key=network.tfstate"
# Ensure needed values are set in terraform.tfvars (public_key should = the contents of setup/secrets/<ENVIRONEMNT>.pub)
terraform apply
# Take note of the vpc_id and one public_subnet_id
```
#### Creating Images with Packer
```
cd packer
packer build consul.json
# if launching in an environment without a default vpc:
packer build -var 'vpc_id=<value from network terraform output>' -var 'subnet_id=<value from network
terraform output>' consul.json
# Take Note of the ami-id created
packer build vault.json
# Take Note of the ami-id created
packer build proxy.json
# Take Note of the ami-id created
packer build websvcs.json
# Take Note of the ami-id created

```

#### Provisioning Foundational Services with Terraform
```
cd terraform/implementation/foundation
terraform remote config -backend=s3 -backend-config="bucket=<your_bucket_name>" -backend-config="key=foundation.tfstate"
# Ensure needed values are set in terraform.tfvars (this includes consul and vault ami-ids from Packer)
terraform apply
```


#### Provisioning App with Terraform
```
cd terraform//implementation/<APP_NAME>
terraform remote config -backend=s3 -backend-config="bucket=<your_bucket_name>" -backend-config="key=<APP_NAME>.tfstate"
# Ensure needed values are set in terraform.tfvars (Including ami-id from app packer builds)
terraform apply
```
