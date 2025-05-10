# this is only here to prevent terraform from also importing the depricated hashicorp/oci provider
terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">=6.0.0"
    }
  }
}

# Get the list of Availability Domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}


data "oci_core_images" "autonomous_linux_images" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Create 2 A1 instances in different ADs if available
resource "oci_core_instance" "a1_instance" {
  count = 2

  # put the hosts in different ADs if we're in a region with > 1 AD
  # the +1 is just to get around an Out of Host Capacity issue in AD1
  availability_domain = element(data.oci_identity_availability_domains.ads.availability_domains.*.name, count.index + 1 % length(data.oci_identity_availability_domains.ads.availability_domains))
  compartment_id      = var.compartment_ocid
  display_name        = "${var.name}-${count.index + 1}"
  shape               = "VM.Standard.A1.Flex"

  # Adjust OCPU and memory as needed
  shape_config {
    ocpus         = 2
    memory_in_gbs = 12
  }

  create_vnic_details {
    subnet_id        = var.host_subnet_ocid
    assign_public_ip = "false"
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.autonomous_linux_images.images[0].id
  }

  metadata = {
    ssh_authorized_keys = file("~/.ssh/id_rsa.pub")
    user_data           = base64encode(file("${path.module}/../../setup/setup.sh"))
  }

  agent_config {
    plugins_config {
      desired_state = "ENABLED"
      name          = "Bastion"
    }
  }
}


resource "oci_bastion_bastion" "bastion" {
  bastion_type                 = "STANDARD"
  compartment_id               = var.compartment_ocid
  target_subnet_id             = var.bastion_subnet_ocid
  client_cidr_block_allow_list = ["0.0.0.0/0"]
  name                         = "appbastion"
}