---
title: Descheduler
linktitle: Descheduler
description: Descheduler
tags: ['ocp-v', 'kubevirt']
---
# Descheduler

???+ warning "VM's need an annotion!"
    VM's / Pods need the annotation `descheduler.alpha.kubernetes.io/evict: true` to be included into the descheduler process! By default VM's createed via templates do  not have the annotation.

    ```yaml
    apiVersion: kubevirt.io/v1
    kind: VirtualMachine
    spec:
      template:
        metadata:
          annotations:
            descheduler.alpha.kubernetes.io/evict: "true"
    ```

    Applying the annotation to all VM's in the current namespace:

    ```bash
    for VM in $(kubectl get vm -o jsonpath='{.items[*].metadata.name}'); do
        echo "Updating compute resources for VM: $VM"
        kubectl patch vm "$VM" --type='json' -p="[{'op': 'add', 'path': '/spec/template/metadata/annotations/descheduler.alpha.kubernetes.io~1evict', 'value': 'true'}]"
    done
    ```

## Resources

* [7.14.15. Enabling descheduler evictions on virtual machines](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html-single/virtualization/index#virt-enabling-descheduler-evictions)
* [4.9.1. Descheduler overview](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html-single/nodes/index#nodes-descheduler-about_nodes-descheduler-about)

## Installation

* [Install Operator Kube Descheduler Operator](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html-single/virtualization/index#nodes-descheduler-installing_virt-enabling-descheduler-evictions)

## Configuration

[KubeDescheduler details](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html-single/nodes/index#nodes-descheduler-profiles_nodes-descheduler-about)

```yaml hl_lines="8 10"
apiVersion: operator.openshift.io/v1
kind: KubeDescheduler
metadata:
  name: cluster
  namespace: openshift-kube-descheduler-operator
spec:
  logLevel: Normal
  mode: Automatic
  operatorLogLevel: Normal
  deschedulingIntervalSeconds: 60
  profileCustomizations:
    devEnableEvictionsInBackground: true
    devLowNodeUtilizationThresholds: Medium
```
