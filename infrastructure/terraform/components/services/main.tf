module "networking" {
  name = "services"
  environment = "${var.environment}"
  source = "../../modules/network"
  second_octet = "${var.second_octet}"
  domain = "${var.domain}"
  subdomain = "${var.subdomain}"
  root_domain_zone_id = "${var.root_domain_zone_id}"
  saving_mode = "${var.saving_mode}"
}

module "application-ecs-cluster" {
  source = "../../modules/ecs-cluster"
  cluster_name = "application-cluster"
  environment = "${var.environment}"
}

module "hello-world-service" {
  source = "../../modules/ecs-service"
  private_subnets = "${module.networking.private_subnets}"
  public_subnets = "${module.networking.public_subnets}"
  cluster_arn = "${module.application-ecs-cluster.cluster_arn}"
  cluster_name = "${module.application-ecs-cluster.cluster_name}"
  ecs_role_arn = "${module.application-ecs-cluster.ecs_role_arn}"
  vpc_id = "${module.networking.vpc_id}"
  nat_sg = "${module.networking.nat_sg}"
  dns_zone_id = "${module.networking.public_dns_zone_id[0]}"
  dns_record = "${module.networking.public_dns_zone_name[0]}"
  service_name = "hello-world"
  container_name = "hello-world"
  container_port = "80"
  desired_count = "${var.saving_mode == "true" ? 0 : 3}"
  health_check_path = "/"
  cpu = "256"
  memory = "512"
  public_lb = "true"
  environment = "${var.environment}"
  aws_account = "${var.aws_account}"
  image_tag = "${var.source_version}"
  saving_mode = "${var.saving_mode}"
}
