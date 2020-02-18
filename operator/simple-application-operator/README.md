# Draft/WIP Simple example ansible operator

```
operator-sdk new simple-application-operator \
  --api-version=simple.application.openshift.pub/v1  \
  --kind=SimpleApp \
  --type=ansible

operator-sdk build quay.io/rbo/demo-http-operator:latest
docker push quay.io/rbo/demo-http-operator:latest

sed -i "" 's|{{ REPLACE_IMAGE }}|quay.io/rbo/demo-http-operator:latest|g' deploy/operator.yaml
sed -i "" 's|{{ pull_policy\|default('\''Always'\'') }}|Always|g' deploy/operator.yaml

oc new-project simple-application-operator
# Setup Service Account
oc create -f deploy/service_account.yaml
# Setup RBAC
oc create -f deploy/role.yaml
oc create -f deploy/role_binding.yaml
# Setup the CRD
oc create -f deploy/crds/simple.application.openshift.pub_simpleapps_crd.yaml
# Deploy the app-operator
oc create -f deploy/operator.yaml

# Create an AppService CR
# The default controller will watch for AppService objects and create a pod for each CR
oc create -f deploy/crds/simple.application.openshift.pub_v1_simpleapp_cr.yaml
```

# Redeploy
```
operator-sdk build quay.io/rbo/demo-http-operator:latest
docker push quay.io/rbo/demo-http-operator:latest
oc delete pods -l name=simple-application-operator
```


# Notes:

* https://github.com/operator-framework/operator-sdk/blob/master/doc/ansible/dev/finalizers.md