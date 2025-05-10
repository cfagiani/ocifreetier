# OCI Free-Tier Environment

This repository contains terraform code to create a simple application hosting environment using only resources
available in the OCI "Always Free" offering. It will create the following:

A single Virtual Cloud Network (VCN) that contains 3 subnets:

* public subnet - subnet into which a Network Load Balancer (NLB) will be provisioned. This subnet will be configured to
  accept incoming HTTP/HTTPS requests on ports 80/443 from the internet.
* bastion subnet - subnet into which a Bastion (using the OCI Bastion service) will be provisioned. This subnet will
  allow incoming SSH connections from the internet and will only be able to connect to the private subnet via SSH
* private subnet - subnet into which 2 VM instances will be provisioned. This subnet will allow incoming traffic from
  ports 80 and 443 from the public subnet as well as incoming ssh traffic on port 22 from the bastion subnet

The NLB will be configured with 2 listeners: one on port 443 and one on port 80. Both listeners will have backend sets
that include both VM instances. The health check is initially configured using a simple TCP connection.

The 2 VMs use an Ampere A1 ARM shape each configured with 2 OCPUs and 12 GB of RAM. They are configured via a cloud-init
script that is run on first boot. The cloud init does the following:

* installs Podman
* installs the OCI CLI
* configures the host firewall to allow incoming connections on ports 80 and 443

In addition to the resources above, an Autonomous Database instance will also be provisioned. While normally this should
be set up to use a private endpoint, that option is not available for "always free" instances, thus the DB is set up to
allow connections from anywhere.

The database uses a randomly generated string as the admin password. *NOTE: This password will show up in your terraform
state file. You should change the password after creation.*

This entire repo is meant to be a template and should be customized for specific application purposes.

### Setup
#### Pre-requisites:
* terraform (version 0.11.0 or greater)
* oci tenancy
* oci CLI set up

#### Tenancy Preparation
* subscribe to the desired region
* create an object storage bucket to use for the terraform state files
* Generate a "customer secret key" via the OCI console in your preferences. This is used for the S3 compatibility mode in
object storage (so we can use the s3 backend for terraform). Put this in .aws/credentials. File should look like:
```
[default]
aws_access_key_id=< KEY ID OBTAINED FROM OCI CONSOLE>
aws_secret_access_key=< KEY VALUE OBTAINED FROM OCI CONSOLE ON CREATION>
request_checksum_calculation=when_required
response_checksum_validation=when_required
```

#### Terraform Setup

Prior to running, log into oci via
```oci session authenticate``` (this will add the profile entry to your .oci/config file)
otherwise you can refresh the session token by running any command. For instance
```oci os ns get``` (to get your object storage namespace)

Create a variables file in the terraform directory (myenv.tfvars) that contains the following:

```
tenancy_ocid = <YOUR TENANCY OCID>
home_region = <TENANCY HOME REGION>
parent_compartment_ocid = <ROOT COMPARMENT UNDER WHICH EVERYTHING SHOULD BE CREATED>
oci_profile_name =  <NAME OF PROFILE IN OCI CONFIG FILE>
```

*NOTE: root compartment can be the tenancy OCID if you want everything to be created under the root*

Create a file called state.tf with the following values:

```
terraform{
 backend "s3" {
    bucket                    = "<BUCKET NAME YOU WANT TO USE TO STORE STATE>"
    region                    = "<REGION IN WHICH YOU WANT TO STORE STATE>"
    key                       = "<OBJECT NAME FOR STATEFILE>>"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    use_path_style              = true
    skip_s3_checksum            = true
    skip_metadata_api_check = true
    endpoints = {
        s3 = "https://<YOUR OBJECT STORAGE NAMESPACE>.compat.objectstorage.<YOUR REGION>.oraclecloud.com"
    }
  }
}
````

#### Deploying the Infrstructure

1. initialize terraform

```
terraform init
```

2. plan and deploy

```
terraform plan -var-file freetier.tfvals
terraform apply -var-file freetier.tfvals
```

NOTE: there seems to be a terraform bug that dis-associates the reserved public ip from the private ip. Manually fix with

```
oci network public-ip update --public-ip-id <publicIpOCID> --private-ip-id <privateIPOCID>
```
if needed, get the private ip ocid via

```
oci network private-ip list --subnet-id <public subnet ocid>
```


### Using the Infrastructure
Once the plan has completed, the environment is ready for use. You cannot directly SSH into the hosts, but instead must go through the bastion. You can do this by 
creating a Bastion session (either in the OCI Console or via the CLI) and then using it as a jump host in the SSH command... for instance:

The syntax for that is 
```
ssh -J <BASTION_SESSION_OCID>@host.bastion.<REGION>.oci.oraclecloud.com opc@<VM PRIVATE IP>
```
for instance:
```
 ssh -J ocid1.bastionsession.oc1.us-chicago-1.amaaaaaafb7qzgqaoevqycqnb4zhuslr7xmm6zubm4lc3f6fs3m24dfeeaaa@host.bastion.us-ashburn-1.oci.oraclecloud.com opc@10.0.2.111
```
Sessions are only valid for a limited time (3 hours).