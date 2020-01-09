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
  "Id": "ParkMyCloudRecommendedPolicyAsOf2020-01-09",
  "Statement": [{
        "Sid": "ParkMyCloudManagement",
        "Action": [
            "autoscaling:Describe*",
            "autoscaling:ResumeProcesses",
            "autoscaling:SuspendProcesses",
            "autoscaling:UpdateAutoScalingGroup",
            "ce:Describe*",
            "ce:Get*",
            "ce:List*",
            "ec2:Describe*",
            "ec2:ModifyInstanceAttribute",
            "ec2:StartInstances",
            "ec2:StopInstances",
            "iam:GetUser",
            "rds:Describe*",
            "rds:ListTagsForResource",
            "rds:ModifyDBInstance",
            "rds:StartDBCluster",
            "rds:StartDBInstance",
            "rds:StopDBCluster",
            "rds:StopDBInstance",
            "savingsplans:Describe*"
        ],
        "Resource": "*",
        "Effect": "Allow"
    },
    {
        "Sid": "ParkMyCloudStartInstanceWithEncryptedBoot",
        "Effect": "Allow",
        "Action": "kms:CreateGrant",
        "Resource": "*"
    },
    {
        "Sid": "ParkMyCloudCloudWatchAccess",
        "Effect": "Allow",
        "Action": [
            "cloudwatch:GetMetricStatistics",
            "cloudwatch:ListMetrics"
        ],
        "Resource": "*",
        "Condition": {
            "Bool": {
                "aws:SecureTransport": "true"
            }
        }
    }
  ]
}
EOF
}
