---
title: Node failure test
linktitle: Node failure
description: Let's switch off some control plane nodes.
tags: ['etcd','control-plane','v4.17']
---

# Node failure test

Just some stupid tests with OpenShift 4.17.6

Useful etcd commands

* Member list

  ```shell
  etcdctl member list -w table
  ```

* Endpoint status

  ```shell
  etcdctl endpoint status --cluster -w table
  ```

* Endpoint health

  ```shell
  etcdctl endpoint health --cluster -w table
  ```

## One control plane node stopeed

```bash
stormshift-ocp1 % oc get nodes
NAME            STATUS                     ROLES                  AGE   VERSION
ocp1-cp-1       Ready                      control-plane,master   47d   v1.30.6
ocp1-cp-2       Ready                      control-plane,master   47d   v1.30.6
ocp1-cp-3       NotReady                   control-plane,master   47d   v1.30.6
ocp1-worker-1   Ready,SchedulingDisabled   worker                 47d   v1.30.6
ocp1-worker-2   Ready                      worker                 47d   v1.30.6
ocp1-worker-3   Ready                      worker                 47d   v1.30.6
stormshift-ocp1 % oc project openshift-etcd
Now using project "openshift-etcd" on server "https://api.ocp1.stormshift.coe.muc.redhat.com:6443".
stormshift-ocp1 % oc rsh etcd-ocp1-cp-1
sh-5.1# etcdctl member list -w table
+------------------+---------+-----------+---------------------------+---------------------------+------------+
|        ID        | STATUS  |   NAME    |        PEER ADDRS         |       CLIENT ADDRS        | IS LEARNER |
+------------------+---------+-----------+---------------------------+---------------------------+------------+
| 9361c16cca0a52c5 | started | ocp1-cp-1 | https://10.32.105.69:2380 | https://10.32.105.69:2379 |      false |
| dd0e380e6566ab83 | started | ocp1-cp-3 | https://10.32.105.71:2380 | https://10.32.105.71:2379 |      false |
| eea27a29a8df8033 | started | ocp1-cp-2 | https://10.32.105.70:2380 | https://10.32.105.70:2379 |      false |
+------------------+---------+-----------+---------------------------+---------------------------+------------+
sh-5.1# etcdctl endpoint status --cluster -w table
{"level":"warn","ts":"2024-12-27T11:07:50.115169Z","logger":"etcd-client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc000334000/10.32.105.69:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = context deadline exceeded"}
Failed to get the status of endpoint https://10.32.105.71:2379 (context deadline exceeded)
+---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|         ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| https://10.32.105.69:2379 | 9361c16cca0a52c5 |  3.5.16 |  216 MB |     false |      false |        96 |   38406435 |           38406435 |        |
| https://10.32.105.70:2379 | eea27a29a8df8033 |  3.5.16 |  225 MB |      true |      false |        96 |   38406627 |           38406627 |        |
+---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
sh-5.1# etcdctl endpoint health --cluster -w table
{"level":"warn","ts":"2024-12-27T11:17:48.594164Z","logger":"client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc000028000/10.32.105.71:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing: dial tcp 10.32.105.71:2379: connect: no route to host\""}
+---------------------------+--------+--------------+---------------------------+
|         ENDPOINT          | HEALTH |     TOOK     |           ERROR           |
+---------------------------+--------+--------------+---------------------------+
| https://10.32.105.70:2379 |   true |  11.411896ms |                           |
| https://10.32.105.69:2379 |   true |  64.159885ms |                           |
| https://10.32.105.71:2379 |  false | 5.001203643s | context deadline exceeded |
+---------------------------+--------+--------------+---------------------------+
Error: unhealthy cluster

```

### Two control plane node stopeed

```bash
stormshift-ocp1 % oc get nodes
E1227 12:22:03.571833   13097 memcache.go:265] couldn't get current server API group list: Get "https://api.ocp1.stormshift.coe.muc.redhat.com:6443/api?timeout=32s": read tcp 10.45.224.79:64868->10.32.105.64:6443: read: connection reset by peer - error from a previous attempt: EOF
E1227 12:22:14.633911   13097 memcache.go:265] couldn't get current server API group list: Get "https://api.ocp1.stormshift.coe.muc.redhat.com:6443/api?timeout=32s": EOF - error from a previous attempt: read tcp 10.45.224.79:64884->10.32.105.64:6443: read: connection reset by peer
E1227 12:22:25.699832   13097 memcache.go:265] couldn't get current server API group list: Get "https://api.ocp1.stormshift.coe.muc.redhat.com:6443/api?timeout=32s": EOF
E1227 12:22:36.760007   13097 memcache.go:265] couldn't get current server API group list: Get "https://api.ocp1.stormshift.coe.muc.redhat.com:6443/api?timeout=32s": read tcp 10.45.224.79:64922->10.32.105.64:6443: read: connection reset by peer - error from a previous attempt: EOF
E1227 12:22:47.828811   13097 memcache.go:265] couldn't get current server API group list: Get "https://api.ocp1.stormshift.coe.muc.redhat.com:6443/api?timeout=32s": read tcp 10.45.224.79:64944->10.32.105.64:6443: read: connection reset by peer - error from a previous attempt: EOF
E1227 12:22:58.879779   13097 memcache.go:265] couldn't get current server API group list: Get "https://api.ocp1.stormshift.coe.muc.redhat.com:6443/api?timeout=32s": EOF
Unable to connect to the server: EOF
stormshift-ocp1 %

# Let's see where the API VIP is located

[root@inf1 ~]# dig +short api.ocp1.stormshift.coe.muc.redhat.com
10.32.105.64
[root@inf1 ~]# for i in {64,69,70,71} ; do arping -c1 -I eno1 10.32.105.${i}; done;
ARPING 10.32.105.64 from 10.32.96.1 eno1
Unicast reply from 10.32.105.64 [0E:C0:EF:20:69:46]  1.969ms
Sent 1 probes (1 broadcast(s))
Received 1 response(s)
ARPING 10.32.105.69 from 10.32.96.1 eno1
Sent 1 probes (1 broadcast(s))
Received 0 response(s)
ARPING 10.32.105.70 from 10.32.96.1 eno1
Unicast reply from 10.32.105.70 [0E:C0:EF:20:69:46]  1.965ms
Unicast reply from 10.32.105.70 [0E:C0:EF:20:69:46]  2.040ms
Sent 1 probes (1 broadcast(s))
Received 2 response(s)
ARPING 10.32.105.71 from 10.32.96.1 eno1
Sent 1 probes (1 broadcast(s))
Received 0 response(s)

# => It's at the last running control plane node.

# API is down!


stormshift-ocp1 % ssh -i ~/.ssh/coe-muc -l core 10.32.105.70
Warning: Permanently added '10.32.105.70' (ED25519) to the list of known hosts.
Red Hat Enterprise Linux CoreOS 417.94.202411201839-0
  Part of OpenShift 4.17, RHCOS is a Kubernetes-native operating system
  managed by the Machine Config Operator (`clusteroperator/machine-config`).

WARNING: Direct SSH access to machines is not recommended; instead,
make configuration changes via `machineconfig` objects:
  https://docs.openshift.com/container-platform/4.17/architecture/architecture-rhcos.html

---
[core@ocp1-cp-2 ~]$ sudo su -
[root@ocp1-cp-2 ~]# podman ps
CONTAINER ID  IMAGE       COMMAND     CREATED     STATUS      PORTS       NAMES
[root@ocp1-cp-2 ~]# crictl ps | grep etcd
fd5cd4dec81fc       134bea824ae987a5f3aae304150939f3c52181046c3c607c56deedb4a93d4487            19 hours ago         Running             guard          0  f27946021fbfa       etcd-guard-ocp1-cp-2
f899f8f88c2d2       134bea824ae987a5f3aae304150939f3c52181046c3c607c56deedb4a93d4487            19 hours ago         Running             etcd-readyz    4  969ca7fb5dadc       etcd-ocp1-cp-2
3a0a97da14ab4       2e2e5aecbcfc3161ff18f627dc4ff74b8500e825290c94f86cecfc1abe0841b1            19 hours ago         Running             etcd-metrics   4  969ca7fb5dadc       etcd-ocp1-cp-2
87a1bcaf770af       2e2e5aecbcfc3161ff18f627dc4ff74b8500e825290c94f86cecfc1abe0841b1            19 hours ago         Running             etcd           4  969ca7fb5dadc       etcd-ocp1-cp-2
12ca9e2a5b987       2e2e5aecbcfc3161ff18f627dc4ff74b8500e825290c94f86cecfc1abe0841b1            19 hours ago         Running             etcdctl        4  969ca7fb5dadc       etcd-ocp1-cp-2
[root@ocp1-cp-2 ~]# crictl exec -ti 87a1bcaf770af bash
[root@ocp1-cp-2 /]#  etcdctl endpoint status  -w table
{"level":"warn","ts":"2024-12-27T11:30:09.797892Z","logger":"etcd-client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc000020000/10.32.105.69:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing: dial tcp 10.32.105.69:2379: connect: no route to host\""}
Failed to get the status of endpoint https://10.32.105.69:2379 (context deadline exceeded)
{"level":"warn","ts":"2024-12-27T11:30:14.810925Z","logger":"etcd-client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc000020000/10.32.105.69:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing: dial tcp 10.32.105.71:2379: connect: no route to host\""}
Failed to get the status of endpoint https://10.32.105.71:2379 (context deadline exceeded)
+---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+-----------------------+
|         ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX |        ERRORS         |
+---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+-----------------------+
| https://10.32.105.70:2379 | eea27a29a8df8033 |  3.5.16 |  228 MB |     false |      false |        96 |   38419686 |           38419686 | etcdserver: no leader |
+---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+-----------------------+
[root@ocp1-cp-2 /]# etcdctl endpoint health -w table
{"level":"warn","ts":"2024-12-27T11:32:27.857912Z","logger":"client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc000004000/10.32.105.69:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing: dial tcp 10.32.105.69:2379: connect: no route to host\""}
{"level":"warn","ts":"2024-12-27T11:32:27.857950Z","logger":"client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc0001dc000/10.32.105.71:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing: dial tcp 10.32.105.71:2379: connect: no route to host\""}
{"level":"warn","ts":"2024-12-27T11:32:27.858004Z","logger":"client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc0000b0000/10.32.105.70:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = context deadline exceeded"}
+---------------------------+--------+--------------+---------------------------+
|         ENDPOINT          | HEALTH |     TOOK     |           ERROR           |
+---------------------------+--------+--------------+---------------------------+
| https://10.32.105.69:2379 |  false | 5.001321907s | context deadline exceeded |
| https://10.32.105.71:2379 |  false | 5.001394336s | context deadline exceeded |
| https://10.32.105.70:2379 |  false |  5.00145915s | context deadline exceeded |
+---------------------------+--------+--------------+---------------------------+
Error: unhealthy cluster
[root@ocp1-cp-2 /]#
```

