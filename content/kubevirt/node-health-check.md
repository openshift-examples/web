---
title: Node Health Check
linktitle: Node Health Check
description: OpenShift Virtualization - Fencing and VM High Availability Guide
tags: ["kubevirt","ocp-v","cnv"]
---
# Node Health Check

## Resources

* [OpenShift Virtualization - Fencing and VM High Availability Guide](https://access.redhat.com/articles/7057929)

## Installation & configuration

* Install Operator "Node Health Check Operator"
* Install Operator "Self Node Remediation Operator"

### Start operator for worker nodes

``` { .yaml .annotate }
apiVersion: remediation.medik8s.io/v1alpha1
kind: NodeHealthCheck
metadata:
  name: worker-availability
spec:
  minHealthy: 51%
  remediationTemplate:
    apiVersion: self-node-remediation.medik8s.io/v1alpha1
    kind: SelfNodeRemediationTemplate
    name: self-node-remediation-automatic-strategy-template
    namespace: openshift-workload-availability
  selector:
    matchExpressions:
      - key: node-role.kubernetes.io/worker
        operator: Exists
        values: []
  unhealthyConditions:
    - duration: 1s # (1)!
      status: 'False'
      type: Ready
    - duration: 1s # (2)!
      status: Unknown
      type: Ready
```

1. Change the seconds to achieve the fasted VM recovery, according to [OpenShift Virtualization - Fencing and VM High Availability Guide](https://access.redhat.com/articles/7057929#test-results-9)
2. Change the seconds to achieve the fasted VM recovery, according to [OpenShift Virtualization - Fencing and VM High Availability Guide](https://access.redhat.com/articles/7057929#test-results-9)

### Update `self-node-remediation-automatic-strategy-template`

``` { .yaml .hl_lines="13" .annotate }
apiVersion: self-node-remediation.medik8s.io/v1alpha1
kind: SelfNodeRemediationTemplate
metadata:
  annotations:
    remediation.medik8s.io/multiple-templates-support: "true"
  labels:
    remediation.medik8s.io/default-template: "true"
  name: self-node-remediation-automatic-strategy-template
  namespace: openshift-workload-availability
spec:
  template:
    spec:
      remediationStrategy: OutOfServiceTaint # (1)!
```

1. Default is "Automatic", but I want a predictable behavor. [Offical documentation](https://docs.redhat.com/en/documentation/workload_availability_for_red_hat_openshift/23.2/html-single/remediation_fencing_and_maintenance/index#about-self-node-remediation-operator_self-node-remediation-operator-remediate-nodes)

    ```bash
    $ oc explain SelfNodeRemediationTemplate.spec.template.spec.remediationStrategy
    GROUP:      self-node-remediation.medik8s.io
    KIND:       SelfNodeRemediationTemplate
    VERSION:    v1alpha1

    FIELD: remediationStrategy <string>

    DESCRIPTION:
        RemediationStrategy is the remediation method for unhealthy nodes.
        Currently, it could be either "Automatic", "OutOfServiceTaint" or
        "ResourceDeletion".
        ResourceDeletion will iterate over all pods and VolumeAttachment related to
        the unhealthy node and delete them.
        OutOfServiceTaint will add the out-of-service taint which is a new
        well-known taint "node.kubernetes.io/out-of-service"
        that enables automatic deletion of pv-attached pods on failed nodes,
        "out-of-service" taint is only supported on clusters with k8s version 1.26+
        or OCP/OKD version 4.13+.
        Automatic will choose the most appropriate strategy during runtime.
    ```

## Example

* Start a RHEL VM with network access
* Provide `~/bin/l`

  ```shell
  #!/usr/bin/env bash

  (echo "# $@"; exec "$@") |  ts '[%Y-%m-%d %H:%M:%S]'  | tee -a /tmp/app.log
  ````

* Run: `l ping $VM_IP`
* Run: `oc get pods -o wide --watch | ts '[%Y-%m-%d %H:%M:%S]' | tee -a /tmp/app.log`
* Watch the log `tail -f /tmp/app.log`
* Stop the VM where the node is running: `l virtctl stop --force --grace-period=0  ocp1-worker-0`

### app.log

```log
[2025-06-16 19:00:01] # oc get vm,vmi
[2025-06-16 19:00:01] NAME                              AGE   STATUS    READY
[2025-06-16 19:00:01] virtualmachine.kubevirt.io/rhel   14m   Running   True
[2025-06-16 19:00:01]
[2025-06-16 19:00:01] NAME                                      AGE     PHASE     IP                              NODENAME        READY
[2025-06-16 19:00:01] virtualmachineinstance.kubevirt.io/rhel   6m49s   Running   2620:52:0:2060:63:97ff:fe00:b   ocp1-worker-0   True
[2025-06-16 19:00:13] # oc get vm,vmi
[2025-06-16 19:00:14] NAME                                       AGE     STATUS    READY
[2025-06-16 19:00:14] virtualmachine.kubevirt.io/ocp1-cp-0       3d19h   Running   True
[2025-06-16 19:00:14] virtualmachine.kubevirt.io/ocp1-cp-1       3d19h   Running   True
[2025-06-16 19:00:14] virtualmachine.kubevirt.io/ocp1-cp-2       3d19h   Running   True
[2025-06-16 19:00:14] virtualmachine.kubevirt.io/ocp1-worker-0   3d19h   Running   True
[2025-06-16 19:00:14] virtualmachine.kubevirt.io/ocp1-worker-1   3d19h   Running   True
[2025-06-16 19:00:14] virtualmachine.kubevirt.io/ocp1-worker-2   3d19h   Running   True
[2025-06-16 19:00:14]
[2025-06-16 19:00:14] NAME                                               AGE     PHASE     IP             NODENAME   READY
[2025-06-16 19:00:14] virtualmachineinstance.kubevirt.io/ocp1-cp-0       3d19h   Running   10.32.105.66   storm2     True
[2025-06-16 19:00:14] virtualmachineinstance.kubevirt.io/ocp1-cp-1       3d9h    Running   10.32.105.67   ucs57      True
[2025-06-16 19:00:14] virtualmachineinstance.kubevirt.io/ocp1-cp-2       3d19h   Running   10.32.105.68   storm6     True
[2025-06-16 19:00:14] virtualmachineinstance.kubevirt.io/ocp1-worker-0   3d12h   Running   10.32.105.69   ucs55      True
[2025-06-16 19:00:14] virtualmachineinstance.kubevirt.io/ocp1-worker-1   3d12h   Running   10.32.105.70   storm3     True
[2025-06-16 19:00:14] virtualmachineinstance.kubevirt.io/ocp1-worker-2   3d12h   Running   10.32.105.71   ucs56      True
[2025-06-16 19:01:34] # ping 10.32.111.147
[2025-06-16 19:01:34] PING 10.32.111.147 (10.32.111.147): 56 data bytes
[2025-06-16 19:01:34] 64 bytes from 10.32.111.147: icmp_seq=0 ttl=57 time=52.220 ms
[..snipped..]
[2025-06-16 19:01:39] # virtctl stop --force ocp1-worker-0
[2025-06-16 19:01:40] 64 bytes from 10.32.111.147: icmp_seq=6 ttl=57 time=52.835 ms
[..snipped..]
[2025-06-16 19:02:02] 64 bytes from 10.32.111.147: icmp_seq=28 ttl=57 time=51.931 ms
[2025-06-16 19:02:02] # virtctl stop --force --grace-period=0 ocp1-worker-0
[2025-06-16 19:02:03] VM ocp1-worker-0 was scheduled to stop
[2025-06-16 19:02:04] Request timeout for icmp_seq 29
[..snipped..]
[2025-06-16 19:02:57] Request timeout for icmp_seq 82
[2025-06-16 19:02:58] virt-launcher-rhel-hc2ds   1/1     Running             0          9m46s   10.131.0.36   ocp1-worker-0   <none>           1/1
[2025-06-16 19:02:58] Request timeout for icmp_seq 83
[2025-06-16 19:02:59] Request timeout for icmp_seq 84
[2025-06-16 19:02:59] virt-launcher-rhel-hc2ds   1/1     Terminating         0          9m47s   10.131.0.36   ocp1-worker-0   <none>           1/1
[2025-06-16 19:03:00] Request timeout for icmp_seq 85
[..snipped..]
[2025-06-16 19:04:38] Request timeout for icmp_seq 183
[2025-06-16 19:04:39] virt-launcher-rhel-hc2ds   1/1     Terminating         0          11m     10.131.0.36   ocp1-worker-0   <none>           1/1
[2025-06-16 19:04:39] Request timeout for icmp_seq 184
[..snipped..]
[2025-06-16 19:06:42] Request timeout for icmp_seq 306
[2025-06-16 19:06:42] virt-launcher-rhel-hc2ds   1/1     Failed              0          13m     10.131.0.36   ocp1-worker-0   <none>           1/1
[2025-06-16 19:06:43] Request timeout for icmp_seq 307
[2025-06-16 19:06:43] virt-launcher-rhel-hc2ds   1/1     Failed              0          13m     10.131.0.36   ocp1-worker-0   <none>           1/1
[2025-06-16 19:06:43] virt-launcher-rhel-hc2ds   1/1     Failed              0          13m     10.131.0.36   ocp1-worker-0   <none>           1/1
[2025-06-16 19:06:44] Request timeout for icmp_seq 308
[..snipped..]
[2025-06-16 19:07:30] Request timeout for icmp_seq 354
[2025-06-16 19:07:31] virt-launcher-rhel-rhf6h   0/1     Pending             0          2s      <none>        <none>          <none>           0/1
[2025-06-16 19:07:31] virt-launcher-rhel-rhf6h   0/1     Pending             0          2s      <none>        ocp1-worker-1   <none>           0/1
[2025-06-16 19:07:31] virt-launcher-rhel-rhf6h   0/1     Pending             0          2s      <none>        ocp1-worker-1   <none>           0/1
[2025-06-16 19:07:31] Request timeout for icmp_seq 355
[2025-06-16 19:07:32] Request timeout for icmp_seq 356
[2025-06-16 19:07:33] virt-launcher-rhel-rhf6h   0/1     Pending             0          4s      <none>        ocp1-worker-1   <none>           0/1
[2025-06-16 19:07:33] Request timeout for icmp_seq 357
[2025-06-16 19:07:34] virt-launcher-rhel-rhf6h   0/1     ContainerCreating   0          5s      <none>        ocp1-worker-1   <none>           0/1
[2025-06-16 19:07:34] Request timeout for icmp_seq 358
[2025-06-16 19:07:35] Request timeout for icmp_seq 359
[2025-06-16 19:07:35] virt-launcher-rhel-rhf6h   0/1     ContainerCreating   0          6s      <none>        ocp1-worker-1   <none>           1/1
[2025-06-16 19:07:36] Request timeout for icmp_seq 360
[..snipped..]
[2025-06-16 19:07:54] Request timeout for icmp_seq 378
[2025-06-16 19:07:54] virt-launcher-rhel-rhf6h   0/1     ContainerCreating   0          25s     <none>        ocp1-worker-1   <none>           1/1
[2025-06-16 19:07:55] virt-launcher-rhel-rhf6h   1/1     Running             0          26s     10.128.2.71   ocp1-worker-1   <none>           1/1
[2025-06-16 19:07:55] virt-launcher-rhel-rhf6h   1/1     Running             0          26s     10.128.2.71   ocp1-worker-1   <none>           1/1
[2025-06-16 19:07:55] Request timeout for icmp_seq 379
[..snipped..]
[2025-06-16 19:09:41] Request timeout for icmp_seq 484
[2025-06-16 19:09:41] 64 bytes from 10.32.111.147: icmp_seq=485 ttl=57 time=51.578 ms
[2025-06-16 19:09:42] 64 bytes from 10.32.111.147: icmp_seq=486 ttl=57 time=51.141 ms
[2025-06-16 19:09:43] 64 bytes from 10.32.111.147: icmp_seq=487 ttl=57 time=51.136 ms
[2025-06-16 19:09:44] 64 bytes from 10.32.111.147: icmp_seq=488 ttl=57 time=51.472 ms
..
```
