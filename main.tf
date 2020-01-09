# Create our server infrastructure needed
resource "aws_instance" "splunk-server" {
  ami           = "ami-047942f791d04b69f"
  instance_type = "t2.small"
  security_groups = ["${aws_security_group.splunk_allow.name}"]
  iam_instance_profile = "${aws_iam_instance_profile.splunk_profile.name}"
  tags = {
    Name = "splunk-server"
  }
}
resource "aws_security_group" "splunk_allow" {
  name = "allow_splunk_ports_ingress"
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 554
    to_port     = 554
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8089
    to_port     = 8089
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 997
    to_port     = 997
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_iam_role" "splunk_role" {
  name = "splunk_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "splunk_policy" {
  name = "splunk_policy"
  role = "${aws_iam_role.splunk_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:Get*",
        "s3:List*",
        "sqs:*",
        "sns:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "splunk_profile" {
  name = "splunk_profile"
  role = "${aws_iam_role.splunk_role.name}"
}


resource "aws_instance" "automation-server" {
  ami           = "ami-06d51e91cea0dac8d"
  instance_type = "t2.small"
  security_groups = ["${aws_security_group.automation_allow.name}"]
  tags = {
    Name = "automation-server"
  }
}
resource "aws_security_group" "automation_allow" {
  name = "allow_automation_ports_ingress"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Configure our CloudTrail

data "aws_caller_identity" "current" {}

resource "aws_cloudtrail" "bsides" {
  name                          = "bsides-trail"
  s3_bucket_name                = "${aws_s3_bucket.bsides_trail.id}"
  s3_key_prefix                 = "prefix"
  include_global_service_events = true
  is_multi_region_trail = true
}

resource "aws_s3_bucket" "bsides_trail" {
  bucket        = "bsides-trail"
  force_destroy = true
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::bsides-trail"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::bsides-trail/prefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}