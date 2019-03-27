#!/bin/sh

set -eux

TASK_DEFINITION_FILE=$(mktemp)
CODEDEPLOY_APPSPEC=$(mktemp)

SUBNETS=$(aws ec2 describe-subnets --filter Name=tag:Name,Values=services-${ENVIRONMENT}-private --query 'Subnets[*].SubnetId')
SECURITY_GROUPS=$(aws ec2 describe-security-groups --filters Name=tag:name,Values=${SERVICE}-${ENVIRONMENT} --query 'SecurityGroups[*].GroupId')
ECS_ROLE=$(aws iam get-role --role-name ecs-role-application-cluster-${ENVIRONMENT} --query 'Role.Arn')
TASK_DEFINITION=$(aws ecs describe-task-definition --task-definition ${SERVICE} --query 'taskDefinition.taskDefinitionArn')

pip install --upgrade awscli || sudo pip install --upgrade awscli

cat <<HERE > "$TASK_DEFINITION_FILE"
{
    "family": "${SERVICE}-${ENVIRONMENT}",
    "executionRoleArn": ${ECS_ROLE},
    "networkMode": "awsvpc",
    "containerDefinitions": [
        {
            "name": "${SERVICE}-${ENVIRONMENT}",
            "image": "${AWS_ACCOUNT}.dkr.ecr.eu-west-1.amazonaws.com/${SERVICE}:${CODEBUILD_RESOLVED_SOURCE_VERSION}",
            "cpu": 1,
            "memory": 512,
            "portMappings": [
                {
                    "containerPort": 80,
                    "hostPort": 80
                }
            ],
            "essential": true
        }
    ],
    "requiresCompatibilities": [
        "FARGATE"
    ],
    "cpu": "256",
    "memory": "512"
}
HERE

cat <<HERE > "$CODEDEPLOY_APPSPEC"
version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: ${TASK_DEFINITION}
        LoadBalancerInfo:
          ContainerName: "${SERVICE}-${ENVIRONMENT}"
          ContainerPort: 80
        NetworkConfiguration:
          AwsvpcConfiguration:
            Subnets: ${SUBNETS}
            SecurityGroups: ${SECURITY_GROUPS}
            AssignPublicIp: "DISABLED"
HERE

aws ecs deploy \
  --service ${SERVICE}-${ENVIRONMENT} \
  --task-definition ${TASK_DEFINITION_FILE} \
  --codedeploy-appspec ${CODEDEPLOY_APPSPEC} \
  --cluster application-cluster-${ENVIRONMENT} \
  --codedeploy-application ${SERVICE}-${ENVIRONMENT} \
  --codedeploy-deployment-group ${SERVICE}-${ENVIRONMENT}-dg
