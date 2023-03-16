resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "Public Subnet ${count.index + 1}"
  }
}
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "Private Subnet ${count.index + 1}"
  }
}
# resource "aws_db_subnet_group" "private_subnet_group" {
#   name       = "private_subnet_group"
#   subnet_ids = [aws_subnet.private_subnets[0].id, aws_subnet.private_subnets[1].id, aws_subnet.private_subnets[2].id]
#   tags = {
#     Name = "private subnet group"
#   }
# }
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Project VPC IG"
  }
}
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Private Route Table"
  }
}
resource "aws_route_table_association" "public_subnet_asso" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "private_subnet_asso" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
  route_table_id = aws_route_table.private_rt.id
}
# resource "aws_iam_role" "EC2-CSYE6225" {
#   name = "EC2-CSYE6225"
#   assume_role_policy = jsonencode({
#     "Version" : "2012-0-17",
#     "Statement" : [{
#       "Action" : [
#         "s3:PutObject",
#         "s3:PutObjectAcl",
#         "s3:GetObject",
#         "s3:GetObjectAcl",
#         "s3:DeleteObject"
#       ],
#       "Effect" : "Allow",
#       "Resource" : [
#         "arn:aws:s3:::${aws_s3_bucket.s3_bucket.bucket}",
#         "arn:aws:s3:::${aws_s3_bucket.s3_bucket.bucket}/*",
#       ]
#     }]
#   })
# }
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
  #   egress {
  #     from_port   = 0
  #     to_port     = 65535
  #     protocol    = "-1"
  #     cidr_blocks = ["0.0.0.0/0"]
  #   }
}
resource "aws_instance" "ec2_instance" {
  ami           = var.ami_id # Use the customized AMI ID here
  instance_type = "t2.micro"
  vpc_security_group_ids = [
    aws_security_group.ec2_security_group.id
  ]
  subnet_id                   = aws_subnet.public_subnets[0].id
  associate_public_ip_address = true
  disable_api_termination     = false
  root_block_device {
    volume_size = 50
    volume_type = "gp2"
  }
}
# resource "aws_security_group" "rds_security_group" {
#   vpc_id = aws_vpc.main.id
#   ingress {
#     from_port   = var.mysql_port
#     to_port     = var.mysql_port
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   egress {
#     from_port   = var.mysql_port
#     to_port     = var.mysql_port
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }
# resource "aws_db_parameter_group" "rds_parameter_group" {
#   family = "mysql8.0"
# }
# resource "aws_db_instance" "rds_instance" {
#   instance_class = "db.t3.micro"
#   vpc_security_group_ids = [
#     aws_security_group.rds_security_group.id
#   ]
#   engine               = "mysql"
#   engine_version       = "8.0"
#   multi_az             = false
#   identifier           = "csye6225"
#   username             = "csye6225"
#   password             = "Me_262A1a"
#   parameter_group_name = "aws_db_parameter_group.rds_parameter_group"
#   db_subnet_group_name = "private_subnet_group"
#   publicly_accessible  = false
#   db_name              = "csye6225"
# }
# resource "aws_s3_bucket" "s3_bucket" {
#   force_destroy = true
# }
# resource "aws_s3_bucket_lifecycle_configuration" "s3_bucket_lifecycle_configuration" {
#   bucket = aws_s3_bucket.s3_bucket.bucket
#   rule {
#     id = "transition_rule"
#     transition {
#       days          = 30
#       storage_class = "STANDARD_IA"
#     }
#     status = "Enabled"
#   }
# }
#resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
#  bucket = aws_s3_bucket.s3_bucket.bucket
#  rule {
#    apply_server_side_encryption_by_default {
#      sse_algorithm = "AES256"
#    }
#  }
#}
data "aws_route53_zone" "junliang" {
  zone_id = var.route53_zone_id
  #  name         = var.route53_zone_name
  #  private_zone = true
}
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.junliang.zone_id
  name    = data.aws_route53_zone.junliang.name
  type    = "A"
  ttl     = 60
  records = ["${aws_instance.ec2_instance.public_ip}"]
}
