module "networking" {
  source = "../../modules/network"
  second_octet = "0"
}
resource "aws_ecs_cluster" "cluster" {
  name = "application-cluster"
}

module "ecs" {
  source = "../../modules/ecs-service"
  service_name = "hello-world"
  desired_count = "3"
  memory = "2048"
  subnets = "${module.networking.private_subnets}"
  public_subnets = "${module.networking.nat_subnets}"
  cluster_arn = "${aws_ecs_cluster.cluster.arn}"
  cpu = "1024"
  vpc_id = "${module.networking.vpc_id}"
  public_lb = true
}
