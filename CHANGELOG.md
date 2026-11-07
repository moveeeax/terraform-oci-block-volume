# Changelog

All notable changes to this module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

- `replicas` input that creates block volume replicas in other availability
  domains or regions (`block_volume_replicas` on `oci_core_volume`), with an
  optional `display_name` and `xrr_kms_key_id` per replica. Defaults to `[]`,
  which keeps the current plan unchanged.
- `remove_replicas` input that sets `block_volume_replicas_deletion`, since the
  provider does not delete existing replicas when the list is emptied.
- `replica_ids` output.

### Changed

- The minimum `oracle/oci` provider version is now 6.14, the first release
  that accepts `xrr_kms_key_id` on `block_volume_replicas`. Configurations
  pinned to an older provider must upgrade it.
