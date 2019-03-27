variable "build_name" {}
variable "role" {}
variable "buildspec" {}
variable "vpc_id" {}
variable "subnets" {
  type = "list"
}
variable "sg" {}
variable "aws_account" {}
variable "environment" {}
variable "service" {}
