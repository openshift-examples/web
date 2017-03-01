# Deploy omd on openshift

```
oc new-project monitoring
oc adm policy add-scc-to-user anyuid system:serviceaccount:monitoring:default
oc process -f omd.json | oc create -f -
```
