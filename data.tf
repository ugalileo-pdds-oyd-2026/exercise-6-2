data "aws_vpc" "main" {
  tags = {
    Name = var.vpc_name
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  tags = {
    Tier = "public"
  }
}

data "aws_instance" "api" {
  filter {
    name   = "tag:Name"
    values = [var.instance_name]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}
