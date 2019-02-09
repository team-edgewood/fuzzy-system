module "networking" {
  source = "../../modules/network"
  second_octet = "${var.second_octet}"
  domain = "${var.domain}"
  subdomain = "${var.subdomain}"
  root_domain_zone_id = "${var.root_domain_zone_id}"
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
  nat_sg = "${module.networking.nat_sg}"
  dns_zone_id = "${module.networking.public_dns_zone_id}"
  dns_record = "${module.networking.public_dns_zone_name}"
  service_name = "hello-world"
  container_name = "hello-world"
  desired_count = "3"
  cpu = "256"
  memory = "512"
  public_lb = "true"
  container_definitions = "${file("hello-world-task.json")}"
}
