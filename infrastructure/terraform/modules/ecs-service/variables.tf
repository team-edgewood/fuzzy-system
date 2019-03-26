variable "service_name" {}
variable "private_subnets" {
  type = "list"
}
variable "public_subnets" {
  type = "list"
}
variable "cluster_arn" {}
variable "cluster_name" {}
variable "desired_count" {}
variable "cpu" {}
variable "memory" {}
variable "vpc_id" {}
variable "public_lb" {}
variable "container_name" {}
variable "ecs_role_arn" {}
variable "nat_sg" {}
variable "dns_zone_id" {}
variable "dns_record" {}
variable "container_port" {}
variable "health_check_path" {}
variable "environment" {}
variable "aws_account" {}
variable "image_tag" {}
variable "saving_mode" {}
