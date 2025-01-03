---
title: Storage Migration (Container)
linktitle: Storage Migration
description: Storage Migration for container workload
tags: ['pvc','storage','MTC','v4.17']
---
# Storage Migration for container workload

* Install Migration Toolkit for Containers Operator

Versions:

|Component|Version|
|---|---|
|OpenShift|4.17.7|
|Migration Toolkit for Containers Operator|1.8.5|

## Created MigPlan

By yaml because WebUI do not list namespaces with `openshift-*`

```yaml
apiVersion: migration.openshift.io/v1alpha1
kind: MigPlan
metadata:
  annotations:
    migration.openshift.io/selected-migplan-type: scc
  name: image-registry
  namespace: openshift-migration
spec:
  destMigClusterRef:
    name: host
    namespace: openshift-migration
  liveMigrate: false
  namespaces:
    - openshift-image-registry
  persistentVolumes:
    - capacity: 100Gi
      name: pvc-8059a107-3874-4ac3-b4a2-a747539fb712
      proposedCapacity: 100Gi
      pvc:
        accessModes:
          - ReadWriteMany
        hasReference: true
        name: 'registry-storage-netapp-nas'
        namespace: openshift-image-registry
        volumeMode: Filesystem
      selection:
        action: copy
        copyMethod: filesystem
        storageClass: coe-netapp-nas
        verify: true
      storageClass: ocs-storagecluster-cephfs
      supported:
        actions:
          - skip
          - copy
        copyMethods:
          - filesystem
          - block
          - snapshot
  srcMigClusterRef:
    name: host
    namespace: openshift-migration
```

### Test Pod

```yaml

apiVersion: v1
kind: Pod
metadata:
  generateName: tools-
  labels:
    app: tools
spec:
  containers:
    - name: tools
      image: registry.redhat.io/rhel9/support-tools:9.5
      command:
        - "/bin/sh"
        - "-c"
        - "sleep infinity"
      volumeMounts:
        - mountPath: /src
          name: src
        - mountPath: /dst
          name: dst
  volumes:
    - name: src
      persistentVolumeClaim:
        claimName: registry-storage-ocs
    - name: dst
      persistentVolumeClaim:
        claimName: registry-storage-ocs-mig-7jrm
```

oc rsh $(oc wait --for=condition=Ready pod -l app=tools -o name )
