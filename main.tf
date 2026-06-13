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

resource "aws_lb_target_group" "api" {
  name        = "mediastream-api-tg"
  protocol    = "HTTP"
  port        = 80
  target_type = "instance"
  vpc_id      = data.aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = { Name = "mediastream-api-tg" }
}
