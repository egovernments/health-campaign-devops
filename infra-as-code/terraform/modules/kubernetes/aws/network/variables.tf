variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "cluster_name" {
}

variable "availability_zones" {
  default = ["af-south-1a", "af-south-1b", "af-south-1c"]
}