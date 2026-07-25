# terraform-oci-block-volume

Terraform module that manages an [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
block volume, with configurable performance (VPUs/GB) and optional KMS encryption. It can
optionally attach the volume to a compute instance.

Because the volume holds data, the module defaults to durable settings: an Oracle-managed
`bronze` backup policy is assigned unless you opt out, and attachments encrypt data in
transit. See [Durability and destroy behaviour](#durability-and-destroy-behaviour).

## Usage

```hcl
module "block_volume" {
  source = "github.com/moveeeax/terraform-oci-block-volume"

  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  display_name        = "prod-data-vol"
  size_in_gbs         = 200
  vpus_per_gb         = 20

  # Oracle-managed backup policy: gold, silver, bronze, or none.
  backup_policy = "silver"

  attach_to_instance_id = var.instance_id
  attachment_type       = "paravirtualized"

  freeform_tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Durability and destroy behaviour

OCI has no "final snapshot on delete" for block volumes: `terraform destroy` (and any change
that forces replacement, such as `availability_domain`) deletes the volume and its data
immediately. The only recoverable copy is a backup, and backups outlive the volume they were
taken from.

For that reason `backup_policy` defaults to `bronze` (monthly full, retained 12 months). Set
`backup_policy = "silver"` or `"gold"` for shorter RPOs, or pass `backup_policy_id` to assign a
user-defined policy (set `backup_policy = "none"` when you do). `backup_policy = "none"` with no
`backup_policy_id` leaves the volume with no backups at all — the volume is then unrecoverable
once destroyed.

Terraform cannot make `lifecycle.prevent_destroy` conditional on an input, so this module does
not set it. If a volume must never be destroyed by Terraform, guard it in the calling
configuration (for example with an OCI IAM policy denying `volume_delete`, or a
`prevent_destroy` on a resource you own in the same module).

Data is always encrypted at rest — with an Oracle-managed key by default, or with your own key
via `kms_key_id`. Attachments encrypt data in transit by default; see
`enable_in_transit_encryption` below for the shape requirements.

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| oci       | >= 5.0   |

## Inputs

| Name                    | Description                                                           | Type          | Default             | Required |
|-------------------------|-----------------------------------------------------------------------|---------------|---------------------|:--------:|
| `compartment_id`        | OCID of the compartment in which to create the block volume.          | `string`      | n/a                 |   yes    |
| `availability_domain`   | Availability domain in which to create the volume.                    | `string`      | n/a                 |   yes    |
| `display_name`          | Human-readable name for the block volume.                             | `string`      | n/a                 |   yes    |
| `size_in_gbs`           | Size of the block volume in GB (whole number, 50-32768).              | `number`      | `50`                |    no    |
| `vpus_per_gb`           | Performance in VPUs per GB (multiple of 10, 0-120).                   | `number`      | `10`                |    no    |
| `kms_key_id`            | KMS key OCID for encryption. Null uses Oracle-managed encryption.     | `string`      | `null`              |    no    |
| `backup_policy`         | Oracle-managed backup policy: `gold`, `silver`, `bronze`, `none`.     | `string`      | `"bronze"`          |    no    |
| `backup_policy_id`      | User-defined backup policy OCID (set `backup_policy = "none"`).       | `string`      | `null`              |    no    |
| `attach_to_instance_id` | Instance OCID to attach the volume to. Null skips attachment.         | `string`      | `null`              |    no    |
| `attachment_type`       | Attachment type (`iscsi` or `paravirtualized`).                      | `string`      | `"paravirtualized"` |    no    |
| `enable_in_transit_encryption` | Encrypt data in transit on the attachment.                     | `bool`        | `true`              |    no    |
| `freeform_tags`         | Free-form tags applied to the block volume.                           | `map(string)` | `{}`                |    no    |
| `defined_tags`          | Defined tags applied to the volume, keyed `namespace.key`.            | `map(string)` | `{}`                |    no    |

## Outputs

| Name            | Description                                             |
|-----------------|---------------------------------------------------------|
| `id`            | OCID of the block volume.                              |
| `size_in_gbs`   | Size of the block volume in GB.                        |
| `is_hydrated`   | Whether the volume finished copying from its source.  |
| `attachment_id` | OCID of the volume attachment, if attached.           |
| `backup_policy_id` | OCID of the assigned backup policy, or null.       |
| `state`         | Lifecycle state of the block volume.                  |

### In-transit encryption

`enable_in_transit_encryption` maps to the field the API expects for the attachment type:

| `attachment_type`  | Field set                             | When `true`                | When `false` |
|--------------------|---------------------------------------|----------------------------|--------------|
| `paravirtualized`  | `is_pv_encryption_in_transit_enabled` | `true`                     | `false`      |
| `iscsi`            | `encryption_in_transit_type`          | `BM_ENCRYPTION_IN_TRANSIT` | `NONE`       |

iSCSI in-transit encryption is only supported on bare metal shapes, so set
`enable_in_transit_encryption = false` for iSCSI attachments to VM instances. Paravirtualized
in-transit encryption requires an instance on a supported shape (VM instances launched from
platform images, and the bare metal shapes Oracle lists as supported).

## Tests

```
terraform test
```

The suite in [`tests/`](tests) uses `mock_provider`, so it needs no OCI credentials and no
network. `mock_provider` requires Terraform/OpenTofu >= 1.7; that is a test-only requirement and
the module itself still supports >= 1.5.

## License

[MIT](LICENSE)
