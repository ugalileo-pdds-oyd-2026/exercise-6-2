resource "aws_security_group" "alb" {
  name        = "mediastream-alb-sg"
  description = "Allow HTTP traffic to the ALB"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port   = var.listener_port
    to_port     = var.listener_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "mediastream-alb-sg" }
}
