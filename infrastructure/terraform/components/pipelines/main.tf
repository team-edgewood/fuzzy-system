module "network" {
  source = "../../modules/network"
  second_octet = "${var.second_octet}"
  saving_mode = "${var.saving_mode}"
}

module "image_repos_terraform_build" {
  source = "../../modules/terraform-build"
  sg = "${aws_security_group.code_build.id}"
  build_name = "image_repos"
  buildspec = "infrastructure/terraform/components/image-repos/buildspec.yml"
  vpc_id = "${module.network.vpc_id}"
  subnets = ["${module.network.private_subnets}"]
  role = "${aws_iam_role.build_role.id}"
  state_bucket = "${var.state_bucket}"
  region = "${var.region}"
  aws_account = "${var.aws_account}"
}

module "services_terraform_build_test" {
  source = "../../modules/terraform-build"
  sg = "${aws_security_group.code_build.id}"
  build_name = "services-terraform-test"
  buildspec = "infrastructure/terraform/components/services/buildspec.yml"
  vpc_id = "${module.network.vpc_id}"
  subnets = ["${module.network.private_subnets}"]
  role = "${aws_iam_role.build_role.id}"
  target_environment = "test"
  state_bucket = "${var.state_bucket}"
  region = "${var.region}"
  aws_account = "${var.aws_account}"
}

module "integration_test" {
  source = "../../modules/terraform-build"
  sg = "${aws_security_group.code_build.id}"
  build_name = "integration_test"
  buildspec = "integration-test/buildspec.yml"
  vpc_id = "${module.network.vpc_id}"
  subnets = ["${module.network.private_subnets}"]
  role = "${aws_iam_role.build_role.id}"
  target_environment = "test"
  state_bucket = "${var.state_bucket}"
  region = "${var.region}"
  aws_account = "${var.aws_account}"
}

module "hello_world_build" {
  source = "../../modules/service-build"
  sg = "${aws_security_group.code_build.id}"
  build_name = "hello_world_build"
  buildspec = "services/hello-world/buildspec.yml"
  vpc_id = "${module.network.vpc_id}"
  subnets = ["${module.network.private_subnets}"]
  role = "${aws_iam_role.build_role.id}"
  region = "${var.region}"
  aws_account = "${var.aws_account}"
}

module "services_terraform_build_prod" {
  source = "../../modules/terraform-build"
  sg = "${aws_security_group.code_build.id}"
  build_name = "services-terraform-prod"
  buildspec = "infrastructure/terraform/components/services/buildspec.yml"
  vpc_id = "${module.network.vpc_id}"
  subnets = ["${module.network.private_subnets}"]
  role = "${aws_iam_role.build_role.id}"
  target_environment = "prod"
  state_bucket = "${var.state_bucket}"
  region = "${var.region}"
  aws_account = "${var.aws_account}"
}

resource "aws_s3_bucket" "pipeline_bucket" {
  bucket = "${var.aws_account}-pipeline"
  acl    = "private"
}

resource "aws_codepipeline" "services" {
  name     = "services-pipeline"
  role_arn = "${aws_iam_role.pipeline_role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.pipeline_bucket.bucket}"
    type     = "S3"
  }

  stage {
    name = "source-code"

    action {
      name             = "source-code"
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
    name = "common"

    action {
      name            = "image_repos"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["sourcecode"]
      version         = "1"
      run_order       = "1"

      configuration = {
        ProjectName = "${module.image_repos_terraform_build.build_name}"
      }
    }
  }


  stage {
    name = "test"


    action {
      name            = "hello-world-build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["sourcecode"]
      version         = "1"
      run_order       = "1"

      configuration = {
        ProjectName = "${module.hello_world_build.build_name}"
      }
    }

    action {
      name            = "services-terraform"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["sourcecode"]
      version         = "1"
      run_order       = "2"

      configuration = {
        ProjectName = "${module.services_terraform_build_test.build_name}"
      }
    }

    action {
      name            = "integration-test"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["sourcecode"]
      version         = "1"
      run_order       = "3"

      configuration = {
        ProjectName = "${module.integration_test.build_name}"
      }
    }
  }

  stage {
    name = "prod"

    action {
      name            = "services"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["sourcecode"]
      version         = "1"
      run_order       = "1"

      configuration = {
        ProjectName = "${module.services_terraform_build_prod.build_name}"
      }
    }
  }
}
