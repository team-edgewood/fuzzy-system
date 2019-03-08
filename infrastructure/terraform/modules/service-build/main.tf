resource "aws_codebuild_project" "build" {
  name = "${var.build_name}"
  description = "${var.build_name}"
  build_timeout = "5"
  service_role = "${var.role}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/docker:18.09.0"
    type = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      "name"  = "REGION"
      "value" = "${var.region}"
    }
    environment_variable {
      "name"  = "AWS_ACCOUNT"
      "value" = "${var.aws_account}"
    }

  }

  source {
    type = "CODEPIPELINE"
    buildspec = "${var.buildspec}"
  }

  vpc_config {
    vpc_id = "${var.vpc_id}"

    subnets = [
      "${var.subnets}"]

    security_group_ids = [
      "${var.sg}"]
  }
}
