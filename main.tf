locals {
  # A user-defined policy OCID always wins; otherwise resolve an Oracle-managed
  # policy by name. backup_policy = "none" with no backup_policy_id opts out.
  lookup_backup_policy = var.backup_policy_id == null && var.backup_policy != "none"
  assign_backup_policy = var.backup_policy_id != null || var.backup_policy != "none"

  backup_policy_id = (
    var.backup_policy_id != null
    ? var.backup_policy_id
    : try(data.oci_core_volume_backup_policies.predefined[0].volume_backup_policies[0].id, null)
  )
}

# Oracle-managed ("predefined") backup policies are global; omitting compartment_id
# returns gold/silver/bronze rather than user-defined policies.
data "oci_core_volume_backup_policies" "predefined" {
  count = local.lookup_backup_policy ? 1 : 0

  filter {
    name   = "display_name"
    values = [var.backup_policy]
  }
}

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

# Without an assignment the volume is never backed up, so `terraform destroy`
# (or any replacement) leaves no recoverable copy of the data. Backups created
# by the policy outlive the volume they were taken from.
resource "oci_core_volume_backup_policy_assignment" "this" {
  count = local.assign_backup_policy ? 1 : 0

  asset_id  = oci_core_volume.this.id
  policy_id = local.backup_policy_id

  lifecycle {
    precondition {
      condition     = var.backup_policy_id == null || var.backup_policy == "none"
      error_message = "Set either backup_policy or backup_policy_id, not both. When supplying a user-defined backup_policy_id, set backup_policy = \"none\"."
    }

    precondition {
      condition     = local.backup_policy_id != null
      error_message = "No Oracle-managed backup policy named \"${var.backup_policy}\" was found."
    }
  }
}

resource "oci_core_volume_attachment" "this" {
  count = var.attach_to_instance_id != null ? 1 : 0

  attachment_type = var.attachment_type
  instance_id     = var.attach_to_instance_id
  volume_id       = oci_core_volume.this.id

  # The two attachment types express in-transit encryption through different
  # fields; setting the wrong one for the type is rejected by the API.
  is_pv_encryption_in_transit_enabled = var.attachment_type == "paravirtualized" ? var.enable_in_transit_encryption : null
  encryption_in_transit_type = (
    var.attachment_type == "iscsi"
    ? (var.enable_in_transit_encryption ? "BM_ENCRYPTION_IN_TRANSIT" : "NONE")
    : null
  )
}
