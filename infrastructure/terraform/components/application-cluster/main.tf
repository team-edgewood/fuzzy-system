module "networking" {
  source = "../../modules/network"
  second_octet = "0"
}

module "application-ecs-cluster" {
  source = "../../modules/ecs-cluster"
  cluster_name = "application-cluster"
}

module "hello-world-service" {
  source = "../../modules/ecs-service"
  private_subnets = "${module.networking.private_subnets}"
  public_subnets = "${module.networking.public_subnets}"
  cluster_arn = "${module.application-ecs-cluster.cluster_arn}"
  ecs_role_arn = "${module.application-ecs-cluster.ecs_role_arn}"
  vpc_id = "${module.networking.vpc_id}"
  service_name = "hello-world"
  container_name = "hello-world"
  desired_count = "3"
  cpu = "256"
  memory = "512"
  public_lb = "true"
  container_definitions = "${file("hello-world-task.json")}"
}
