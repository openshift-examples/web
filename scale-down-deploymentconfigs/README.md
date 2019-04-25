# Auto scale down of deployment configs

Quite old, not tested yet and old fassion way. 
Next time write an operator! Maybe you can use
https://github.com/zalando-incubator/kopf/blob/master/README.md

## Setup job
```
oc new-build https://github.com/rbo/openshift-examples.git \
    --name=auto-scale-down \
    --context-dir=scale-down-deploymentconfigs/


oc create sa cluster-admin -n openshift-jobs

oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:openshift-jobs:cluster-admin
```



## Run local

```
docker build -t scaledown .
```
