---
title: Hosted Control Plane
linktitle: Hosted Control Plane
description: Hosted Control Plane aka HyperShift
tags:
  - HostedControlPlane
  - hcp
  - hypershift
---

# Hosted Control Plane

<https://docs.google.com/document/d/1EUaKD_0JGPPPAD7rAshfXUVfAOzTqmU5qx_60Hl_NE0/edit>

<https://github.com/gqlo/blogs/blob/main/hosted-control-plane-with-the-kubevirt-provider.md>


## Platform

- Cluster erstellen
- Bestehendes zeigen
- BareMetal zeigen
- MetalLB
-


### KubeVirt

```bash

export PULL_SECRET=${HOME}/redhat-pullsecret-rh-ee-rbohne.json
export KUBEVIRT_CLUSTER_NAME=ibm
export TRUSTED_BUNDLE=${HOME}/Devel/gitlab.consulting.redhat.com/coe-lab/certificates/ca-bundle-v1.pem


hypershift create cluster \
kubevirt \
  --name $KUBEVIRT_CLUSTER_NAME \
  --namespace rbohne-hcp \
  --node-pool-replicas=2 \
  --memory '16Gi' \
  --cores '8' \
  --generate-ssh \
  --root-volume-size 120 \
  --root-volume-storage-class 'coe-netapp-nas' \
  --pull-secret $PULL_SECRET \
  --etcd-storage-class ocs-storagecluster-ceph-rbd \
  --control-plane-availability-policy HighlyAvailable \
  --additional-trust-bundle $TRUSTED_BUNDLE \
  --auto-repair \
  --release-image=quay.io/openshift-release-dev/ocp-release:4.12.1-x86_64

  --render
  # Optional - add --render to show yaml

```

#### Export kubeconfig

```
hypershift create kubeconfig \
  --name $KUBEVIRT_CLUSTER_NAME \
  --namespace rbohne-hcp | sed "s/admin/$KUBEVIRT_CLUSTER_NAME/" > ~/.kube/clusters/${KUBEVIRT_CLUSTER_NAME}
```



### Agent


#### Exposing vie MetalLB

Missing:
```
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2advertisement
  namespace: metallb
spec:
  ipAddressPools:
   - ingress-public-ip
```

### None

???+ warning

  Will not supported and disapear from upstream docs.
  Please go with agent.


```
hypershift create cluster \
none \
  --expose-through-load-balancer \
  --name $KUBEVIRT_CLUSTER_NAME \
  --control-plane-availability-policy HighlyAvailable \
  --etcd-storage-class ocs-storagecluster-ceph-rbd \
  --release-image=quay.io/openshift-release-dev/ocp-release:4.12.1-x86_64 \
  --pull-secret $PULL_SECRET \
  --render

```