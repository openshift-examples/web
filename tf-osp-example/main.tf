provider "openstack" {
  user_name   = "${var.OS_USERNAME}"
  tenant_name = "${var.OS_PROJECT_NAME}"
  password    = "${var.OS_PASSWORD}"
  auth_url    = "${var.OS_AUTH_URL}"
  region      = "${var.OS_REGION_NAME}"
}

data "openstack_images_image_v2" "rhel" {
  name = "rhel-server-7.5-update-4-x86_64"
  most_recent = true
}

data "openstack_networking_subnet_v2" "private" {
  name = "private_subnet"
}

data "openstack_networking_subnet_v2" "public" {
  name = "public_subnet"
}

data "template_file" "script" {
  template = "${file("${path.module}/terraform.cloud-init.tpl")}"

  vars {
    rh_subscription_username  = "${var.rh_subscription_username}"
    rh_subscription_password  = "${var.rh_subscription_password}"
    rh_subscription_pool      = "${var.rh_subscription_pool}"
  }
}

output "cidr" {
  value = "${data.openstack_networking_subnet_v2.private.cidr}"
}

/*

   Security groups

   Based on https://docs.openshift.com/container_platform/3.11/install/prerequisites.html#install_config_network_using_firewalld

*/

resource "openstack_compute_secgroup_v2" "ocp_internal_communication" {
  name        = "ocp_internal_communication"
  description = "OpenShift internal communication, rule should apply to all nodes"

  # DNS
  rule {
    from_port   = 8053 
    to_port     = 8053
    ip_protocol = "tcp"
    cidr        = "${data.openstack_networking_subnet_v2.private.cidr}"
  }

  rule {
    from_port   = 8053 
    to_port     = 8053
    ip_protocol = "udp"
    cidr        = "${data.openstack_networking_subnet_v2.private.cidr}"
  }
 rule {
    from_port   = 53 
    to_port     = 53
    ip_protocol = "tcp"
    cidr        = "${data.openstack_networking_subnet_v2.private.cidr}"
  }

  rule {
    from_port   = 53 
    to_port     = 53
    ip_protocol = "udp"
    cidr        = "${data.openstack_networking_subnet_v2.private.cidr}"
  }

  # SDN
  rule {
    from_port   = 4789
    to_port     = 4789
    ip_protocol = "udp"
    cidr        = "${data.openstack_networking_subnet_v2.private.cidr}"
  }

  # The master proxies to node hosts via the Kubelet for oc commands.
  # Master to node 
  rule {
    from_port   = 10250
    to_port     = 10250
    ip_protocol = "tcp"
    cidr        = "${data.openstack_networking_subnet_v2.private.cidr}"
  }

  # If using CRI_O, open this port to allow oc exec and oc rsh operations.
  # Master to node 
  rule {
    from_port   = 10010
    to_port     = 10010
    ip_protocol = "tcp"
    cidr        = "${data.openstack_networking_subnet_v2.private.cidr}"
  }

  # etcd
  # Master to Master / etcd hosts
  rule {
    from_port   = 2379
    to_port     = 2380
    ip_protocol = "tcp"
    cidr        = "${data.openstack_networking_subnet_v2.private.cidr}"
  }

  # Port that the controller service listens on. Required to be open for the /metrics and /healthz endpoints.
  rule {
    from_port   = 8444
    to_port     = 8444
    ip_protocol = "tcp"
    cidr        = "${data.openstack_networking_subnet_v2.private.cidr}"
  }




}

