provider "oci" {}

module "block_volume" {
  source = "../.."

  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  display_name        = "example-data-vol"
  size_in_gbs         = 100
  vpus_per_gb         = 10

  freeform_tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

variable "compartment_id" {
  description = "Compartment OCID to deploy the example volume into."
  type        = string
}

variable "availability_domain" {
  description = "Availability domain name for the example volume."
  type        = string
}

output "block_volume_id" {
  value = module.block_volume.id
}
