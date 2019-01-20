provider "aws" {
  region     = "${var.region}"
}

terraform {
  backend "s3" {
    bucket = "${var.state-bucket-name}"
    key    = "instance.tfstate"
    region = "${var.region}"
  }
}
