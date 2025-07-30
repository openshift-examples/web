---
title: Application Aware Quota
linktitle: Application Aware Quota
description: Let's dive into Application Aware Quota
tags: ['aaq','cnv','v4.18']
---
# Application Aware Quota

Documentation:

* <https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index#virt-understanding-aaq-operator>
* <https://access.redhat.com/solutions/7063206>

Tested with:

|Component|Version|
|---|---|
|OpenShift|v4.18.19|
|OpenShift Virt|v4.18.8|

## Enable Application Aware Quota in  OpenShift Virt

```shell
oc edit hco -n openshift-cnv   kubevirt-hyperconverged
```

Change following settings

```yaml
spec:
  applicationAwareConfig:
    allowApplicationAwareClusterResourceQuota: true
    vmiCalcConfigName: DedicatedVirtualResources
  featureGates:
    enableApplicationAwareQuota: true
```

## Let's create a project with quota

```shell
oc new-project single-project-quota-test
```

Label project to enabel application aware quota:

```shell
oc label namespace single-project-quota-test application-aware-quota/enable-gating=
```

Apply quota:

=== "OC"

    ```
    oc apply -f {{ page.canonical_url }}example-resource-quota.ApplicationAwareResourceQuota.yaml
    ```

=== "example-resource-quota.ApplicationAwareResourceQuota.yaml"

    ```yaml
    --8<-- "content/kubevirt/application-aware-quota/example-resource-quota.ApplicationAwareResourceQuota.yaml"
    ```

Check the quota

```shell hl_lines="26 27"
$ oc describe arq  example-resource-quota
Name:         example-resource-quota
Namespace:    single-project-quota-test
Labels:       <none>
Annotations:  <none>
API Version:  aaq.kubevirt.io/v1alpha1
Kind:         ApplicationAwareResourceQuota
Metadata:
  Creation Timestamp:  2025-07-30T20:15:36Z
  Generation:          1
  Resource Version:    8431156
  UID:                 cb3dbe5a-a09e-4fa6-8c99-07f46290796d
Spec:
  Hard:
    limits.cpu/vmi:       10
    limits.memory/vmi:    20Gi
    requests.cpu/vmi:     5
    requests.memory/vmi:  10Gi
Status:
  Hard:
    limits.cpu/vmi:       10
    limits.memory/vmi:    20Gi
    requests.cpu/vmi:     5
    requests.memory/vmi:  10Gi
  Used:
    requests.cpu/vmi:     0
    requests.memory/vmi:  0
Events:                   <none>
```

Start some workload

```shell
oc apply -k git@github.com:openshift-examples/kustomize/components/vmpool-no-load
oc scale vmpool/no-load --replicas 10
```

!!! info

    Only five (5) will be scheduled.

??? quote "List of VM's"

    ```shell
    oc get vm,vmi
    NAME                                   AGE   STATUS     READY
    virtualmachine.kubevirt.io/no-load-0   45s   Starting   False
    virtualmachine.kubevirt.io/no-load-1   45s   Running    True
    virtualmachine.kubevirt.io/no-load-2   45s   Starting   False
    virtualmachine.kubevirt.io/no-load-3   45s   Starting   False
    virtualmachine.kubevirt.io/no-load-4   45s   Running    True
    virtualmachine.kubevirt.io/no-load-5   45s   Starting   False
    virtualmachine.kubevirt.io/no-load-6   45s   Running    True
    virtualmachine.kubevirt.io/no-load-7   45s   Running    True
    virtualmachine.kubevirt.io/no-load-8   45s   Running    True
    virtualmachine.kubevirt.io/no-load-9   45s   Starting   False

    NAME                                           AGE   PHASE        IP             NODENAME   READY
    virtualmachineinstance.kubevirt.io/no-load-0   44s   Scheduling                             False
    virtualmachineinstance.kubevirt.io/no-load-1   45s   Running      10.128.2.216   ucs55      True
    virtualmachineinstance.kubevirt.io/no-load-2   44s   Scheduling                             False
    virtualmachineinstance.kubevirt.io/no-load-3   43s   Scheduling                             False
    virtualmachineinstance.kubevirt.io/no-load-4   44s   Running      10.128.2.217   ucs55      True
    virtualmachineinstance.kubevirt.io/no-load-5   44s   Scheduling                             False
    virtualmachineinstance.kubevirt.io/no-load-6   45s   Running      10.128.2.215   ucs55      True
    virtualmachineinstance.kubevirt.io/no-load-7   44s   Running                     ucs56      True
    virtualmachineinstance.kubevirt.io/no-load-8   44s   Running                     ucs56      True
    virtualmachineinstance.kubevirt.io/no-load-9   43s   Scheduling                             False
    ```

Check the quota again:

