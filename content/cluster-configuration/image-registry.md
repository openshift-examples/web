---
title: Image Registry
linktitle: Image Registry
weight: 19000
description: Some stuff about the OpenShift 4 image registry
ignore_macros: true
---

# Image Registry

## Use ReadWriteOnce volumes - new in 4.4!

!!! note
    Only available since OpenShift version 4.4.0

!!! warning
    By using a ReadWriteOnce volume you have to

     * Change the Rollout Strategy from rolling to recreate and

     * its only supported to have exactly one replica.

    **That means, during a cluster or image-registry upgrade, your internal registry has downtime between stopping the old pod and starting the new pod! **

Documentation bug for official documentation: [https://bugzilla.redhat.com/show_bug.cgi?id=1826292](https://bugzilla.redhat.com/show_bug.cgi?id=1826292)

#### On vSphere with cloud provider integration:

--8<-- "content/cluster-configuration/image-registry/vsphere-registry.md"

## Exposing the registry

Documentation: [Exposing the registry
](https://docs.openshift.com/container-platform/4.3/registry/securing-exposing-registry.html)

### Discover exposed registry - Work in progress -

!!! note
    This is work in progress

```bash
export REGISTRY=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
export REGISTRY_TOKEN=$(oc whoami -t)

podman login -u $(oc whoami) -p $REGISTRY_TOKEN --tls-verify=false $HOST

# List all images
curl -s -H "Authorization: Bearer $REGISTRY_TOKEN" \
    https://$REGISTRY/v2/_catalog

# List tages of an image
export IMAGE=openshift/python
curl -s -H "Authorization: Bearer $REGISTRY_TOKEN" \
    https://$REGISTRY/v2/$IMAGE/tags/list

# Get sha/digest
export TAG=latest
curl -s -H "Authorization: Bearer $REGISTRY_TOKEN"  \
    https://$REGISTRY/v2/$IMAGE/manifests/$TAG
```

## Setup non AWS S3 storage backend

### Deploy min.io via helm3

```bash

helm repo add stable https://kubernetes-charts.storage.googleapis.com
# https://github.com/helm/charts/tree/master/stable/minio#configuration
helm install minio stable/minio \
  --set persistence.storageClass=managed-premium \
  --set securityContext.runAsUser=$( oc get project $(oc project  -q) -ojsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.uid-range}' | cut -f1 -d '/' ) \
  --set securityContext.fsGroup=$( oc get project $(oc project  -q) -ojsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.supplemental-groups}' | cut -f1 -d '/' ) \
  --set ingress.enabled=true \
  --set ingress.hosts={minio-$(oc project  -q).$( oc get ingresses.config.openshift.io/cluster -o jsonpath="{.spec.domain}" )}

# helm uninstall minio

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

