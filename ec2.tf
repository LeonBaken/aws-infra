data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "EC2-CSYE6225" {
  name               = "EC2-CSYE6225"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    effect  = "Allow"
    actions = [
      "sts:AssumeRole",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.s3_bucket.bucket}",
      "arn:aws:s3:::${aws_s3_bucket.s3_bucket.bucket}/*"
    ]
  }
}

resource "aws_iam_policy" "WebAppS3" {
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  role       = aws_iam_role.EC2-CSYE6225.name
  policy_arn = aws_iam_policy.WebAppS3.arn
}

resource "aws_iam_role_policy_attachment" "logs_policy_attachment" {
  role       = aws_iam_role.EC2-CSYE6225.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "iam_instance_profile" {
  role = aws_iam_role.EC2-CSYE6225.name
}

resource "aws_security_group" "ec2_security_group" {
  vpc_id = aws_vpc.main.id
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
  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = var.mysql_port
    to_port     = var.mysql_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_instance" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.ec2_security_group.id]
  subnet_id                   = aws_subnet.public_subnets[0].id
  iam_instance_profile        = aws_iam_instance_profile.iam_instance_profile.name
  associate_public_ip_address = true
  disable_api_termination     = false
  root_block_device {
    volume_size = 50
    volume_type = "gp2"
  }
  user_data = <<EOF
  #!/bin/bash
  sudo echo "bucketName=${aws_s3_bucket.s3_bucket.bucket}" >> /home/ec2-user/webapp/application.properties
  sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/home/ec2-user/webapp/cloudWatchConfig.json \
    -s
  sudo java \
    -Dspring.config.location=/home/ec2-user/webapp/application.properties \
    -Ddb_endpoint=${aws_db_instance.rds_instance.endpoint} \
    -Ddb_name=${aws_db_instance.rds_instance.db_name} \
    -Ddb_username=${aws_db_instance.rds_instance.username} \
    -Ddb_password=${aws_db_instance.rds_instance.password} \
    -jar /home/ec2-user/webapp/webapp-0.0.1-SNAPSHOT.jar
  EOF
}