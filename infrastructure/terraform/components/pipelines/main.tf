module "network" {
  source = "../../modules/network"
  second_octet = "${var.second_octet}"
  saving_mode = "${var.saving_mode}"
}

module "services_terraform_build_dev" {
  source = "../../modules/terraform-build"
  sg = "${aws_security_group.code_build.id}"
  build_name = "services-dev"
  buildspec = "infrastructure/terraform/components/services/buildspec.yml"
  vpc_id = "${module.network.vpc_id}"
  subnets = ["${module.network.private_subnets}"]
  role = "${aws_iam_role.build_role.id}"
  target_environment = "dev"
  state_bucket = "${var.state_bucket}"
  region = "${var.region}"
}

resource "aws_s3_bucket" "pipeline_bucket" {
  bucket = "${var.aws_account}-pipeline"
  acl    = "private"
}

resource "aws_codepipeline" "test" {
  name     = "tf-test-pipeline"
  role_arn = "${aws_iam_role.pipeline_role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.pipeline_bucket.bucket}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["sourcecode"]

      configuration = {
        Owner  = "${var.github_owner}"
        Repo   = "${var.github_repo}"
        Branch = "master"
        OAuthToken = "${var.oauth_token}"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["sourcecode"]
      version         = "1"

      configuration = {
        ProjectName = "${module.services_terraform_build_dev.build_name}"
      }
    }
  }
}
