resource "aws_ecs_service" "service" {
  name                = "${var.service_name}"
  cluster             = "${var.cluster_arn}"
  task_definition     = "${aws_ecs_task_definition.task_definition.arn}"
  scheduling_strategy = "REPLICA"
  launch_type = "FARGATE"
  desired_count = "${var.desired_count}"

  network_configuration {
    subnets = ["${var.subnets}"]
    security_groups = ["${aws_security_group.service_sg.id}"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = "${aws_lb_target_group.tg.arn}"
    container_name   = "hello-world"
    container_port   = 80
  }

  depends_on = ["aws_lb_listener.lb"]
}

resource "aws_security_group" "service_sg" {
  name        = "${var.service_name}-sg"
  description = "Service sg"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_ecs_task_definition" "task_definition" {
  family                = "${var.service_name}"
  container_definitions = "${file("hello-world-task.json")}"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "${var.cpu}"
  memory                   = "${var.memory}"
  network_mode = "awsvpc"
  execution_role_arn = "${aws_iam_role.ecr_role.arn}"
}

resource "aws_iam_policy" "ecr_policy" {
  name = "ecr_policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "ecr_role" {
  name = "ecr_role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
            "Service": [
                "ecs-tasks.amazonaws.com"
            ]
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = "${aws_iam_role.ecr_role.name}"
  policy_arn = "${aws_iam_policy.ecr_policy.arn}"
}



resource "aws_lb" "lb" {
  name               = "${var.service_name}-lb"
  internal           = "${!var.public_lb}"
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.lb_sg.id}"]
  subnets            = ["${var.public_subnets}"]

  enable_deletion_protection = false
}

resource "aws_security_group" "lb_sg" {
  name        = "${var.service_name}-lb-sg"
  description = "Load balancer sg"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_security_group_rule" "internet_in" {
//  count           = "${var.public_lb == true ? 1 : 0}"
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.lb_sg.id}"
}

resource "aws_security_group_rule" "service_out" {
  type            = "egress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  security_group_id = "${aws_security_group.lb_sg.id}"
  source_security_group_id = "${aws_security_group.service_sg.id}"
}

resource "aws_security_group_rule" "service_in" {
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  source_security_group_id = "${aws_security_group.lb_sg.id}"
  security_group_id = "${aws_security_group.service_sg.id}"
}

resource "aws_security_group_rule" "ecr" {
  type            = "egress"
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.service_sg.id}"
}

resource "aws_lb_target_group" "tg" {
  name        = "${var.service_name}-tg"
  port        = 80
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
