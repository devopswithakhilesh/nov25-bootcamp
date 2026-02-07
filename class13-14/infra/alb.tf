
# ALB that point to nginx ecs services

# target group  for ALB -> type ip -> port 80 -> health check / 

# ALB listener on port 80


# ALb listener on port 443


# load balancer for ecs 
resource "aws_lb" "app_alb" {
  name               = "${var.environment}-${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = aws_subnet.public[*].id

  access_logs {
    bucket  = "logging-bucket-879381241087"
    prefix  = "nov25/devsecops/class16/alb-logs"
    enabled = true
  }
}





resource "aws_lb_target_group" "app_tg" {
  name        = "${var.environment}-${var.app_name}-tg"
  port        = local.ecs_services_interpreted["nginx"].container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 20
    path                = "/"
    matcher             = "200"
  }
}

# resource "aws_lb_listener" "app_listener" {
#  load_balancer_arn = aws_lb.app_alb.arn
#  port              = "80"
#  protocol          = "HTTP"
#
#  default_action {
#   type             = "forward"
#    target_group_arn = aws_lb_target_group.app_tg.arn
#  }
#}

# listenr for https
resource "aws_lb_listener" "app_listener_https" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"    
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

  depends_on = [aws_acm_certificate_validation.cert_validation]
}

# # DNS record for ALB

