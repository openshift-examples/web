---
title: Cross Cluster Live Migration
linktitle: Cross Cluster Live Migration
description: Cross Cluster Live Migration
tags: ['cnv','kubevirt','ocp-v','v4.12']
---
# Cross cluster live migration

Official documentation: [12.5. Configuring a cross-cluster live migration network](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/virtualization/live-migration#virt-configuring-cross-cluster-live-migration-network)

Tested with:

|Component|Version|
|---|---|
|OpenShift|v4.20.4|
|OpenShift Virt|v4.20.1|
|MTV|v2.10.0|

Without ACM, just a pure cross cluster live migration with two OpenShift clusters.

## Cluster overview

We have two identicial clusters in terms of

* OpenShift Version
* CPU Type and Model

Cluster one called OCP1 is the target cluster with mtv.
Cluster two called OCP7 is the source cluster.

This cluster are running on bare OpenShift Cluster called ISAR.

![](cclm/overview.drawio)

### Details about the OCP1 & OCP7 adjustments at ISAR

OCP1 and OCP7 are provided via our [stormshift automation](https://github.com/stormshift/automation)

??? quote "OCP1 & OCP7 Infrastructure details"

    #### Patch the cpu model

    === "Command"

        ```shell
        oc get vm -o name | xargs oc patch  --type=merge -p '{"spec":{"template":{"spec":{"domain":{"cpu":{"model":"Haswell-v4"}}}}}}'
        ```

    #### Enable VT-X/vmx feature

    === "Command"

        ```shell
        oc get vm -o name | xargs oc patch  --type=merge -p '{"spec":{"template":{"spec":{"domain":{"cpu":{"features":[{"name":"vmx","policy":"require"}]}}}}}}'
        ```

    #### Restart all VM's

    === "Command"

        ```shell
        oc get vm --no-headers -o custom-columns="NAME:.metadata.name" | xargs -n1 virtctl restart
        ```

    #### Check setttings as ISAR

    === "Command"

        ```shell
        oc get vm -o custom-columns=NAME:.metadata.name,CPU:.spec.template.spec.domain.cpu
        ```

    === "Example output"

        ```shell
        oc get vm -o custom-columns=NAME:.metadata.name,CPU:.spec.template.spec.domain.cpu
        NAME            CPU
        ocp1-cp-0       map[cores:8 features:[map[name:vmx policy:require]] model:Haswell-v4 sockets:1 threads:1]
        ocp1-cp-1       map[cores:8 features:[map[name:vmx policy:require]] model:Haswell-v4 sockets:1 threads:1]
        ocp1-cp-2       map[cores:8 features:[map[name:vmx policy:require]] model:Haswell-v4 sockets:1 threads:1]
        ocp1-worker-0   map[cores:8 features:[map[name:vmx policy:require]] model:Haswell-v4 sockets:1 threads:1]
        ocp1-worker-1   map[cores:8 features:[map[name:vmx policy:require]] model:Haswell-v4 sockets:1 threads:1]
        ocp1-worker-2   map[cores:8 features:[map[name:vmx policy:require]] model:Haswell-v4 sockets:1 threads:1]
        ```

    #### Add second interface into vlan 2001 for the VM's/nodes

    === "oc apply -f ...."

        ```bash
        oc apply -n stormshift-ocp1-infra -f {{ page.canonical_url }}cclm/isar-2001-net-attach-def.yaml
        oc apply -n stormshift-ocp7-infra -f {{ page.canonical_url }}cclm/isar-2001-net-attach-def.yaml

        ```

    === "isar-2001-net-attach-def.yaml"

        ```yaml
        --8<-- "content/kubevirt/livemigration/cclm/isar-2001-net-attach-def.yaml"
        ```

    #### Adjust VM's to add second interface to worker nodes:

    ![](cclm/isar-second-interface.png)

## OCP1 and OCP7 cluster preperation

### Install following operators

* Nmstate Operator (instantiate the operator now)
* OpenShift Virtualization (instantiate the operator **LATER!**)
* Migration Toolkit for Virtualization (instantiate the operator **LATER!**)

### Prepare required live migration network

Both clusters have to be connected via an L2 network.
In my case it's vlan 2001 with `192.168.201.0/24 subnet

Here an high level overview:

![](cclm/live-migration-network.drawio)

???+ bug "There is an documetion bug in the offical docs"

    <https://issues.redhat.com/browse/CNV-74609>

??? example "NodeNetworkConfigurationPolicy for linux bridge into VLAN 2001"

    Apply this to OCP1 and OCP7

    === "coe-bridge-via-enp2s0.yaml"

        ```yaml
        --8<-- "content/kubevirt/livemigration/cclm/coe-bridge-via-enp2s0.yaml"
        ```

    === "oc apply -f ...."

        ```bash
        oc apply -f {{ page.canonical_url }}cclm/coe-bridge-via-enp2s0.yaml
        ```

??? example "NetworkAttachmentDefinition for OCP1 and OCP7"

    Little helper for find out the interfaces on the nodes:

    ```shell
    oc get nodes -l node-role.kubernetes.io/worker -o name | while read line ; do echo "# $line";oc debug -q $line -- ip -br l | grep enp ; done
    ```

    Apply this to OCP1

    === "ocp1.net-attach-def.yaml"

        ```yaml
        --8<-- "content/kubevirt/livemigration/cclm/ocp1.net-attach-def.yaml"
        ```

    === "oc apply -f ...."

        ```bash
        oc apply -f {{ page.canonical_url }}cclm/ocp1.net-attach-def.yaml
        ```

    Apply this to OCP7

    === "ocp7.net-attach-def.yaml"

        ```yaml
        --8<-- "content/kubevirt/livemigration/cclm/ocp7.net-attach-def.yaml"
        ```

    === "oc apply -f ...."

        ```bash
        oc apply -f {{ page.canonical_url }}cclm/ocp7.net-attach-def.yaml
        ```

### Instantiate the operator

#### OpenShift Virtualization on OCP1 and OCP7

Instantiate with following changes:

```yaml
spec:
  liveMigrationConfig:
    network: livemigration-network
  featureGates:
    decentralizedLiveMigration: true
```

Wait until `virt-synchronization-controller-xxx` pods are running:

```shell
oc get pods -n openshift-cnv -l kubevirt.io=virt-synchronization-controller
```

```shell
% oc get pods -n openshift-cnv -l kubevirt.io=virt-synchronization-controller
NAME                                               READY   STATUS    RESTARTS   AGE
virt-synchronization-controller-5b58bd4478-5l25n   1/1     Running   0          3d21h
virt-synchronization-controller-5b58bd4478-zwpn4   1/1     Running   0          3d21h
```

Optional: Check the virt-handler migration network configuration:

```shell
% oc project openshift-cnv
% oc get pods -l kubevirt.io=virt-handler  -o name | while read line ; do oc exec -q $line -- /bin/sh -c 'echo -n "$HOSTNAME $NODE_NAME "; ip -4 -br a show dev migration0' ; done
virt-handler-dm5mh ocp1-worker-2 migration0@if9   UP             192.168.201.129/24
virt-handler-h6bn9 ocp1-worker-1 migration0@if9   UP             192.168.201.131/24
virt-handler-nndkq ocp1-worker-0 migration0@if9   UP             192.168.201.130/24
```

```shell
% oc project openshift-cnv
% oc get pods -l kubevirt.io=virt-handler  -o name | while read line ; do oc exec -q $line -- /bin/sh -c 'echo -n "$HOSTNAME $NODE_NAME "; ip -4 -br a show dev migration0' ; done
virt-handler-bjwvt ocp7-worker-1 migration0@if9   UP             192.168.201.3/24
virt-handler-gl8gs ocp7-worker-0 migration0@if9   UP             192.168.201.1/24
virt-handler-kxg7k ocp7-worker-2 migration0@if8   UP             192.168.201.4/24
```

#### Migration toolkit for Virtualization on OCP1

Instantiate with following change:

```yaml
spec:
  feature_ocp_live_migration: 'true'
```

## Migration toolkit for Virtualization

### Create provide at OCP1

#### Create service account and token at OCP7

Create clusterrole `live-migration-role`

```shell
oc apply  -f {{ page.canonical_url }}cclm/clusterrole.yaml
```

```shell
oc create namespace openshift-mtv
oc create serviceaccount cclm -n openshift-mtv
oc create clusterrolebinding cclm --clusterrole=live-migration-role --serviceaccount=openshift-mtv:cclm
oc apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: cclm
  namespace: openshift-mtv
  annotations:
    kubernetes.io/service-account.name: cclm
type: kubernetes.io/service-account-token
EOF
```

Get the token:

```shell
{% raw %}
oc get secret "cclm" -n "openshift-mtv" -o  go-template='{{ .data.token | base64decode}}{{"\n"}}'
{% endraw %}
```

#### Add provider `ocp7` to OCP1

![](cclm/create-mtv-provider.png)

## Run a cross cluster live migration

<iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/ctx9qYyQlms" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Resources

* <https://access.redhat.com/solutions/7130438>
* <https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/virtualization/networking#virt-dedicated-network-live-migration>
* <https://github.com/k8snetworkplumbingwg/whereabouts>
* <https://docs.google.com/document/d/1x4r9gJVXVGe8ef6lMcciOqNbywJ5HKtR7E9kHVzIjAQ/edit?tab=t.0>
* <https://github.com/openshift/runbooks/pull/362>
