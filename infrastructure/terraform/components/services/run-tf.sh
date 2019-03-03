#!/bin/sh

set -eux

cd $(dirname $0)

which terraform || {
  wget https://releases.hashicorp.com/terraform/0.11.11/terraform_0.11.11_linux_amd64.zip
  unzip terraform_0.11.11_linux_amd64.zip
  mv terraform /usr/local/bin
}

cmd="terraform"

[ -f ${TARGET_ENVIRONMENT}.vars ] || exit 1

eval $cmd init \
  -backend-config="bucket=${TF_STATE_BUCKET}" \
  -backend-config="key=services-${TARGET_ENVIRONMENT}.tfstate" \
  -backend-config="region=${REGION}" \
  -reconfigure
eval $cmd get
eval "$cmd ${1:-'apply'} -auto-approve -var-file=${TARGET_ENVIRONMENT}.vars \
  -var saving_mode=${SAVING_MODE:-'false'} \
  -var aws_account=${AWS_ACCOUNT:-'false'}"
