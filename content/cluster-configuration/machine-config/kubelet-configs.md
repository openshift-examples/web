---
title: Kubelet Configs
linktitle: Kubelet Configs
weight: 22300
description: Example for post-installation configurations on Kubelet
---

# Kubelet Configs

The following configuration for kubelet is applied after the cluster is deployed.

## Example Kubelet Configuration

```yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: KubeletConfig
metadata:
  name: set-virt-values
spec:
  machineConfigPoolSelector:
    matchLabels:
      pools.operator.machineconfiguration.openshift.io/worker: ""
  kubeletConfig:
    autoSizingReserved: true              ### added
    maxPods: 500                          ### added
    nodeStatusMaxImages: -1               ### added
    kubeAPIBurst: 200                     ### added
    kubeAPIQPS: 100                       ### added
    evictionSoft:                         ### added
      memory.available: "50Gi"
    evictionSoftGracePeriod:              ### added
      memory.available: "5m"
    evictionPressureTransitionPeriod: 0s  ### added
```

* `kubeAPIBurst` and `kubeAPIQPS` - Adjusting these values up to `200` and `100` from the default of 100 and 50, respectively, accommodates bulk object creation on the nodes. The lower values are useful on clusters with smaller nodes to keep API server resource utilization reasonable, however with larger nodes this is not an issue.

* `maxPods` - By default, OpenShift sets the maximum Pods per node to 250. This value affects not just the Pods running core OpenShift services and node functions but also virtual machines. For large virtualization nodes that can host many virtual machines, this value is likely too small. If you’re using very large nodes and may have more than 500 VMs and Pods on a node, this value can be increased beyond `500`, however you will also need to adjust the size of the cluster network’s host prefix when deploying the cluster.

* `nodeStatusMaxImage` - The scheduler factors both the count of container images and which container images are on a host when deciding where to place a Pod or virtual machine. For large nodes with many different Pods and VMs, this can lead to unnecessary and undesired behavior. Disabling the `imageLocality` scheduler plugin by setting `nodeStatusMaxImage` to `-1` facilitates balanced scheduling across cluster nodes, avoiding scenarios where VMs are scheduled to the same host as a result of the image already being present vs factoring in other resource availability.

* `autoSizingReserved` - parameter set to `true` to allow OpenShift Container Platform to automatically determine and allocate the system-reserved resources on the nodes associated with the specified label. To disable automatic allocation on those nodes, set this parameter to `false`.
  * Source: [Automatically allocating resources for nodes](https://docs.openshift.com/container-platform/4.15/nodes/nodes/nodes-nodes-resources-configuring.html#nodes-nodes-resources-configuring-auto_nodes-nodes-resources-configuring)

* [Configure CPU manager](https://docs.openshift.com/container-platform/4.15/scalability_and_performance/using-cpu-manager.html#setting_up_cpu_manager_using-cpu-manager-and-topology_manager) - to enable dedicated resources for virtual machines to be assigned. Without CPU manager, virtual machines using dedicated CPU scheduling, such as those configured with the cx instance type, cannot be scheduled.

* [soft eviction](https://docs.openshift.com/container-platform/4.15/post_installation_configuration/node-tasks.html#nodes-nodes-garbage-collection-configuring_post-install-node-tasks) - sets the upper boundary for memory utilization on the nodes before the virtual machines are attempted to be moved to other hosts in the cluster. This value should be set for a reasonable value according to the approximate maximum amount of memory utilization you want on the node, however if all nodes are exceeding this value then workload will not be rescheduled.
