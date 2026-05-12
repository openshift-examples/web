---
title: Hosted Control Plane and tenant networking
linktitle: Hosted Control Plane and tenant networking
description: Hosted Control Plane and tenant networking
tags: ['hcp','v4.21']
---
# Hosted Control Plane and tenant networking

Official documentation: Net yet available

Tested with:

|Component|Version|
|---|---|
|OpenShift|v4.21.9|
|OpenShift Virt|v4.21.0|

## Overview

Challenge: running an hosted cluster with in different tenant network segment/vlan without widely open access from tenant segment to managment segment.

Addtional requirement, the hub cluster should not have any address or network connection into the tenant network segment. It's only allowed to place virtual machines into the network segment. 

![](overview.drawio){ page="Page-1" }

The worker nodes of the hosted cluster are quite easy to solve, just connected them into the tenant network segment (import, DHCP is required).

The hosted control plane compontents to expose into tenant network segment is more challenging. Following components have to concider:

* API Server
* OAuth
* Konnectivity
* Ignition 

Here an list of possible exposing options for these components:

|Component/Service|Exposing strategy (`servicePublishingStrategy`)|Kubernetes Service type `LoadBalancer`|Ingress/Route|
|---|---|---|---|
|API Server|<li>LoadBalancer (Recommended, K8s Service Type Load Balancer)</li><li>NodePort* (not for production)</li>|✅|❌|
|OAuth|<li>Route/Ingress (default)</li><li>NodePort* (not for production)</li>|❌|✅|
|Konnectivity|<li>Route/Ingress (default)</li><li>LoadBalancer (K8s Service Type Load Balancer)</li><li>NodePort* (not for production)</li>|✅|✅|
|Ignition|<li>Route/Ingress (default)</li><li>NodePort* (not for production)</li>|✅|❌|

For our proof of concept we want to try following, exposing the components via:

* API Server: LoadBalancer
* OAuth: Router/Ingress: via a dedicted router shard. 
* Konnectivity: via a dedicted router shard. 
* Ignition: via a dedicted router shard. 

## Exposing compontents via router/ingress shard

The idea with the dedicated router/ingress shared is to expose the router/ingress shard into the tenant network segment and only for the hosted cluster components. 

In front of the router/ingress shared is an external load balancer (for example, f5 bigip, netscaler,..) with access into the managment network segment and expose the router shared into the tenant network segment.




## Proof of concept envrioment overview

![](overview.drawio){ page="Page-2" }

### Router between Mgmt and Tenant-A

[VyOS Router](https://vyos.io/) router & firewall. Do not allow Traffic between Mgmt and Tenant-A network except DNS and gateway.

??? example "VyOS config commands"

    ```shell
    --8<-- "content/cluster-installation/hosted-control-plane/tenant-network/vyos-router-2003.txt"
    ```

### Ingress Sharding

* [2.3.4. Ingress sharding in OpenShift Container Platform](https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html/ingress_and_load_balancing/configuring-ingress-cluster-traffic#nw-ingress-sharding-concept_configuring-ingress-cluster-traffic-ingress-controller)
* [3.1.3.8.1. Example load balancer configuration for user-provisioned clusters](https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html/installing_on_vmware_vsphere/user-provisioned-infrastructure)


???+ example "Ingress Controller"

    ```yaml
    --8<-- "content/cluster-installation/hosted-control-plane/tenant-network/ingress-controller-shard.yaml"
    ```

```shell
% oc get svc -n openshift-ingress router-nodeport-tenant-a
NAME                       TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)                                     AGE
router-nodeport-tenant-a   NodePort   172.30.141.209   <none>        80:32460/TCP,443:32488/TCP,1936:32095/TCP   106s
```

Ingress sharding load balancer is an RHEL 9 system with haproxy.

* Install HAProxy `dnf install haproxy`
* Configure selinux `setsebool -P haproxy_connect_any 1`
* Apply Example haproxy.conf (don't forget to update ports)
* Enabel and start haproxy `systemctl enable --now haproxy`

??? example "HAProxy config"

    ```shell
    --8<-- "content/cluster-installation/hosted-control-plane/tenant-network/ingress-shared-haproxy.conf"
    ```

Add DNS Records 

```bind
konnectivity.tenant-a.coe.muc.redhat.com.       IN A 192.168.203.111
oauth.tenant-a.coe.muc.redhat.com.              IN A 192.168.203.111
ignition.tenant-a.coe.muc.redhat.com.           IN A 192.168.203.111
```









apiVersion: project.openshift.io/v1
kind: Project
metadata:
  name: 'clusters'
---
apiVersion: hypershift.openshift.io/v1beta1
kind: HostedCluster
metadata:
  name: 'tenant-a'
  namespace: 'clusters'
  labels:
    "cluster.open-cluster-management.io/clusterset": 'default'
spec:
  configuration:
    ingress:
      appsDomain: apps.tenant-a.coe.muc.redhat.com
      domain: ''
      loadBalancer:
        platform:
          type: ''
  channel: fast-4.21
  etcd:
    managed:
      storage:
        persistentVolume:
          size: 8Gi
        type: PersistentVolume
    managementType: Managed
  release:
    image: quay.io/openshift-release-dev/ocp-release:4.21.11-multi
  pullSecret:
    name: pullsecret-cluster-tenant-a
  sshKey:
    name: sshkey-cluster-tenant-a
  networking:
    clusterNetwork:
      - cidr: 10.132.0.0/14
    serviceNetwork:
      - cidr: 172.31.0.0/16
    networkType: OVNKubernetes
  controllerAvailabilityPolicy: SingleReplica
  infrastructureAvailabilityPolicy: SingleReplica
  platform:
    type: KubeVirt
    kubevirt:
      baseDomainPassthrough: false
  infraID: 'tenant-a'
  services:
    - service: APIServer
      servicePublishingStrategy:
        type: LoadBalancer
        loadBalancer:
          hostname: api.tenant-a.coe.muc.redhat.com
    - service: OAuthServer
      servicePublishingStrategy:
        type: Route
        route:
          hostname: oauth.tenant-a.coe.muc.redhat.com
    - service: OIDC
      servicePublishingStrategy:
        type: Route
    - service: Konnectivity
      servicePublishingStrategy:
        type: Route
        route:
          hostname: konnectivity.tenant-a.coe.muc.redhat.com
    - service: Ignition
      servicePublishingStrategy:
        type: Route
        route:
          hostname: ignition.tenant-a.coe.muc.redhat.com

---
apiVersion: hypershift.openshift.io/v1beta1
kind: NodePool
metadata:
  name: 'tenant-a'
  namespace: 'clusters'
spec:
  arch: amd64
  clusterName: 'tenant-a'
  replicas: 2
  management:
    autoRepair: false
    upgradeType: Replace
  platform:
    type: KubeVirt
    kubevirt:
      compute:
        cores: 2
        memory: 8Gi
      rootVolume:
        type: Persistent
        persistent:
          size: 32Gi
      additionalNetworks:
      - name: default/cudn-localnet1-2003
      attachDefaultNetwork: false
  release:
    image: quay.io/openshift-release-dev/ocp-release:4.21.11-multi

