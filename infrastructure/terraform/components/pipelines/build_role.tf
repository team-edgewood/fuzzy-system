resource "aws_iam_role" "build_role" {
  name = "build"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "build_policy" {
  role = "${aws_iam_role.build_role.name}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "route53:*",
        "iam:*",
        "ecr:*",
        "ecs:*",
        "elasticloadbalancing:*",
        "acm:*",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.pipeline_bucket.arn}",
        "${aws_s3_bucket.pipeline_bucket.arn}/*",
        "arn:aws:s3:::${var.state_bucket}",
        "arn:aws:s3:::${var.state_bucket}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_security_group" "code_build" {
  vpc_id = "${module.network.vpc_id}"
  description = "Code build sg"
}

resource "aws_security_group_rule" "code_build_to_internet" {
  from_port = 443
  to_port = 443
  protocol = "tcp"
  security_group_id = "${aws_security_group.code_build.id}"
  type = "egress"
  cidr_blocks = ["0.0.0.0/0"]
}
