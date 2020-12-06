---
title: Quota - WiP
linktitle: Quota - WiP
description: TBD
tags:
  - work-in-progress
---

oc apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: storage
spec:
  hard:
    hostpath-provisioner.storageclass.storage.k8s.io/persistentvolumeclaims: 0
    managed-nfs-storage.storageclass.storage.k8s.io/persistentvolumeclaims: 1
EOF

$ oc describe quota/storage
Name:                                                                    storage
Namespace:                                                               cnv-demo
Resource                                                                 Used  Hard
--------                                                                 ----  ----
hostpath-provisioner.storageclass.storage.k8s.io/persistentvolumeclaims  0     0
managed-nfs-storage.storageclass.storage.k8s.io/persistentvolumeclaims   0     1
$

oc apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-hostpath-provisioner
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: hostpath-provisioner
EOF

Error from server (Forbidden): error when creating "STDIN": persistentvolumeclaims "pvc-hostpath-provisioner" is forbidden: exceeded quota: storage, requested: hostpath-provisioner.storageclass.storage.k8s.io/persistentvolumeclaims=1, used: hostpath-provisioner.storageclass.storage.k8s.io/persistentvolumeclaims=0, limited: hostpath-provisioner.storageclass.storage.k8s.io/persistentvolumeclaims=0

oc apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-managed-nfs-storage-1
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: managed-nfs-storage
EOF
persistentvolumeclaim/pvc-managed-nfs-storage-1 created

oc apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-managed-nfs-storage-2
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: managed-nfs-storage
EOF
Error from server (Forbidden): error when creating "STDIN": persistentvolumeclaims "pvc-managed-nfs-storage-2" is forbidden: exceeded quota: storage, requested: managed-nfs-storage.storageclass.storage.k8s.io/persistentvolumeclaims=1, used: managed-nfs-storage.storageclass.storage.k8s.io/persistentvolumeclaims=1, limited: managed-nfs-storage.storageclass.storage.k8s.io/persistentvolumeclaims=1

$ oc describe quota/storage
Name:                                                                    storage
Namespace:                                                               cnv-demo
Resource                                                                 Used  Hard
--------                                                                 ----  ----
hostpath-provisioner.storageclass.storage.k8s.io/persistentvolumeclaims  0     0
managed-nfs-storage.storageclass.storage.k8s.io/persistentvolumeclaims   1     1