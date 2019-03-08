variable "second_octet" {}
variable "domain" {
  default = "team-edgewood.com"
}
variable "subdomain" {}
variable "root_domain_zone_id" {
  default = "Z1QTGG41PYAVAC"
}
variable "environment" {}
variable "aws_account" {}
variable region {
  type = "string"
}
variable "saving_mode" {
  default = "false"
}
variable "source_version" {}

