resource "aws_vpc" "main" {
  cidr_block = var.cidr

  tags = {
    Name = "Assignment 3 VPC"
  }
}
