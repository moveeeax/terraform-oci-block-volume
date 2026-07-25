variable "compartment_id" {
  description = "OCID of the compartment in which to create the block volume."
  type        = string
}

variable "availability_domain" {
  description = "Name of the availability domain in which to create the volume."
  type        = string
}

variable "display_name" {
  description = "Human-readable name for the block volume."
  type        = string
}

variable "size_in_gbs" {
  description = "Size of the block volume in GB. OCI accepts whole numbers from 50 to 32768 and rejects anything outside that at apply time."
  type        = number
  default     = 50

  validation {
    condition     = var.size_in_gbs >= 50 && var.size_in_gbs <= 32768 && floor(var.size_in_gbs) == var.size_in_gbs
    error_message = "size_in_gbs must be a whole number between 50 and 32768."
  }
}

variable "vpus_per_gb" {
  description = "Volume performance in VPUs per GB (0 = Lower Cost, 10 = Balanced, 20 = Higher Performance, 30-120 = Ultra High Performance)."
  type        = number
  default     = 10

  validation {
    condition     = var.vpus_per_gb >= 0 && var.vpus_per_gb <= 120 && var.vpus_per_gb % 10 == 0
    error_message = "vpus_per_gb must be a multiple of 10 between 0 and 120."
  }
}

variable "kms_key_id" {
  description = "OCID of the KMS key used to encrypt the volume. Null uses Oracle-managed encryption."
  type        = string
  default     = null
}

variable "backup_policy" {
  description = "Oracle-managed backup policy to assign to the volume: \"gold\", \"silver\", \"bronze\", or \"none\" to opt out. A volume with no backup policy has no recoverable copy once it is deleted."
  type        = string
  default     = "bronze"

  validation {
    condition     = contains(["gold", "silver", "bronze", "none"], var.backup_policy)
    error_message = "backup_policy must be one of: gold, silver, bronze, none."
  }
}

variable "backup_policy_id" {
  description = "OCID of a user-defined backup policy to assign instead of an Oracle-managed one. Set backup_policy = \"none\" when using this."
  type        = string
  default     = null
}

variable "attach_to_instance_id" {
  description = "OCID of an instance to attach the volume to. Null skips attachment."
  type        = string
  default     = null
}

variable "attachment_type" {
  description = "Attachment type when attach_to_instance_id is set."
  type        = string
  default     = "paravirtualized"

  validation {
    condition     = contains(["iscsi", "paravirtualized"], var.attachment_type)
    error_message = "attachment_type must be iscsi or paravirtualized."
  }
}

variable "enable_in_transit_encryption" {
  description = "Encrypt data in transit between the instance and the volume. Applied as is_pv_encryption_in_transit_enabled for paravirtualized attachments and as encryption_in_transit_type for iSCSI ones. iSCSI in-transit encryption requires a supported bare metal shape; set this to false for iSCSI attachments to VM instances."
  type        = bool
  default     = true
}

variable "freeform_tags" {
  description = "Free-form tags applied to the block volume."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags applied to the block volume, keyed as \"namespace.key\"."
  type        = map(string)
  default     = {}
}
