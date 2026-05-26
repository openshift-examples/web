---
title: Hosted Control Plane and tenant networking
linktitle: Hosted Control Plane and tenant networking
description: Hosted Control Plane and tenant networking
tags: ['hcp','v4.21']
---
# Hosted Control Plane and tenant networking

Challenge: running a hosted cluster in a different tenant network segment or VLAN without wide-open access from the tenant segment to the management segment.

???+ note "Hub cluster must not route into tenant networks"

    The hub cluster must **not** have arbitrary Layer-3 addressing or routing into the tenant network segment. The hub may only attach hosted-cluster workloads—for example, KubeVirt VMs on a UDN `localnet`—to that segment.

    **Do not use MetalLB on the hub** to expose services into a tenant network. That pattern typically requires:

    * Tenant-network IP addressing on hub bare-metal nodes
    * [Enabling IP forwarding globally](https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html/networking_operators/cluster-network-operator#nw-cno-enable-ip-forwarding_cluster-network-operator)
    * [Enabling `routingViaHost`](https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html/networking_operators/cluster-network-operator#nw-operator-configuration-parameters-for-ovn-sdn_cluster-network-operator)

    Together, those changes let **any** workload on the hub reach tenant networks—not only the hosted cluster you intend to isolate.

    This guide uses **external load balancers in the tenant segment** and a **dedicated ingress controller shard** on the hub instead.

    ![](overview.drawio){ page="Page-1" }

An hosted cluster can devide into two parts: **control plane** and **data plan aka worker nodes**. For there parts there different technics to place it into a tenant network:

## Exposing hosted control plane into tenant network

... it is fairly hard. The following components must be reachable from workers and clients in/from tenant network and beyond:

* API Server
* OAuth
* Konnectivity
* Ignition

Here is a summary of common publishing options for these components:

|Component/Service|Exposing strategy (`servicePublishingStrategy`)|Kubernetes Service type `LoadBalancer`|Route (OpenShift router)|
|---|---|---|---|
|API Server|<li>LoadBalancer (recommended; Kubernetes `LoadBalancer` service)</li><li>NodePort* (not for production)</li>|✅|❌|
|OAuth|<li>Route (default)</li><li>NodePort* (not for production)</li>|❌|✅|
|Konnectivity|<li>Route (default)</li><li>LoadBalancer (Kubernetes `LoadBalancer` service)</li><li>NodePort* (not for production)</li>|✅|✅|
|Ignition|<li>Route (default)</li><li>NodePort* (not for production)</li>|❌|✅|

For this proof of concept, endpoints are exposed as follows:

* API Server: `LoadBalancer` (fronted by external `api-lb` in the tenant segment; see below)
* OAuth, Konnectivity, Ignition: `Route` via a **dedicated ingress controller shard** on the hub, fronted by external `ingress-shared-lb` with VIPs/DNS in the tenant segment

### Exposing components via a dedicated router shard

Use a dedicated OpenShift Ingress Controller shard on the **hub** so only the hosted-cluster control-plane Routes are served by that shard. Tenant clients resolve OAuth, Konnectivity, and Ignition hostnames to `ingress-shared-lb`, which forwards to the shard’s NodePorts on the management network.

Place an external load balancer in front of that shard (for example F5 BIG-IP or NetScaler) that can reach the hub’s management network and present stable tenant-facing VIPs or addresses.

## Exposing hosted worker nodes into netant network

Worker nodes (VM's) of the hosted cluster are straightforward: attach them to the tenant network segment (DHCP or equivalent addressing is required).

## Proof of concept environment overview

![](overview.drawio){ page="Page-2" }

### Router between Mgmt and Tenant-A

[VyOS](https://vyos.io/) acts as router and firewall between the management and the Tenant-A network. Restrict **lateral** traffic between the two segments (no full mesh); allow only what you need (for example DNS to resolvers, default route or NAT for internet egress). Hosted-cluster control-plane traffic from tenant nodes should flow to the **external load balancer VIPs** in the tenant segment (not directly into arbitrary management subnets).

??? example "VyOS config commands"

    ```shell
    --8<-- "content/cluster-installation/hosted-control-plane/tenant-network/vyos-router-2003.txt"
    ```

### Deployment sequence (reference)

Three external load balancers appear in this write-up; keep their roles distinct:

| Name | Role |
|------|------|
| `ingress-shared-lb` | Tenant-facing VIPs for OAuth, Konnectivity, Ignition Routes on the **hub** ingress shard |
| `api-lb` | Tenant-facing VIP for the hosted cluster **API** (`APIServer` publishing) |
| `ingress-lb` | Tenant-facing VIP for **hosted cluster** application Routes (`*.apps…`) |

Suggested order:

1. Hub ingress shard + `ingress-shared-lb` + DNS for the three control-plane hostnames: OAuth, Konnectivity, and Ignition
2. Apply `HostedCluster` and `NodePool`.
3. Deploy external load balancer for the Hosted-Cluster API `api-lb` + API DNS. Based on the NodePorts for the api kubernetes Service, located in hub cluster
4. Deploy external load balancer for the Hosted-Cluster Ingress `ingress-lb` + wildcard apps DNS. Based on the NodePorts of the ingress kubernetes service, located in hosted cluster.

### Hub ingress shard + `ingress-shared-lb`

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

The ingress shard load balancer is an RHEL 9 host running HAProxy (external load balancer `ingress-shared-lb`).

* Install HAProxy: `dnf install haproxy`
* Configure SELinux: `setsebool -P haproxy_connect_any 1`
* Apply the example `haproxy` configuration (update ports to match your NodePort service)
* Enable and start HAProxy: `systemctl enable --now haproxy`

??? example "HAProxy config"

    ```shell
    --8<-- "content/cluster-installation/hosted-control-plane/tenant-network/ingress-shared-haproxy.conf"
    ```

Add DNS records

```bind
konnectivity.tenant-a.coe.muc.redhat.com.       IN A 192.168.203.111
oauth.tenant-a.coe.muc.redhat.com.              IN A 192.168.203.111
ignition.tenant-a.coe.muc.redhat.com.           IN A 192.168.203.111
```

### Apply `HostedCluster` and `NodePool`

```yaml hl_lines="11 43-66" title="HostedCluster"
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
      appsDomain: apps.tenant-a.coe.muc.redhat.com # (1)
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
          hostname: api.tenant-a.coe.muc.redhat.com  # (2)
    - service: OAuthServer
      servicePublishingStrategy:
        type: Route
        route:
          hostname: oauth.tenant-a.coe.muc.redhat.com  # (3)
    - service: OIDC
      servicePublishingStrategy:
        type: Route
    - service: Konnectivity
      servicePublishingStrategy:
        type: Route
        route:
          hostname: konnectivity.tenant-a.coe.muc.redhat.com  # (4)
    - service: Ignition
      servicePublishingStrategy:
        type: Route
        route:
          hostname: ignition.tenant-a.coe.muc.redhat.com  # (5)
```

1. `appsDomain`: resolve names under `apps.tenant-a.coe.muc.redhat.com` to **`ingress-lb`** (hosted cluster ingress), not the hub shard.
2. API server `loadBalancer.hostname`: resolve to **`api-lb`**, which forwards to the `APIServer` publishing target on the hub.
3. OAuth `route.hostname`: resolve to **`ingress-shared-lb`** (hub dedicated shard).
4. Konnectivity `route.hostname`: resolve to **`ingress-shared-lb`**.
5. Ignition `route.hostname`: resolve to **`ingress-shared-lb`**.

```yaml hl_lines="24-26" title="NodePool"
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
      - name: default/cudn-localnet1-2003 # (1)
      attachDefaultNetwork: false
  release:
    image: quay.io/openshift-release-dev/ocp-release:4.21.11-multi
```

1. Attach NodePool VMs to the tenant segment using a user-defined network (UDN) `localnet` attachment (`default/cudn-localnet1-2003` in this lab).

??? example "ClusterUserDefinedNetwork for `default/cudn-localnet1-2003`"

    ```yaml
    --8<-- "content/cluster-installation/hosted-control-plane/tenant-network/cudn-localnet1-2003.yaml"
    ```

### Deploy external load balancer for the Hosted-Cluster API (`api-lb`)

Use an RHEL 9 virtual machine with HAProxy.

* Install HAProxy: `dnf install haproxy`
* Configure SELinux: `setsebool -P haproxy_connect_any 1`
* Apply the example `haproxy` configuration (update ports to match your environment)
* Enable and start HAProxy: `systemctl enable --now haproxy`

??? example "HAProxy config"

    ```shell
    --8<-- "content/cluster-installation/hosted-control-plane/tenant-network/api-lb.conf"
    ```

Add DNS record:

```bind
api.tenant-a.coe.muc.redhat.com.       IN A 192.168.203.<IP of VM>
```

### Deploy external load balancer for Hosted-Cluster ingress (`ingress-lb`)

Use an RHEL 9 virtual machine with HAProxy.

* Install HAProxy: `dnf install haproxy`
* Configure SELinux: `setsebool -P haproxy_connect_any 1`
* Apply the example `haproxy` configuration (update ports to match your environment)
* Enable and start HAProxy: `systemctl enable --now haproxy`

??? example "HAProxy config"

    ```shell
    --8<-- "content/cluster-installation/hosted-control-plane/tenant-network/ingress-lb.conf"
    ```

Add DNS record:

```bind
*.apps.tenant-a.coe.muc.redhat.com.       IN A 192.168.203.<IP of VM>
```

## Open topics

* Disable or constrain cloud provider integration so that Kubernetes `LoadBalancer` Service requests for the hosted cluster are not satisfied by the hub cluster cloud integration unless that is intentional.
* WebUI bug: ACM shows `https://console-openshift-console.apps.tenant-a.apps.ocp5.stormshift.coe.muc.redhat.com/` for the console, but the URL should be `https://console-openshift-console.apps.tenant-a.coe.muc.redhat.com/`.
* Add custom endpoint publishing strategy
* Find a solution for the NodePort chicken-and-egg problem of the external API load balancer
* Improve ClusterUserDefinedNetwork with following selector:

    ```yaml
    namespaceSelector:
      matchExpressions:
      - key: hypershift.openshift.io/hosted-control-plane
        operator: Exists
    ```

## Verions

Tested with:

|Component|Version|
|---|---|
|OpenShift|v4.21.9|
|OpenShift Virt|v4.21.0|
|MCE|v2.11.1|
