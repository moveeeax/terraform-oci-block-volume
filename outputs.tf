output "id" {
  description = "OCID of the block volume."
  value       = oci_core_volume.this.id
}

output "size_in_gbs" {
  description = "Size of the block volume in GB."
  value       = oci_core_volume.this.size_in_gbs
}

output "is_hydrated" {
  description = "Whether the volume's data has finished copying from its source."
  value       = oci_core_volume.this.is_hydrated
}

output "attachment_id" {
  description = "OCID of the volume attachment, if the volume was attached."
  value       = try(oci_core_volume_attachment.this[0].id, null)
}

output "backup_policy_id" {
  description = "OCID of the backup policy assigned to the volume, or null if none was assigned."
  value       = one(oci_core_volume_backup_policy_assignment.this[*].policy_id)
}

output "state" {
  description = "Lifecycle state of the block volume."
  value       = oci_core_volume.this.state
}
