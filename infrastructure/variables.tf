variable "aws_region" {
  default = "us-east-1"
}

variable "db_availability_zone" {
  type        = string
  description = "The AWS Availability Zone in which to create the DB"
  default     = "us-east-1a"
}

variable "db_instance_type" {
  type        = string
  description = "The AWS EC2 instance type for the DB"
  default     = "t3.small"
}

variable "db_key_name" {
  type        = string
  description = "The name of the SSH key pair to use for the DB"
  default     = "alannix"
}

variable "db_volume_size" {
  type        = string
  description = "The size of the DB storage volume (in GB)"
  default     = "20"
}

variable "eks_cluster_name" {
  type        = string
  description = "The name of the AWS EKS cluster"
  default     = "NIXLAB-EKS"
}

variable "eks_subnets" {
  type        = string
  description = "The number of EKS subnets to use"
  default     = 1
}

variable "vpc_name" {
  type        = string
  description = "The name of the AWC VPC"
  default     = "NIXLAB"
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR subnet address for the VPC"
  default     = "10.0.0.0/16"
}

variable "vpc_subnets" {
  type        = string
  description = "The number of subnets to configure for the VPC"
  default     = 2
}
