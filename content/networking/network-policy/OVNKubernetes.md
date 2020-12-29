---
title: Network Policy with OVNKubernetes
linktitle: OVNKubernetes
weight: 16300
description: Network Policy with OVNKubernetes
tags:
  - NetworkPolicy
  - OVNKubernetes
---

# Network Policy with OVNKubernetes

!!! info
    Work in progress not ready yet!
## Nice to know / Basics

1. Based on labeling or annotations
    * project / namespaces seldom have labels :-/
2. Empty label selector match all
2. Rules for allowing
    * Ingress -&gt; who can connect to this POD
    * Egress -&gt; where can this POD connect to
4. **Rules**
    * traffic is allowed unless a Network Policy selecting the POD
    * traffic is denied if pod is selected in policie but none of them have any rules allowing it
    * =  You can only write rules that allow traffic!
    * Scope: Namespace

## Tutorial / Demo - OpenShift v4!

### Deploy demo environment

![demo overview](demo-overview.png)

```bash
oc new-project bouvier
oc new-app quay.io/rbo/demo-http:master --name patty
oc expose svc/patty
oc scale deployment/patty --replicas=1
oc new-app quay.io/rbo/demo-http:master --name selma
oc scale deployment/selma --replicas=1
oc expose svc/selma

oc new-project simpson
oc new-app quay.io/rbo/demo-http:master --name homer
oc expose svc/homer
oc scale deployment/homer --replicas=1
oc new-app quay.io/rbo/demo-http:master --name marge
oc scale deployment/marge --replicas=1
oc expose svc/marge
```
### Download some helper scripts

```bash
git clone https://github.com/openshift-examples/network-policies-tests.git
cd network-policies-tests/
```
### Run connection overview

```bash
./run-tmux.sh apps.<cluster_name>.<base_domain>
```
![Clean](without-policies.png)

### Discover the environment

#### List POD's

```bash
$ oc get pods -o wide -n simpson
NAME                     READY   STATUS    RESTARTS   AGE    IP             NODE       NOMINATED NODE   READINESS GATES
homer-789b78ddf5-89dqp   1/1     Running   0          142m   10.129.0.113   master-0   <none>           <none>
marge-5887b4985f-td9qx   1/1     Running   0          142m   10.130.0.207   master-1   <none>           <none

$ oc get pods -o wide -n bouvier
NAME                     READY   STATUS    RESTARTS   AGE    IP             NODE       NOMINATED NODE   READINESS GATES
patty-7c674bc58c-tvtnc   1/1     Running   0          142m   10.129.0.111   master-0   <none>           <none>
selma-6787cf669f-bnrj5   1/1     Running   0          142m   10.129.0.112   master-0   <none>           <none>
```

### Let's start with the Network Policy demonstration

Every one can connect to each other

![Clean](without-policies.png)

```bash
$ ./OVNKubernetes/dump-net.sh --all case0
Run dump at
master-1;ovs-node-c97cv
master-0;ovs-node-t84dc
master-2;ovs-node-xs2fm
Write: case0.2020-12-29-12-07-39.1609240059.master-1.OpenFlow13.br-ex
Write: case0.2020-12-29-12-07-39.1609240059.master-1.OpenFlow13.br-int
Write: case0.2020-12-29-12-07-39.1609240059.master-1.OpenFlow13.br-local
Write: case0.2020-12-29-12-07-39.1609240059.master-1.iptables
Write: case0.2020-12-29-12-07-39.1609240059.master-0.OpenFlow13.br-ex
Write: case0.2020-12-29-12-07-39.1609240059.master-0.OpenFlow13.br-int
Write: case0.2020-12-29-12-07-39.1609240059.master-0.OpenFlow13.br-local
Write: case0.2020-12-29-12-07-39.1609240059.master-0.iptables
Write: case0.2020-12-29-12-07-39.1609240059.master-2.OpenFlow13.br-ex
Write: case0.2020-12-29-12-07-39.1609240059.master-2.OpenFlow13.br-int
Write: case0.2020-12-29-12-07-39.1609240059.master-2.OpenFlow13.br-local
Write: case0.2020-12-29-12-07-39.1609240059.master-2.iptables
```

