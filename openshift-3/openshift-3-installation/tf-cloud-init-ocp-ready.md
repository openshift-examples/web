# Terraform example

Important: after successful terraform apply, cloud-init install and configure everything in the background and after that cloud-init perform an final reboot.

```text
source ~/keystonerc_admin
eval $(env | grep ^OS_ | xargs -n1 printf "export TF_VAR_%s\n" )
export TF_VAR_rh_subscription_username=...
export TF_VAR_rh_subscription_pool=...
export TF_VAR_rh_subscription_password=...

cd tf-osp-example/

terraform init
terraform apply
```

{% embed url="https://github.com/rbo/openshift-examples/tree/master/tf-osp-example" caption="Terraform examples OpenShift on OpenStack" %}



