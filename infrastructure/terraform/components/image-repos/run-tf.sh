#!/bin/sh

set -eux

cd $(dirname $0)

which terraform || {
  wget https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_linux_amd64.zip
  unzip terraform_0.11.13_linux_amd64.zip
  mv terraform /usr/local/bin
}

cmd="terraform"

eval $cmd init \
  -backend-config="bucket=${TF_STATE_BUCKET}" \
  -backend-config="key=image-repos.tfstate" \
  -backend-config="region=${REGION}" \
  -reconfigure
eval $cmd get
eval "$cmd ${1:-'apply'} -auto-approve -var-file=terraform.vars"
