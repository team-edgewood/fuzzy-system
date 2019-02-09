variable "service_name" {
}
variable "private_subnets" {
  type = "list"
}
variable "public_subnets" {
  type = "list"
}
variable "cluster_arn" {
}
variable "desired_count" {
}
variable "cpu" {
}
variable "memory" {
}
variable "vpc_id" {
}
variable "public_lb" {
}
variable "container_name" {
}
variable "container_definitions" {
}
variable "ecs_role_arn" {
}
variable "nat_sg" {
}
variable "dns_zone_id" {
}
variable "dns_record" {
}
