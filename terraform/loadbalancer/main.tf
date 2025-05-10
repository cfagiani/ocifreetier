# this is only here to prevent terraform from also importing the depricated hashicorp/oci provider
terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">=6.0.0"
    }
  }
}

locals {
  preserve_source = false
}


resource "oci_core_public_ip" "nlb_public_ip" {
  compartment_id = var.compartment_ocid
  lifetime       = "RESERVED"
  display_name   = "nlb-public-ip"
  lifecycle {
    # manually associate the private IP of the NLB with this public IP using the CLI.
    ignore_changes = [
      private_ip_id,
    ]
  }
}


# Create a network load balancer in the public subnet
resource "oci_network_load_balancer_network_load_balancer" "nlb" {
  compartment_id                 = var.compartment_ocid
  subnet_id                      = var.subnet_ocid
  display_name                   = var.name
  is_preserve_source_destination = local.preserve_source
  is_private                     = false
  reserved_ips {
    id = oci_core_public_ip.nlb_public_ip.id
  }
}

# Create a backend set for the network load balancer
resource "oci_network_load_balancer_backend_set" "https_backendset" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb.id
  name                     = "https_backendset"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = local.preserve_source

  health_checker {
    protocol = "TCP"
    port     = 443
  }
}

resource "oci_network_load_balancer_backend_set" "http_backendset" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb.id
  name                     = "http_backendset"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = local.preserve_source

  health_checker {
    protocol = "TCP"
    port     = 80
  }
}


# Create a listener for the network load balancer
resource "oci_network_load_balancer_listener" "https_listener" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb.id
  name                     = "https_listener"
  protocol                 = "TCP"
  port                     = 443
  default_backend_set_name = oci_network_load_balancer_backend_set.https_backendset.name
}

resource "oci_network_load_balancer_listener" "http_listener" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb.id
  name                     = "http_listener"
  protocol                 = "TCP"
  port                     = 80
  default_backend_set_name = oci_network_load_balancer_backend_set.http_backendset.name
}

# Get the private IP addresses of the instances
data "oci_core_vnic_attachments" "instance_vnics" {
  count = 2

  instance_id    = var.backend_instance_ids[count.index]
  compartment_id = var.compartment_ocid
}

data "oci_core_vnic" "instance_vnic" {
  count = 2

  vnic_id = data.oci_core_vnic_attachments.instance_vnics[count.index].vnic_attachments[0].vnic_id
}

data "oci_core_private_ips" "target_instance_ips" {
  count   = 2
  vnic_id = data.oci_core_vnic_attachments.instance_vnics[count.index].vnic_attachments[0].vnic_id
  #ip_address = data.oci_core_vnic.instance_vnic[count.index].private_ip_address

}

# Create backend servers for the network load balancer
resource "oci_network_load_balancer_backend" "https_backend" {
  count = 2

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb.id
  backend_set_name         = oci_network_load_balancer_backend_set.https_backendset.name
  ip_address               = data.oci_core_vnic.instance_vnic[count.index].private_ip_address
  port                     = 443
  target_id                = data.oci_core_private_ips.target_instance_ips[count.index].private_ips[0].id
  name                     = "${data.oci_core_vnic.instance_vnic[count.index].private_ip_address}:443"
}

resource "oci_network_load_balancer_backend" "http_backend" {
  count = 2

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb.id
  backend_set_name         = oci_network_load_balancer_backend_set.http_backendset.name
  ip_address               = data.oci_core_vnic.instance_vnic[count.index].private_ip_address
  port                     = 80
  target_id                = data.oci_core_private_ips.target_instance_ips[count.index].private_ips[0].id
  name                     = "${data.oci_core_vnic.instance_vnic[count.index].private_ip_address}:80"
}
