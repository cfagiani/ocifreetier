output "vcn_id" {
  value = oci_core_virtual_network.vcn.id
}

output "public_subnet_ocid" {
  value = oci_core_subnet.public_subnet.id
}

output "private_subnet_ocid" {
  value = oci_core_subnet.private_subnet.id
}

output "bastion_subnet_ocid" {
  value = oci_core_subnet.bastion_subnet.id
}