### Case 1 - Simpson - default-deny

```yaml
oc create -n simpson  -f - <<EOF
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: default-deny
spec:
  podSelector: {}
EOF
```

<!-- ![Case 1](case1.png) -->


```bash
$ ./OVNKubernetes/dump-net.sh master-0 master-0.case1
Run dump at
master-0;ovs-node-t84dc
Write: master-0.case1.master-0.OpenFlow13.br-ex
Write: master-0.case1.master-0.OpenFlow13.br-int
Write: master-0.case1.master-0.OpenFlow13.br-local
Write: master-0.case1.master-0.iptables
```

Diff of OpenFlow13
```diff
$ diff -Nuar case0.2020-12-29-12-07-39.1609240059.master-0.OpenFlow13.br-ex master-0.case1.master-0.OpenFlow13.br-ex
$ diff -Nuar case0.2020-12-29-12-07-39.1609240059.master-0.OpenFlow13.br-local master-0.case1.master-0.OpenFlow13.br-local
$ diff -Nuar case0.2020-12-29-12-07-39.1609240059.master-0.OpenFlow13.br-int master-0.case1.master-0.OpenFlow13.br-int
--- case0.2020-12-29-12-07-39.1609240059.master-0.OpenFlow13.br-int	2020-12-29 12:07:49.000000000 +0100
+++ master-0.case1.master-0.OpenFlow13.br-int	2020-12-29 12:08:58.000000000 +0100
@@ -3327,6 +3327,15 @@
  cookie=0x5ba0d9b7, table=44, priority=2001,ct_state=-new+est-rpl+trk,ct_label=0x1/0x1,ip,metadata=0x3,nw_src=10.128.0.2 actions=load:0x1->NXM_NX_XXREG0[97],resubmit(,45)
  cookie=0x56194a07, table=44, priority=2001,ct_state=-new+est-rpl+trk,ct_label=0x1/0x1,ip,metadata=0x5,nw_src=10.129.0.2 actions=load:0x1->NXM_NX_XXREG0[97],resubmit(,45)
  cookie=0xb258993d, table=44, priority=2001,ct_state=-new+est-rpl+trk,ct_label=0/0x1,ip,metadata=0x5,nw_src=10.129.0.2 actions=resubmit(,45)
+ cookie=0xa3134bb9, table=44, priority=2001,ct_state=-new+est-rpl+trk,ct_label=0x1/0x1,arp,reg15=0x49,metadata=0x5 actions=load:0x1->NXM_NX_XXREG0[97],resubmit(,45)
+ cookie=0x8951af69, table=44, priority=2001,ct_state=-new+est-rpl+trk,ct_label=0/0x1,arp,reg15=0x49,metadata=0x5 actions=resubmit(,45)
+ cookie=0xa3134bb9, table=44, priority=2001,ct_state=+new-est+trk,arp,reg15=0x49,metadata=0x5 actions=load:0x1->NXM_NX_XXREG0[97],resubmit(,45)
+ cookie=0x8951af69, table=44, priority=2001,ct_state=-trk,arp,reg15=0x49,metadata=0x5 actions=resubmit(,45)
+ cookie=0x52df188c, table=44, priority=2000,ct_state=+est+trk,ct_label=0x1/0x1,reg15=0x49,metadata=0x5 actions=drop
+ cookie=0x6ca413a8, table=44, priority=2000,ct_state=+est+trk,ct_label=0/0x1,ipv6,reg15=0x49,metadata=0x5 actions=ct(commit,zone=NXM_NX_REG13[0..15],exec(load:0x1->NXM_NX_CT_LABEL[0]))
+ cookie=0x6ca413a8, table=44, priority=2000,ct_state=+est+trk,ct_label=0/0x1,ip,reg15=0x49,metadata=0x5 actions=ct(commit,zone=NXM_NX_REG13[0..15],exec(load:0x1->NXM_NX_CT_LABEL[0]))
+ cookie=0x52df188c, table=44, priority=2000,ct_state=-trk,reg15=0x49,metadata=0x5 actions=drop
+ cookie=0x52df188c, table=44, priority=2000,ct_state=-est+trk,reg15=0x49,metadata=0x5 actions=drop
  cookie=0x93b0b827, table=44, priority=1,ct_state=-est+trk,ip,metadata=0x4 actions=load:0x1->NXM_NX_XXREG0[97],resubmit(,45)
  cookie=0x93b0b827, table=44, priority=1,ct_state=-est+trk,ipv6,metadata=0x4 actions=load:0x1->NXM_NX_XXREG0[97],resubmit(,45)
  cookie=0xb723d24c, table=44, priority=1,ct_state=-est+trk,ipv6,metadata=0x3 actions=load:0x1->NXM_NX_XXREG0[97],resubmit(,45)

```

