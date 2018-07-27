variable "region" {
    type = "string"
    default = "eu-west-2"
}

# Uses ~/.aws/credentials, default profile
provider "aws" {
    region = "${var.region}"
    profile = "default"
}

# Key pair to use for instances
variable "key_pair_name" {
    type = "string"
}

# Data inputs
data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"]
}

data "aws_ami" "amazon" {
    most_recent = true

    filter {
        name = "name"
        values = ["amzn-ami-hvm-2018.03.0.20180622-x86_64-gp2"]
    }
}

# VPC Resources
resource "aws_vpc" "aws_proxy_pattern_vpc" {
    cidr_block = "10.0.0.0/16"

    tags {
        Name = "aws_proxy_pattern_vpc"
    }
    enable_dns_support = true
    enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {
    vpc_id = "${aws_vpc.aws_proxy_pattern_vpc.id}"
}

# The proxy will live here, think of it as the DMZ where everything gets
# internet access if it has a public IP
resource "aws_subnet" "public_subnet" {
    vpc_id = "${aws_vpc.aws_proxy_pattern_vpc.id}"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true

    tags {
        Name = "aws_proxy_pattern_public_subnet"
    }
}

# The private host will live here and default routes traffic out to the public
# subnet
resource "aws_subnet" "private_subnet" {
    vpc_id = "${aws_vpc.aws_proxy_pattern_vpc.id}"
    cidr_block = "10.0.2.0/24"

    tags {
        Name = "aws_proxy_pattern_private_subnet"
    }
}

# Route tables for each type of subnet
resource "aws_route_table" "public_routes" {
    vpc_id = "${aws_vpc.aws_proxy_pattern_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.igw.id}"
    }

    tags {
        Name = "public_routes"
    }
}

resource "aws_route_table" "private_routes" {
    vpc_id = "${aws_vpc.aws_proxy_pattern_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        network_interface_id = "${aws_network_interface.proxy.id}"
    }

    tags {
        Name = "private_routes"
    }
}

resource "aws_route_table_association" "public_routes_association" {
    subnet_id = "${aws_subnet.public_subnet.id}"
    route_table_id = "${aws_route_table.public_routes.id}"
}

resource "aws_route_table_association" "private_routes_association" {
    subnet_id = "${aws_subnet.private_subnet.id}"
    route_table_id = "${aws_route_table.private_routes.id}"
}

# The proxy instance with interface specified separately to make it easier to
# associate with a route table
resource "aws_network_interface" "proxy" {
    subnet_id = "${aws_subnet.public_subnet.id}"

    # Important to disable this check to allow traffic not addressed to the
    # proxy to be received
    source_dest_check = false
}

resource "aws_instance" "proxy" {
    ami = "${data.aws_ami.amazon.id}"
    instance_type = "t2.micro"

    key_name = "${var.key_pair_name}"

    user_data = "${file("proxy_user_data.sh")}"

    network_interface {
        network_interface_id = "${aws_network_interface.proxy.id}"
        device_index = 0
    }

    tags {
        Name = "aws_proxy_pattern_proxy"
    }
}

# The example host instance
resource "aws_instance" "host" {
    ami = "${data.aws_ami.ubuntu.id}"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.private_subnet.id}"

    key_name = "${var.key_pair_name}"

    tags {
        Name = "aws_proxy_pattern_host"
    }
}

# A host that will enable us to SSH to the private host for testing
resource "aws_instance" "management_host" {
    ami = "${data.aws_ami.ubuntu.id}"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.public_subnet.id}"

    key_name = "${var.key_pair_name}"

    tags {
        Name = "aws_proxy_pattern_management_host"
    }
}

output "proxy_public_ip" {
    value = "${aws_instance.proxy.public_ip}"
}

output "host_private_ip" {
    value = "${aws_instance.proxy.private_ip}"
}

output "management_public_ip" {
    value = "${aws_instance.management_host.public_ip}"
}
