# NOTE: `mock_provider` / `override_data` require Terraform (or OpenTofu) >= 1.7.
# That is a test-only requirement -- the module itself still supports >= 1.5, so
# do not raise required_version in versions.tf on account of this file.

mock_provider "oci" {}

# `command = plan` below: variable validation and resource preconditions are
# evaluated during plan, and the mock provider invents values for attributes
# left null in the configuration once an apply runs.

variables {
  compartment_id      = "ocid1.compartment.oc1..aaaaaaaaexamplecompartment"
  availability_domain = "Uocm:PHX-AD-1"
  display_name        = "test-data-vol"
}

override_data {
  target = data.oci_core_volume_backup_policies.predefined
  values = {
    volume_backup_policies = [{
      compartment_id     = null
      defined_tags       = {}
      destination_region = null
      display_name       = "bronze"
      freeform_tags      = {}
      id                 = "ocid1.volumebackuppolicy.oc1..aaaaaaaaexamplebronze"
      schedules          = []
      time_created       = "2024-01-01T00:00:00Z"
    }]
  }
}

run "defaults_are_durable" {
  assert {
    condition     = length(oci_core_volume_backup_policy_assignment.this) == 1
    error_message = "A backup policy must be assigned by default: an unbacked-up volume has no recoverable copy after destroy."
  }

  assert {
    condition     = oci_core_volume_backup_policy_assignment.this[0].policy_id == "ocid1.volumebackuppolicy.oc1..aaaaaaaaexamplebronze"
    error_message = "The assignment must use the policy resolved from the backup_policy name."
  }

  assert {
    condition     = tonumber(oci_core_volume.this.size_in_gbs) == 50
    error_message = "Default size must be the OCI minimum of 50 GB."
  }

  assert {
    condition     = length(oci_core_volume_attachment.this) == 0
    error_message = "No attachment must be created unless attach_to_instance_id is set."
  }

  assert {
    condition     = oci_core_volume.this.block_volume_replicas_deletion == null
    error_message = "block_volume_replicas_deletion must stay unset unless remove_replicas is true."
  }
}

run "custom_backup_policy_id_is_used" {
  variables {
    backup_policy    = "none"
    backup_policy_id = "ocid1.volumebackuppolicy.oc1..aaaaaaaaexamplecustom"
  }

  assert {
    condition     = oci_core_volume_backup_policy_assignment.this[0].policy_id == "ocid1.volumebackuppolicy.oc1..aaaaaaaaexamplecustom"
    error_message = "A user-defined backup_policy_id must be assigned verbatim."
  }
}

run "backup_policy_none_opts_out" {
  variables {
    backup_policy = "none"
  }

  assert {
    condition     = length(oci_core_volume_backup_policy_assignment.this) == 0
    error_message = "backup_policy = \"none\" must skip the assignment entirely."
  }
}

run "paravirtualized_attachment_encrypts_in_transit" {
  command = plan

  variables {
    attach_to_instance_id = "ocid1.instance.oc1..aaaaaaaaexampleinstance"
  }

  assert {
    condition     = oci_core_volume_attachment.this[0].is_pv_encryption_in_transit_enabled == true
    error_message = "Paravirtualized attachments must enable in-transit encryption by default."
  }
}

run "iscsi_attachment_encrypts_in_transit" {
  command = plan

  variables {
    attach_to_instance_id = "ocid1.instance.oc1..aaaaaaaaexampleinstance"
    attachment_type       = "iscsi"
  }

  assert {
    condition     = oci_core_volume_attachment.this[0].encryption_in_transit_type == "BM_ENCRYPTION_IN_TRANSIT"
    error_message = "iSCSI attachments must request in-transit encryption by default."
  }
}

run "in_transit_encryption_can_be_disabled" {
  command = plan

  variables {
    attach_to_instance_id        = "ocid1.instance.oc1..aaaaaaaaexampleinstance"
    attachment_type              = "iscsi"
    enable_in_transit_encryption = false
  }

  assert {
    condition     = oci_core_volume_attachment.this[0].encryption_in_transit_type == "NONE"
    error_message = "Disabling in-transit encryption must map to NONE for iSCSI attachments."
  }
}

