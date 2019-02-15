resource "aws_codebuild_project" "example" {
  name          = "${var.build_name}"
  description   = "${var.build_name}"
  build_timeout = "5"
  service_role = "${var.role}"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/nodejs:6.3.1"
    type         = "LINUX_CONTAINER"
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/team-edgewood/fuzzy-system.git"
    git_clone_depth = 1
    buildspec = "${var.buildspec}"
  }

  vpc_config {
    vpc_id = "${var.vpc_id}"

    subnets = ["${var.subnets}"]

    security_group_ids = ["${var.sg}"]
  }
}
