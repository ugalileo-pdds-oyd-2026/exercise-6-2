variable "region" {
  type        = string
  description = "AWS region."
  default     = "us-east-1"
}

variable "vpc_name" {
  type        = string
  description = "Name tag applied to the VPC and subnets — used by data sources in the root workspace."
  default     = "mediastream-vpc"
}

variable "instance_name" {
  type        = string
  description = "Name tag applied to the EC2 instance — used by the data source in the root workspace."
  default     = "mediastream-api"
}
