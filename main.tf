resource "oci_core_volume" "this" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  display_name        = var.display_name
  size_in_gbs         = var.size_in_gbs
  vpus_per_gb         = var.vpus_per_gb
  kms_key_id          = var.kms_key_id

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_volume_attachment" "this" {
  count = var.attach_to_instance_id != null ? 1 : 0

  attachment_type = var.attachment_type
  instance_id     = var.attach_to_instance_id
  volume_id       = oci_core_volume.this.id
}
