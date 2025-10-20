# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false  # Set to true for production

  tags = merge(var.tags, {
    Name = "${var.project_name}-alb"
  })
}

# Target Group for web servers
resource "aws_lb_target_group" "web_servers" {
  name     = "${var.project_name}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-web-tg"
  })
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "web_servers" {
  count = length(aws_instance.web_servers)

  target_group_arn = aws_lb_target_group.web_servers.arn
  target_id        = aws_instance.web_servers[count.index].id
  port             = 80
}

# ALB Listener for HTTP
resource "aws_lb_listener" "web_http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_servers.arn
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-http-listener"
  })
}

# ALB Listener for HTTPS (redirecting to HTTP for development)
# In production, you would configure SSL certificate here
resource "aws_lb_listener" "web_https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "80"
      protocol    = "HTTP"
      status_code = "HTTP_301"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-https-listener"
  })
}