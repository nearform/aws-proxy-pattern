# Inputs
variable "subnet_id" {}
variable "key_pair_name" {}

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

# The proxy instance with interface specified separately to make it easier to
# associate with a route table
resource "aws_network_interface" "proxy" {
    subnet_id = "${var.subnet_id}"

    # Important to disable this check to allow traffic not addressed to the
    # proxy to be received
    source_dest_check = false
}

resource "aws_instance" "proxy" {
    ami = "${data.aws_ami.ubuntu.id}"
    instance_type = "${var.proxy_instance_type}"

    key_name = "${var.key_pair_name}"

    user_data = "${file("proxy/proxy_user_data.sh")}"

    network_interface {
        network_interface_id = "${aws_network_interface.proxy.id}"
        device_index = 0
    }

    tags {
        Name = "aws_proxy_pattern_proxy"
    }
}

# Outputs
output "proxy_public_ip" {
    value = "${aws_instance.proxy.public_ip}"
}

output "proxy_network_interface_id" {
    value = "${aws_network_interface.proxy.id}"
}
