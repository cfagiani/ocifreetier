variable "compartment_ocid" {
  type        = string
  description = "Compartment for the load balancer"
}

variable "subnet_ocid" {
  type        = string
  description = "Subnet for the load balancer"
}

variable "backend_instance_ids" {
  type        = list(string)
  description = "Instance OCIDs for the hosts that are the backends for the load balancer"
}

variable "name" {
  type        = string
  description = "Name for the load balancer"
}