* OpenShift Console still response but is not really available because it's relying on the API Server.
* Forward to oauth works but then: `{"error":"server_error","error_description":"The authorization server encountered an unexpected condition that prevented it from fulfilling the request.","state":"3f6e22484bc53d44b94682fef012f597"}`

Let's restart all control plane nodes...

## Let's scale control plane to 5

* `oc adm node-image create` is only to add worker nodes.

* [OCP 4.17 Release nodes](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/release_notes/ocp-4-17-release-notes#ocp-4-17-etcd-4-5-nodes_release-notes)
  * [Node scaling for etcd](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html-single/scalability_and_performance/#etcd-node-scaling_recommended-etcd-practices)
    * For more information about how to scale control plane nodes by using the Assisted Installer, see
      "[Adding hosts with the API](https://docs.redhat.com/en/documentation/assisted_installer_for_openshift_container_platform/2024/html/installing_openshift_container_platform_with_the_assisted_installer/expanding-the-cluster#adding-hosts-with-the-api_expanding-the-cluster)"
      and
      "Installing a primary control plane node on a healthy cluster".

      **Link missing!** <https://issues.redhat.com/browse/OSDOCS-13017>

      Let's try the old fassion way:

```yaml
apiVersion: metal3.io/v1alpha1
kind: BareMetalHost
metadata:
  name: ocp1-cp-5
  namespace: openshift-machine-api
spec:
  automatedCleaningMode: metadata
  bootMACAddress: 0E:C0:EF:20:69:49
  bootMode: legacy
  customDeploy:
    method: install_coreos
  externallyProvisioned: true
  online: true
  userData:
    name: master-user-data-managed
    namespace: openshift-machine-api
status:
  hardware:
    hostname: ''
    nics:
      - ip: 10.32.105.73
        mac: '0E:C0:EF:20:69:49'
        model: "unknown"
         name: "enp1s0"
```

```yaml
apiVersion: machine.openshift.io/v1beta1
kind: Machine
metadata:
  annotations:
    machine.openshift.io/instance-state: externally provisioned
    metal3.io/BareMetalHost: openshift-machine-api/ocp1-cp-5
  labels:
    machine.openshift.io/cluster-api-cluster: ocp1-nlxjs
    machine.openshift.io/cluster-api-machine-role: master
    machine.openshift.io/cluster-api-machine-type: master
  name: ocp1-cp-5
  namespace: openshift-machine-api
spec:
  metadata: {}
  providerSpec:
    value:
      apiVersion: baremetal.cluster.k8s.io/v1alpha1
      customDeploy:
        method: install_coreos
      hostSelector: {}
      image:
        checksum: ""
        url: ""
      kind: BareMetalMachineProviderSpec
      metadata:
        creationTimestamp: null
      userData:
        name: master-user-data-managed
```

```bash
etcd-ocp1-cp-4                 3/4     CrashLoopBackOff   40 (54s ago)   168m

oc logs ...

#### attempt 134
      member={name="ocp1-cp-1", peerURLs=[https://10.32.105.69:2380}, clientURLs=[https://10.32.105.69:2379]
      member={name="ocp1-cp-3", peerURLs=[https://10.32.105.71:2380}, clientURLs=[https://10.32.105.71:2379]
      member={name="ocp1-cp-2", peerURLs=[https://10.32.105.70:2380}, clientURLs=[https://10.32.105.70:2379]
      member "https://10.32.105.72:2380" not found in member list, check operator logs for possible scaling problems
#### sleeping...

oc get bmh,nodes,machine -A
NAMESPACE               NAME                                    STATE       CONSUMER                    ONLINE   ERROR   AGE
openshift-machine-api   baremetalhost.metal3.io/ocp1-cp-1       unmanaged   ocp1-nlxjs-master-0         true             48d
openshift-machine-api   baremetalhost.metal3.io/ocp1-cp-2       unmanaged   ocp1-nlxjs-master-1         true             48d
openshift-machine-api   baremetalhost.metal3.io/ocp1-cp-3       unmanaged   ocp1-nlxjs-master-2         true             48d
openshift-machine-api   baremetalhost.metal3.io/ocp1-cp-4       unmanaged   ocp1-cp-4                   true             3h6m
openshift-machine-api   baremetalhost.metal3.io/ocp1-worker-1   unmanaged   ocp1-nlxjs-worker-0-cj9p7   true             48d
openshift-machine-api   baremetalhost.metal3.io/ocp1-worker-2   unmanaged   ocp1-nlxjs-worker-0-j9xr2   true             48d
openshift-machine-api   baremetalhost.metal3.io/ocp1-worker-3   unmanaged   ocp1-nlxjs-worker-0-jfhvn   true             48d

NAMESPACE   NAME                 STATUS   ROLES                  AGE    VERSION
            node/ocp1-cp-1       Ready    control-plane,master   48d    v1.30.6
            node/ocp1-cp-2       Ready    control-plane,master   48d    v1.30.6
            node/ocp1-cp-3       Ready    control-plane,master   48d    v1.30.6
            node/ocp1-cp-4       Ready    control-plane,master   176m   v1.30.6
            node/ocp1-worker-1   Ready    worker                 48d    v1.30.6
            node/ocp1-worker-2   Ready    worker                 48d    v1.30.6
            node/ocp1-worker-3   Ready    worker                 48d    v1.30.6

NAMESPACE               NAME                                                     PHASE         TYPE   REGION   ZONE   AGE
openshift-machine-api   machine.machine.openshift.io/ocp1-cp-4                   Provisioned                          3h6m
openshift-machine-api   machine.machine.openshift.io/ocp1-nlxjs-master-0         Running                              48d
openshift-machine-api   machine.machine.openshift.io/ocp1-nlxjs-master-1         Running                              48d
openshift-machine-api   machine.machine.openshift.io/ocp1-nlxjs-master-2         Running                              48d
openshift-machine-api   machine.machine.openshift.io/ocp1-nlxjs-worker-0-cj9p7   Running                              48d
openshift-machine-api   machine.machine.openshift.io/ocp1-nlxjs-worker-0-j9xr2   Running                              48d
openshift-machine-api   machine.machine.openshift.io/ocp1-nlxjs-worker-0-jfhvn   Running                              48d

export HOST_PROXY_API_PATH="http://127.0.0.1:8001/apis/metal3.io/v1alpha1/namespaces/openshift-machine-api/baremetalhosts"

read -r -d '' host_patch << EOF
{
  "status": {
    "hardware": {
      "nics": [
        {
          "ip": "10.32.105.73",
          "mac": "0E:C0:EF:20:69:49"
        }
      ]
    }
  }
}
EOF

curl -vv \
     -X PATCH \
     "${HOST_PROXY_API_PATH}/ocp1-cp-5/status" \
     -H "Content-type: application/merge-patch+json" \
     -d "${host_patch}"

oc get bmh,nodes,machine -A
NAMESPACE               NAME                                    STATE       CONSUMER                    ONLINE   ERROR   AGE
openshift-machine-api   baremetalhost.metal3.io/ocp1-cp-1       unmanaged   ocp1-nlxjs-master-0         true             48d
openshift-machine-api   baremetalhost.metal3.io/ocp1-cp-2       unmanaged   ocp1-nlxjs-master-1         true             48d
openshift-machine-api   baremetalhost.metal3.io/ocp1-cp-3       unmanaged   ocp1-nlxjs-master-2         true             48d
openshift-machine-api   baremetalhost.metal3.io/ocp1-cp-4       unmanaged   ocp1-cp-4                   true             3h28m
openshift-machine-api   baremetalhost.metal3.io/ocp1-worker-1   unmanaged   ocp1-nlxjs-worker-0-cj9p7   true             48d
openshift-machine-api   baremetalhost.metal3.io/ocp1-worker-2   unmanaged   ocp1-nlxjs-worker-0-j9xr2   true             48d
openshift-machine-api   baremetalhost.metal3.io/ocp1-worker-3   unmanaged   ocp1-nlxjs-worker-0-jfhvn   true             48d

NAMESPACE   NAME                 STATUS   ROLES                  AGE     VERSION
            node/ocp1-cp-1       Ready    control-plane,master   48d     v1.30.6
            node/ocp1-cp-2       Ready    control-plane,master   48d     v1.30.6
            node/ocp1-cp-3       Ready    control-plane,master   48d     v1.30.6
            node/ocp1-cp-4       Ready    control-plane,master   3h18m   v1.30.6
            node/ocp1-worker-1   Ready    worker                 48d     v1.30.6
            node/ocp1-worker-2   Ready    worker                 48d     v1.30.6
            node/ocp1-worker-3   Ready    worker                 48d     v1.30.6

NAMESPACE               NAME                                                     PHASE     TYPE   REGION   ZONE   AGE
openshift-machine-api   machine.machine.openshift.io/ocp1-cp-4                   Running                          3h28m
openshift-machine-api   machine.machine.openshift.io/ocp1-nlxjs-master-0         Running                          48d
openshift-machine-api   machine.machine.openshift.io/ocp1-nlxjs-master-1         Running                          48d
openshift-machine-api   machine.machine.openshift.io/ocp1-nlxjs-master-2         Running                          48d
openshift-machine-api   machine.machine.openshift.io/ocp1-nlxjs-worker-0-cj9p7   Running                          48d
openshift-machine-api   machine.machine.openshift.io/ocp1-nlxjs-worker-0-j9xr2   Running                          48d
openshift-machine-api   machine.machine.openshift.io/ocp1-nlxjs-worker-0-jfhvn   Running                          48d
```

Maybe we can change the iso from `oc adm node..`

```bash
coreos-installer iso ignition show node.x86_64.iso  | jq | grep -A5 -B5 worker
        "mode": 420
      },
      {
        "group": {},
        "overwrite": true,
        "path": "/etc/assisted/clusterconfig/worker-ignition-endpoint.json",
        "user": {
          "name": "root"
        },
        "contents": {
          "source": "data:text/plain;charset=utf-8;base64,eyJjYV9jZXJ0aWZpY2F0ZSI6IkxTMHRMUzFDUlVkSlRpQkRSVkpVU1VaSlEwRlVSUzB0TFMwdENrMUpTVVJGUkVORFFXWnBaMEYzU1VKQlowbEpTMll4YlZwQ2NGZGFUbk4zUkZGWlNrdHZXa2xvZG1OT1FWRkZURUpSUVhkS2FrVlRUVUpCUjBFeFZVVUtRM2hOU21JelFteGliazV2WVZkYU1FMVNRWGRFWjFsRVZsRlJSRVYzWkhsaU1qa3dURmRPYUUxQ05GaEVWRWt3VFZSRmQwOVVSVEZPVkdzeFRURnZXQXBFVkUwd1RWUkZkMDU2UlRGT1ZHc3hUVEZ2ZDBwcVJWTk5Ra0ZIUVRGVlJVTjRUVXBpTTBKc1ltNU9iMkZYV2pCTlVrRjNSR2RaUkZaUlVVUkZkMlI1Q21JeU9UQk1WMDVvVFVsSlFrbHFRVTVDWjJ0eGFHdHBSemwzTUVKQlVVVkdRVUZQUTBGUk9FRk5TVWxDUTJkTFEwRlJSVUY1YTBwU1JraENURTV4ZW13S1dqaFBUM3BCZGxkaFdVNVJWakZQYjNBNGFrUnBkR1V5VFRSWVlraG1iRmxMTldKTE5XNHhXV1JSUzJVNU5YaHdaR3RGVXpSWFpIUnJUalk1VGtsNVdRcGhLeXNyTWt0TmVtNVJkR05rWTA1VmNtTjJSVUZIV2xFM1JqaHFTWFF6V1RGSlpESlBMMDkxUjA5dFVuSktiV1JSVkVGdGNEWkRZVGhVV0ZOMk9YZFdDbUp1VlhBeVJtVnJkV1JHUnl0aWFFdFNZbmxoWVVwMVUyTk5ZbGxNVERKd2VUTkNVVlV2T0RaWWJ6TkZPVTQwYkRsWllTdGhNQzlQTkVsRldtUnFaVUVLTUhjdmQzRm5RVUpHWVhwalZtWmtibWhIUkdKTGJIcFRVVlpuVkdGdE5USTNNWGRxU0hOSmNFWkpkR05tWm14bGVsTnNSMjR2VEVWaGMwRlJVVEpKWWdwV05WaGhTalUwVlZGNVMyWndiM2N2VW5WR01TczFhbUU0Tmxoa1VqUk5TbFZGZG10RVVFZHRUMmhxY1ZkMk5qZ3ZXbVozZGxrMGVscHNOWE0zVEU5NENqaGtOek54SzBkUWVYZEpSRUZSUVVKdk1FbDNVVVJCVDBKblRsWklVVGhDUVdZNFJVSkJUVU5CY1ZGM1JIZFpSRlpTTUZSQlVVZ3ZRa0ZWZDBGM1JVSUtMM3BCWkVKblRsWklVVFJGUm1kUlZWbFBTemxNTkRrclRuUTVNbTVWUzNsVU9YcFpaakkwV0d0NVkzZEVVVmxLUzI5YVNXaDJZMDVCVVVWTVFsRkJSQXBuWjBWQ1FVdEtiSFYxSzJsRmVXdHpSVVk1UTJ4b1ZIUTBTamxoYmxoREwwRXdXbGQwUlV4aGMyVXdaR3RNYlVSTWNHUkNia1ZRYzFGQ2NsZGhWM0pPQ2xSQ1dVWnBjM05NVEVJNU5rWlBRMVJHUWtNd1RWQkJTMUozTkd4NmJXWklVSEJ4YWpJd2FrUXhMM1U1T1hOUVNVcEhSSFJSY1daNmIwUnlWM0YxWWxJS01ETnBXRlZaV0ZCc0wwVmpRM0JqWmtVNVJuVkxWVVp0YkhsbFRXd3hXRWg0U2k4clIyMTFkVlphUVdKaFJVbDVWalZTUkU5TWJHSlFSMUZ4WWk5M1VBcGFhVUZhUkZSSVNuZGlUMHhzTDFSMGNqaFdMMmQ2YTIwdlZVMVBiMDlsTjBaS2RtOTVkRXRGWWtGTVExcG9XbkV5VDJWMkswNUhkbWd3V0dFMmFHMUNDbVJsTTJoRVYyazVja1ZTVFdsRFRHaDFURkkxYVZWTE5rc3hPRTlVVW5vME5IZHJOV05YWWs5MWRqTXZSWGh3UVhoWlVsSldOR0o0VmtwS2VFc3dlRFlLTDA1eFRVNWpWVzlRUzNwQ01tdGhlRWhyWlRoc1dpdFFRbEpKUFFvdExTMHRMVVZPUkNCRFJWSlVTVVpKUTBGVVJTMHRMUzB0Q2c9PSIsInVybCI6Imh0dHBzOi8vMTAuMzIuMTA1LjY0OjIyNjIzL2NvbmZpZy93b3JrZXIifQ==",

echo eyJjYV9jZXJ0aWZpY2F0ZSI6IkxTMHRMUzFDUlVkSlRpQkRSVkpVU1VaSlEwRlVSUzB0TFMwdENrMUpTVVJGUkVORFFXWnBaMEYzU1VKQlowbEpTMll4YlZwQ2NGZGFUbk4zUkZGWlNrdHZXa2xvZG1OT1FWRkZURUpSUVhkS2FrVlRUVUpCUjBFeFZVVUtRM2hOU21JelFteGliazV2WVZkYU1FMVNRWGRFWjFsRVZsRlJSRVYzWkhsaU1qa3dURmRPYUUxQ05GaEVWRWt3VFZSRmQwOVVSVEZPVkdzeFRURnZXQXBFVkUwd1RWUkZkMDU2UlRGT1ZHc3hUVEZ2ZDBwcVJWTk5Ra0ZIUVRGVlJVTjRUVXBpTTBKc1ltNU9iMkZYV2pCTlVrRjNSR2RaUkZaUlVVUkZkMlI1Q21JeU9UQk1WMDVvVFVsSlFrbHFRVTVDWjJ0eGFHdHBSemwzTUVKQlVVVkdRVUZQUTBGUk9FRk5TVWxDUTJkTFEwRlJSVUY1YTBwU1JraENURTV4ZW13S1dqaFBUM3BCZGxkaFdVNVJWakZQYjNBNGFrUnBkR1V5VFRSWVlraG1iRmxMTldKTE5XNHhXV1JSUzJVNU5YaHdaR3RGVXpSWFpIUnJUalk1VGtsNVdRcGhLeXNyTWt0TmVtNVJkR05rWTA1VmNtTjJSVUZIV2xFM1JqaHFTWFF6V1RGSlpESlBMMDkxUjA5dFVuSktiV1JSVkVGdGNEWkRZVGhVV0ZOMk9YZFdDbUp1VlhBeVJtVnJkV1JHUnl0aWFFdFNZbmxoWVVwMVUyTk5ZbGxNVERKd2VUTkNVVlV2T0RaWWJ6TkZPVTQwYkRsWllTdGhNQzlQTkVsRldtUnFaVUVLTUhjdmQzRm5RVUpHWVhwalZtWmtibWhIUkdKTGJIcFRVVlpuVkdGdE5USTNNWGRxU0hOSmNFWkpkR05tWm14bGVsTnNSMjR2VEVWaGMwRlJVVEpKWWdwV05WaGhTalUwVlZGNVMyWndiM2N2VW5WR01TczFhbUU0Tmxoa1VqUk5TbFZGZG10RVVFZHRUMmhxY1ZkMk5qZ3ZXbVozZGxrMGVscHNOWE0zVEU5NENqaGtOek54SzBkUWVYZEpSRUZSUVVKdk1FbDNVVVJCVDBKblRsWklVVGhDUVdZNFJVSkJUVU5CY1ZGM1JIZFpSRlpTTUZSQlVVZ3ZRa0ZWZDBGM1JVSUtMM3BCWkVKblRsWklVVFJGUm1kUlZWbFBTemxNTkRrclRuUTVNbTVWUzNsVU9YcFpaakkwV0d0NVkzZEVVVmxLUzI5YVNXaDJZMDVCVVVWTVFsRkJSQXBuWjBWQ1FVdEtiSFYxSzJsRmVXdHpSVVk1UTJ4b1ZIUTBTamxoYmxoREwwRXdXbGQwUlV4aGMyVXdaR3RNYlVSTWNHUkNia1ZRYzFGQ2NsZGhWM0pPQ2xSQ1dVWnBjM05NVEVJNU5rWlBRMVJHUWtNd1RWQkJTMUozTkd4NmJXWklVSEJ4YWpJd2FrUXhMM1U1T1hOUVNVcEhSSFJSY1daNmIwUnlWM0YxWWxJS01ETnBXRlZaV0ZCc0wwVmpRM0JqWmtVNVJuVkxWVVp0YkhsbFRXd3hXRWg0U2k4clIyMTFkVlphUVdKaFJVbDVWalZTUkU5TWJHSlFSMUZ4WWk5M1VBcGFhVUZhUkZSSVNuZGlUMHhzTDFSMGNqaFdMMmQ2YTIwdlZVMVBiMDlsTjBaS2RtOTVkRXRGWWtGTVExcG9XbkV5VDJWMkswNUhkbWd3V0dFMmFHMUNDbVJsTTJoRVYyazVja1ZTVFdsRFRHaDFURkkxYVZWTE5rc3hPRTlVVW5vME5IZHJOV05YWWs5MWRqTXZSWGh3UVhoWlVsSldOR0o0VmtwS2VFc3dlRFlLTDA1eFRVNWpWVzlRUzNwQ01tdGhlRWhyWlRoc1dpdFFRbEpKUFFvdExTMHRMVVZPUkNCRFJWSlVTVVpKUTBGVVJTMHRMUzB0Q2c9PSIsInVybCI6Imh0dHBzOi8vMTAuMzIuMTA1LjY0OjIyNjIzL2NvbmZpZy93b3JrZXIifQ== | base64 -d | jq
{
  "ca_certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURFRENDQWZpZ0F3SUJBZ0lJS2YxbVpCcFdaTnN3RFFZSktvWklodmNOQVFFTEJRQXdKakVTTUJBR0ExVUUKQ3hNSmIzQmxibk5vYVdaME1SQXdEZ1lEVlFRREV3ZHliMjkwTFdOaE1CNFhEVEkwTVRFd09URTFOVGsxTTFvWApEVE0wTVRFd056RTFOVGsxTTFvd0pqRVNNQkFHQTFVRUN4TUpiM0JsYm5Ob2FXWjBNUkF3RGdZRFZRUURFd2R5CmIyOTBMV05oTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUF5a0pSRkhCTE5xemwKWjhPT3pBdldhWU5RVjFPb3A4akRpdGUyTTRYYkhmbFlLNWJLNW4xWWRRS2U5NXhwZGtFUzRXZHRrTjY5Tkl5WQphKysrMktNem5RdGNkY05VcmN2RUFHWlE3RjhqSXQzWTFJZDJPL091R09tUnJKbWRRVEFtcDZDYThUWFN2OXdWCmJuVXAyRmVrdWRGRytiaEtSYnlhYUp1U2NNYllMTDJweTNCUVUvODZYbzNFOU40bDlZYSthMC9PNElFWmRqZUEKMHcvd3FnQUJGYXpjVmZkbmhHRGJLbHpTUVZnVGFtNTI3MXdqSHNJcEZJdGNmZmxlelNsR24vTEVhc0FRUTJJYgpWNVhhSjU0VVF5S2Zwb3cvUnVGMSs1amE4NlhkUjRNSlVFdmtEUEdtT2hqcVd2NjgvWmZ3dlk0elpsNXM3TE94CjhkNzNxK0dQeXdJREFRQUJvMEl3UURBT0JnTlZIUThCQWY4RUJBTUNBcVF3RHdZRFZSMFRBUUgvQkFVd0F3RUIKL3pBZEJnTlZIUTRFRmdRVVlPSzlMNDkrTnQ5Mm5VS3lUOXpZZjI0WGt5Y3dEUVlKS29aSWh2Y05BUUVMQlFBRApnZ0VCQUtKbHV1K2lFeWtzRUY5Q2xoVHQ0SjlhblhDL0EwWld0RUxhc2UwZGtMbURMcGRCbkVQc1FCcldhV3JOClRCWUZpc3NMTEI5NkZPQ1RGQkMwTVBBS1J3NGx6bWZIUHBxajIwakQxL3U5OXNQSUpHRHRRcWZ6b0RyV3F1YlIKMDNpWFVZWFBsL0VjQ3BjZkU5RnVLVUZtbHllTWwxWEh4Si8rR211dVZaQWJhRUl5VjVSRE9MbGJQR1FxYi93UApaaUFaRFRISndiT0xsL1R0cjhWL2d6a20vVU1Pb09lN0ZKdm95dEtFYkFMQ1poWnEyT2V2K05HdmgwWGE2aG1CCmRlM2hEV2k5ckVSTWlDTGh1TFI1aVVLNksxOE9UUno0NHdrNWNXYk91djMvRXhwQXhZUlJWNGJ4VkpKeEsweDYKL05xTU5jVW9QS3pCMmtheEhrZThsWitQQlJJPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==",
  "url": "https://10.32.105.64:22623/config/worker"
```

### Five node master failure test

```bash
 oc rsh etcd-ocp1-cp-1
sh-5.1#  etcdctl member list -w table
+------------------+---------+-----------+---------------------------+---------------------------+------------+
|        ID        | STATUS  |   NAME    |        PEER ADDRS         |       CLIENT ADDRS        | IS LEARNER |
+------------------+---------+-----------+---------------------------+---------------------------+------------+
|  a94d184cdb2b189 | started | ocp1-cp-4 | https://10.32.105.72:2380 | https://10.32.105.72:2379 |      false |
| 6e4b8df7058b874d | started | ocp1-cp-5 | https://10.32.105.73:2380 | https://10.32.105.73:2379 |      false |
| 9361c16cca0a52c5 | started | ocp1-cp-1 | https://10.32.105.69:2380 | https://10.32.105.69:2379 |      false |
| dd0e380e6566ab83 | started | ocp1-cp-3 | https://10.32.105.71:2380 | https://10.32.105.71:2379 |      false |
| eea27a29a8df8033 | started | ocp1-cp-2 | https://10.32.105.70:2380 | https://10.32.105.70:2379 |      false |
+------------------+---------+-----------+---------------------------+---------------------------+------------+
sh-5.1# etcdctl endpoint status --cluster -w table
+---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|         ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| https://10.32.105.72:2379 |  a94d184cdb2b189 |  3.5.16 |  299 MB |     false |      false |       106 |   43758933 |           43758933 |        |
| https://10.32.105.73:2379 | 6e4b8df7058b874d |  3.5.16 |  297 MB |     false |      false |       106 |   43758933 |           43758933 |        |
| https://10.32.105.69:2379 | 9361c16cca0a52c5 |  3.5.16 |  283 MB |     false |      false |       106 |   43758933 |           43758933 |        |
| https://10.32.105.71:2379 | dd0e380e6566ab83 |  3.5.16 |  277 MB |      true |      false |       106 |   43758933 |           43758933 |        |
| https://10.32.105.70:2379 | eea27a29a8df8033 |  3.5.16 |  282 MB |     false |      false |       106 |   43758933 |           43758933 |        |
+---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
sh-5.1# etcdctl endpoint health --cluster -w table
+---------------------------+--------+-------------+-------+
|         ENDPOINT          | HEALTH |    TOOK     | ERROR |
+---------------------------+--------+-------------+-------+
| https://10.32.105.69:2379 |   true | 12.405665ms |       |
| https://10.32.105.71:2379 |   true | 15.124655ms |       |
| https://10.32.105.73:2379 |   true | 16.209654ms |       |
| https://10.32.105.72:2379 |   true | 17.704027ms |       |
| https://10.32.105.70:2379 |   true |  18.14493ms |       |
+---------------------------+--------+-------------+-------+
```

=> Stopped ocp1-cp-4 and ocp1-cp-5 -> Still a quorum ( no big deal)

```shell
% sh-5.1# etcdctl member list -w table
+------------------+---------+-----------+---------------------------+---------------------------+------------+
|        ID        | STATUS  |   NAME    |        PEER ADDRS         |       CLIENT ADDRS        | IS LEARNER |
+------------------+---------+-----------+---------------------------+---------------------------+------------+
|  a94d184cdb2b189 | started | ocp1-cp-4 | https://10.32.105.72:2380 | https://10.32.105.72:2379 |      false |
| 6e4b8df7058b874d | started | ocp1-cp-5 | https://10.32.105.73:2380 | https://10.32.105.73:2379 |      false |
| 9361c16cca0a52c5 | started | ocp1-cp-1 | https://10.32.105.69:2380 | https://10.32.105.69:2379 |      false |
| dd0e380e6566ab83 | started | ocp1-cp-3 | https://10.32.105.71:2380 | https://10.32.105.71:2379 |      false |
| eea27a29a8df8033 | started | ocp1-cp-2 | https://10.32.105.70:2380 | https://10.32.105.70:2379 |      false |
+------------------+---------+-----------+---------------------------+---------------------------+------------+
sh-5.1# etcdctl endpoint status --cluster -w table
{"level":"warn","ts":"2024-12-30T21:28:52.086828Z","logger":"etcd-client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc0004de000/10.32.105.69:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = context deadline exceeded"}
Failed to get the status of endpoint https://10.32.105.72:2379 (context deadline exceeded)
{"level":"warn","ts":"2024-12-30T21:28:57.089354Z","logger":"etcd-client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc0004de000/10.32.105.69:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = context deadline exceeded"}
Failed to get the status of endpoint https://10.32.105.73:2379 (context deadline exceeded)
+---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|         ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| https://10.32.105.69:2379 | 9361c16cca0a52c5 |  3.5.16 |  284 MB |     false |      false |       106 |   43777801 |           43777801 |        |
| https://10.32.105.71:2379 | dd0e380e6566ab83 |  3.5.16 |  278 MB |      true |      false |       106 |   43777803 |           43777803 |        |
| https://10.32.105.70:2379 | eea27a29a8df8033 |  3.5.16 |  283 MB |     false |      false |       106 |   43777803 |           43777803 |        |
+---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
sh-5.1# etcdctl endpoint health --cluster -w table
{"level":"warn","ts":"2024-12-30T21:29:03.463711Z","logger":"client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc00054c000/10.32.105.73:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = context deadline exceeded"}
{"level":"warn","ts":"2024-12-30T21:29:03.464054Z","logger":"client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc00054c780/10.32.105.72:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = context deadline exceeded"}
+---------------------------+--------+--------------+---------------------------+
|         ENDPOINT          | HEALTH |     TOOK     |           ERROR           |
+---------------------------+--------+--------------+---------------------------+
| https://10.32.105.71:2379 |   true |  46.507125ms |                           |
| https://10.32.105.69:2379 |   true |  46.617708ms |                           |
| https://10.32.105.70:2379 |   true |  46.925516ms |                           |
| https://10.32.105.73:2379 |  false | 5.007672716s | context deadline exceeded |
| https://10.32.105.72:2379 |  false | 5.007831398s | context deadline exceeded |
+---------------------------+--------+--------------+---------------------------+
Error: unhealthy cluster
sh-5.1#
```

=> Stopped ocp2-cp-1 as well -> No quorum anymore
  => k8s/OpenShift API is down!
  => ssh -l core 10.32.105.71...

```shell
[root@ocp1-cp-3 ~]# crictl  ps --name etcdctl
CONTAINER           IMAGE                                                              CREATED             STATE               NAME                ATTEMPT             POD ID              POD
7c1862dfece7e       2e2e5aecbcfc3161ff18f627dc4ff74b8500e825290c94f86cecfc1abe0841b1   3 days ago          Running             etcdctl             0                   d88510b37e130       etcd-ocp1-cp-3
[root@ocp1-cp-3 ~]# crictl exec -ti 7c1862dfece7e bash
# Or just one:
# [root@ocp1-cp-3 ~]# crictl exec -ti $(crictl  ps --name etcdctl -q) bash

[root@ocp1-cp-3 /]# etcdctl member list --endpoints=${ALL_ETCD_ENDPOINTS}
{"level":"fatal","ts":"2024-12-30T21:38:03.227805Z","caller":"flags/flag.go:85","msg":"conflicting environment variable is shadowed by corresponding command-line flag (either unset environment variable or disable flag))","environment-variable":"ETCDCTL_ENDPOINTS","stacktrace":"go.etcd.io/etcd/pkg/v3/flags.verifyEnv\n\tgo.etcd.io/etcd/pkg/v3@v3.5.16/flags/flag.go:85\ngo.etcd.io/etcd/pkg/v3/flags.SetPflagsFromEnv\n\tgo.etcd.io/etcd/pkg/v3@v3.5.16/flags/flag.go:63\ngo.etcd.io/etcd/etcdctl/v3/ctlv3/command.clientConfigFromCmd\n\tgo.etcd.io/etcd/etcdctl/v3/ctlv3/command/global.go:129\ngo.etcd.io/etcd/etcdctl/v3/ctlv3/command.mustClientFromCmd\n\tgo.etcd.io/etcd/etcdctl/v3/ctlv3/command/global.go:175\ngo.etcd.io/etcd/etcdctl/v3/ctlv3/command.memberListCommandFunc\n\tgo.etcd.io/etcd/etcdctl/v3/ctlv3/command/member_command.go:229\ngithub.com/spf13/cobra.(*Command).execute\n\tgithub.com/spf13/cobra@v1.1.3/command.go:856\ngithub.com/spf13/cobra.(*Command).ExecuteC\n\tgithub.com/spf13/cobra@v1.1.3/command.go:960\ngithub.com/spf13/cobra.(*Command).Execute\n\tgithub.com/spf13/cobra@v1.1.3/command.go:897\ngo.etcd.io/etcd/etcdctl/v3/ctlv3.Start\n\tgo.etcd.io/etcd/etcdctl/v3/ctlv3/ctl.go:107\ngo.etcd.io/etcd/etcdctl/v3/ctlv3.MustStart\n\tgo.etcd.io/etcd/etcdctl/v3/ctlv3/ctl.go:111\nmain.main\n\tgo.etcd.io/etcd/etcdctl/v3/main.go:59\nruntime.main\n\truntime/proc.go:271"}
[root@ocp1-cp-3 /]# etcdctl member list -w table
{"level":"warn","ts":"2024-12-30T21:38:13.508998Z","logger":"etcd-client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc0004d6000/10.32.105.69:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = context deadline exceeded"}
Error: context deadline exceeded
[root@ocp1-cp-3 /]# etcdctl endpoint status  -w table
{"level":"warn","ts":"2024-12-30T21:38:28.196351Z","logger":"etcd-client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc0004a6000/10.32.105.69:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing: dial tcp 10.32.105.69:2379: connect: no route to host\""}
Failed to get the status of endpoint https://10.32.105.69:2379 (context deadline exceeded)
{"level":"warn","ts":"2024-12-30T21:38:33.222409Z","logger":"etcd-client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc0004a6000/10.32.105.69:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing: dial tcp 10.32.105.72:2379: connect: no route to host\""}
Failed to get the status of endpoint https://10.32.105.72:2379 (context deadline exceeded)
{"level":"warn","ts":"2024-12-30T21:38:38.223996Z","logger":"etcd-client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc0004a6000/10.32.105.69:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing: dial tcp 10.32.105.73:2379: connect: no route to host\""}
Failed to get the status of endpoint https://10.32.105.73:2379 (context deadline exceeded)
+---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+-----------------------+
|         ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX |        ERRORS         |
+---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+-----------------------+
| https://10.32.105.70:2379 | eea27a29a8df8033 |  3.5.16 |  283 MB |     false |      false |       107 |   43779786 |           43779786 | etcdserver: no leader |
| https://10.32.105.71:2379 | dd0e380e6566ab83 |  3.5.16 |  278 MB |     false |      false |       107 |   43779786 |           43779786 | etcdserver: no leader |
+---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+-----------------------+
[root@ocp1-cp-3 /]# etcdctl endpoint health  -w table
{"level":"warn","ts":"2024-12-30T21:38:50.390211Z","logger":"client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc00009a000/10.32.105.70:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = context deadline exceeded"}
{"level":"warn","ts":"2024-12-30T21:38:50.390349Z","logger":"client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc000210000/10.32.105.71:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = context deadline exceeded"}
{"level":"warn","ts":"2024-12-30T21:38:50.390254Z","logger":"client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc00018a000/10.32.105.69:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing: dial tcp 10.32.105.69:2379: connect: no route to host\""}
{"level":"warn","ts":"2024-12-30T21:38:50.390153Z","logger":"client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc0002a2000/10.32.105.72:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing: dial tcp 10.32.105.72:2379: connect: no route to host\""}
{"level":"warn","ts":"2024-12-30T21:38:50.390204Z","logger":"client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc0000fa000/10.32.105.73:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing: dial tcp 10.32.105.73:2379: connect: no route to host\""}
+---------------------------+--------+--------------+---------------------------+
|         ENDPOINT          | HEALTH |     TOOK     |           ERROR           |
+---------------------------+--------+--------------+---------------------------+
| https://10.32.105.70:2379 |  false | 5.001329475s | context deadline exceeded |
| https://10.32.105.71:2379 |  false | 5.001395077s | context deadline exceeded |
| https://10.32.105.69:2379 |  false | 5.001451712s | context deadline exceeded |
| https://10.32.105.72:2379 |  false |  5.00152639s | context deadline exceeded |
| https://10.32.105.73:2379 |  false | 5.001602722s | context deadline exceeded |
+---------------------------+--------+--------------+---------------------------+
Error: unhealthy cluster
[root@ocp1-cp-3 /]#

```

|Node|IP|Mac|Leader|API VIP|
|---|---|---|---|---|
|cp-1 (0)|10.32.105.69|0E:C0:EF:20:69:45|X|X|
|cp-2 (1)|10.32.105.70|0E:C0:EF:20:69:46|X|✅|
|cp-3 (2)|10.32.105.71|0E:C0:EF:20:69:47|✅|X|
|cp-4 (4)|10.32.105.72|0E:C0:EF:20:69:48|X|X|
|cp-5 (5)|10.32.105.73|0E:C0:EF:20:69:49|X|X|

Let's start the desaster recory:

https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html-single/backup_and_restore/index#about-dr

Prepare DHCP & DNS

|Node|IP|Mac|
|---|---|---|
|cp-6 (6)|10.32.105.74|0E:C0:EF:20:69:4A|

Start / Boot like described in add-node.md

Backup from existing cp-3 node:

```bash
% ssh -i ~/.ssh/coe-muc -l core 10.32.105.71
Last login: Mon Dec 30 22:04:25 2024 from 10.45.224.22
[core@ocp1-cp-3 ~]$ sudo su -
Last login: Mon Dec 30 22:04:33 UTC 2024 on pts/0
[root@ocp1-cp-3 ~]# /usr/local/bin/cluster-backup.sh /home/core/assets/backup
Certificate /etc/kubernetes/static-pod-certs/configmaps/etcd-all-bundles/server-ca-bundle.crt is missing. Checking in different directory
Certificate /etc/kubernetes/static-pod-resources/etcd-certs/configmaps/etcd-all-bundles/server-ca-bundle.crt found!
Error from server (Timeout): the server was unable to return a response in the time allotted, but may still be processing the request (get clusteroperators.config.openshift.io kube-apiserver)
Could not find the status of the kube-apiserver. Check if the API server is running. Pass the --force flag to skip checks.
[root@ocp1-cp-3 ~]# /usr/local/bin/cluster-backup.sh --force /home/core/assets/backup
Certificate /etc/kubernetes/static-pod-certs/configmaps/etcd-all-bundles/server-ca-bundle.crt is missing. Checking in different directory
Certificate /etc/kubernetes/static-pod-resources/etcd-certs/configmaps/etcd-all-bundles/server-ca-bundle.crt found!
found latest kube-apiserver: /etc/kubernetes/static-pod-resources/kube-apiserver-pod-30
found latest kube-controller-manager: /etc/kubernetes/static-pod-resources/kube-controller-manager-pod-10
found latest kube-scheduler: /etc/kubernetes/static-pod-resources/kube-scheduler-pod-8
found latest etcd: /etc/kubernetes/static-pod-resources/etcd-pod-19
d300000b22992b76b917d9a34431d799ccd3308221e42a6e1d9129b4855eb57b
etcdctl version: 3.5.16
API version: 3.5
{"level":"info","ts":"2024-12-31T09:04:53.034345Z","caller":"snapshot/v3_snapshot.go:65","msg":"created temporary db file","path":"/home/core/assets/backup/snapshot_2024-12-31_090451__POSSIBLY_DIRTY__.db.part"}
{"level":"info","ts":"2024-12-31T09:04:53.043438Z","logger":"client","caller":"v3@v3.5.16/maintenance.go:212","msg":"opened snapshot stream; downloading"}
{"level":"info","ts":"2024-12-31T09:04:53.043489Z","caller":"snapshot/v3_snapshot.go:73","msg":"fetching snapshot","endpoint":"https://10.32.105.71:2379"}
{"level":"info","ts":"2024-12-31T09:04:56.534228Z","logger":"client","caller":"v3@v3.5.16/maintenance.go:220","msg":"completed snapshot read; closing"}
{"level":"info","ts":"2024-12-31T09:04:56.627041Z","caller":"snapshot/v3_snapshot.go:88","msg":"fetched snapshot","endpoint":"https://10.32.105.71:2379","size":"278 MB","took":"3 seconds ago"}
{"level":"info","ts":"2024-12-31T09:04:56.627241Z","caller":"snapshot/v3_snapshot.go:97","msg":"saved","path":"/home/core/assets/backup/snapshot_2024-12-31_090451__POSSIBLY_DIRTY__.db"}
Snapshot saved at /home/core/assets/backup/snapshot_2024-12-31_090451__POSSIBLY_DIRTY__.db
{"hash":636417352,"revision":39240041,"totalKey":18483,"totalSize":277909504}
snapshot db and kube resources are successfully saved to /home/core/assets/backup
[root@ocp1-cp-3 ~]# chown -R core: /home/core/assets

% scp -r -i ~/.ssh/coe-muc core@10.32.105.71:~assets /tmp
static_kuberesources_2024-12-31_090451__POSSIBLY_DIRTY__.tar.gz        100%   97KB 415.2KB/s   00:00
snapshot_2024-12-31_090451__POSSIBLY_DIRTY__.db                        100%  265MB   4.3MB/s   01:02

% scp -r -i ~/.ssh/coe-muc /tmp/assets core@10.32.105.74:~/
static_kuberesources_2024-12-31_090451__POSSIBLY_DIRTY__.tar.gz        100%   97KB 646.0KB/s   00:00
snapshot_2024-12-31_090451__POSSIBLY_DIRTY__.db                        100%  265MB   4.5MB/s   00:58

ssh -i ~/.ssh/coe-muc core@10.32.105.74
Warning: Permanently added '10.32.105.74' (ED25519) to the list of known hosts.
Red Hat Enterprise Linux CoreOS 417.94.202411201839-0
  Part of OpenShift 4.17, RHCOS is a Kubernetes-native operating system
  managed by the Machine Config Operator (`clusteroperator/machine-config`).

WARNING: Direct SSH access to machines is not recommended; instead,
make configuration changes via `machineconfig` objects:
  https://docs.openshift.com/container-platform/4.17/architecture/architecture-rhcos.html

---
[core@ocp1-cp-6 ~]$ sudo su -
[root@ocp1-cp-6 ~]# sudo mv -v /etc/kubernetes/manifests/etcd-pod.yaml /tmp
mv: cannot stat '/etc/kubernetes/manifests/etcd-pod.yaml': No such file or directory
[root@ocp1-cp-6 ~]# sudo crictl ps | grep etcd | egrep -v "operator|etcd-guard"
[root@ocp1-cp-6 ~]# sudo mv -v /etc/kubernetes/manifests/kube-apiserver-pod.yaml /tmp
mv: cannot stat '/etc/kubernetes/manifests/kube-apiserver-pod.yaml': No such file or directory
[root@ocp1-cp-6 ~]# sudo crictl ps | grep kube-apiserver | egrep -v "operator|guard"
[root@ocp1-cp-6 ~]# sudo mv -v /etc/kubernetes/manifests/kube-controller-manager-pod.yaml /tmp
mv: cannot stat '/etc/kubernetes/manifests/kube-controller-manager-pod.yaml': No such file or directory
[root@ocp1-cp-6 ~]# sudo crictl ps | grep kube-controller-manager | egrep -v "operator|guard"
[root@ocp1-cp-6 ~]# sudo mv -v /etc/kubernetes/manifests/kube-scheduler-pod.yaml /tmp
mv: cannot stat '/etc/kubernetes/manifests/kube-scheduler-pod.yaml': No such file or directory
[root@ocp1-cp-6 ~]# sudo crictl ps | grep kube-scheduler | egrep -v "operator|guard"
[root@ocp1-cp-6 ~]# sudo mv -v /var/lib/etcd/ /tmp
mv: cannot stat '/var/lib/etcd/': No such file or directory
[root@ocp1-cp-6 ~]# sudo mv -v /etc/kubernetes/manifests/keepalived.yaml /tmp
copied '/etc/kubernetes/manifests/keepalived.yaml' -> '/tmp/keepalived.yaml'
removed '/etc/kubernetes/manifests/keepalived.yaml'
[root@ocp1-cp-6 ~]# sudo crictl ps --name keepalived
CONTAINER           IMAGE                                                                                                                    CREATED             STATE               NAME                 ATTEMPT             POD ID              POD
62bf0a1c6c5de       3cf7680bc48d62db658df3c9cb4bfa045061d59717d7ba2512346da5d50fe869                                                         7 minutes ago       Running             keepalived-monitor   0                   8adcefd453128       keepalived-ocp1-cp-6
975ba2367fbae       quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:d0294dc01770438a6d8a848621c9ce71b7dca772b82f8592a0bd6615a99178fa   7 minutes ago       Running             keepalived           0                   8adcefd453128       keepalived-ocp1-cp-6
[root@ocp1-cp-6 ~]# ip -o address | egrep '<api_vip>|<ingress_vip>'
[root@ocp1-cp-6 ~]# ip -o address | egrep '10.32'
5: br-ex    inet 10.32.105.74/20 brd 10.32.111.255 scope global dynamic noprefixroute br-ex\       valid_lft 10270sec preferred_lft 10270sec
[root@ocp1-cp-6 ~]# [root@ocp1-cp-6 ~]# sudo -E /usr/local/bin/cluster-restore.sh /home/core/assets/backup/
sudo: /usr/local/bin/cluster-restore.sh: command not found
[root@ocp1-cp-6 ~]# ls /usr/local/bin/
configure-ip-forwarding.sh  kubenswrapper  nm-clean-initrd-state.sh  recover-kubeconfig.sh  wait-for-br-ex-up.sh
configure-ovs.sh            mco-hostname   nmstate-configuration.sh  resolv-prepender.sh    wait-for-primary-ip.sh
[root@ocp1-cp-6 ~]#

scp -r -i ~/.ssh/coe-muc core@10.32.105.71:/usr/local/bin/cluster-restore.sh /tmp
Warning: Permanently added '10.32.105.71' (ED25519) to the list of known hosts.
cluster-restore.sh                                                                                                       100% 5990    52.7KB/s   00:00

scp -r -i ~/.ssh/coe-muc /tmp/cluster-restore.sh core@10.32.105.74:~/
Warning: Permanently added '10.32.105.74' (ED25519) to the list of known hosts.
cluster-restore.sh

[root@ocp1-cp-6 core]# sudo -E /usr/local/bin/cluster-restore.sh /home/core/assets/backup/
required dependencies not found, please ensure this script is run on a node with a functional etcd static pod
[root@ocp1-cp-6 core]#
```

## Resources

* <https://issues.redhat.com/browse/OCPSTRAT-539>
* <https://docs.google.com/presentation/d/1t9MSuM7DxcKAY9F0u_upjOedJRinSURHjpGBLQPt-go/edit#slide=id.g301bdd19e2d_8_0>
  * <https://www.youtube.com/live/DvKHwz-c11c?si=ve0conc9FRkL10EL&t=740>
* ETCD-654 - <https://issues.redhat.com/browse/ETCD-654>
  * <https://github.com/openshift/cluster-etcd-operator/pull/1313>
  * <https://docs.google.com/document/d/17w9oVIfDjOnEyGonetdReMVEgw1Qe6GQkIvbuIkWfns/edit?tab=t.0>
* ETCD-293 - <https://issues.redhat.com/browse/ETCD-293>
* <https://issues.redhat.com/browse/RFE-2573>
* <https://docs.google.com/document/d/19N0BPwu7HaKlyDJsQt68Mz6boIL0Q0KicJhl4lmk-xo/edit?tab=t.0>
* <https://issues.redhat.com/browse/OCPPLAN-7568>
* <https://www.dobrica.sh/notes/Recovering-from-losing-quorum-in-etcd-cluster>
* <https://access.redhat.com/solutions/5781231> (v4.5)
* <https://bugzilla.redhat.com/show_bug.cgi?id=1925727> (v4.5)
* <https://www.redhat.com/en/blog/ocp-disaster-recovery-part-3-recovering-an-openshift-4-ipi-cluster-with-the-loss-of-two-master-nodes>
  (vsphere ipi)
* <https://www.redhat.com/en/blog/ocp-disaster-recovery-part-2-recovering-an-openshift-4-ipi-cluster-with-the-loss-of-one-master-node> (vsphere ipi)
