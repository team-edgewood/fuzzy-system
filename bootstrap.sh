#!/bin/bash

set -eu

count_bucket() {
  aws s3api list-buckets | jq --arg bucket "$1" '.Buckets | map(select(.Name == $bucket)) | length'
}

bucket=${TF_STATE_BUCKET}
region=${TF_STATE_REGION}

if [ $(count_bucket $bucket) -eq 0 ]; then
  aws s3api create-bucket --bucket ${bucket} --create-bucket-configuration "LocationConstraint=${region}"
fi

