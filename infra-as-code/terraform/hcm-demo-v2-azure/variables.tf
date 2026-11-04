variable "environment" {
  description = "The environment tag for Azure resources"
  type        = string
  validation {
    condition = (
      length(var.environment) >= 3 &&
      length(var.environment) <= 40 &&
      can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.environment)) &&
      !can(regex("--", var.environment)) # no consecutive hyphens
    )
    error_message = <<EOT
Environment name must:
- Be 3 to 40 characters long
- Contain only lowercase letters, numbers, and hyphens
- Start with a lowercase letter
- Not start or end with a hyphen
- Not contain consecutive hyphens
EOT
  }
}

variable "resource_group" {
  description = "Azure Resource Group name"
  type        = string
}

variable "location" {
  description = "Azure region for the environment"
  type        = string
}

variable "vnet_cidr" {
  description = "Address space for the environment VNet. Must not overlap hcm-demo (10.20.27.0/24)."
  type        = string
}

variable "aks_subnet_cidr" {
  description = "Subnet for AKS nodes"
  type        = string
}

variable "postgres_subnet_cidr" {
  description = "Delegated subnet for the PostgreSQL flexible server"
  type        = string
}

variable "kubernetes_version" {
  description = <<EOT
AKS control plane version. The v2.2 environment moves ahead of hcm-demo, which
runs 1.34 — so the parallel environment also validates HCM v2.2 against the
newer Kubernetes before cutover.
EOT
  type        = string
  default     = "1.35"
}

variable "vm_size" {
  description = "Node pool VM size"
  type        = string
  default     = "Standard_E4s_v3"
}

variable "node_count" {
  description = "Initial node count for the autoscaling pool"
  type        = number
  default     = 8
}

variable "node_min_count" {
  type    = number
  default = 1
}

variable "node_max_count" {
  type    = number
  default = 8
}

variable "os_disk_size_gb" {
  type    = number
  default = 128
}

variable "db_version" {
  description = "PostgreSQL major version. Must match the source server for pg_restore."
  type        = string
  default     = "15"
}

variable "db_sku_name" {
  description = "Tier-prefixed flexible server SKU. GP_Standard_D2ds_v4 is the GeneralPurpose D2ds_v4 that hcm-demo runs on."
  type        = string
  default     = "GP_Standard_D2ds_v4"
}

variable "db_storage_mb" {
  type    = number
  default = 65536
}

variable "db_backup_retention_days" {
  type    = number
  default = 7
}

variable "db_name" {
  description = "Application database name. Matches the source (healthdemo) so connection strings carry over unchanged."
  type        = string
  default     = "healthdemo"
}

variable "db_user" {
  description = "Azure DB admin user name"
  type        = string

  validation {
    condition = (
      length(var.db_user) >= 3 &&
      length(var.db_user) <= 40 &&
      can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.db_user)) &&
      !can(regex("--", var.db_user))
    )
    error_message = <<EOT
DB User name must:
- Be 3 to 40 characters long
- Contain only lowercase letters & numbers
- Start with a lowercase letter
EOT
  }
}

variable "db_password" {
  description = "Azure DB admin password"
  type        = string
  sensitive   = true

  validation {
    condition = (
      length(var.db_password) >= 6 &&
      length(var.db_password) <= 16 &&
      can(regex("^[a-z][a-z0-9@#]*$", var.db_password))
    )
    error_message = <<EOT
DB password must:
- Be 6 to 16 characters long
- Start with a lowercase letter
- Use only lowercase letters, numbers, and @ or # (no other symbols)
EOT
  }
}

variable "filestore_account_name" {
  description = "Storage account backing egov-filestore. 3-24 lowercase alphanumeric characters."
  type        = string
}

variable "es_data_disk_size_gb" {
  description = "Size of each static Elasticsearch data disk. Matches hcm-demo (50Gi PVs)."
  type        = number
  default     = 50
}

variable "es_master_disk_size_gb" {
  description = "Size of each static Elasticsearch master disk. Matches hcm-demo (20Gi PVs)."
  type        = number
  default     = 20
}

variable "es_node_count" {
  description = "Number of ES master/data nodes, and therefore of static disks to create."
  type        = number
  default     = 3
}

variable "es_snapshot_container" {
  description = "Blob container holding the Elasticsearch snapshot repository used to move index data from hcm-demo."
  type        = string
  default     = "es-snapshots"
}

variable "sops_principal_object_id" {
  description = <<EOT
Object ID of the service principal ArgoCD's repo-server uses to decrypt SOPS
files. Defaults to sops-argocd-hcm-demo-azure, the same identity hcm-demo uses —
the key material is per-environment, only the identity is shared.
EOT
  type        = string
  default     = "944d0629-0263-4e9c-b171-c2bd0f0ef951"
}
