variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  #default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "profile" {
  type = string
}

variable "region" {
  type = string
  #default = "us-east-1"
}

variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "mysql_port" {
  type    = number
  default = 3306
}

variable "ami_id" {
  type    = string
  default = "ami-09d9d87f5568a152a"
}

variable "rds_db_name" {
  type    = string
  default = "cloud_computing"
}

variable "rds_db_username" {
  type    = string
  default = "Jun_Liang"
}

variable "rds_db_password" {
  type    = string
  default = "Me_262A1a"
}

variable "route53_zone_id" {
  type    = string
  default = "Z023941623DSGTO0HLNF6"
}

variable "route53_zone_name" {
  type    = string
  default = "junliang.me."
}

variable "route53_name" {
  type    = string
  default = "dev.junliang.me"
}
