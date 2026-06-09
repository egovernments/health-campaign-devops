variable "name" {}
variable "node_count" {}
variable "vm_size" {}
variable "resource_group" {}
variable "location" {}
variable "environment" {}
variable "vnet_subnet_id" {}
variable "os_disk_size_gb" {}
variable "enable_auto_scaling" {
  description = "Enable auto scaling for the default node pool"
  type        = bool
  default     = false
}
variable "min_node_count" {
  description = "Minimum number of nodes for auto scaling"
  type        = number
  default     = 1
}
variable "max_node_count" {
  description = "Maximum number of nodes for auto scaling"
  type        = number
  default     = 10
}