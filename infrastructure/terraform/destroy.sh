#!/bin/bash

set -ue

usage() {
  echo "USAGE: $0 <component> <env>"
  exit 1
}

if [ $# -ne 2 ]; then
  usage
fi

component="$1"
env="$2"

cd $(dirname $0)/components/${component} || exit 1

[ -f "$env.vars" ] || {
  echo "No file $(dirname $0)/components/${component}/${env}.vars"
  exit 1
}

terraform init \
  -backend-config="bucket=${TF_STATE_BUCKET}" \
  -backend-config="key=${component}-${env}.tfstate" \
  -backend-config="region=${REGION}" \
  -reconfigure
terraform destroy -var-file=${env}.vars
