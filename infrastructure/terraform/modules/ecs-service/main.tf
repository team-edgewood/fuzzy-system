resource "null_resource" "create_ecs_service" {

  provisioner "local-exec" {
    command = <<EOF
#!/bin/sh

set -eux

aws ecs create-service \
    --cluster "$CLUSTER_NAME" \
    --service-name "$SERVICE_NAME" \
    --task-definition "$TARGET_DEFINITION" \
    --desired-count "$DESIRED_COUNT" \
    --launch-type FARGATE \
    --scheduling-strategy REPLICA \
    --deployment-controller type="CODE_DEPLOY" \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SECURITY_GROUPS],assignPublicIp=DISABLED}" \
    --load-balancers "targetGroupArn=$TARGET_GROUP_ARN,containerName=$CONTAINER_NAME,containerPort=$CONTAINER_PORT"

EOF
    environment {
      CLUSTER_NAME = "${var.cluster_name}"
      SERVICE_NAME = "${var.service_name}-${var.environment}"
      TARGET_DEFINITION = "${aws_ecs_task_definition.task_definition.arn}"
      DESIRED_COUNT = "${var.desired_count}"
      SUBNETS = "${join(",", var.private_subnets)}"
      SECURITY_GROUPS = "${aws_security_group.service_sg.id}"
      TARGET_GROUP_ARN = "${aws_lb_target_group.blue.arn}"
      CONTAINER_NAME = "${var.container_name}-${var.environment}"
      CONTAINER_PORT = "${var.container_port}"
    }
  }
  depends_on = ["aws_lb_listener.public_lb", "aws_lb_listener.private_lb"]
}

resource "null_resource" "update_ecs_service" {
  triggers {
    desired_count = "${var.desired_count}"
  }

  provisioner "local-exec" {
    command = <<EOF
#!/bin/sh

set -eux

aws ecs update-service \
    --cluster "$CLUSTER_NAME" \
    --service "$SERVICE_NAME" \
    --desired-count "$DESIRED_COUNT"

EOF
    environment {
      CLUSTER_NAME = "${var.cluster_name}"
      SERVICE_NAME = "${var.service_name}-${var.environment}"
      DESIRED_COUNT = "${var.desired_count}"
    }
  }
  depends_on = ["aws_lb_listener.public_lb", "aws_lb_listener.private_lb", "null_resource.create_ecs_service"]
}

resource "null_resource" "code_deploy" {
  triggers {
    task_definition = "${aws_ecs_task_definition.task_definition.arn}"
  }

  provisioner "local-exec" {
    command = <<EOF
#!/bin/sh

set -eux

TASK_DEFINITION=$(mktemp)
CODEDEPLOY_APPSPEC=$(mktemp)

cat <<HERE > "$TASK_DEFINITION"
{
    "family": "${var.service_name}-${var.environment}",
    "executionRoleArn": "${var.ecs_role_arn}",
    "networkMode": "awsvpc",
    "containerDefinitions": [
        {
            "name": "${var.service_name}-${var.environment}",
            "image": "${var.aws_account}.dkr.ecr.eu-west-1.amazonaws.com/${var.service_name}:${var.image_tag}",
            "cpu": ${var.cpu < 1024 ? 1 : var.cpu / 1024},
            "memory": ${var.memory},
            "portMappings": [
                {
                    "containerPort": 80,
                    "hostPort": 80
                }
            ],
            "essential": true
        }
    ],
    "requiresCompatibilities": [
        "FARGATE"
    ],
    "cpu": "${var.cpu}",
    "memory": "${var.memory}"
}
HERE

cat <<HERE > "$CODEDEPLOY_APPSPEC"
version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: "${aws_ecs_task_definition.task_definition.arn}"
        LoadBalancerInfo:
          ContainerName: "${var.container_name}-${var.environment}"
          ContainerPort: ${var.container_port}
        NetworkConfiguration:
          AwsvpcConfiguration:
            Subnets: ["${join("\",\"", var.private_subnets)}"]
            SecurityGroups: ["${aws_security_group.service_sg.id}"]
            AssignPublicIp: "DISABLED"
HERE

aws ecs deploy \
  --service "$SERVICE_NAME" \
  --task-definition "$TASK_DEFINITION" \
  --codedeploy-appspec "$CODEDEPLOY_APPSPEC" \
  --cluster "$CLUSTER_NAME" \
  --codedeploy-application "$APPLICATION_NAME" \
  --codedeploy-deployment-group "$DEPLOYMENT_GROUP"


EOF
    environment {
      CLUSTER_NAME = "${var.cluster_name}"
      SERVICE_NAME = "${var.service_name}-${var.environment}"
      APPLICATION_NAME = "${aws_codedeploy_app.app.name}"
      DEPLOYMENT_GROUP = "${aws_codedeploy_deployment_group.dg.deployment_group_name}"
    }
  }
  depends_on = ["aws_lb_listener.public_lb", "aws_lb_listener.private_lb", "null_resource.create_ecs_service"]
}

resource "aws_security_group" "service_sg" {
  name        = "${var.service_name}-sg"
  description = "${var.service_name} sg"
  vpc_id      = "${var.vpc_id}"
  tags {
    name = "${var.service_name}-${var.environment}"
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  family                = "${var.service_name}-${var.environment}"
  container_definitions = <<EOF
[
  {
    "name": "${var.service_name}-${var.environment}",
    "image": "${var.aws_account}.dkr.ecr.eu-west-1.amazonaws.com/${var.service_name}:${var.image_tag}",
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
  count = "${var.saving_mode == "true" ? 0 : 1}"
  name               = "${var.service_name}-${var.environment}-lb"
  internal           = "${var.public_lb == "true" ? false : true}"
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.lb_sg.id}"]
  subnets            = ["${var.public_subnets}"]

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "blue" {
  name        = "${var.service_name}-${var.environment}-blue-tg"
  port        = "${var.container_port}"
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
  target_type = "ip"

  health_check {
    matcher = "200"
    path = "${var.health_check_path}"
  }
}

resource "aws_lb_target_group" "green" {
  name        = "${var.service_name}-${var.environment}-green-tg"
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
    target_group_arn = "${aws_lb_target_group.blue.id}"
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
    target_group_arn = "${aws_lb_target_group.blue.id}"
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

resource "aws_codedeploy_app" "app" {
  compute_platform = "ECS"
  name             = "${var.service_name}"
}

resource "aws_codedeploy_deployment_group" "dg" {
  app_name               = "${aws_codedeploy_app.app.name}"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "${var.service_name}-dg"
  service_role_arn       = "${aws_iam_role.code_deploy_role.arn}"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 1
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = "${var.cluster_name}"
    service_name = "${var.service_name}-${var.environment}"
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = ["${aws_lb_listener.public_lb.arn}"]
      }

      target_group {
        name = "${aws_lb_target_group.blue.name}"
      }

      target_group {
        name = "${aws_lb_target_group.green.name}"
      }
    }
  }
  depends_on = ["null_resource.create_ecs_service"]
}

resource "aws_iam_role" "code_deploy_role" {
  name = "code-deploy-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "code_deploy_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
  role       = "${aws_iam_role.code_deploy_role.name}"
}

