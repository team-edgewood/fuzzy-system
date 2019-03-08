#!/bin/sh

set -eux

cd $(dirname $0)

$(aws ecr get-login --no-include-email --region "$REGION")

ECR_TAG="${AWS_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/hello-world:${CODEBUILD_RESOLVED_SOURCE_VERSION}"

docker build -t "$ECR_TAG" .

docker push "$ECR_TAG"
