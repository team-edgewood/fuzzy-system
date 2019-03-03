resource "aws_ecr_repository" "repo" {
  name = "${var.service_name}-${var.environment}"
}

resource "aws_ecs_service" "service" {
  name                = "${var.service_name}-${var.environment}"
  cluster             = "${var.cluster_arn}"
  task_definition     = "${aws_ecs_task_definition.task_definition.arn}"
  scheduling_strategy = "REPLICA"
  launch_type = "FARGATE"
  desired_count = "${var.desired_count}"

  network_configuration {
    subnets = ["${var.private_subnets}"]
    security_groups = ["${aws_security_group.service_sg.id}"]
  }

  load_balancer {
    target_group_arn = "${aws_lb_target_group.tg.arn}"
    container_name   = "${var.container_name}-  ${var.environment}"
    container_port   = "${var.container_port}"
  }

  depends_on = ["aws_lb_listener.public_lb", "aws_lb_listener.private_lb"]
}

resource "aws_security_group" "service_sg" {
  name        = "${var.service_name}-sg"
  description = "${var.service_name} sg"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_ecs_task_definition" "task_definition" {
  family                = "${var.service_name}-${var.environment}"
  container_definitions = <<EOF
[
  {
    "name": "${var.service_name}-${var.environment}",
    "image": "${var.aws_account}.dkr.ecr.eu-west-1.amazonaws.com/${var.service_name}-${var.environment}:latest",
    "cpu": ${var.cpu < 1024 ? 1 : var.cpu / 1024},
    "memory": ${var.memory},
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ]
  }
]
EOF
  requires_compatibilities = ["FARGATE"]
  cpu                      = "${var.cpu}"
  memory                   = "${var.memory}"
  network_mode = "awsvpc"
  execution_role_arn = "${var.ecs_role_arn}"
}

resource "aws_lb" "lb" {
  name               = "${var.service_name}-${var.environment}-lb"
  internal           = "${var.public_lb == "true" ? false : true}"
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.lb_sg.id}"]
  subnets            = ["${var.public_subnets}"]

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "tg" {
  name        = "${var.service_name}-${var.environment}-tg"
  port        = "${var.container_port}"
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
  target_type = "ip"

  health_check {
    matcher = "200"
    path = "${var.health_check_path}"
  }
}

resource "aws_lb_listener" "private_lb" {
  count = "${var.public_lb == "true" ? 0 : 1}"
  load_balancer_arn = "${aws_lb.lb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.tg.id}"
    type             = "forward"
  }
}

resource "aws_lb_listener" "public_lb" {
  count = "${var.public_lb == "true" ? 1 : 0}"
  load_balancer_arn = "${aws_lb.lb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${aws_acm_certificate.cert.arn}"

  default_action {
    target_group_arn = "${aws_lb_target_group.tg.id}"
    type             = "forward"
  }
}

resource "aws_security_group" "lb_sg" {
  name        = "${var.service_name}-${var.environment}-lb-sg"
  description = "${var.service_name} load balancer sg"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_security_group_rule" "load_balancer_from_internet" {
  count           = "${var.public_lb == "true" ? 1 : 0}"
  type            = "ingress"
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.lb_sg.id}"
}

resource "aws_security_group_rule" "load_balancer_to_service" {
  type            = "egress"
  from_port       = "${var.container_port}"
  to_port         = "${var.container_port}"
  protocol        = "tcp"
  security_group_id = "${aws_security_group.lb_sg.id}"
  source_security_group_id = "${aws_security_group.service_sg.id}"
}

resource "aws_security_group_rule" "service_from_load_balancer" {
  type            = "ingress"
  from_port       = "${var.container_port}"
  to_port         = "${var.container_port}"
  protocol        = "tcp"
  source_security_group_id = "${aws_security_group.lb_sg.id}"
  security_group_id = "${aws_security_group.service_sg.id}"
}

resource "aws_security_group_rule" "service_to_nat" {
  type            = "egress"
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  source_security_group_id = "${var.nat_sg}"
  security_group_id = "${aws_security_group.service_sg.id}"
}

resource "aws_route53_record" "lb_dns" {
  name = "${var.dns_record}"
  zone_id = "${var.dns_zone_id}"
  type    = "A"

  alias {
    name                   = "${aws_lb.lb.dns_name}"
    zone_id                = "${aws_lb.lb.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "cert" {
  count           = "${var.public_lb == "true" ? 1 : 0}"
  domain_name       = "${var.dns_record}"
  validation_method = "DNS"

  tags = {
    Environment = "${var.service_name}-${var.environment}-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  name    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.dns_zone_id}"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}
