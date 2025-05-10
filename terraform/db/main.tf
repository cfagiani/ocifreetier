# this is only here to prevent terraform from also importing the depricated hashicorp/oci provider
terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">=6.0.0"
    }
  }
}

resource "random_string" "password" {
  length           = 16
  special          = true
  min_special      = 2
  min_numeric      = 2
  override_special = "#"
}

resource "oci_database_autonomous_database" "adb" {
  compartment_id = var.compartment_ocid
  db_name        = var.name
  display_name   = "${var.name}-adb"
  cpu_core_count = 0 # this value is ignored since we're create an "always free" db      
  db_workload    = "OLTP"
  admin_password = random_string.password.result
  db_version     = "23ai"
  is_free_tier   = true
  license_model  = "LICENSE_INCLUDED"

}