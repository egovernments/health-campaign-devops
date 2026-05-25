variable "sku_name" {}
variable "location" {}
variable "resource_group" {}
variable "storage_mb" {}
variable "backup_retention_days" {}
variable "administrator_login" {}
variable "administrator_password" {}
variable "environment" {}
variable "db_name" {}
variable "db_version" {}
variable "delegated_subnet_id" {}
variable "private_dns_zone_id" {}
variable "auto_grow_enabled" {
  description = "Enable auto grow for the PostgreSQL Flexible Server storage"
  type        = bool
  default     = false
}