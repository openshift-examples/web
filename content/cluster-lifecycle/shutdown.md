---
title: Shutdown
linktitle: Shutdown
description: Some information about shutting down a cluster
tags: ['shutdown', 'restart', 'lifecycle']
---

## Some information about shutting down a cluster

Guide to gracefully shut down your cluster.

!!! Warning

    Important
    It is important to take an etcd backup before performing this procedure so that your cluster can be restored if you encounter any issues when restarting the cluster.

    For example, the following conditions can cause the restarted cluster to malfunction:

    * etcd data corruption during shutdown
    * Node failure due to hardware
    * Network connectivity issues

### Certificate Expiration

Check the expiration date of the cluster certificates.

=== "Command"

    ```bash
    oc -n openshift-kube-apiserver-operator \
      get secret kube-apiserver-to-kubelet-signer \
      -o jsonpath='{.metadata.annotations.auth\.openshift\.io/certificate-not-after}'
    ```

=== "Example output"

    ```bash
    oc -n openshift-kube-apiserver-operator \
      get secret kube-apiserver-to-kubelet-signer \
      -o jsonpath='{.metadata.annotations.auth\.openshift\.io/certificate-not-after}'
    2025-11-20T12:30:34Z
    ```

!!! Info

    To ensure that the cluster can restart gracefully, plan to restart it on or before the specified date. As the cluster restarts, the process might require you to manually approve the pending certificate signing requests (CSRs) to recover kubelet certificates.

### Cordon and evacuate the Nodes

Mark all the nodes in the cluster as unschedulable.

```bash
oc get nodes -o name | xargs oc adm cordon
```

Evacuate the pods using the following method:

```bash
for node in $(oc get nodes -l node-role.kubernetes.io/worker -o name); do
  echo ${node} ;
  oc adm drain ${node} \
    --delete-emptydir-data \
    --ignore-daemonsets=true \
    --timeout=15s --force
done
```

### Shutdown the Nodes

Shut down all of the nodes in the cluster.

```bash
for node in $(oc get nodes -o name); do
  oc debug ${node} -- chroot /host shutdown -h 1;
done
```

!!! Note

    It is not necessary to drain control plane nodes of the standard pods that ship with OpenShift Container Platform prior to shutdown. Cluster administrators are responsible for ensuring a clean restart of their own workloads after the cluster is restarted. If you drained control plane nodes prior to shutdown because of custom workloads, you must mark the control plane nodes as schedulable before the cluster will be functional again after restart.

### Shutting down OpenShift with Ceph / OpenShift Data Foundations (simplified)

Source (origin): [Shutting down OpenShift with Ceph / OpenShift Data Foundations (simplified)](https://hackmd.io/@johnsimcall/HJXwaZkJC?utm_source=preview-mode&utm_medium=rec)

Steps:

1. Setup some connection variables
2. Mark the OpenShift nodes as unschedulable which prevents Pods & VMs from restarting
3. Stop everything using ODF a. VMs - gracefully shutdown with oc delete VirtualMachineInstance/... b. Monitoring - graceful shutdown with oc delete Pod/... c. other apps
4. Shutdown the nodes (remaining ODF processes, kube-apiserver, etcd, and other OCP processes)

* [Shutdown ODF first](https://access.redhat.com/solutions/6642401)
* [Shutdown OCP last](https://docs.openshift.com/container-platform/latest/backup_and_restore/graceful-cluster-shutdown.html)

The script below tries to gracefully shutdown a 3-node / "compact" OCP cluster.

```bash
#!/bin/bash

set -euo pipefail

CLUSTER_NAME="tacos"
OC_BIN=/usr/local/bin/oc
KUBECONFIG=/home/jcall/ocp-tacos/kubeconfig
OC_CMD="$OC_BIN --kubeconfig=$KUBECONFIG"


# check if we're connected to the correct cluster
CONNECTED_CLUSTER=$($OC_CMD whoami --show-console)
if [[ $CONNECTED_CLUSTER =~ $CLUSTER_NAME ]]; then
  CERT_EXPIRE=$($OC_CMD -n openshift-kube-apiserver-operator get secret/kube-apiserver-to-kubelet-signer -o jsonpath='{.metadata.annotations.auth\.openshift\.io/certificate-not-after}')
  echo "Please restart the cluster before the certificates expire: $(date -d $CERT_EXPIRE)"
else
  echo "Error: Not connected to $CLUSTER_NAME"
  echo "found $CONNECTED_CLUSTER instead!"
  exit 1
fi

echo "Marking all nodes as Unschedulable"
for i in $($OC_CMD get nodes -o name); do
  $OC_CMD adm cordon $i
done

echo ; echo "Find all Pods and VMs using ODF storage"
export STORAGECLASSES=$(oc get sc -o json | jq -j '.items | .[] | select(.provisioner|endswith("csi.ceph.com")) | .metadata.name')
export PVCS=$(oc get pvc -A -o json | jq -j --arg sc "$STORAGECLASSES" '.items | .[] | select(.spec.storageClassName | inside($sc) )| .metadata.name')
export PODS=$(oc get pods -A -o json | jq -r --arg pvc "$PVCS" '.items | .[] | select(.spec.volumes | try(.[]) | try(.persistentVolumeClaim) | select(.claimName | inside($pvc))) | .metadata.namespace+" "+.metadata.name' | sort | uniq | tee /dev/tty)

echo ; echo "Enter to continue to delete the above pods, or press Ctrl + C to abort"
read yes

echo ; echo "Sending graceful shutdown command to Pods and VMs"
echo "$PODS" | while read line; do
  oc delete pod -n $line
done

# nothing should be using ODF at this point, move on to shutting down the nodes
echo ; echo "Telling the nodes to shutdown/halt in 5 minutes..."
for node in $($OC_CMD get nodes -o name); do
  oc debug $node -- chroot /host shutdown -h 5
done

echo ; echo "Please remember to \"uncordon\" the nodes when the cluster is restarted!"
echo "For example, using this loop command:"
echo "for i in $(oc get nodes -o name); do oc adm uncordon $i; done"
```

## Sources

* [Docs - Shutting down the cluster gracefully](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/backup_and_restore/graceful-shutdown-cluster#graceful-shutdown_graceful-shutdown-cluster)
* [John Call via HackMD - Shutting down OpenShift with Ceph / OpenShift Data Foundations (simplified)](https://hackmd.io/@johnsimcall/HJXwaZkJC?utm_source=preview-mode&utm_medium=rec)
