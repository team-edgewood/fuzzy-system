#!/bin/sh

set -eux

cd $(dirname $0)

cmd="docker run -i -t hashicorp/terraform:light"

[ -f ${TARGET_ENVIRONMENT}.vars ] || exit 1

eval $cmd init \
  -backend-config="bucket=${TF_STATE_BUCKET}" \
  -backend-config="key=services-${TARGET_ENVIRONMENT}.tfstate" \
  -backend-config="region=${REGION}" \
  -reconfigure
eval $cmd get
eval $cmd apply -var-file="${TARGET_ENVIRONMENT}.vars" -var "saving_mode=${SAVING_MODE}" $(pwd)
