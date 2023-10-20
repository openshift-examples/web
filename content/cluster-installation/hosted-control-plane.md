---
title: Hosted Control Plane
linktitle: Hosted Control Plane
description: Hosted Control Plane aka HyperShift
tags: ['HostedControlPlane','hcp','hypershift']
---

# Hosted Control Plane

<https://docs.google.com/document/d/1EUaKD_0JGPPPAD7rAshfXUVfAOzTqmU5qx_60Hl_NE0/edit>

<https://github.com/gqlo/blogs/blob/main/hosted-control-plane-with-the-kubevirt-provider.md>

## Platform

### Platform - KubeVirt

```bash

export PULL_SECRET=${HOME}/redhat-pullsecret-rh-ee-rbohne.json
export KUBEVIRT_CLUSTER_NAME=oat23
export TRUSTED_BUNDLE=${HOME}/Devel/gitlab.consulting.redhat.com/coe-lab/certificates/ca-bundle-v1.pem

hcp create cluster \
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
  --release-image=quay.io/openshift-release-dev/ocp-release:4.14.1-x86_64
  # --render
  # Optional - add --render to show yaml

```

#### Export kubeconfig

```bash
hcp create kubeconfig \
  --name $KUBEVIRT_CLUSTER_NAME \
  --namespace rbohne-hcp | sed "s/admin/$KUBEVIRT_CLUSTER_NAME/" > ~/.kube/clusters/${KUBEVIRT_CLUSTER_NAME}
```


### Platform - None / BareMetal


Not tested, for a long time:
```bash
hcp create cluster \
none \
  --expose-through-load-balancer \
  --name $KUBEVIRT_CLUSTER_NAME \
  --control-plane-availability-policy HighlyAvailable \
  --etcd-storage-class ocs-storagecluster-ceph-rbd \
  --release-image=quay.io/openshift-release-dev/ocp-release:4.12.1-x86_64 \
  --pull-secret $PULL_SECRET
  ## --render

```

#### Loadbalacner for ingress

Ingress is running on physical nodes, you have to provide an external load balancer.

Here a container solution bases on [openshift-4-loadbalancer](https://github.com/RedHat-EMEA-SSA-Team/openshift-4-loadbalancer)

 * Create new project
 * Create service account `privileged` : `oc create sa privileged`
 * Grant scc `privileged` to service account `privileged`
 * Download and edit line 35 & 37 with your BareMetal endpoints

=== "Download, edit and apply"

    ```
    curl -L -O  {{ page.canonical_url }}hosted-control-plane/openshift-4-loadbalancer-deployment.yaml
    $EDITOR openshift-4-loadbalancer-deployment.yaml
    oc apply -f openshift-4-loadbalancer-deployment.yaml
    ```

=== "openshift-4-loadbalancer-deployment.yaml"

    ```yaml  hl_lines="37 35"
    --8<-- "content/cluster-installation/hosted-control-plane/openshift-4-loadbalancer-deployment.yaml"
    ```

 * Apply service type load balancer

=== "Apply"

    ```
    oc apply -f  {{ page.canonical_url }}hosted-control-plane/openshift-4-loadbalancer-service.yaml
    ```

=== "openshift-4-loadbalancer-deployment.yaml"

    ```yaml  hl_lines="37 35"
    --8<-- "content/cluster-installation/hosted-control-plane/openshift-4-loadbalancer-service.yaml"
    ```



# Trouble shooting

<https://hypershift-docs.netlify.app/how-to/troubleshooting/>

```bash
export KUBEVIRT_CLUSTER_NAME=lenggries3
export CLUSTERNS="rbohne-hcp"

mkdir clusterDump-${CLUSTERNS}-${KUBEVIRT_CLUSTER_NAME}
hcp dump cluster \
    --name ${KUBEVIRT_CLUSTER_NAME} \
    --namespace ${CLUSTERNS} \
    --dump-guest-cluster \
    --artifact-dir clusterDump-${CLUSTERNS}-${KUBEVIRT_CLUSTER_NAME}
```