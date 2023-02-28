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
  default = "ami-008d808a5bd19d0f3"
}
variable "key_name" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbBWPDDbGCl9ApCNF/1iNhqo9M2UXy+VnRsQzfjUBjKdI9NYU4Rvl/Ie3VFUDGo3xUwD0SxH2Sm1VJMhTNGSBDPmctNMlGO50eD6pR1amtuIe12MUaVrPGdmipg9cq8SgGTCiL8uzunMqzcXRdOtizU5jyJRSIDjwvhBYhNv/mcMDGAqXxw7APIL5XoW5aZ0IMcFI8Hh8L+KXHUaCcZkzPLhAhyUKZxUtE6wJdAmeQunbNdwQpJszwPNVrDt9qkA9p/1+5tPi5rKKdYzfgYF/GUEbMt4OtVfLEUGqimkKc5Fn+4YE67T7aDMQ+PoHbIqHpNK+Fj5BHbDvOEcBMpPqmC99Y/E9BSlD40WNmzs6EzIOLVz2GmfxpiM3AA2J2vClY5KWVEdKjtVhM3kQNhmkzbiOkGbV9ha5Pb0rKEiyW/V7PkR40tMIXTCSIzglLEDYOIL/qJkdaIE5ll6EUxEXUDb1hBJ6ym4esjAFyXr/i+MDGRN5GZxyNv6Z73eEKXE0= LiangJunAddress@gmail.com"
}
