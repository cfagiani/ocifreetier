provider "oci" {
  region              = var.home_region
  auth                = "SecurityToken"
  config_file_profile = var.oci_profile_name
}



resource "oci_identity_compartment" "dataplane_compartment" {
  compartment_id = var.parent_compartment_ocid
  description    = "compartment for all infrastructure resources in data plane"
  name           = "dataplane-compartment"
}


module "db" {
  source           = "./db"
  name             = "appdb"
  compartment_ocid = oci_identity_compartment.dataplane_compartment.id
}


module "hostingvcn" {
  source           = "./vcn"
  name             = "app hosting"
  dns_label        = "app"
  compartment_ocid = oci_identity_compartment.dataplane_compartment.id
}


module "apphosts" {
  source              = "./apphosts"
  name                = "app hosting"
  tenancy_ocid        = var.tenancy_ocid
  compartment_ocid    = oci_identity_compartment.dataplane_compartment.id
  host_subnet_ocid    = module.hostingvcn.private_subnet_ocid
  bastion_subnet_ocid = module.hostingvcn.bastion_subnet_ocid
}


module "loadbalancer" {
  source               = "./loadbalancer"
  compartment_ocid     = oci_identity_compartment.dataplane_compartment.id
  subnet_ocid          = module.hostingvcn.public_subnet_ocid
  backend_instance_ids = module.apphosts.instance_ids
  name                 = "app-nlb"
}

