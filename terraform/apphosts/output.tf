output "instance_ids" {
  value = oci_core_instance.a1_instance.*.id
}