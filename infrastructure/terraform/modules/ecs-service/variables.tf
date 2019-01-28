variable "service_name" {
}
variable "subnets" {
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
  default = false
}
