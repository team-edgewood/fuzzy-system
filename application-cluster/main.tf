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

  network_configuration {
    subnets = ["${aws_subnet.public_a.id}", "${aws_subnet.public_b.id}", "${aws_subnet.public_c.id}"]
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  family                = "${var.service_name}"
  container_definitions = "${file("hello-world-task.json")}"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  network_mode = "awsvpc"
}

resource "aws_vpc" "application" {
  cidr_block = "10.0.0.0/16"
}

data "aws_availability_zones" "available" {}


resource "aws_subnet" "public_a" {
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  vpc_id     = "${aws_vpc.application.id}"
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "public_b" {
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
  vpc_id     = "${aws_vpc.application.id}"
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "public_c" {
  availability_zone = "${data.aws_availability_zones.available.names[2]}"
  vpc_id     = "${aws_vpc.application.id}"
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "private_a" {
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  vpc_id     = "${aws_vpc.application.id}"
  cidr_block = "10.0.4.0/24"

  tags = {
    Name = "private"
  }
}

resource "aws_subnet" "private_b" {
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
  vpc_id     = "${aws_vpc.application.id}"
  cidr_block = "10.0.5.0/24"

  tags = {
    Name = "private"
  }
}

resource "aws_subnet" "private_c" {
  availability_zone = "${data.aws_availability_zones.available.names[2]}"
  vpc_id     = "${aws_vpc.application.id}"
  cidr_block = "10.0.6.0/24"

  tags = {
    Name = "private"
  }
}
