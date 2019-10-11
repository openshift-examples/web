---
description: Somes PV & PVC examples
---

# Storage

## PV & PVC - HostPath /var/log 

```bash
# oc adm policy add-cluster-role-to-user sudoer admin
# oc create -f hostPath-var-log.pv.yml --as=system:admin
# oc create -f hostPath.pvc.yml

# oc create sa anyuid
# oc adm policy add-scc-to-user anyuid -z anyuid --as=system:admin

# Don't forget:  chcon -Rt svirt_sandbox_file_t /pv/hostpath-example
oc create -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  creationTimestamp: null
  name: hostpath-var-log
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 100Mi
  hostPath:
    path: /var/log
  persistentVolumeReclaimPolicy: Retain
EOF


```

### PVC

```bash
oc creat -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: hostpath
spec:
  accessModes: [ "ReadWriteMany" ]
  resources:
    requests:
      storage: 100Mi
EOF
```

## Pod with HostPath

```bash
oc create -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: busybox-hostpath
spec:
  containers:
    - name: busybox-hostpath
      image: busybox
      command: [ "/bin/sh", "-c", "while true ; do date; sleep 1; done;" ]
      volumeMounts:
        - mountPath: /hostpath
          name: hostpath
  volumes:
    - name: hostpath
      persistentVolumeClaim:
        claimName: hostpath
  restartPolicy: Never
EOF
```

## Dynamic Provisioning

### PVC with StorageClass

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: example-pvc-rwo
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard
```

#### Example POD to PVC

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox
spec:
  containers:
    - name: busybox
      image: busybox
      command: [ "/bin/sh", "-c", "while true ; do date; sleep 1; done;" ]
      volumeMounts:
        - mountPath: /pvc
          name: pvc
  volumes:
    - name: pvc
      persistentVolumeClaim:
        claimName: example-pvc-rwo
  restartPolicy: Never
```