run "replicas_are_passed_through" {
  command = plan

  variables {
    replicas = [
      {
        availability_domain = "Uocm:PHX-AD-2"
        display_name        = "test-data-vol-ad2"
      },
      {
        availability_domain = "Uocm:US-ASHBURN-AD-1"
        xrr_kms_key_id      = "ocid1.key.oc1.iad.aaaaaaaaexamplexrrkey"
      },
    ]
  }

  assert {
    condition     = length(oci_core_volume.this.block_volume_replicas) == 2
    error_message = "Every entry in replicas must become a block_volume_replicas block."
  }

  assert {
    condition     = oci_core_volume.this.block_volume_replicas[0].availability_domain == "Uocm:PHX-AD-2" && oci_core_volume.this.block_volume_replicas[0].display_name == "test-data-vol-ad2"
    error_message = "A cross-AD replica must keep its availability_domain and display_name."
  }

  assert {
    condition     = oci_core_volume.this.block_volume_replicas[1].xrr_kms_key_id == "ocid1.key.oc1.iad.aaaaaaaaexamplexrrkey"
    error_message = "A cross-region replica must pass xrr_kms_key_id through."
  }
}

run "remove_replicas_sets_deletion_flag" {
  command = plan

  variables {
    remove_replicas = true
  }

  assert {
    condition     = oci_core_volume.this.block_volume_replicas_deletion == true
    error_message = "remove_replicas = true must set block_volume_replicas_deletion."
  }
}

run "rejects_remove_replicas_with_replicas" {
  command = plan

  variables {
    remove_replicas = true
    replicas        = [{ availability_domain = "Uocm:PHX-AD-2" }]
  }

  expect_failures = [oci_core_volume.this]
}

run "rejects_empty_replica_availability_domain" {
  command = plan

  variables {
    replicas = [{ availability_domain = " " }]
  }

  expect_failures = [var.replicas]
}

run "rejects_duplicate_replica_availability_domain" {
  command = plan

  variables {
    replicas = [
      { availability_domain = "Uocm:PHX-AD-2" },
      { availability_domain = "uocm:phx-ad-2" },
    ]
  }

  expect_failures = [var.replicas]
}

run "rejects_size_below_minimum" {
  command = plan

  variables {
    size_in_gbs = 49
  }

  expect_failures = [var.size_in_gbs]
}

run "rejects_size_above_maximum" {
  command = plan

  variables {
    size_in_gbs = 32769
  }

  expect_failures = [var.size_in_gbs]
}

run "rejects_fractional_size" {
  command = plan

  variables {
    size_in_gbs = 100.5
  }

  expect_failures = [var.size_in_gbs]
}

run "rejects_invalid_vpus_per_gb" {
  command = plan

  variables {
    vpus_per_gb = 15
  }

  expect_failures = [var.vpus_per_gb]
}

run "rejects_vpus_per_gb_above_maximum" {
  command = plan

  variables {
    vpus_per_gb = 130
  }

  expect_failures = [var.vpus_per_gb]
}

run "rejects_unknown_backup_policy" {
  command = plan

  variables {
    backup_policy = "platinum"
  }

  expect_failures = [var.backup_policy]
}

run "rejects_invalid_attachment_type" {
  command = plan

  variables {
    attach_to_instance_id = "ocid1.instance.oc1..aaaaaaaaexampleinstance"
    attachment_type       = "nvme"
  }

  expect_failures = [var.attachment_type]
}

run "rejects_conflicting_backup_policy_inputs" {
  command = plan

  variables {
    backup_policy    = "gold"
    backup_policy_id = "ocid1.volumebackuppolicy.oc1..aaaaaaaaexamplecustom"
  }

  expect_failures = [oci_core_volume_backup_policy_assignment.this]
}
