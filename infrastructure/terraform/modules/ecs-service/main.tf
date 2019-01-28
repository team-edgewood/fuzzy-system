resource "aws_ecs_service" "service" {
  name                = "${var.service_name}"
  cluster             = "${var.cluster_arn}"
  task_definition     = "${aws_ecs_task_definition.task_definition.arn}"
  scheduling_strategy = "REPLICA"
  launch_type = "FARGATE"
  desired_count = "${var.desired_count}"

  network_configuration {
    subnets = ["${var.subnets}"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = "${var.target_group_arn}"
    container_name   = "hello-world"
    container_port   = 80
  }
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
