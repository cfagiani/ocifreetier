variable "tenancy_ocid" {
  type        = string
  description = "tenancy OCID"
}

variable "compartment_ocid" {
  type        = string
  description = "Compartment ID in which all the resources in this module will be created"
}

variable "name" {
  type        = string
  description = "Name to use for the compute hosts"
}

variable "host_subnet_ocid" {
  type        = string
  description = "OCID of subnet in which hosts should reside"
}

variable "bastion_subnet_ocid" {
  type        = string
  description = "OCID of subnet in which bastion should reside"
}
