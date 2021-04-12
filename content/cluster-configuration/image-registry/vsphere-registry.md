

##### Create PVC

```bash
oc create -f - <<EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: image-registry-pvc
  namespace: openshift-image-registry
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  storageClassName: thin
EOF
```

##### Patch registry operator crd

```bash
oc patch configs.imageregistry.operator.openshift.io/cluster \
    --type='json' \
    --patch='[
        {"op": "replace", "path": "/spec/managementState", "value": "Managed"},
        {"op": "replace", "path": "/spec/rolloutStrategy", "value": "Recreate"},
        {"op": "replace", "path": "/spec/replicas", "value": 1},
        {"op": "replace", "path": "/spec/storage", "value": {"pvc":{"claim": "image-registry-pvc" }}}
    ]'

```
