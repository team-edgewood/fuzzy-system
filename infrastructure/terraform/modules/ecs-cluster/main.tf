resource "aws_ecs_cluster" "cluster" {
  name = "${var.cluster_name}-${var.environment}"
}

resource "aws_iam_policy" "ecs_policy" {
  name = "ecs-policy-${var.cluster_name}-${var.environment}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "ecs_role" {
  name = "ecs-role-${var.cluster_name}-${var.environment}"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
            "Service": [
                "ecs-tasks.amazonaws.com"
            ]
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_role_policy_attachment" {
  role       = "${aws_iam_role.ecs_role.name}"
  policy_arn = "${aws_iam_policy.ecs_policy.arn}"
}
