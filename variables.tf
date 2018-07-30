variable "region" {
    type = "string"
    default = "eu-west-2"
}

# Key pair to use for instances
variable "key_pair_name" {
    type = "string"
}

# CIDR block for example VPC
variable "cidr_block" {
    type = "string"
    default = "10.0.0.0/16"
}

# CIDR block for public subnet
variable "cidr_public_subnet" {
    type = "string"
    default = "10.0.1.0/24"
}

# CIDR block for private subnet
variable "cidr_private_subnet" {
    type = "string"
    default = "10.0.2.0/24"
}

# AWS instance type to use for proxy
variable "proxy_instance_type" {
    type = "string"
    default = "t2.micro"
}
