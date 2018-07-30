# Subnet to place proxy in
variable "subnet_id" {}

# SSH key pair inside AWS to use to access proxy
variable "key_pair_name" {}

# AWS instance type to use for proxy
variable "proxy_instance_type" {
    type = "string"
    default = "t2.micro"
}
