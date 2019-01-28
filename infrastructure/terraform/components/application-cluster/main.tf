module "networking" {
  source = "../../modules/network"
  second_octet = "0"
}

resource "aws_ecs_cluster" "cluster" {
  name = "application-cluster"
}

module "load-balancer" {
  source = "../../modules/load-balancer"
  vpc_id = "${module.networking.vpc_id}"
  name = "hello-world"
  subnets = "${module.networking.nat_subnets}"
}

module "ecs" {
  source = "../../modules/ecs-service"
  service_name = "hello-world"
  desired_count = "3"
  memory = "2048"
  subnets = "${module.networking.nat_subnets}"
  cluster_arn = "${aws_ecs_cluster.cluster.arn}"
  cpu = "1024"
  target_group_arn="${module.load-balancer.target_group_arn}"
}
