
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

variable "master_count" {
  type    = "string"
  default = "1"
}


variable "infra_count" {
  type    = "string"
  default = "1"
}


variable "node_count" {
  type    = "string"
  default = "3"
}

