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
  description = "Size of the block volume in GB (minimum 50)."
  type        = number
  default     = 50

  validation {
    condition     = var.size_in_gbs >= 50 && var.size_in_gbs <= 32768
    error_message = "size_in_gbs must be between 50 and 32768."
  }
}

variable "vpus_per_gb" {
  description = "Volume performance in VPUs per GB (0 = Lower Cost, 10 = Balanced, 20 = Higher Performance)."
  type        = number
  default     = 10
}

variable "kms_key_id" {
  description = "OCID of the KMS key used to encrypt the volume. Null uses Oracle-managed encryption."
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
