# terraform-oci-block-volume

Terraform module that manages an [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
block volume, with configurable performance (VPUs/GB) and optional KMS encryption. It can
optionally attach the volume to a compute instance.

## Usage

```hcl
module "block_volume" {
  source = "github.com/cybercapybara/terraform-oci-block-volume"

  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  display_name        = "prod-data-vol"
  size_in_gbs         = 200
  vpus_per_gb         = 20

  attach_to_instance_id = var.instance_id
  attachment_type       = "paravirtualized"

  freeform_tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

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
| `size_in_gbs`           | Size of the block volume in GB (50-32768).                            | `number`      | `50`                |    no    |
| `vpus_per_gb`           | Volume performance in VPUs per GB.                                    | `number`      | `10`                |    no    |
| `kms_key_id`            | KMS key OCID for encryption. Null uses Oracle-managed encryption.     | `string`      | `null`              |    no    |
| `attach_to_instance_id` | Instance OCID to attach the volume to. Null skips attachment.         | `string`      | `null`              |    no    |
| `attachment_type`       | Attachment type (`iscsi` or `paravirtualized`).                      | `string`      | `"paravirtualized"` |    no    |
| `freeform_tags`         | Free-form tags applied to the block volume.                           | `map(string)` | `{}`                |    no    |
| `defined_tags`          | Defined tags applied to the volume, keyed `namespace.key`.            | `map(string)` | `{}`                |    no    |

## Outputs

| Name            | Description                                             |
|-----------------|---------------------------------------------------------|
| `id`            | OCID of the block volume.                              |
| `size_in_gbs`   | Size of the block volume in GB.                        |
| `is_hydrated`   | Whether the volume finished copying from its source.  |
| `attachment_id` | OCID of the volume attachment, if attached.           |
| `state`         | Lifecycle state of the block volume.                  |

## License

[MIT](LICENSE)
