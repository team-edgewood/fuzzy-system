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

bucket=${TF_STATE_BUCKET}
region=${TF_STATE_REGION}

cd $(dirname $0)/${component} || exit 1

[ -f "$env.vars" ] || {
  echo "No file $(dirname $0)/${component}/${env}.vars"
  exit 1
}

terraform init \
  -backend-config="bucket=${bucket}" \
  -backend-config="key=${component}-${env}.tfstate" \
  -backend-config="region=${region}" \
  -reconfigure
terraform destroy -var-file=${env}.vars