variable "tenancy_ocid" {
  type        = string
  description = "OCID for your tenancy"

  validation {
    condition     = length(var.tenancy_ocid) > 14 && substr(var.tenancy_ocid, 0, 14) == "ocid1.tenancy."
    error_message = "Please provide a valid value for variable tenancy_ocid."
  }
}

variable "parent_compartment_ocid" {
  type        = string
  description = "OCID for root compartment for everything created by terraform"

  validation {
    condition     = length(var.parent_compartment_ocid) > 6 && substr(var.parent_compartment_ocid, 0, 6) == "ocid1."
    error_message = "Please provide a valid value for variable parent_compartmenr_ocid."
  }
}



variable "home_region" {
  type        = string
  description = "region identifier for the tenancy's home region."

  validation {
    condition     = var.home_region != null && length(var.home_region) > 0
    error_message = "Please provide a valid value for variable home_region"
  }
}


variable "oci_profile_name" {
  type        = string
  description = "Name of the profile in your oci config file"
  default     = "DEFAULT"
}