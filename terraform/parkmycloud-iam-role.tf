provider "aws" {
  access_key = "put-access-key-here"
  secret_key = "put-secret-key-here"
  region     = "us-east-1"
}

resource "aws_iam_role" "ParkMyCloud_Role" {
  name = "ParkMyCloud_Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::753542375798:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ParkMyCloud_policy" {
  name = "ParkMyCloud_policy"
  role = "${aws_iam_role.ParkMyCloud_Role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "iam:GetUser",
        "ec2:Describe*",
        "ec2:StartInstances",
        "ec2:StopInstances",
        "autoscaling:Describe*",
        "autoscaling:UpdateAutoScalingGroup",
        "autoscaling:SuspendProcesses",
        "autoscaling:ResumeProcesses",
        "rds:DescribeDBInstances",
        "rds:ListTagsForResource",
        "rds:StartDBInstance",
        "rds:StopDBInstance",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:GetLogEvents",
        "logs:TestMetricFilter",
        "logs:FilterLogEvents"
      ],
      "Resource": [
        "*"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF
}
