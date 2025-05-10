terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">=6.0.0"
    }
  }
  required_version = ">= 1.11.0"
}
