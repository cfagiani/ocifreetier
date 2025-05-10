variable "compartment_ocid" {
  type        = string
  description = "Compartment ID in which all the resources in this module will be created"
}

variable "name" {
  type        = string
  description = "Name to use for the vcn"
}

variable "dns_label" {
  type        = string
  description = "DNS label for the vcn"
}