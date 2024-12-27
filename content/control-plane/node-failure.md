---
title: Node failure test
linktitle: Node failure
description: Let's switch off some control plane nodes.
tags: ['etcd','control-plane']
---

# Node failure test

Just some stupid tests with OpenShift 4.17.6

### One control plane node stopeed

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

```
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
