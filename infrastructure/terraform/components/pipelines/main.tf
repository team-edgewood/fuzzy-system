module "network" {
  source = "../../modules/network"
  second_octet = "${var.second_octet}"
  saving_mode = "${var.saving_mode}"
}

module "hello_world_build" {
  source = "../../modules/service-build"
  sg = "${aws_security_group.code_build.id}"
  build_name = "hello-world"
  buildspec = "services/hello-world/buildspec.yml"
  vpc_id = "${module.network.vpc_id}"
  subnets = ["${module.network.private_subnets}"]
  role = "${aws_iam_role.build.id}"
}
