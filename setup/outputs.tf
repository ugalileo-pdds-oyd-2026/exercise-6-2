output "vpc_id" {
  description = "ID of the provisioned VPC."
  value       = aws_vpc.main.id
}

output "instance_id" {
  description = "ID of the API EC2 instance."
  value       = aws_instance.api.id
}
