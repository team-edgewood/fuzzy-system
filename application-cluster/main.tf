resource "aws_ecs_cluster" "cluster" {
  name = "application-cluster"
}

variable "service_name" {
  default = "hello-world"
}

resource "aws_ecs_service" "service" {
  name                = "${var.service_name}"
  cluster             = "${aws_ecs_cluster.cluster.arn}"
  task_definition     = "${aws_ecs_task_definition.task_definition.arn}"
  scheduling_strategy = "REPLICA"
  launch_type = "FARGATE"
  desired_count = 1
}

resource "aws_ecs_task_definition" "task_definition" {
  family                = "${var.service_name}"
  container_definitions = "${file("hello-world-task.json")}"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  network_mode = "awsvpc"
}
