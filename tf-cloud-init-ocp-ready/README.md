# OpenStack example

Important: after successful terraform apply, cloud-init install and configure 
everything in the background and after that cloud-init perform an final reboot.

```
source ~/keystonerc_admin
eval $(env | grep ^OS_ | xargs -n1 printf "export TF_VAR_%s\n" )
export TF_VAR_rh_subscription_username=...
export TF_VAR_rh_subscription_pool=...
export TF_VAR_rh_subscription_password=...

terraform init
terraform apply

```
