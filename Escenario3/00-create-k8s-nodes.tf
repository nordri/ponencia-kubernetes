# Configure the OpenStack Provider
provider "openstack" {
    user_name   = "demo"
    tenant_name = "demo"
    password    = "p4ssw0rd"
    auth_url    = "http://192.168.101.105:35357/v3"
    domain_name = "Default"
}

##Setup needed variables
variable "node-count" {}
variable "internal-ip-pool" {}
variable "floating-ip-pool" {}
variable "image-name" {}
variable "image-flavor" {}
variable "security-groups" {}
variable "key-pair" {}

##Create a single master node and floating IP
resource "openstack_compute_floatingip_v2" "master-ip" {
  pool = "${var.floating-ip-pool}"
}

resource "openstack_compute_instance_v2" "k8s-master" {
  name = "k8s-master"
  image_id = "${var.image-name}"
  flavor_name = "${var.image-flavor}"
  key_pair = "${var.key-pair}"
  security_groups = ["${split(",", var.security-groups)}"]
  network {
    name = "${var.internal-ip-pool}"
  }
  floating_ip = "${openstack_compute_floatingip_v2.master-ip.address}"
}

##Create desired number of k8s nodes and floating IPs
resource "openstack_compute_floatingip_v2" "node-ip" {
  pool = "${var.floating-ip-pool}"
  count = "${var.node-count}"
}

resource "openstack_compute_instance_v2" "k8s-node" {
  count = "${var.node-count}"
  name = "k8s-node-${count.index}"
  image_id = "${var.image-name}"
  flavor_name = "${var.image-flavor}"
  key_pair = "${var.key-pair}"
  security_groups = ["${split(",", var.security-groups)}"]
  network {
    name = "${var.internal-ip-pool}"
  }
  floating_ip = "${element(openstack_compute_floatingip_v2.node-ip.*.address, count.index)}"
}
