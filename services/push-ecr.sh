#!/bin/sh

set -eu

SERVICE="$1"

$(aws ecr get-login --no-include-email --region "$REGION")

cd "$(dirname $0)/$SERVICE"

docker build -t "$SERVICE" .

ECR_TAG="$AWS_ACCOUNT.dkr.ecr.eu-west-1.amazonaws.com/$SERVICE:latest"

docker tag "$SERVICE:latest" "$ECR_TAG"

docker push "$ECR_TAG"


