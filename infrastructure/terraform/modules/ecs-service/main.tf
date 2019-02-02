resource "aws_ecs_service" "service" {
  name                = "${var.service_name}"
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
    container_name   = "${var.container_name}"
    container_port   = "80"
  }

  depends_on = ["aws_lb_listener.lb"]
}

resource "aws_security_group" "service_sg" {
  name        = "${var.service_name}-sg"
  description = "${var.service_name} sg"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_ecs_task_definition" "task_definition" {
  family                = "${var.service_name}"
  container_definitions = "${var.container_definitions}"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "${var.cpu}"
  memory                   = "${var.memory}"
  network_mode = "awsvpc"
  execution_role_arn = "${var.ecs_role_arn}"
}

resource "aws_lb" "lb" {
  name               = "${var.service_name}-lb"
  internal           = "${!var.public_lb}"
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.lb_sg.id}"]
  subnets            = ["${var.public_subnets}"]

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "tg" {
  name        = "${var.service_name}-tg"
  port        = "80"
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
  target_type = "ip"
}

# Redirect all traffic from the ALB to the target group
resource "aws_lb_listener" "lb" {
  load_balancer_arn = "${aws_lb.lb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.tg.id}"
    type             = "forward"
  }
}

resource "aws_security_group" "lb_sg" {
  name        = "${var.service_name}-lb-sg"
  description = "${var.service_name} load balancer sg"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_security_group_rule" "load_balancer_from_internet" {
  count           = "${var.public_lb == "true" ? 1 : 0}"
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.lb_sg.id}"
}

resource "aws_security_group_rule" "load_balancer_to_service" {
  type            = "egress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  security_group_id = "${aws_security_group.lb_sg.id}"
  source_security_group_id = "${aws_security_group.service_sg.id}"
}

resource "aws_security_group_rule" "service_from_load_balancer" {
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  source_security_group_id = "${aws_security_group.lb_sg.id}"
  security_group_id = "${aws_security_group.service_sg.id}"
}

resource "aws_security_group_rule" "service_to_nat" {
  type            = "egress"
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.service_sg.id}"
}
