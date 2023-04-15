resource "aws_security_group" "rds_security_group" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = var.mysql_port
    to_port     = var.mysql_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = var.mysql_port
    to_port     = var.mysql_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_parameter_group" "rds_parameter_group" {
  family = "mysql8.0"
}

resource "aws_db_subnet_group" "db_subnet_group" {
  subnet_ids = [
    aws_subnet.private_subnets[0].id,
    aws_subnet.private_subnets[1].id,
    aws_subnet.private_subnets[2].id
  ]
}

resource "aws_db_instance" "rds_instance" {
  allocated_storage      = 50
  instance_class         = "db.t3.micro"
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]
  engine                 = "mysql"
  engine_version         = "8.0"
  multi_az               = false
  identifier             = "csye6225"
  username               = var.rds_db_username
  password               = var.rds_db_password
  parameter_group_name   = aws_db_parameter_group.rds_parameter_group.id
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.id
  publicly_accessible    = false
  db_name                = var.rds_db_name
  skip_final_snapshot    = true
}