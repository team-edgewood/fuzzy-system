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
    image = "aws/codebuild/ubuntu-base:14.04"
    type = "LINUX_CONTAINER"

    environment_variable {
      "name"  = "TARGET_ENVIRONMENT"
      "value" = "${var.target_environment}"
    }
    environment_variable {
      "name"  = "TF_STATE_BUCKET"
      "value" = "${var.state_bucket}"
    }
    environment_variable {
      "name"  = "REGION"
      "value" = "${var.region}"
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