resource "openstack_compute_secgroup_v2" "master_api" {
  name        = "master_api"
  description = "External access to master_api"
  
  rule {
    from_port   = 8443
    to_port     = 8443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "router" {
  name        = "router"
  description = "External access to router"
  
  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  
  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "dns" {
  name        = "DNS"
  description = "Allow port 53 (DNS) tcp and udp"

  rule {
    from_port   = 53 
    to_port     = 53
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 53 
    to_port     = 53
    ip_protocol = "udp"
    cidr        = "0.0.0.0/0"
  }
}


resource "openstack_compute_secgroup_v2" "ssh" {
  name        = "SSH"
  description = "Allow port 22 (ssh) tcp"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

}

/*

   Load balancer

*/

resource "openstack_lb_loadbalancer_v2" "single_ocp" {
  vip_subnet_id = "${data.openstack_networking_subnet_v2.private.id}"
}


resource "openstack_networking_floatingip_v2" "single_ocp" {
  pool    = "public"
  port_id = "${openstack_lb_loadbalancer_v2.single_ocp.vip_port_id}"
}


output "public_ip" {
  value = "${openstack_networking_floatingip_v2.single_ocp.address}"
}

resource "openstack_lb_listener_v2" "single_ocp_admin_api" {
  protocol        = "HTTPS"
  protocol_port   = 8443
  loadbalancer_id = "${openstack_lb_loadbalancer_v2.single_ocp.id}"
}


resource "openstack_lb_listener_v2" "single_ocp_bastion" {
  protocol        = "TCP"
  protocol_port   = 22
  loadbalancer_id = "${openstack_lb_loadbalancer_v2.single_ocp.id}"
}


resource "openstack_lb_listener_v2" "single_ocp_router_https" {
  protocol        = "HTTPS"
  protocol_port   = 443
  loadbalancer_id = "${openstack_lb_loadbalancer_v2.single_ocp.id}"
}


resource "openstack_lb_listener_v2" "single_ocp_router_http" {
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = "${openstack_lb_loadbalancer_v2.single_ocp.id}"
}

resource "openstack_lb_pool_v2" "single_ocp_admin_api" {
  protocol    = "HTTPS"
  lb_method   = "ROUND_ROBIN"
  listener_id = "${openstack_lb_listener_v2.single_ocp_admin_api.id}"
}


resource "openstack_lb_pool_v2" "single_ocp_bastion" {
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = "${openstack_lb_listener_v2.single_ocp_bastion.id}"
}


resource "openstack_lb_pool_v2" "single_ocp_router_https" {
  protocol    = "HTTPS"
  lb_method   = "ROUND_ROBIN"
  listener_id = "${openstack_lb_listener_v2.single_ocp_router_https.id}"
}

resource "openstack_lb_pool_v2" "single_ocp_router_http" {
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = "${openstack_lb_listener_v2.single_ocp_router_http.id}"
}


resource "openstack_lb_monitor_v2" "single_ocp_bastion" {
  pool_id     = "${openstack_lb_pool_v2.single_ocp_bastion.id}"
  type        = "TCP"
  delay       = 20
  timeout     = 10
  max_retries = 5
}


resource "openstack_lb_monitor_v2" "single_ocp_admin_api" {
  pool_id     = "${openstack_lb_pool_v2.single_ocp_admin_api.id}"
  type        = "HTTPS"
  url_path    = "/"
  expected_codes  = "200"
  delay       = 20
  timeout     = 10
  max_retries = 5
}

resource "openstack_lb_monitor_v2" "single_ocp_router_https" {
  pool_id     = "${openstack_lb_pool_v2.single_ocp_router_https.id}"
  type        = "HTTPS"
  url_path    = "/"
  expected_codes  = "200"
  delay       = 20
  timeout     = 10
  max_retries = 5
}

resource "openstack_lb_monitor_v2" "single_ocp_router_http" {
  pool_id     = "${openstack_lb_pool_v2.single_ocp_router_http.id}"
  type        = "HTTP"
  url_path    = "/"
  expected_codes  = "200"
  delay       = 20
  timeout     = 10
  max_retries = 5
}

/*

   Instances

*/



resource "openstack_compute_instance_v2" "bastion" {
  name = "bastion"
  user_data     = "${data.template_file.script.rendered}\nhostname: bastion\nfqdn: bastion"
  flavor_name = "m1.small"
  key_pair = "default"
  security_groups = ["default","ssh"]
  network {
    name = "private"
  }

  metadata {
    role = "bastion"
  }

  block_device {
    uuid                  = "${data.openstack_images_image_v2.rhel.id}"
    source_type           = "image"
    destination_type      = "volume"
    volume_size	          = 20
    boot_index            = 0
    delete_on_termination = true
  }
}

resource "openstack_lb_member_v2" "single_ocp_bastion" {
  address  = "${openstack_compute_instance_v2.bastion.access_ip_v4}"
  protocol_port = 22
  pool_id   = "${openstack_lb_pool_v2.single_ocp_bastion.id}"
  subnet_id = "${data.openstack_networking_subnet_v2.private.id}"
}



resource "openstack_compute_instance_v2" "masters" {
  count = "${var.master_count}"
  name = "master${count.index}"
  user_data     = "${data.template_file.script.rendered}\nhostname: master${count.index}\nfqdn: master${count.index}"
  flavor_name = "ocp.generic"
  key_pair = "default"
  security_groups = ["default","ssh","ocp_internal_communication","master_api"]
  network {
    name = "private"
  }

  metadata {
    role = "master"
  }

  block_device {
    uuid                  = "${data.openstack_images_image_v2.rhel.id}"
    source_type           = "image"
    destination_type      = "volume"
    volume_size	          = 30 
    boot_index            = 0
    delete_on_termination = true
  }
  
  # Docker storage
  block_device {
    source_type           = "blank"
    destination_type      = "volume"
    volume_size	          = 15
    boot_index            = 1
    delete_on_termination = true
  }
  # Gluster storage
  block_device {
    source_type           = "blank"
    destination_type      = "volume"
    volume_size	          = 15
    boot_index            = 2
    delete_on_termination = true
  }
}

resource "openstack_lb_member_v2" "single_ocp_admin_api" {
  count = "${var.master_count}"
  address  = "${element(openstack_compute_instance_v2.masters.*.access_ip_v4, count.index)}"

  protocol_port = 8443
  pool_id   = "${openstack_lb_pool_v2.single_ocp_admin_api.id}"
  subnet_id = "${data.openstack_networking_subnet_v2.private.id}"
}


resource "openstack_compute_instance_v2" "infras" {
  count = "${var.infra_count}"
  name = "infra${count.index}"
  user_data     = "${data.template_file.script.rendered}\nhostname: infra${count.index}\nfqdn: infra${count.index}"
  flavor_name = "ocp.generic"
  key_pair = "default"
  security_groups = ["default","ssh","ocp_internal_communication","router"]
  network {
    name = "private"
  }

  metadata {
    role = "infra"
  }

  block_device {
    uuid                  = "${data.openstack_images_image_v2.rhel.id}"
    source_type           = "image"
    destination_type      = "volume"
    volume_size	          = 30
    boot_index            = 0
    delete_on_termination = true
  }
  
  # Docker storage
  block_device {
    source_type           = "blank"
    destination_type      = "volume"
    volume_size	          = 15
    boot_index            = 1
    delete_on_termination = true
  }
  # Gluster storage
  block_device {
    source_type           = "blank"
    destination_type      = "volume"
    volume_size	          = 15
    boot_index            = 2
    delete_on_termination = true
  }
}

resource "openstack_lb_member_v2" "single_ocp_router_http" {
  count = "${var.master_count}"
  address  = "${element(openstack_compute_instance_v2.infras.*.access_ip_v4, count.index)}"

  protocol_port = 80
  pool_id   = "${openstack_lb_pool_v2.single_ocp_router_http.id}"
  subnet_id = "${data.openstack_networking_subnet_v2.private.id}"
}

resource "openstack_lb_member_v2" "single_ocp_router_https" {
  count = "${var.master_count}"
  address  = "${element(openstack_compute_instance_v2.infras.*.access_ip_v4, count.index)}"

  protocol_port = 443
  pool_id   = "${openstack_lb_pool_v2.single_ocp_router_https.id}"
  subnet_id = "${data.openstack_networking_subnet_v2.private.id}"
}



resource "openstack_compute_instance_v2" "nodes" {
  count = "${var.node_count}"
  name = "node${count.index}"
  user_data     = "${data.template_file.script.rendered}\nhostname: node${count.index}\nfqdn: node${count.index}"
  flavor_name = "ocp.generic"
  key_pair = "default"
  security_groups = ["default","ssh","ocp_internal_communication"]
  network {
    name = "private"
  }

  metadata {
    role = "node"
  }

  block_device {
    uuid                  = "${data.openstack_images_image_v2.rhel.id}"
    source_type           = "image"
    destination_type      = "volume"
    volume_size	          = 30
    boot_index            = 0
    delete_on_termination = true
  }
  
  # Docker storage
  block_device {
    source_type           = "blank"
    destination_type      = "volume"
    volume_size	          = 15
    boot_index            = 1
    delete_on_termination = true
  }
  # Gluster storage
  block_device {
    source_type           = "blank"
    destination_type      = "volume"
    volume_size	          = 15
    boot_index            = 2
    delete_on_termination = true
  }
}

