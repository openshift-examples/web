---
description: Some stuff about the OpenShift 4 image registry
---

# Image Registry

## Expose image registry \(OpenShift 4\)

{% embed url="https://docs.openshift.com/container-platform/4.3/registry/securing-exposing-registry.html" %}



## Setup non AWS S3 storage backend

### Deploy min.io

```bash
oc new-project minio
oc create -f https://github.com/minio/minio/blob/master/docs/orchestration/kubernetes/minio-standalone-pvc.yaml?raw=true
oc create -f https://github.com/minio/minio/blob/master/docs/orchestration/kubernetes/minio-standalone-deployment.yaml?raw=true
# Create non SSL service
oc create -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: minio-service
spec:
  type: ClusterIP
  ports:
    - port: 9000
      targetPort: 9000
      protocol: TCP
  selector:
    app: minio
EOF
```

### Upgrade to SSL

```bash
# Create service cert
oc annotate service minio-service \
    service.beta.openshift.io/serving-cert-secret-name=minio-service-cert

# Create confimap with service ca 
oc create -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: signing-cabundle
  annotations:
    service.beta.openshift.io/inject-cabundle: "true"
EOF

# Add certificates to minio deployment
oc patch deployment/minio --type='json' --patch='[
  {"op": "add", "path": "/spec/template/spec/volumes/-", "value":  { "name": "certificate", "secret": { "defaultMode": 420, "items": [ { "key": "tls.crt", "path": "public.crt" }, { "key": "tls.key", "path": "private.key" } ], "secretName": "minio-service-cert" }}},
  {"op": "add", "path": "/spec/template/spec/volumes/-", "value":   { "name": "ca","configMap": { "defaultMode": 420, "items": [ { "key": "service-ca.crt", "path": "public.crt" } ], "name": "signing-cabundle" }}},
  {"op": "add", "path": "/spec/template/spec/containers/0/volumeMounts/-", "value": {"mountPath": "/.minio/certs","name": "certificate"}},
  {"op": "add", "path": "/spec/template/spec/containers/0/volumeMounts/-", "value": {"mountPath": "/.minio/certs/CAs","name": "ca"}}
]'


```

### Configure image registry

```bash
minio-service.minio.svc.cluster.local

oc create secret generic image-registry-private-configuration-user \
    --from-literal=REGISTRY_STORAGE_S3_ACCESSKEY=minio \
    --from-literal=REGISTRY_STORAGE_S3_SECRETKEY=minio123 \
    --namespace openshift-image-registry


oc patch configs.imageregistry.operator.openshift.io/cluster \
    --type='json' \
    --patch='[
        {"op": "remove", "path": "/spec/storage" },
        {"op": "add", "path": "/spec/storage", "value": {"s3":{"bucket": "minio-service", "regionEndpoint": "minio.svc.cluster.local:9000", "encrypt": false, "region": "dummyregion"}}}
    ]'

oc describe configs.imageregistry.operator.openshift.io/cluster
[...snipped...]
Name:         cluster
API Version:  imageregistry.operator.openshift.io/v1
Kind:         Config
[...snipped...]
Spec:
[...snipped...
  Storage:
    s3:
      Bucket:           minio-service
      Encrypt:          false
      Region:           dummyregionf
      Region Endpoint:  minio.svc.cluster.local:9000
Status:
  Conditions:
    Last Transition Time:  2020-02-26T21:04:38Z
    Message:               The registry is ready
    Reason:                Ready
    Status:                True
    Type:                  Available
    Last Transition Time:  2020-02-29T20:21:55Z
    Message:               Unable to apply resources: unable to sync storage configuration: RequestError: send request failed
caused by: Head https://minio-service.minio.svc.cluster.local:9000/: dial tcp 172.30.202.88:9000: connect: connection refused
    Reason:                Error
    Status:                True
[...snipped...]


```

