#!/bin/sh

set -eux

cd $(dirname $0)

cmd="terraform"

eval $cmd init \
  -backend-config="bucket=${TF_STATE_BUCKET}" \
  -backend-config="key=pipelines-main.tfstate" \
  -backend-config="region=${REGION}" \
  -reconfigure
eval $cmd get
eval $cmd apply -var-file="terraform.vars" \
  -var "saving_mode=${SAVING_MODE:-'false'}" \
  -var "oauth_token=${OAUTH_TOKEN}" \
  -var "state_bucket=${TF_STATE_BUCKET}" \
  -var "aws_account=${AWS_ACCOUNT}" \
  -var "github_owner=${GITHUB_OWNER}" \
  -var "github_repo=${GITHUB_REPO}" \
  $(pwd)