#### 2\) Simpson allow from openshift-ingress namespaces, because of router
```yaml
cat << EOF| oc create -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-openshift-ingress
spec:
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          network.openshift.io/policy-group: ingress
  podSelector: {}
  policyTypes:
  - Ingress
EOF
```

Because of HostNetwork access of the OpenShift Ingress you have to apply a label to the default namespace:
```bash
oc label namespace default 'network.openshift.io/policy-group=ingress'
```
[Documentation: 2. If the default Ingress Controller configuration has the...](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.6/html-single/networking/index#nw-networkpolicy-multitenant-isolation_multitenant-network-policy)

```bash
$ ./OVNKubernetes/dump-net.sh master-0 master-0.case2
Run dump at
master-0;ovs-node-t84dc
Write: master-0.case2.master-0.OpenFlow13.br-ex
Write: master-0.case2.master-0.OpenFlow13.br-int
Write: master-0.case2.master-0.OpenFlow13.br-local
Write: master-0.case2.master-0.iptables

```

Diff:
```diff
$ diff -Nuar master-0.case1.master-0.OpenFlow13.br-int master-0.case2.master-0.OpenFlow13.br-int
$ diff -Nuar master-0.case1.master-0.OpenFlow13.br-ex master-0.case2.master-0.OpenFlow13.br-ex
$ diff -Nuar master-0.case1.master-0.OpenFlow13.br-local master-0.case2.master-0.OpenFlow13.br-local
```

!!! warning
    Problem - did not work!
    [Bug 1909777](https://bugzilla.redhat.com/show_bug.cgi?id=1909777) - Setting up multitenant netwotk policy does not work with OVN-Kubernetes network plugin.

<!-- ![Case 2](case2.png) -->

#### 3\) Simpson allow internal communcation

```yaml
cat << EOF| oc create -f -
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-same-namespace
spec:
  podSelector:
  ingress:
  - from:
    - podSelector: {}
EOF
```

```bash
$ ./OVNKubernetes/dump-net.sh master-0 master-0.case3

```

Diff
```diff
$ diff -Nuar master-0.case2.master-0.OpenFlow13.br-int master-0.case3.master-0.OpenFlow13.br-int
--- master-0.case2.master-0.OpenFlow13.br-int	2020-12-29 13:22:34.000000000 +0100
+++ master-0.case3.master-0.OpenFlow13.br-int	2020-12-29 13:27:13.000000000 +0100
@@ -3331,6 +3331,14 @@
  cookie=0x8951af69, table=44, priority=2001,ct_state=-new+est-rpl+trk,ct_label=0/0x1,arp,reg15=0x49,metadata=0x5 actions=resubmit(,45)
  cookie=0xa3134bb9, table=44, priority=2001,ct_state=+new-est+trk,arp,reg15=0x49,metadata=0x5 actions=load:0x1->NXM_NX_XXREG0[97],resubmit(,45)
  cookie=0x8951af69, table=44, priority=2001,ct_state=-trk,arp,reg15=0x49,metadata=0x5 actions=resubmit(,45)
+ cookie=0x25d2c138, table=44, priority=2001,ct_state=-new+est-rpl+trk,ct_label=0/0x1,ip,reg15=0x49,metadata=0x5,nw_src=10.129.0.113 actions=resubmit(,45)
+ cookie=0x4b57e23f, table=44, priority=2001,ct_state=-new+est-rpl+trk,ct_label=0x1/0x1,ip,reg15=0x49,metadata=0x5,nw_src=10.129.0.113 actions=load:0x1->NXM_NX_XXREG0[97],resubmit(,45)
+ cookie=0x4b57e23f, table=44, priority=2001,ct_state=-new+est-rpl+trk,ct_label=0x1/0x1,ip,reg15=0x49,metadata=0x5,nw_src=10.130.0.207 actions=load:0x1->NXM_NX_XXREG0[97],resubmit(,45)
+ cookie=0x25d2c138, table=44, priority=2001,ct_state=-new+est-rpl+trk,ct_label=0/0x1,ip,reg15=0x49,metadata=0x5,nw_src=10.130.0.207 actions=resubmit(,45)
+ cookie=0x25d2c138, table=44, priority=2001,ct_state=-trk,ip,reg15=0x49,metadata=0x5,nw_src=10.129.0.113 actions=resubmit(,45)
+ cookie=0x25d2c138, table=44, priority=2001,ct_state=-trk,ip,reg15=0x49,metadata=0x5,nw_src=10.130.0.207 actions=resubmit(,45)
+ cookie=0x4b57e23f, table=44, priority=2001,ct_state=+new-est+trk,ip,reg15=0x49,metadata=0x5,nw_src=10.129.0.113 actions=load:0x1->NXM_NX_XXREG0[97],resubmit(,45)
+ cookie=0x4b57e23f, table=44, priority=2001,ct_state=+new-est+trk,ip,reg15=0x49,metadata=0x5,nw_src=10.130.0.207 actions=load:0x1->NXM_NX_XXREG0[97],resubmit(,45)
  cookie=0x52df188c, table=44, priority=2000,ct_state=+est+trk,ct_label=0x1/0x1,reg15=0x49,metadata=0x5 actions=drop
  cookie=0x6ca413a8, table=44, priority=2000,ct_state=+est+trk,ct_label=0/0x1,ipv6,reg15=0x49,metadata=0x5 actions=ct(commit,zone=NXM_NX_REG13[0..15],exec(load:0x1->NXM_NX_CT_LABEL[0]))
  cookie=0x6ca413a8, table=44, priority=2000,ct_state=+est+trk,ct_label=0/0x1,ip,reg15=0x49,metadata=0x5 actions=ct(commit,zone=NXM_NX_REG13[0..15],exec(load:0x1->NXM_NX_CT_LABEL[0]))
$ diff -Nuar master-0.case2.master-0.OpenFlow13.br-ex master-0.case3.master-0.OpenFlow13.br-ex
$ diff -Nuar master-0.case3.master-0.OpenFlow13.br-local master-0.case3.master-0.OpenFlow13.br-local

```

<!-- ![Case 3](case3.png) -->

#### 4\) Selma and Patty want's to talk with Marge!
1) First label the namespace bouvier:
   ```bash
   oc label namespace/bouvier name=bouvier
   ```

2) Apply Network Policy
   ```yaml
   oc create -n simpson -f - <<EOF
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: allow-from-bouviers-to-marge
   spec:
     podSelector:
       matchLabels:
         deployment: marge
     ingress:
     - from:
       - namespaceSelector:
           matchLabels:
             name: bouvier
   EOF
   ```


```bash
$ ./OVNKubernetes/dump-net.sh master-0 master-0.case4
```

Diff
```diff
$ diff -Nuar master-0.case3.master-0.OpenFlow13.br-int master-0.case4.master-0.OpenFlow13.br-int
$ diff -Nuar master-0.case3.master-0.OpenFlow13.br-ex master-0.case4.master-0.OpenFlow13.br-ex
$ diff -Nuar master-0.case3.master-0.OpenFlow13.br-local master-0.case4.master-0.OpenFlow13.br-local

```

**Nothing??**

<!-- ![Case 4](case4.png) -->

### Destroy demo env

```bash
oc delete project simpson bouvier
```

## Useful commands

| Info | Command |
| :--- | :--- |
| Dump northbound db | `oc rsh -n openshift-ovn-kubernetes -c northd ovnkube-master-6s6bw ovn-nbctl -C /ovn-ca/ca-bundle.crt -p /ovn-cert/tls.key -c /ovn-cert/tls.crt --db=ssl:192.168.51.10:9641 --pretty show`
