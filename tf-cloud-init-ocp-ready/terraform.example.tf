
/*

 To transform the openstack env variables into the terraform one:

   eval $(env | grep ^OS_ | xargs -n1 printf "export TF_VAR_%s\n" )

*/

variable "OS_USERNAME"     { type    = "string" }
variable "OS_PROJECT_NAME" { type    = "string" }
variable "OS_PASSWORD"     { type    = "string" }
variable "OS_AUTH_URL"     { type    = "string" }
variable "OS_REGION_NAME"  { type    = "string" default = "RegionOne" }

variable "rh_subscription_username"     { type    = "string" }
variable "rh_subscription_password"     { type    = "string" }
variable "rh_subscription_pool"         { type    = "string" }


provider "openstack" {
  user_name   = "${var.OS_USERNAME}"
  tenant_name = "${var.OS_PROJECT_NAME}"
  password    = "${var.OS_PASSWORD}"
  auth_url    = "${var.OS_AUTH_URL}"
  region      = "${var.OS_REGION_NAME}"
}

output "cidr" {
  value = "${path.module}/cloud-init.tpl"
}


data "template_file" "script" {
  template = "${file("${path.module}/terraform.cloud-init.tpl")}"

  vars {
    rh_subscription_username  = "${var.rh_subscription_username}"
    rh_subscription_password  = "${var.rh_subscription_password}"
    rh_subscription_pool      = "${var.rh_subscription_pool}"
  }
}

data "openstack_images_image_v2" "rhel" {
  name = "rhel-server-7.5-update-4-x86_64"
  most_recent = true
}

output "cloud-init" {
  value = "${data.template_file.script.rendered}"
}

resource "openstack_compute_instance_v2" "cloud-init" {
  name = "cloud-init-example"
  user_data     = "${data.template_file.script.rendered}\nhostname: cloud-init-example\nfqdn: cloud-init-example"
  flavor_name = "m1.small"
  key_pair = "default"
  security_groups = ["default"]
  network {
    name = "private"
  }

  block_device {
    uuid                  = "${data.openstack_images_image_v2.rhel.id}"
    source_type           = "image"
    destination_type      = "volume"
    volume_size	          = 60
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


resource "openstack_networking_floatingip_v2" "public" {
  pool = "public"
}

resource "openstack_compute_floatingip_associate_v2" "public" {
  floating_ip = "${openstack_networking_floatingip_v2.public.address}"
  instance_id = "${openstack_compute_instance_v2.cloud-init.id}"
}

