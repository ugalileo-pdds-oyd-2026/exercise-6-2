variable "region" {
  type        = string
  description = "AWS region."
  default     = "us-east-1"
}

variable "vpc_name" {
  type        = string
  description = "Name tag used to look up the existing VPC."
  default     = "mediastream-vpc"
}

variable "instance_name" {
  type        = string
  description = "Name tag used to look up the existing EC2 instance."
  default     = "mediastream-api"
}

variable "listener_port" {
  type        = number
  description = "Port the ALB listener accepts traffic on."
  default     = 80
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. dev, prod)."
}
