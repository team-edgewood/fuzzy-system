variable "build_name" {}
variable "role" {}
variable "buildspec" {}
variable "vpc_id" {}
variable "subnets" {
  type = "list"
}
variable "sg" {}
variable "target_environment" {}
variable "state_bucket" {}
variable "region" {}
