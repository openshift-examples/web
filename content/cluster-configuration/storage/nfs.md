---
title: NFS Client provisioner
linktitle: NFS Client provisioner
description: TBD
tags:
  - storage
---
# NFS Storage for dynamic provisioning and image registry

## Setup NFS-Server
```bash
yum -y install nfs-utils
systemctl enable --now rpcbind
# RHEL 8: systemctl enable --now nfs-server
# RHEL 7: systemctl enable --now nfs
mkdir -p /srv/nfs-storage-{pv-infra-registry,pv-user-pvs}
chmod 770 /srv/nfs-storage-{pv-infra-registry,pv-user-pvs}

echo "
/srv/nfs-storage-pv-infra-registry 192.168.51.0/24(rw,sync,no_root_squash)
/srv/nfs-storage-pv-user-pvs 192.168.51.0/24(rw,sync,no_root_squash)
" >> /etc/exports

exportfs -ra
```
## Configure image registry
### Create PersistentVolume for image registry

```yaml
oc create -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-registry-storage
spec:
  accessModes:
  - ReadWriteMany
  capacity:
    storage: 100Gi
  nfs:
    path: "/srv/nfs-storage-pv-infra-registry"
    server: "192.168.51.1"
  persistentVolumeReclaimPolicy: Recycle
EOF
```

### Create PersistentVolumeClaim for image registry
```yaml
oc create -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: registry-storage
  namespace: openshift-image-registry
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 100Gi
EOF
```

### Patch Image registry

```bash
oc patch configs.imageregistry.operator.openshift.io cluster --type='json' -p='[{"op": "remove", "path": "/spec/storage" },{"op": "add", "path": "/spec/storage", "value": {"pvc":{"claim": "registry-storage"}}}]'
```


## Deploy nfs-csi


```bash


  
  
  # --set storageClass.create=true \
  # --set storageClass.name=nfs-csi \
  # --set storageClass.parameters.server=10.32.97.1 \
  # --set storageClass.parameters.share=/coe_stormshift_ocp1 \
  # --set storageClass.parameters.share.subDir='${pvc.metadata.namespace}-${pvc.metadata.name}-${pv.metadata.name}'

oc apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-csi
  annotations:
    storageclass.kubevirt.io/is-default-virt-class: 'true'
    storageclass.kubernetes.io/is-default-class: 'true'
provisioner: nfs.csi.k8s.io   
parameters:
  server: 10.32.97.1 
  share:  /coe_stormshift_ocp1      
  subDir: ${pvc.metadata.namespace}-${pvc.metadata.name}-${pv.metadata.name}
reclaimPolicy: Delete
volumeBindingMode: Immediate
allowVolumeExpansion: true
EOF

oc apply -f << EOF
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: nfs-csi-snapclass
driver: nfs.csi.k8s.io
deletionPolicy: Delete
EOF

```


### Air-gapped deployment

```bash
# Part of general oc adm release mirror
export LOCAL_REPOSITORY=ocp4/openshift4
export LOCAL_REGISTRY=host.compute.local:5000
export LOCAL_SECRET_JSON=pullsecret.json

# Mirror nfs-client-provisioner
oc image mirror -a ${LOCAL_SECRET_JSON} \
  quay.io/external_storage/nfs-client-provisioner:latest \
  ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:nfs-client-provisioner-latest

# Deployment
oc process -f https://raw.githubusercontent.com/openshift-examples/external-storage-nfs-client/main/openshift-template-nfs-client-provisioner.yaml \
  -p NFS_SERVER=192.168.51.1 \
  -p NFS_PATH=/var/lib/libvirt/images/air-gapped-pv-user-pvs \
  -p PROVISIONER_IMAGE=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:nfs-client-provisioner-latest | oc apply -f -
```