```shell hl_lines="26 27"
oc describe arq  example-resource-quota
Name:         example-resource-quota
Namespace:    single-project-quota-test
Labels:       <none>
Annotations:  <none>
API Version:  aaq.kubevirt.io/v1alpha1
Kind:         ApplicationAwareResourceQuota
Metadata:
  Creation Timestamp:  2025-07-30T20:15:36Z
  Generation:          1
  Resource Version:    8447197
  UID:                 cb3dbe5a-a09e-4fa6-8c99-07f46290796d
Spec:
  Hard:
    limits.cpu/vmi:       10
    limits.memory/vmi:    20Gi
    requests.cpu/vmi:     5
    requests.memory/vmi:  10Gi
Status:
  Hard:
    limits.cpu/vmi:       10
    limits.memory/vmi:    20Gi
    requests.cpu/vmi:     5
    requests.memory/vmi:  10Gi
  Used:
    requests.cpu/vmi:     5
    requests.memory/vmi:  5120M
Events:                   <none>
```

## Let's configure a cluster wide quota

Change project request template, to label all new project/namespaces. [Documetation](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/building_applications/projects#configuring-project-creation)

Create template

```shell
oc adm create-bootstrap-project-template -o yaml > template.yaml
```

Adjust template:

=== "Changes (diff)"

```diff
# diff -Nuar <(oc adm create-bootstrap-project-template -o yaml) template.yaml
--- /dev/fd/11  2025-07-30 22:42:46.359683599 +0200
+++ template.yaml       2025-07-30 22:42:26.314463561 +0200
@@ -3,6 +3,7 @@
 metadata:
   creationTimestamp: null
   name: project-request
+  namespace: openshift-config
 objects:
 - apiVersion: project.openshift.io/v1
   kind: Project
@@ -11,6 +12,8 @@
       openshift.io/description: ${PROJECT_DESCRIPTION}
       openshift.io/display-name: ${PROJECT_DISPLAYNAME}
       openshift.io/requester: ${PROJECT_REQUESTING_USER}
+    labels:
+      application-aware-quota/enable-gating: ""
     creationTimestamp: null
     name: ${PROJECT_NAME}
   spec: {}
```

=== "Apply via CLI"

    ```
    oc apply -f {{ page.canonical_url }}template.yaml
    ```

=== "Final YAML"

    ```yaml
    --8<-- "content/kubevirt/application-aware-quota/template.yaml"
    ```

Configura template

```shell
oc edit project.config.openshift.io/cluster
```

Change

```yaml
spec:
  projectRequestTemplate:
    name: project-request
```

Create cluster wide quota

=== "OC"

    ```
    oc apply -f {{ page.canonical_url }}example-resource-quota.aacrq.yaml
    ```

=== "example-resource-quota.aacrq.yaml"

    ```yaml
    --8<-- "content/kubevirt/application-aware-quota/example-resource-quota.aacrq.yaml"
    ```

Let's check the quota

```shell hl_lines="42 43 51 52"
$ oc describe  aacrq example-resource-quota
Name:         example-resource-quota
Namespace:    cluster-wide-quota-a
Labels:       aaq.kubevirt.io=true
Annotations:  <none>
API Version:  aaq.kubevirt.io/v1alpha1
Kind:         ApplicationAwareAppliedClusterResourceQuota
Metadata:
  Creation Timestamp:  2025-07-30T20:52:10Z
  Generation:          6
  Owner References:
    API Version:           aaq.kubevirt.io/v1alpha1
    Block Owner Deletion:  true
    Controller:            true
    Kind:                  ApplicationAwareClusterResourceQuota
    Name:                  example-resource-quota
    UID:                   fb9a1ec3-9940-4356-803d-d092d1f81486
  Resource Version:        8478833
  UID:                     b62ae8b1-05e6-42bb-b30e-811e19ab6fcb
Spec:
  Quota:
    Hard:
      limits.cpu/vmi:       20
      limits.memory/vmi:    20Gi
      requests.cpu/vmi:     20
      requests.memory/vmi:  20Gi
  Selector:
    Annotations:  <nil>
    Labels:
      Match Labels:
        application-aware-quota/enable-gating:
Status:
  Namespaces:
    Namespace:                single-project-quota-test
    Status:
      Hard:
        limits.cpu/vmi:       20
        limits.memory/vmi:    20Gi
        requests.cpu/vmi:     20
        requests.memory/vmi:  20Gi
      Used:
        requests.cpu/vmi:     5
        requests.memory/vmi:  5120M
  Total:
    Hard:
      limits.cpu/vmi:       20
      limits.memory/vmi:    20Gi
      requests.cpu/vmi:     20
      requests.memory/vmi:  20Gi
    Used:
      requests.cpu/vmi:     5
      requests.memory/vmi:  5120M
Events:                     <none>
```

!!! info

    We alread have some quota consumed, because the cluster quota includes our first project `single-project-quota-test`

Add more workload:

```shell
oc new-project cluster-wide-quota-a
oc apply -k git@github.com:openshift-examples/kustomize/components/vmpool-no-load
oc scale vmpool/no-load --replicas 10
```

Check quota again:

```shell hl_lines="42 43 52 53 61 62"
oc describe  aacrq example-resource-quota
Name:         example-resource-quota
Namespace:    cluster-wide-quota-a
Labels:       aaq.kubevirt.io=true
Annotations:  <none>
API Version:  aaq.kubevirt.io/v1alpha1
Kind:         ApplicationAwareAppliedClusterResourceQuota
Metadata:
  Creation Timestamp:  2025-07-30T20:52:10Z
  Generation:          13
  Owner References:
    API Version:           aaq.kubevirt.io/v1alpha1
    Block Owner Deletion:  true
    Controller:            true
    Kind:                  ApplicationAwareClusterResourceQuota
    Name:                  example-resource-quota
    UID:                   fb9a1ec3-9940-4356-803d-d092d1f81486
  Resource Version:        8483427
  UID:                     b62ae8b1-05e6-42bb-b30e-811e19ab6fcb
Spec:
  Quota:
    Hard:
      limits.cpu/vmi:       20
      limits.memory/vmi:    20Gi
      requests.cpu/vmi:     20
      requests.memory/vmi:  20Gi
  Selector:
    Annotations:  <nil>
    Labels:
      Match Labels:
        application-aware-quota/enable-gating:
Status:
  Namespaces:
    Namespace:  single-project-quota-test
    Status:
      Hard:
        limits.cpu/vmi:       20
        limits.memory/vmi:    20Gi
        requests.cpu/vmi:     20
        requests.memory/vmi:  20Gi
      Used:
        requests.cpu/vmi:     5
        requests.memory/vmi:  5120M
    Namespace:                cluster-wide-quota-a
    Status:
      Hard:
        limits.cpu/vmi:       20
        limits.memory/vmi:    20Gi
        requests.cpu/vmi:     20
        requests.memory/vmi:  20Gi
      Used:
        requests.cpu/vmi:     10
        requests.memory/vmi:  10240M
  Total:
    Hard:
      limits.cpu/vmi:       20
      limits.memory/vmi:    20Gi
      requests.cpu/vmi:     20
      requests.memory/vmi:  20Gi
    Used:
      requests.cpu/vmi:     15
      requests.memory/vmi:  15360M
Events:                     <none>
```

## Life Migration still works with 100% quota exited

Check quota:

```shell
$ oc describe  aacrq example-resource-quota
...
  Total:
    Hard:
      limits.cpu/vmi:       20
      limits.memory/vmi:    20Gi
      requests.cpu/vmi:     20
      requests.memory/vmi:  20Gi
    Used:
      requests.cpu/vmi:     20
      requests.memory/vmi:  20480M
```

Check VMi's

```shell
$ oc get vmi
NAME         AGE     PHASE        IP             NODENAME   READY
no-load-0    16m     Running      10.128.2.232   ucs55      True
no-load-1    16m     Running      10.128.2.228   ucs55      True
no-load-10   9m15s   Running      10.128.2.234   ucs55      True
no-load-11   9m15s   Running      10.129.0.190   ucs56      True
no-load-12   9m13s   Scheduling                             False
no-load-13   9m14s   Scheduling                             False
no-load-14   9m14s   Running      10.129.0.191   ucs56      True
no-load-15   9m14s   Running      10.128.2.236   ucs55      True
no-load-16   9m14s   Scheduling                             False
no-load-17   9m14s   Scheduling                             False
no-load-18   9m14s   Running      10.128.2.235   ucs55      True
no-load-19   9m14s   Scheduling                             False
no-load-2    16m     Running      10.128.2.233   ucs55      True
no-load-3    16m     Running      10.128.2.229   ucs55      True
no-load-4    16m     Running      10.129.0.185   ucs56      True
no-load-5    16m     Running      10.128.2.226   ucs55      True
no-load-6    16m     Running      10.129.0.187   ucs56      True
no-load-7    16m     Running      10.128.2.227   ucs55      True
no-load-8    16m     Running      10.128.2.230   ucs55      True
no-load-9    16m     Running      10.130.0.123   ucs57      True
```

Lets migrate

```shell
$ virtctl  migrate no-load-8
VM no-load-8 was scheduled to migrate
$ oc get vmi no-load-8 --watch
NAME        AGE   PHASE     IP             NODENAME   READY
no-load-8   17m   Running   10.128.2.230   ucs55      True
no-load-8   17m   Running   10.128.2.230   ucs55      True
no-load-8   17m   Running   10.128.2.230   ucs55      True
no-load-8   17m   Running   10.128.2.230   ucs55      True
no-load-8   17m   Running   10.128.2.230   ucs55      True
no-load-8   17m   Running   10.128.2.230   ucs55      True
no-load-8   17m   Running   10.128.2.230   ucs56      True
no-load-8   17m   Running   10.129.0.193   ucs56      True
no-load-8   17m   Running   10.129.0.193   ucs56      False
no-load-8   17m   Running   10.129.0.193   ucs56      True
```
