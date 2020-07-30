# Workload Monitoring

Enable TechPreview workload monitoring: [Enabling monitoring of your own services
](https://docs.openshift.com/container-platform/4.4/monitoring/monitoring-your-own-services.html#enabling-monitoring-of-your-own-services_monitoring-your-own-services)


```yaml
oc create -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |
    techPreviewUserWorkload:
      enabled: true
EOF
```


Deploy sample app: https://docs.openshift.com/container-platform/4.4/monitoring/monitoring-your-own-services.html#deploying-a-sample-service_monitoring-your-own-services

```
oc create -f - <<EOF
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: monitor-crd-edit
rules:
- apiGroups: ["monitoring.coreos.com"]
  resources: ["prometheusrules", "servicemonitors", "podmonitors"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
EOF
```