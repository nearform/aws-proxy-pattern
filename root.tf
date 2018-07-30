module "vpc" {
    source = "vpc"
    key_pair_name = "${var.key_pair_name}"
    proxy_network_interface_id = "${module.proxy.proxy_network_interface_id}"
}

module "proxy" {
    source = "proxy"
    key_pair_name = "${var.key_pair_name}"
    subnet_id = "${module.vpc.public_subnet_id}"
}

output "host_private_ip" {
    value = "${module.vpc.host_private_ip}"
}

output "management_host_public_ip" {
    value = "${module.vpc.management_public_ip}"
}

output "proxy_public_ip" {
    value = "${module.proxy.proxy_public_ip}"
}

