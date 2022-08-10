#
# Variables Configuration
#

variable "cluster_name" {
  default = "health-eks-dev"
}

variable "vpc_cidr_block" {
  default = "192.168.0.0/16"
}

variable "network_availability_zones" {
  default = ["ap-south-1b", "ap-south-1a"]
}

variable "availability_zones" {
  default = ["ap-south-1b"]
}

variable "kubernetes_version" {
  default = "1.20"
}

variable "instance_type" {
  default = "m4.xlarge"
}

variable "override_instance_types" {
  default = ["r5a.large", "r5ad.large", "r5d.large", "m4.xlarge"]
  
}

variable "number_of_worker_nodes" {
  default = "3"
}

variable "ssh_key_name" {
  default = "health-eks-dev"
}

variable "bucket_name" {
  default = "health-s3-dev"
}

variable "db_name" {
default = "healthdev"
}

variable "db_username" {
default = "healthegovdemo"
}

variable "db_password" {}

